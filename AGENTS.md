# AGENTS.md

本文件供在此仓库工作的开发者和编码 Agent 使用。开始改动前先阅读 [README.md](README.md)。

## 项目背景

Coding Foreman 是 AI Coding 项目。主链路为：网页接收任务 → FastAPI 创建或恢复会话 → DeepAgents 调用模型、工具和子 Agent → 在独立工作区操作仓库 → 通过 SSE 将过程返回 Vue 前端。

## 架构与职责

```text
ui/                     Vue 3 + Vite 前端；开发端口 3000
agent/app.py            FastAPI 应用、环境加载、日志与 CORS；端口 2024
agent/api/              HTTP 路由、Dashboard SSE 接口与请求模型
agent/core/runtime.py   任务分类、计划确认、状态更新和运行编排
agent/core/streaming_runtime.py
                        DeepAgents 事件转 SSE
agent/server.py         模型、工具、子 Agent、backend、middleware 装配
agent/backends/         文件后端 工作区、Shell 命令与文件权限边界
agent/src/tools/        Agent工具
agent/src/store/        业务 Store
scripts/                启动、停止、验证和同步脚本
data/、logs/            本机运行数据；不提交
```

持久化职责必须分清：

- `checkpoints.sqlite` 是会话消息、工具状态和 thread state 的权威来源；前端聊天历史从这里恢复。
- `store.sqlite` 保存任务摘要、仓库地址、PR URL 和结构化 review findings，不保存聊天正文。
- `langgraph_store.sqlite` 保存仓库级长期记忆。

## 环境与命令

- Python `>=3.12`，用 `uv` 管理依赖。
- 前端使用 Node.js `>=22`、pnpm、Vue 3 和 Vite。
- 从 `.env.example` 创建 `.env`；`.env` 永不提交。
- 显式设置 `AI_WORKSPACE_ROOT`，且必须位于本仓库外；目标仓库放在 `<AI_WORKSPACE_ROOT>/projects/`。

```powershell
uv sync
Set-Location ui; pnpm install; Set-Location ..
.venv\Scripts\python.exe scripts\sync_skills.py

# 启动
scripts\start_backend.cmd
scripts\start_ui.cmd
# 或：.venv\Scripts\python.exe scripts\start_all.py

# 验证
.venv\Scripts\python.exe agent\tests\verify_backend.py
uv run ruff check agent scripts
Set-Location ui; pnpm build; Set-Location ..
```

`agent\tests\verify_gitee_e2e.py` 会调用模型并创建 PR，只能针对测试仓库运行。

## 开发约定

### 后端与前端

- `agent/app.py` 只负责启动配置和路由注册；HTTP 逻辑放 `agent/api/`，业务编排放 `agent/core/runtime.py`。
- 新增 Agent 能力前先划分到模型、工具、backend、中间件或 runtime 中一个明确职责，避免把业务逻辑堆进路由。
- 用户可见的 Agent 指引和 Review 输出使用中文；代码标识符、路径和命令可保留英文。
- 编码任务必须经过 `runtime.py` 的计划确认流程；不要绕过它直接实施。
- 聊天历史以 checkpoint 为准，禁止把业务 Store 作为第二个消息源。
- 前端 API 或 SSE 事件变动时，同时检查 `ui/src/api/`、stores 与组件的消费逻辑。

### 安全边界

- Agent 只能在 `AI_WORKSPACE_ROOT` 下的目标工作区操作；不得让工具修改本项目或任意主机路径。
- 修改 `LocalShellBackend`、`permissions.py`、`safe_http.py` 或工具权限前，先阅读调用链并补充针对性验证。
- Reviewer 子 Agent 只读目标项目；不要赋予它提交、push、创建 PR 或修改 `/projects` 的权限。
- 不记录、不输出、不提交密钥、令牌、Cookie、私钥、SQLite 数据或运行日志。

### 代码与文档

- Python 遵循 Ruff 规则 `E,F,W,I,UP,B`，沿用现有类型注解、模块文档字符串和职责边界。
- 对外行为、环境变量、启动方式或接口变化时，同步更新 README 或相应 `docs/`。
- `scripts/*.cmd` 必须保持 **ASCII 编码 + CRLF 换行**；不要加入中文注释，也不要改为 LF。

## 提交前检查

按改动范围执行：

```powershell
uv run ruff check agent scripts
.venv\Scripts\python.exe agent\tests\verify_backend.py
Set-Location ui; pnpm build; Set-Location ..
git diff --check
git status --short
```

不要提交未验证的功能、构建产物或本地运行数据。真实 Gitee e2e 测试有外部副作用，不是常规提交前检查。

## 常见问题

| 现象 | 优先检查 |
| --- | --- |
| `Missing required environment variable` | `.env` 是否存在，`DEEPSEEK_API_KEY` 和 `DEEPSEEK_BASE_URL` 是否已填写。 |
| 工作区落到不存在的盘符 | 显式设置 `AI_WORKSPACE_ROOT`；Windows 默认值为 `E:\ai_workspace`。 |
| 前端无法连接后端 | 检查 `http://127.0.0.1:2024/health`、Vite 代理与 `VITE_DASHBOARD_API_BASE_URL`。 |
| `.cmd` 脚本异常 | 确认仍为 ASCII + CRLF，且 `.venv` 和 `ui/node_modules` 已安装。 |
| 刷新后消息缺失或重复 | 检查 checkpoint 历史恢复和 SSE 事件合并；不要用 Store 恢复聊天正文。 |
| Gitee 操作失败 | 检查 URL、`GITEE_TOKEN` / `SCM_GITEE_TOKEN`、令牌权限与测试仓库范围。 |
| Agent 无法修改文件 | 检查工作区映射、`LocalShellBackend` 限制及当前任务是否为只读类型。 |
| SQLite 被锁定 | 确认没有遗留后端进程；使用 `scripts/stop_all.py` 后重试。 |
