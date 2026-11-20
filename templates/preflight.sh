#!/usr/bin/env bash
# preflight.sh —— 开工前把环境摸一遍，输出人能读也能当 entry 附件的东西。
#
# 设计判据：
#   1. 只读，不改任何东西。可以在任何时刻重复跑。
#   2. 每项都输出 OK / WARN / FAIL，FAIL 退出码非 0。
#   3. 不打印任何密钥，只打印「有没有」。
#   4. 装不上就跳过，不报错——体检脚本自己崩掉是最没用的体检脚本。
#
# 用法：./scripts/preflight.sh [--json]

set -uo pipefail
JSON=0; [ "${1:-}" = "--json" ] && JSON=1
FAILED=0

say()  { [ "$JSON" = 1 ] || printf '%s\n' "$*"; }
ok()   { say "  OK    $*"; }
warn() { say "  WARN  $*"; }
fail() { say "  FAIL  $*"; FAILED=$((FAILED+1)); }
have() { command -v "$1" >/dev/null 2>&1; }

say "== 平台 =="
OSVER="$(sw_vers -productVersion 2>/dev/null || true)"
[ -z "$OSVER" ] && OSVER="$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-unknown}")"
say "  $(uname -s) $(uname -m) · ${OSVER:-unknown}"
say "  shell: ${SHELL:-?} · cwd: $(pwd)"

say "== 运行时 =="
if have node; then
  V=$(node -v | tr -d v); MAJ=${V%%.*}
  [ "${MAJ:-0}" -ge 20 ] && ok "node ${V}" || warn "node ${V}（要求 >= 20）"
else fail "node 未安装"; fi

have python3 && ok "python3 $(python3 -V 2>&1 | awk '{print $2}')" || warn "python3 未安装"
have git    && ok "git $(git --version | awk '{print $3}')"          || fail "git 未安装"
have jq     && ok "jq"                                                || warn "jq 未安装（JSON 校验会麻烦一点）"
have ffmpeg && ok "ffmpeg"                                            || warn "ffmpeg 未安装（可选）"

say "== 凭证（只看有没有，不打印内容）=="
for f in .env .env.local .secrets; do
  [ -e "$f" ] && ok "$f 存在（权限 $(stat -f '%Sp' "$f" 2>/dev/null || stat -c '%A' "$f" 2>/dev/null)）"
done
[ -z "$(ls -A .env .env.local 2>/dev/null)" ] && warn "没有本地环境文件（.env / .env.local）"
for v in GITHUB_TOKEN GH_TOKEN; do
  [ -n "${!v:-}" ] && ok "$v 已注入" || say "  ----  $v 未注入（不一定是问题）"
done

say "== 端口 =="
# PORTS="8080 3000" ./preflight.sh
for p in ${PORTS:-8080}; do
  if have lsof && lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then
    warn "$p 已被占用：$(lsof -nP -iTCP:"$p" -sTCP:LISTEN | awk 'NR==2{print $1" pid "$2}')"
  else ok "$p 空闲"; fi
done

say "== 仓库状态 =="
if git rev-parse --git-dir >/dev/null 2>&1; then
  ok "分支 $(git rev-parse --abbrev-ref HEAD) · $(git log -1 --format='%h %s' 2>/dev/null | cut -c1-60)"
  N=$(git status --porcelain | wc -l | tr -d ' ')
  [ "$N" = 0 ] && ok "工作区干净" || warn "工作区有 $N 个未提交改动"
else fail "不是 git 仓库（先 git init && git add -A && git commit）"; fi

say "== 约定的文件 =="
for f in AGENTS.md DESIGN.md DECISIONS.md PITFALLS.md; do
  [ -f "$f" ] && ok "$f" || warn "$f 缺失"
done

say
if [ "$FAILED" -gt 0 ]; then say "== 有 $FAILED 项 FAIL，先别开工 =="; exit 1; fi
say "== 体检通过 =="
