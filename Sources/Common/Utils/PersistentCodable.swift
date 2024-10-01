import Foundation

@propertyWrapper
class PersistentCodable<ValueType: Codable> {
    let fileName: String
    private let lock = NSLock()
    private let isAsync: Bool
    var onFlush: ((ValueType, Swift.Error?) -> Void)?

    private lazy var persistenceQueue = DispatchQueue(
        label: "ChatSDK.PersistentCodable.persistenceQueue.\(self.fileName)"
    )

    @ThreadSafe
    private var _wrappedValue: ValueType

    init(
        wrappedValue: ValueType,
        fileName: String,
        async: Bool = true,
        onFlush: ((ValueType, Swift.Error?) -> Void)? = nil
    ) {
        self.fileName = fileName
        self._wrappedValue = wrappedValue
        self.isAsync = async
        self.onFlush = onFlush

        guard async else {
            self._wrappedValue = ValueType.read(from: fileName) ?? wrappedValue
            return
        }

        self.persistenceQueue.async {
            self._wrappedValue = ValueType.read(from: fileName) ?? wrappedValue
        }
    }

    private lazy var flushDebouncer = Debouncer(timeout: 0.3) { [weak self] in
        self?.persistenceQueue.async { [weak self] in
            self?.flush()
        }
    }

    private func flush() {
        let error = self._wrappedValue.write(to: self.fileName)
        self.onFlush?(self._wrappedValue, error)
    }

    var wrappedValue: ValueType {
        get { _wrappedValue }
        set {
            self.lock.withLock {
                self._wrappedValue = newValue

                if self.isAsync {
                    self.flushDebouncer.reset()
                    return
                }

                self.flush()
            }
        }
    }
}
