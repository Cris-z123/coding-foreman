# Coding Foreman

Coding Foreman 是一个AI Coding。它覆盖 AI Coding 的核心闭环：理解需求、规划、在独立工作区操作仓库、执行验证、提交/推送，以及创建或审查Pull Request.

## 功能

- 从 Web 界面发起编码、分析、规划、同步和代码审查任务。
- 用 POST + SSE 实时展示消息、计划和 Agent 输出。
- 在独立工作区中管理代码仓库，避免 Agent 直接修改本项目源码。
- 支持保存会话 checkpoint、任务摘要、review findings 和仓库级长期记忆。
- 支持 Pull Request 上下文、差异审查、结构化 finding 与评论发布。

## 架构

```text
Vue 3 + Vite (:3000)
       │ POST SSE
       ▼
FastAPI (:2024)
       ├── API：会话、流式消息、健康检查
       ├── Runtime：任务分类、状态和 SSE 事件编排
       ├── DeepAgents：模型、工具、middleware、子 Agent
       ├── LocalShellBackend：工作区与权限边界
       └── 持久化：checkpoint、业务 Store、长期记忆
                    │
                    ▼
      AI_WORKSPACE_ROOT/projects/<owner>/<repo> → Gitee
```

## 快速开始

### 1. 前置条件

- Python 3.12+
- [uv](https://docs.astral.sh/uv/)
- Node.js 22+ 与 pnpm
- Git

推荐在 Windows PowerShell 中运行。

### 2. 安装依赖

```powershell
# 后端：创建 .venv 并安装 Python 依赖
uv sync

# 前端：安装 JavaScript 依赖
Set-Location ui
pnpm install
Set-Location ..
```

### 3. 配置本地环境

```powershell
Copy-Item .env.example .env
```

编辑 `.env`。至少填写模型配置：

| 变量 | 是否必填 | 用途 |
| --- | --- | --- |
| `DEEPSEEK_API_KEY` | 是 | 主模型 API 密钥 |
| `DEEPSEEK_BASE_URL` | 是 | 主模型 API 地址 |
| `MAIN_MODEL` | 否 | 模型名 |
| `AI_WORKSPACE_ROOT` | 强烈建议 | Agent 操作目标仓库的独立目录 |
| `ZHIPU_API_KEY` | 按需 | `web_search` 工具 |
| `GITEE_TOKEN` / `SCM_GITEE_TOKEN` | 按需 | 仓库与 PR 操作 |

`.env` 只能保存在本机，禁止提交。建议显式设置独立工作区：

```powershell
$env:AI_WORKSPACE_ROOT = 'D:\ai_workspace'
New-Item -ItemType Directory -Force $env:AI_WORKSPACE_ROOT
.venv\Scripts\python.exe scripts\sync_skills.py
```

> 未设置时，Windows 默认工作区为 `E:\ai_workspace`；换机器后可能指向不存在的盘符。

### 4. 启动

分别启动：

```powershell
scripts\start_backend.cmd
scripts\start_ui.cmd
```

或用一个进程同时管理：

```powershell
.venv\Scripts\python.exe scripts\start_all.py
```

- 前端：http://127.0.0.1:3000/agents
- 健康检查：http://127.0.0.1:2024/health

停止服务：

```powershell
.venv\Scripts\python.exe scripts\stop_all.py
```

## 开发与验证

```powershell
# 后端基础自检：不调用模型、不 push、不创建 PR
.venv\Scripts\python.exe agent\tests\verify_backend.py

# Python 静态检查
uv run ruff check agent scripts

# 前端生产构建
Set-Location ui
pnpm build
Set-Location ..
```

真实 Gitee 端到端验证会调用模型并创建 Pull Request，仅可针对测试仓库执行：

```powershell
.venv\Scripts\python.exe agent\tests\verify_gitee_e2e.py https://gitee.com/<owner>/<repo>.git
```

## 目录结构

```text
agent/
  api/            FastAPI 路由与请求模型
  backends/       本地工作区、Shell 和权限边界
  core/           运行时、状态、持久化、流式事件与长期记忆
  skills/         内置 Agent skills
  store/          业务 Store
  tools/          工具
  app.py          FastAPI 应用入口
  server.py       DeepAgents 装配入口
ui/               前端
scripts/          启动、停止、验证和同步脚本
```
