import Foundation

class AsyncOperation: Operation {
    enum State: String {
        case ready, executing, finished

        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }

    var state: State = .ready {
        willSet {
            self.willChangeValue(forKey: newValue.keyPath)
            self.willChangeValue(forKey: self.state.keyPath)
        }
        didSet {
            self.didChangeValue(forKey: oldValue.keyPath)
            self.didChangeValue(forKey: self.state.keyPath)
        }
    }

    // MARK: - Override

    override var isReady: Bool {
        return super.isReady && self.state == .ready
    }

    override var isExecuting: Bool {
        return self.state == .executing
    }

    override var isFinished: Bool {
        return self.state == .finished
    }

    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        if self.isCancelled {
            self.state = .finished
            return
        }
        self.main()
        self.state = .executing
    }

    override func cancel() {
        self.state = .finished
    }
}
