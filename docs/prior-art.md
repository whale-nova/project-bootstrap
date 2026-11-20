# 同类东西调研（2026-11）

调研目的不是证明这套东西好，是找**别人已经想明白、而这里还没想明白**的部分。

## 六个流派

| 流派 | 代表 | 核心机制 | 解决什么 | 与本仓的关系 |
|---|---|---|---|---|
| 规格流水线 | [spec-kit](https://github.com/github/spec-kit) ★151k | constitution → specify → clarify → plan → tasks → analyze → implement → converge，阶段间有闸 | 需求到代码的可追溯性 | 它有流程，我没有。**没有闸是漏**：卡做完才发现 DESIGN 没更新，现在没人挡 |
| 三件套规格 | [Kiro](https://www.verdent.ai/guides/agents/kiro-spec-driven-development) | requirements.md / design.md / tasks.md，需求用 EARS 写（`WHEN … THE SYSTEM SHALL …`） | 需求可测、非工程师能审 | 我的 `DESIGN 不变量` ≈ 它的 constitution；我的 CARD 验收缺一句形式化「期望行为」 |
| 角色编排 | [BMAD](https://github.com/bmad-code-org/BMAD-METHOD) ★56k | PM/架构/开发/QA 各是 agent，文档在角色间传递 | 大团队分工 | 拒绝：一个人一个仓，编排的成本 > 收益。批评它的原话是「生成的规格文档吃光 token」 |
| 标准即技能 | [Agent OS](https://github.com/buildermethods/agent-os) ★5.6k | `standards/` 按需被 skill 调起；每任务组一个 subagent 隔离上下文 | 上下文预算 | 吸收：DESIGN/PITFALLS 不该 always-on，应按路径/关键词命中才读。DSH 有 skill 机制，正好接 |
| 任务是文件 | [Backlog.md](https://github.com/MrLesk/Backlog.md) ★7.4k | 一任务一 md；验收标准 + DoD + 实现计划 + 依赖；一任务 = 一个上下文窗口 = 一个 PR | **人的注意力**，不是 agent 的智商 | 最接近本仓的 CARD。它的立论比我狠：「一小时生成的代码你一天读不完，瓶颈是注意力」 |
| 方法论即技能 | [superpowers](https://github.com/obra/superpowers) ★322k | 技能自动触发：说清要什么 → 切小段给你签 → 计划 → subagent 逐任务执行 | 让 agent 自己别急着写代码 | 它管**干活时的行为**，本仓管**留下的物证**。两者不冲突，可以同时装 |

另外两个相关但不同层的：[OpenSpec](https://github.com/Fission-AI/OpenSpec) ★75k（变更提案制的 delta 规格）、[PRP](https://github.com/coleam00/context-engineering-intro) ★14k（把 PRD + 代码库情报 + runbook 打成一个包，一次过一个 feature）。PRP 最接近「反向写提示词」的原问题，它的已知问题是每个 feature 都要人工策展一份。

## 该吸收的四条

**1. 决定要有状态机。** 抄 [MADR](https://github.com/adr/madr)：`proposed / accepted / superseded by NNNN / deprecated`。改决定时**不改旧条目**，写新的一条并引用旧的。现在的 DECISIONS 是 append-only 但没有"这条死了"的标记，半年后读不出哪条还活着。

**2. 台账要记「为什么没早发现」。** 抄无责复盘：光记根因不够，要记**检测缺口**——它静默了几周、是什么让人最后发现的。这一栏能直接逼出「该加什么检查」，比「兜底」有产出。

**3. 一个任务 = 一个上下文窗口。** 抄 Backlog.md。卡大到需要分几次读，就会在第二次读的时候丢掉第一次的判断。

**4. 验收补一句 EARS。** `WHEN <触发> THE SYSTEM SHALL <行为>` 一行，再跟命令。英文那套不用照抄，中文也成立：「当声码器权重缺失时，系统应当拒绝启动并给出人话错误」。它比散文准，比命令早——命令还没写出来时，这句话就能判。

## 该拒绝的两条

**BMAD 式的角色编排**：四个角色互相传文档，在没有多人协作的仓里是纯开销。

**spec-kit 式九阶段**：闸太多。它的 `/clarify` `/analyze` 在单个会话里等价于「再想一遍」，而 DSH 里我已经可以在动手前问。留一条闸就够：**卡没写 verify 不许开工**。

## 一个空位

上面六个流派，全都在做「意图 → 计划 → 任务」。没有一个把**「环境怎么静默地骗人」**当成一等公民的产物。

这不是没想到，是有数据支撑的空白：有研究测过，agent 对**显式报错**的标记率 91.3%，对**格式正确但值错了**的只有 58.8%（[Loud Failures, Quiet Failures](https://agentpatterns.ai/patterns/anti-patterns)）。人更低。所以「沉默失败台账」不是补充材料，是唯一能补上这 32 个百分点的东西。

同一份资料给的五类机制，可以直接当台账的分类轴：

1. 环境怪癖（版本、平台、路径、区域）
2. 设计假设错配（默认值、单位、编码）
3. 错误被吞（catch 了但没上报、降级成静默）
4. 连锁幻觉（上一步错，下一步基于它继续"成功"）
5. 操作遗漏（忘了那一步，但流程看起来走完了）

按这五类归档，比按时间序有用——时间序只回答「最近踩了什么」，分类回答「哪一类还没设防」。

## 结论

本仓的位置：**不做流程编排，只发明物证**。别人保证「照着做能到」，本仓保证「换个人接手也知道哪里会骗人、哪条决定还活着」。

v0.2 据此改了四处：DECISIONS 加状态机、PITFALLS 加检测缺口与五类分类、CARD 加「一任务一窗口」与依赖、README 第一屏改成立场。
