import Foundation

struct ProbeEngine {
    private struct RouteContext: Sendable {
        let ip: String
        let interface: String
    }

    private enum PreflightResult: Sendable {
        case proceed(RouteContext?)
        case stop(ProbeOutcome)
    }

    static func perform(configuration: KeepAliveConfiguration) async -> ProbeOutcome {
        let preflightResult: PreflightResult = await Task.detached(priority: .utility) {
            runPreflight(configuration: configuration)
        }.value

        switch preflightResult {
        case .stop(let outcome):
            return outcome
        case .proceed(let routeContext):
            return await Task.detached(priority: .utility) {
                if configuration.transport.isHTTP {
                    return performHTTP(configuration: configuration, route: routeContext)
                }
                return performTCP(configuration: configuration, route: routeContext)
            }.value
        }
    }

    private static func runPreflight(
        configuration: KeepAliveConfiguration
    ) -> PreflightResult {
        if configuration.requireEasyConnect && !easyConnectTunnelIsRunning() {
            return .stop(.skipped("EasyConnect 当前未建立隧道，已跳过。"))
        }

        let host = configuration.normalizedHost
        let resolvedIP = resolveIPv4(host: host)
        let route = resolvedIP.flatMap { ip -> RouteContext? in
            guard let interface = routeInterface(for: ip) else { return nil }
            return RouteContext(ip: ip, interface: interface)
        }

        if configuration.requireTunnelRoute {
            guard let route else {
                return .stop(.skipped("无法确认 \(host) 的 VPN 路由，已跳过。"))
            }
            guard route.interface.hasPrefix("utun") else {
                return .stop(.skipped("目标当前走 \(route.interface)，不是 utun，已跳过。"))
            }
        }

        return .proceed(route)
    }

    private static func performHTTP(
        configuration: KeepAliveConfiguration,
        route: RouteContext?
    ) -> ProbeOutcome {
        let defaultPort = configuration.transport.defaultPort
        let portPart = configuration.port == defaultPort ? "" : ":\(configuration.port)"
        let rawURL = "\(configuration.transport.rawValue.lowercased())://\(configuration.normalizedHost)\(portPart)\(configuration.normalizedPath)"

        guard URL(string: rawURL) != nil else {
            return .failure("请求地址无效：\(rawURL)")
        }

        var arguments = [
            "--noproxy", "*",
            "--connect-timeout", "5",
            "--max-time", "10",
            "--silent",
            "--show-error",
            "--output", "/dev/null",
            "--header", "Cache-Control: no-cache",
            "--user-agent", "EasyConnectKeepAlive/1.0",
            "--write-out", "%{http_code}\t%{remote_ip}\t%{size_download}"
        ]
        if configuration.method == .get {
            arguments.append(contentsOf: ["--range", "0-0"])
        } else {
            arguments.append("--head")
        }
        arguments.append(rawURL)

        let result = runProcess(executable: "/usr/bin/curl", arguments: arguments)
        let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard result.status == 0 else {
            return .failure("\(configuration.method.rawValue) \(rawURL) 失败：\(output)")
        }

        let fields = output.split(separator: "\t", omittingEmptySubsequences: false)
        guard fields.count >= 3, let statusCode = Int(fields[0]) else {
            return .failure("无法解析 curl 响应：\(output)")
        }

        let remoteIP = String(fields[1])
        let downloadedBytes = String(fields[2])
        let routeText = route.map { "，经 \($0.interface)（\($0.ip)）" } ?? ""
        let summary = "\(configuration.method.rawValue) \(rawURL) → HTTP \(statusCode)，\(downloadedBytes) B，远端 \(remoteIP)\(routeText)"
        if (200..<400).contains(statusCode) {
            return .success(summary)
        }
        return .failure(summary)
    }

    private static func performTCP(
        configuration: KeepAliveConfiguration,
        route: RouteContext?
    ) -> ProbeOutcome {
        var arguments = ["-G", "5", "-w", "5"]
        if configuration.tcpPayload.isEmpty {
            arguments.append("-z")
        }
        arguments.append(configuration.normalizedHost)
        arguments.append(String(configuration.port))

        let input = configuration.tcpPayload.isEmpty
            ? nil
            : Data(configuration.tcpPayload.utf8)
        let result = runProcess(
            executable: "/usr/bin/nc",
            arguments: arguments,
            standardInput: input
        )

        let routeText = route.map { "，经 \($0.interface)（\($0.ip)）" } ?? ""
        if result.status == 0 {
            let payloadText = input.map { "，发送 \($0.count) B" } ?? "，仅连接探测"
            return .success("TCP \(configuration.normalizedHost):\(configuration.port) 成功\(payloadText)\(routeText)")
        }

        let detail = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return .failure(
            "TCP \(configuration.normalizedHost):\(configuration.port) 失败" +
            (detail.isEmpty ? "。" : "：\(detail)")
        )
    }

    private static func easyConnectTunnelIsRunning() -> Bool {
        let result = runProcess(
            executable: "/usr/bin/pgrep",
            arguments: [
                "-f",
                "/Applications/EasyConnect.app/Contents/Resources/bin/CSClient.app/Contents/MacOS/CSClient"
            ]
        )
        return result.status == 0
    }

    private static func resolveIPv4(host: String) -> String? {
        if isIPv4(host) {
            return host
        }

        let result = runProcess(
            executable: "/usr/bin/dscacheutil",
            arguments: ["-q", "host", "-a", "name", host]
        )
        guard result.status == 0 else { return nil }

        for line in result.output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("ip_address:") else { continue }
            let value = trimmed.dropFirst("ip_address:".count)
                .trimmingCharacters(in: .whitespaces)
            if isIPv4(value) {
                return value
            }
        }
        return nil
    }

    private static func routeInterface(for ip: String) -> String? {
        let result = runProcess(
            executable: "/sbin/route",
            arguments: ["-n", "get", ip]
        )
        guard result.status == 0 else { return nil }

        for line in result.output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("interface:") else { continue }
            return trimmed.dropFirst("interface:".count)
                .trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let number = Int(part) else { return false }
            return (0...255).contains(number)
        }
    }

    private struct ProcessResult {
        let status: Int32
        let output: String
    }

    private static func runProcess(
        executable: String,
        arguments: [String],
        standardInput: Data? = nil
    ) -> ProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let inputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        if standardInput != nil {
            process.standardInput = inputPipe
        }

        do {
            try process.run()
            if let standardInput {
                inputPipe.fileHandleForWriting.write(standardInput)
                try? inputPipe.fileHandleForWriting.close()
            }
            process.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return ProcessResult(
                status: process.terminationStatus,
                output: String(decoding: data, as: UTF8.self)
            )
        } catch {
            return ProcessResult(status: -1, output: error.localizedDescription)
        }
    }
}
