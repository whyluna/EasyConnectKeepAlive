## EasyConnect 保活 v1.0.1

首个公开版本。

### 主要功能

- HTTPS、HTTP、TCP 三种探测协议。
- 自定义地址、端口、请求方式、路径、TCP 内容和发送间隔。
- EasyConnect 隧道进程检查。
- `utun` 目标路由检查，减少请求误走普通网络的风险。
- 单次测试、开始/停止控制和运行日志。
- HTTP GET 在服务器支持时只下载 1 字节。
- 不开机自启，不保存 VPN 凭据，不收集遥测。
- Apple Silicon + Intel 通用应用。

### 本地验收

- HTTPS 测试返回 HTTP 206，下载 1 B。
- 路由回读确认目标经过 `utun4`。
- 在同一华科 VPN 环境中连续观察超过 1 小时，周期请求持续成功。

### 安装说明

下载 `EasyConnect-KeepAlive-v1.0.1-macOS-universal.zip`，解压后将应用拖入“应用程序”。

此版本使用本地临时签名，未经过 Apple Developer ID 公证。首次打开若 macOS 提示无法验证开发者，请在 Finder 中右键应用并选择“打开”。

> 本工具不会自动登录或重新连接 EasyConnect，也不会绕过短信认证/MFA。默认华科地址仅为示例，其他组织请改为自己有权访问的 VPN 内部目标。
