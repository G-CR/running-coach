# iPhone 真机安装与联调指南

这份 runbook 用于把 `AIRunningCoach` 安装到你的 iPhone，并接到本机或局域网内的 API 服务。

## 1. 前置条件

- 一台已安装 Xcode 的 Mac mini。
- 一台登录了同一 Apple ID 或已加入开发团队的 iPhone。
- iPhone 与 Mac mini 在同一个局域网内。
- 本地 API 已能启动，参考 `docs/runbooks/local-dev.md`。

## 2. 启动本地 API

先在 Mac mini 上启动 API：

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/api"
.venv/bin/python -m uvicorn app.main:app --reload --app-dir services/api --host 0.0.0.0 --port 8000
```

确认健康检查通过：

```bash
curl http://127.0.0.1:8000/health
```

## 3. 把 API 地址改成 Mac mini 的局域网 IP

iPhone 不能访问自己的 `127.0.0.1` 去命中 Mac mini，所以真机联调时要把 API 地址改成 Mac mini 的局域网 IP，例如 `http://192.168.31.20:8000`。

先查看 Mac mini 的局域网 IP：

```bash
ipconfig getifaddr en0
```

然后修改 `apps/ios/AIRunningCoach/Info.plist` 里的 `AIRunningCoachAPIBaseURL`：

```xml
<key>AIRunningCoachAPIBaseURL</key>
<string>http://192.168.31.20:8000</string>
```

说明：

- `AIR_RUNNING_COACH_API_BASE_URL` 环境变量更适合模拟器或 Xcode 本地调试。
- 真机安装后，默认以 `Info.plist` 中的地址为准。

## 4. 配置签名与唯一 Bundle ID

先重新生成 Xcode 工程：

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
xcodegen generate --spec apps/ios/project.yml
```

然后在 Xcode 中打开 `apps/ios/AIRunningCoach.xcodeproj`，完成以下设置：

1. 选中 `AIRunningCoach` target。
2. 在 `Signing & Capabilities` 中勾选 `Automatically manage signing`。
3. 选择你的 `Team`。
4. 把 `Bundle Identifier` 改成你自己的唯一值，例如 `com.<your-name>.airunningcoach`。

注意：

- 如果你后续还会重复执行 `xcodegen generate`，请同步把 `apps/ios/project.yml` 中的 `PRODUCT_BUNDLE_IDENTIFIER` 改成同一个值，否则会被生成结果覆盖。
- 当前工程已经包含 `HealthKit` entitlement，真机运行时会弹出健康数据授权框。

## 5. 连接 iPhone 并安装 App

1. 用数据线连接 iPhone 与 Mac mini。
2. 在 iPhone 上点击「信任此电脑」。
3. 如系统提示，打开 iPhone 的「开发者模式」。
4. 在 Xcode 顶部设备列表里选择你的 iPhone。
5. 按 `Run`（`Cmd + R`）安装并启动 App。

首次安装时，如果出现开发者证书未信任：

- 打开 iPhone 的「设置」→「通用」→「VPN 与设备管理」。
- 信任对应的开发者证书后重新启动 App。

## 6. 首次启动后的操作

App 启动后，进入个人页，按下面顺序操作：

1. 点击「请求 HealthKit 授权」。
2. 在系统弹窗中允许读取跑步与相关健康数据。
3. 确认页面上的 API 地址是局域网地址，不是 `127.0.0.1`。
4. 点击「同步最近跑步」。

当前最小可用链路支持：

- 读取跑步 workout；
- 读取平均 / 最大心率；
- 基于步数估算平均步频；
- 上传结构化跑步记录到本地 API。

## 7. 常见问题

### 7.1 手机点同步没有反应

优先检查：

- iPhone 与 Mac mini 是否在同一个 Wi-Fi。
- `AIRunningCoachAPIBaseURL` 是否仍然是 `127.0.0.1`。
- Mac mini 防火墙是否拦截了 `8000` 端口。
- API 是否用 `--host 0.0.0.0` 启动。

### 7.2 HealthKit 没有弹窗

先检查：

- 当前运行目标是否是真机，而不是模拟器。
- iPhone 是否已经开启健康数据权限。
- Xcode 是否使用了正确的签名 Team。

### 7.3 重新生成工程后签名配置丢失

如果你只改了 Xcode 工程，没有同步更新 `apps/ios/project.yml`，重新执行 `xcodegen generate` 后会被覆盖。长期保留的配置，应当回写到 `apps/ios/project.yml`。

## 8. 当前限制

当前真机导入链路以「先跑通 HealthKit 授权 + 最小同步闭环」为目标，暂时还有这些限制：

- `laps`、心率 / 配速分布还没有做完整导入；
- 轨迹 route 暂未导入，`hasRoute` 当前固定为 `false`；
- 本地开发 token 采用单用户开发态方案，不适合直接用于生产环境。
