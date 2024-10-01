import Foundation

class Debouncer {
    private let timeout: TimeInterval
    private var timer = Timer()
    private var action: (() -> Void)?

    init(timeout: TimeInterval, action: @escaping () -> Void) {
        self.timeout = timeout
        self.action = action
        reset()
    }

    func reset() {
        self.timer.invalidate()
        self.timer = .scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.action?()
        }
    }

    func fireNow() {
        if self.timer.isValid {
            self.timer.invalidate()
            self.action?()
            self.action = nil
        }
    }

    func cancel() {
        self.timer.invalidate()
    }

    deinit {
        self.fireNow()
        self.action = nil
    }
}

class Throttler {
    private let timeout: TimeInterval
    private let action: () -> Void

    private var mayExecute = true
    private var pendingExecutionExists = false
    private var executesPendingAfterCooldown = false

    private let lock = NSLock()

    init(
        timeout: TimeInterval,
        executesPendingAfterCooldown: Bool = false,
        action: @escaping () -> Void
    ) {
        self.executesPendingAfterCooldown = executesPendingAfterCooldown
        self.timeout = timeout
        self.action = action
    }

    func execute() {
        self.lock.withLock {
            guard self.mayExecute else {
                if self.executesPendingAfterCooldown {
                    self.pendingExecutionExists = true
                }
                return
            }

            self.mayExecute = false

            self.action()

            delay(self.timeout) { [weak self] in
                guard let self else {
                    return
                }
                self.mayExecute = true
                if self.pendingExecutionExists {
                    self.pendingExecutionExists = false
                    self.execute()
                }
            }
        }
    }

    func reset() {
        self.lock.withLock {
            self.mayExecute = true
        }
    }
}
