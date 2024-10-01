import Foundation

final class UnfairLock {
    private let mutex: UnsafeMutablePointer<os_unfair_lock_s> = .allocate(capacity: 1)

    init() {
        mutex.initialize(to: os_unfair_lock_s())
    }

    func lock() {
        os_unfair_lock_lock(mutex)
    }

    func unlock() {
        os_unfair_lock_unlock(mutex)
    }

    deinit {
        mutex.deinitialize(count: 1)
        mutex.deallocate()
    }

    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try body()
    }
}

extension NSLock {
    @inlinable
    @discardableResult
    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try body()
    }
}

extension NSRecursiveLock {
    @inlinable
    @discardableResult
    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try body()
    }
}

@propertyWrapper
struct ThreadSafe<Value> {
    private var _wrappedValue: Value
    private let lock = UnfairLock()

    init(wrappedValue: Value) {
        self._wrappedValue = wrappedValue
    }

    var wrappedValue: Value {
        get {
            lock.withLock { _wrappedValue }
        }
        set {
            lock.withLock { _wrappedValue = newValue }
        }
        _modify {
            lock.lock()
            defer { lock.unlock() }

            yield &_wrappedValue
        }
    }

    /// returns previous value
    @discardableResult
    mutating func update(_ newValue: Value) -> Value {
        // swiftlint:disable all
        { value in
            defer { value = newValue }
            return value
        }(&wrappedValue)
        // swiftlint:enable all
    }
}
