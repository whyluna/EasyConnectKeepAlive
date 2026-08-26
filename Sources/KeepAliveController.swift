import Foundation

@MainActor
final class KeepAliveController: ObservableObject {
    enum State: Equatable {
        case stopped
        case checking
        case running
        case waiting
        case error

        var title: String {
            switch self {
            case .stopped: "已停止"
            case .checking: "正在发送"
            case .running: "运行中"
            case .waiting: "等待条件"
            case .error: "请求失败"
            }
        }
    }

    struct LogEntry: Identifiable {
        enum Kind {
            case info
            case success
            case warning
            case error
        }

        let id = UUID()
        let date: Date
        let kind: Kind
        let message: String
    }

    @Published private(set) var state: State = .stopped
    @Published private(set) var isRunning = false
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var lastResult = "尚未发送请求"

    private var loopTask: Task<Void, Never>?

    func start(configuration: KeepAliveConfiguration) {
        guard !isRunning else { return }
        if let error = configuration.validationError() {
            state = .error
            append(.error, error)
            lastResult = error
            return
        }

        isRunning = true
        state = .running
        append(.info, "已开始；每 \(configuration.intervalSeconds) 秒检查并发送一次。")

        loopTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.performCycle(configuration: configuration)
                if Task.isCancelled { break }
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(configuration.intervalSeconds) * 1_000_000_000
                    )
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        loopTask?.cancel()
        loopTask = nil
        isRunning = false
        state = .stopped
        append(.info, "已停止，不再发送请求。")
    }

    func testOnce(configuration: KeepAliveConfiguration) {
        if let error = configuration.validationError() {
            state = .error
            append(.error, error)
            lastResult = error
            return
        }

        Task { [weak self] in
            await self?.performCycle(configuration: configuration, isTest: true)
        }
    }

    func clearLogs() {
        logs.removeAll()
    }

    private func performCycle(
        configuration: KeepAliveConfiguration,
        isTest: Bool = false
    ) async {
        state = .checking
        if isTest {
            append(.info, "开始单次测试。")
        }

        let outcome = await ProbeEngine.perform(configuration: configuration)
        switch outcome {
        case .success(let message):
            state = isRunning ? .running : .stopped
            lastResult = message
            append(.success, message)
        case .skipped(let message):
            state = isRunning ? .waiting : .stopped
            lastResult = message
            append(.warning, message)
        case .failure(let message):
            state = .error
            lastResult = message
            append(.error, message)
        }
    }

    private func append(_ kind: LogEntry.Kind, _ message: String) {
        logs.append(LogEntry(date: Date(), kind: kind, message: message))
        if logs.count > 200 {
            logs.removeFirst(logs.count - 200)
        }
    }

    #if DOCS_SCREENSHOT
    func prepareDocumentationScreenshot() {
        let baseDate = Date(timeIntervalSince1970: 1_788_000_000)
        state = .stopped
        isRunning = false
        lastResult = "GET https://one.hust.edu.cn/ → HTTP 206，1 B，远端 210.42.108.232，经 utun4"
        logs = [
            LogEntry(date: baseDate, kind: .info, message: "开始单次测试。"),
            LogEntry(
                date: baseDate.addingTimeInterval(1),
                kind: .success,
                message: "GET https://one.hust.edu.cn/ → HTTP 206，1 B，远端 210.42.108.232，经 utun4（210.42.108.232）"
            )
        ]
    }
    #endif
}
