# 一张填好的卡（样例）

> 真实项目改写过，人名路径已替换。重点看三处：`verify` 是可跑的、`不做` 那一段挡住了范围蔓延、末尾的修订记录说明这张卡第一次写错了。

## T-20261120-03 · 修「有进度、没声音」

- **owner**: mac
- **agent**: mac-agent
- **repo**: `~/code/audiobook-tts-plugin`
- **deadline**: 2026-11-20T15:00:00Z
- **session**: silent-audio
- **verify**: `curl -s localhost:8291/health | jq -e '.status=="ok"'` 退出码 0；且 `curl -s -o /tmp/probe.wav -w '%{size_download}' 'localhost:8291/listening?text=测试一句话' ` > 40KB；`xxd -s 20 -l 2 /tmp/probe.wav` 不是全零

### 目标

手机阅读器里进度条走完、时间也在涨，但全程无声。让它出声。

### 范围

**允许**：读 `mimo-tts/src/local.mjs`、`mimo-tts/sidecar/server.py`、改这两处；在 `PITFALLS.md` 追加一条。
**禁止**：改 `src/service.mjs`（路由层）、改流式默认值、动配置 schema、开 issue。

### 验收（缺一条算失败）

1. **现状**：`/listening` 返回 200 且 Content-Length 正常，但 PCM 数据段全零 —— 说明合成链路"成功"返回了静音，不是路由问题。
2. **方案**：在 Node 侧与 Python 侧各加一道权重完整性校验（文件存在 + 大小 ≥ 600MB），不达标直接拒启并给出人话错误；不达标时不要把静音当成功返回。
3. **不做**：不改流式开关（那是另一件事，`01-stream-default.md`）、不重新设计错误码体系、不动 Hybrid 的降级顺序。

### 失败

`status: blocked`，正文写 `need: <谁> <要什么>`。如果根因不在权重而在推理库版本，也 blocked —— 不自行升级依赖。

---

### 修订记录

- `2026-11-20T11:20Z`：初版把验收写成「音频听起来正常」。mac 标了 blocked 并要求给出可判定条件；改成上面三条命令后重发。
- `2026-11-20T13:05Z`：初版禁止改 `sidecar/server.py`，但方案第 2 条要求 Python 侧也加校验 —— 自相矛盾。解除该禁止，同时限定只加校验、不动推理参数。
