#!/usr/bin/env bash
# bootstrap.sh —— 把五份脚手架文件铺进一个目录。不覆盖已有文件。
#
#   ./bootstrap.sh ~/code/my-thing --name my-thing
#   ./bootstrap.sh . --name my-thing --only missing   # 只补缺的
#   ./bootstrap.sh . --name my-thing --dry-run

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""; NAME=""; ONLY=0; DRY=0; OWNER="${USER:-owner}"

while [ $# -gt 0 ]; do
  case "$1" in
    --name)  NAME="${2:?}"; shift 2 ;;
    --only)  [ "${2:-}" = "missing" ] && ONLY=1; shift 2 ;;
    --owner) OWNER="${2:?}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "用法: $0 <目标目录> --name <项目名> [--only missing] [--dry-run]"; exit 2; }
[ -n "$NAME" ]   || NAME="$(basename "$TARGET")"
mkdir -p "$TARGET"; TARGET="$(cd "$TARGET" && pwd)"
DATE="$(date +%Y-%m-%d)"

copy() {  # copy <模板> <目标相对路径>
  local from="$HERE/templates/$1" to="$TARGET/$2"
  if [ -e "$to" ]; then
    [ "$ONLY" = 1 ] && { echo "  跳过  ${2}（已存在）"; return; }
    echo "  保留  ${2}（已存在，不覆盖）"; return
  fi
  if [ "$DRY" = 1 ]; then echo "  将写  $2"; return; fi
  mkdir -p "$(dirname "$to")"
  sed -e "s|{{PROJECT}}|$NAME|g" -e "s|{{OWNER}}|$OWNER|g" -e "s|{{DATE}}|$DATE|g" "$from" > "$to"
  chmod +x "$to" 2>/dev/null || true
  echo "  写入  $2"
}

echo "铺脚手架 → ${TARGET}（${NAME}）"
copy AGENTS.md   AGENTS.md
copy CARD.md     tasks/_TEMPLATE.md
copy DESIGN.md   DESIGN.md
copy DECISIONS.md DECISIONS.md
copy PITFALLS.md PITFALLS.md
copy preflight.sh scripts/preflight.sh

if [ "$DRY" = 0 ]; then
  mkdir -p "$TARGET/entries"
  touch "$TARGET/entries/.gitkeep"
fi

cat <<EOF

下一步（十分钟）：
  1. 填 DESIGN.md 的「一句话定位」和「它不做什么」——只填这两栏也够开工。
  2. 把第一件事写成 tasks/T-$(date +%Y%m%d)-01.md（owner / 范围 / 验收 / 失败）。
  3. 跑一次 ./scripts/preflight.sh，输出贴进 DESIGN「验收口径」。
  4. 之后每撞到一个「不报错但结果是错的」，往 PITFALLS.md 加一条。
  5. 每做一个不可逆决定，往 DECISIONS.md 加一条，务必写「否掉的选项」。
EOF
