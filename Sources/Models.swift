import Foundation

enum KeepAliveTransport: String, CaseIterable, Identifiable, Sendable {
    case https = "HTTPS"
    case http = "HTTP"
    case tcp = "TCP"

    var id: String { rawValue }

    var defaultPort: Int {
        switch self {
        case .https: 443
        case .http: 80
        case .tcp: 22
        }
    }

    var isHTTP: Bool {
        self != .tcp
    }
}

enum KeepAliveHTTPMethod: String, CaseIterable, Identifiable, Sendable {
    case get = "GET"
    case head = "HEAD"

    var id: String { rawValue }
}

struct KeepAliveConfiguration: Sendable {
    let transport: KeepAliveTransport
    let address: String
    let port: Int
    let method: KeepAliveHTTPMethod
    let path: String
    let tcpPayload: String
    let intervalSeconds: Int
    let requireEasyConnect: Bool
    let requireTunnelRoute: Bool

    var normalizedHost: String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let components = URLComponents(string: trimmed), let host = components.host {
            return host
        }
        return trimmed
            .replacingOccurrences(of: "https://", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "http://", with: "", options: [.caseInsensitive])
            .split(separator: "/", maxSplits: 1)
            .first
            .map(String.init) ?? trimmed
    }

    var normalizedPath: String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "/" }
        return trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    }

    func validationError() -> String? {
        if normalizedHost.isEmpty {
            return "请填写发送地址。"
        }
        if !(1...65_535).contains(port) {
            return "端口必须在 1 到 65535 之间。"
        }
        if !(30...3_600).contains(intervalSeconds) {
            return "发送间隔必须在 30 到 3600 秒之间。"
        }
        return nil
    }
}

enum ProbeOutcome: Sendable {
    case success(String)
    case skipped(String)
    case failure(String)
}
