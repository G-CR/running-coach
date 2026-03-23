# AI Running Coach

AI Running Coach 是一个面向跑者训练场景的 MVP 单体仓库，包含 iOS 客户端、后端 API、分析 Worker，以及共享领域模型。项目当前聚焦「导入训练数据 → 生成分析结果 → 在移动端查看反馈」这条最小可用链路。

## 项目特性

- iOS 客户端：提供跑步训练计划、训练详情、反馈与同步相关界面。
- FastAPI 服务：承载健康检查、训练数据接入与业务接口。
- 分析 Worker：处理分析任务，输出规则化训练反馈。
- 共享领域模型：统一 API 与 Worker 之间的核心数据结构。
- 回放与发布检查：内置 golden fixture 回放和本地验证 Runbook。

## 仓库结构

```text
.
|-- apps/ios                    # iPhone 客户端与测试工程
|-- services/api                # FastAPI 服务
|-- services/analysis-worker    # 后台分析任务
|-- packages/domain             # 共享 Python 领域模型
|-- infra/supabase              # Supabase 相关迁移与初始化数据
|-- docs/runbooks               # 本地开发与回放检查文档
`-- docs/fixtures/workouts      # 测试与回归使用的训练样例
```

## 环境要求

- macOS（iOS 工程生成与测试需要 Xcode 环境）
- Python >= 3.14
- Xcode
- [xcodegen](https://github.com/yonaskolb/XcodeGen)
- 可选：Docker / Docker Compose（用于本地 PostgreSQL）

## 快速开始

### 1. 克隆仓库

```bash
git clone git@github.com:G-CR/running-coach.git
cd running-coach
```

### 2. 创建 Python 虚拟环境

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e packages/domain
pip install -e services/api
pip install -e services/analysis-worker
```

如果已经创建过虚拟环境，可以直接复用：

```bash
source .venv/bin/activate
```

### 3. 配置环境变量

先复制示例配置：

```bash
cp .env.example .env
```

`.env.example` 中包含以下变量：

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_URL`
- `OPENAI_API_KEY`

本地开发时，如果只验证 API + Worker 的最小链路，可以优先使用 SQLite：

```bash
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
```

### 4. 启动本地依赖（可选）

如果你想使用 PostgreSQL，可以直接启动仓库内的 Compose 配置：

```bash
docker compose up -d
```

默认数据库配置：

- 数据库名：`ai_running_coach`
- 用户名：`postgres`
- 密码：`postgres`
- 端口：`5432`

### 5. 启动 API

```bash
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/api"
.venv/bin/python -m uvicorn app.main:app --reload --app-dir services/api
```

健康检查：

```bash
curl http://127.0.0.1:8000/health
```

### 6. 运行分析 Worker

```bash
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/analysis-worker"
.venv/bin/python -m app.main <analysis_job_id>
```

## 常用命令

```bash
make test-api
make test-domain
make ios-generate
```

也可以直接执行完整 Python 测试集：

```bash
.venv/bin/python -m pytest packages/domain/tests services/api/tests services/analysis-worker/tests -q
```

## iOS 开发

先生成 Xcode 工程：

```bash
xcodegen generate --spec apps/ios/project.yml
```

运行 iOS 测试：

```bash
xcodebuild -project apps/ios/AIRunningCoach.xcodeproj \
  -scheme AIRunningCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /Users/ws/Desktop/Running/ai-running-coach/.derived-data \
  test
```

## 回放与回归检查

运行 golden fixture 回放测试：

```bash
.venv/bin/python -m pytest services/analysis-worker/tests/test_golden_replays.py -q
```

查看本地分析任务队列：

```bash
sqlite3 .local-dev.db "select id, trigger, status, created_at from analysis_jobs order by created_at;"
```

如果未来接入真实 LLM，建议保留模板兜底路径，确保在以下场景仍可稳定验证：

- 网络不可用
- 模型密钥缺失
- 回放测试需要确定性输出

## 文档入口

- 本地开发说明：`docs/runbooks/local-dev.md`
- 回放与重分析说明：`docs/runbooks/reanalysis.md`
- 训练样例说明：`docs/fixtures/workouts/README.md`
- 接口契约示例：`docs/contracts/workout-import.json`

## 贡献说明

欢迎提交 Issue 和 Pull Request。在提交代码前，建议至少完成以下检查：

```bash
.venv/bin/python -m pytest packages/domain/tests services/api/tests services/analysis-worker/tests -q
xcodegen generate --spec apps/ios/project.yml
```

## 许可证

当前仓库暂未单独声明许可证；如需对外发布，请在正式开源前补充 `LICENSE` 文件。
