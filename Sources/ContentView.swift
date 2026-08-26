import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var controller = KeepAliveController()

    @AppStorage("transport") private var transportRaw = KeepAliveTransport.https.rawValue
    @AppStorage("address") private var address = "one.hust.edu.cn"
    @AppStorage("port") private var port = 443
    @AppStorage("httpMethod") private var methodRaw = KeepAliveHTTPMethod.get.rawValue
    @AppStorage("requestPath") private var requestPath = "/"
    @AppStorage("tcpPayload") private var tcpPayload = ""
    @AppStorage("intervalSeconds") private var intervalSeconds = 300
    @AppStorage("requireEasyConnect") private var requireEasyConnect = true
    @AppStorage("requireTunnelRoute") private var requireTunnelRoute = true

    private var transport: KeepAliveTransport {
        KeepAliveTransport(rawValue: transportRaw) ?? .https
    }

    private var method: KeepAliveHTTPMethod {
        KeepAliveHTTPMethod(rawValue: methodRaw) ?? .get
    }

    private var configuration: KeepAliveConfiguration {
        KeepAliveConfiguration(
            transport: transport,
            address: address,
            port: port,
            method: method,
            path: requestPath,
            tcpPayload: tcpPayload,
            intervalSeconds: intervalSeconds,
            requireEasyConnect: requireEasyConnect,
            requireTunnelRoute: requireTunnelRoute
        )
    }

    var body: some View {
        VStack(spacing: 18) {
            header

            GroupBox("请求设置") {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                    GridRow {
                        label("协议")
                        Picker("协议", selection: transportBinding) {
                            ForEach(KeepAliveTransport.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    GridRow {
                        label("发送地址")
                        TextField("例如 one.hust.edu.cn", text: $address)
                            .textFieldStyle(.roundedBorder)
                    }

                    GridRow {
                        label("端口")
                        HStack {
                            TextField("端口", value: $port, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                            Text("默认：\(transport.defaultPort)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }

                    if transport.isHTTP {
                        GridRow {
                            label("请求")
                            HStack(spacing: 10) {
                                Picker("请求方式", selection: methodBinding) {
                                    ForEach(KeepAliveHTTPMethod.allCases) { item in
                                        Text(item.rawValue).tag(item)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 110)

                                TextField("路径，例如 /", text: $requestPath)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    } else {
                        GridRow {
                            label("发送内容")
                            TextField("可留空，仅建立 TCP 连接", text: $tcpPayload)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    GridRow {
                        label("发送间隔")
                        HStack {
                            TextField("秒", value: $intervalSeconds, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                            Text("秒（华科约 20 分钟超时，建议 300–600 秒）")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 6)
                .disabled(controller.isRunning)
            }

            GroupBox("发送条件") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("仅在 EasyConnect 隧道进程在线时发送", isOn: $requireEasyConnect)
                    Toggle("仅在目标路由经过 utun 时发送", isOn: $requireTunnelRoute)
                    Text("建议保持两项开启；这样请求不会在 VPN 断开后误走普通网络。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .disabled(controller.isRunning)
            }

            controls
            logPanel
        }
        .padding(22)
        .frame(minWidth: 680, minHeight: 700)
        .onDisappear {
            controller.stop()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("EasyConnect 保活")
                    .font(.title2.weight(.semibold))
                Text("仅在你点击开始后发送；停止或退出应用后立即结束。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
                Text(controller.state.title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(statusColor.opacity(0.12), in: Capsule())
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if controller.isRunning {
                    controller.stop()
                } else {
                    controller.start(configuration: configuration)
                }
            } label: {
                Label(
                    controller.isRunning ? "停止保活" : "开始保活",
                    systemImage: controller.isRunning ? "stop.fill" : "play.fill"
                )
                .frame(minWidth: 115)
            }
            .buttonStyle(.borderedProminent)
            .tint(controller.isRunning ? .red : .blue)
            .controlSize(.large)

            Button("立即测试") {
                controller.testOnce(configuration: configuration)
            }
            .controlSize(.large)
            .disabled(controller.isRunning)

            Spacer()

            Text(controller.lastResult)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 360, alignment: .trailing)
        }
    }

    private var logPanel: some View {
        GroupBox {
            VStack(spacing: 8) {
                HStack {
                    Text("运行记录")
                        .font(.headline)
                    Spacer()
                    Button("清空") {
                        controller.clearLogs()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(controller.logs.isEmpty)
                }

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 7) {
                            if controller.logs.isEmpty {
                                Text("点击“立即测试”可先验证一次配置。")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            ForEach(controller.logs) { entry in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: icon(for: entry.kind))
                                        .foregroundStyle(color(for: entry.kind))
                                        .frame(width: 14)
                                    Text(entry.date, format: .dateTime.hour().minute().second())
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                    Text(entry.message)
                                        .textSelection(.enabled)
                                }
                                .font(.caption)
                                .id(entry.id)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: controller.logs.count) {
                        if let last = controller.logs.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .frame(minHeight: 125)
            }
        }
    }

    private var transportBinding: Binding<KeepAliveTransport> {
        Binding(
            get: { transport },
            set: { newValue in
                let oldDefault = transport.defaultPort
                transportRaw = newValue.rawValue
                if port == oldDefault {
                    port = newValue.defaultPort
                }
            }
        )
    }

    private var methodBinding: Binding<KeepAliveHTTPMethod> {
        Binding(
            get: { method },
            set: { methodRaw = $0.rawValue }
        )
    }

    private var statusColor: Color {
        switch controller.state {
        case .stopped: .secondary
        case .checking: .blue
        case .running: .green
        case .waiting: .orange
        case .error: .red
        }
    }

    private func label(_ value: String) -> some View {
        Text(value)
            .frame(width: 76, alignment: .trailing)
            .foregroundStyle(.secondary)
    }

    private func icon(for kind: KeepAliveController.LogEntry.Kind) -> String {
        switch kind {
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    private func color(for kind: KeepAliveController.LogEntry.Kind) -> Color {
        switch kind {
        case .info: .blue
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }
}
