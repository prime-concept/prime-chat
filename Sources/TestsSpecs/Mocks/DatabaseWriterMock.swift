//
//  DatabaseWriter.swift
//
//
//  Created by Hayk Kolozyan on 05.06.24.
//

import Foundation
import GRDB

final class DatabaseWriterMock: DatabaseWriter, DatabaseReader {

    var invokedConfigurationGetter = false
    var invokedConfigurationGetterCount = 0
    var stubbedConfiguration: GRDB.Configuration!

    var configuration: GRDB.Configuration {
        invokedConfigurationGetter = true
        invokedConfigurationGetterCount += 1
        return stubbedConfiguration
    }

    var invokedWrite = false
    var invokedWriteCount = 0
    var stubbedWriteUpdatesResult: (Database, Void)?
    var stubbedWriteError: Error?
    var stubbedWriteResult: Any!
    var didThrowError: Bool = false

    // SR-15150 Async overloading in protocol implementation fails
    func write<T>(_ updates: (Database) throws -> T) throws -> T {
        invokedWrite = true
        invokedWriteCount += 1
        if let result = stubbedWriteUpdatesResult {
            _ = try? updates(result.0)
        }
        if let error = stubbedWriteError {
            didThrowError = true
            throw error
        }
        return stubbedWriteResult as! T
    }

    var invokedWriteWithoutTransaction = false
    var invokedWriteWithoutTransactionCount = 0
    var stubbedWriteWithoutTransactionUpdatesResult: (Database, Void)?
    var stubbedWriteWithoutTransactionError: Error?
    var stubbedWriteWithoutTransactionResult: Any!

    // SR-15150 Async overloading in protocol implementation fails
    func writeWithoutTransaction<T>(_ updates: (Database) throws -> T) rethrows -> T {
        invokedWriteWithoutTransaction = true
        invokedWriteWithoutTransactionCount += 1
        if let result = stubbedWriteWithoutTransactionUpdatesResult {
            _ = try? updates(result.0)
        }
        return stubbedWriteWithoutTransactionResult as! T
    }

    var invokedBarrierWriteWithoutTransaction = false
    var invokedBarrierWriteWithoutTransactionCount = 0
    var stubbedBarrierWriteWithoutTransactionUpdatesResult: (Database, Void)?
    var stubbedBarrierWriteWithoutTransactionResult: Any!

    // SR-15150 Async overloading in protocol implementation fails
    func barrierWriteWithoutTransaction<T>(_ updates: (Database) throws -> T) rethrows -> T {
        invokedBarrierWriteWithoutTransaction = true
        invokedBarrierWriteWithoutTransactionCount += 1
        if let result = stubbedBarrierWriteWithoutTransactionUpdatesResult {
            _ = try? updates(result.0)
        }
        return stubbedBarrierWriteWithoutTransactionResult as! T
    }

    var invokedAsyncBarrierWriteWithoutTransaction = false
    var invokedAsyncBarrierWriteWithoutTransactionCount = 0
    var stubbedAsyncBarrierWriteWithoutTransactionUpdatesResult: (Database, Void)?

    func asyncBarrierWriteWithoutTransaction(_ updates: @escaping (Database) -> Void) {
        invokedAsyncBarrierWriteWithoutTransaction = true
        invokedAsyncBarrierWriteWithoutTransactionCount += 1
        if let result = stubbedAsyncBarrierWriteWithoutTransactionUpdatesResult {
            updates(result.0)
        }
    }

    var invokedAsyncWrite = false
    var invokedAsyncWriteCount = 0
    var stubbedAsyncWriteUpdatesResult: (Database, Void)?

    func asyncWrite<T>(
        _ updates: @escaping (Database) throws -> T,
        completion: @escaping (Database, Result<T, Error>) -> Void) {
        invokedAsyncWrite = true
        invokedAsyncWriteCount += 1
        if let result = stubbedAsyncWriteUpdatesResult {
            _ = try? updates(result.0)
        }
    }

    var invokedAsyncWriteWithoutTransaction = false
    var invokedAsyncWriteWithoutTransactionCount = 0
    var stubbedAsyncWriteWithoutTransactionUpdatesResult: (Database, Void)?

    func asyncWriteWithoutTransaction(_ updates: @escaping (Database) -> Void) {
        invokedAsyncWriteWithoutTransaction = true
        invokedAsyncWriteWithoutTransactionCount += 1
        if let result = stubbedAsyncWriteWithoutTransactionUpdatesResult {
            updates(result.0)
        }
    }

    var invokedUnsafeReentrantWrite = false
    var invokedUnsafeReentrantWriteCount = 0
    var stubbedUnsafeReentrantWriteUpdatesResult: (Database, Void)?
    var stubbedUnsafeReentrantWriteResult: Any!

    func unsafeReentrantWrite<T>(_ updates: (Database) throws -> T) rethrows -> T {
        invokedUnsafeReentrantWrite = true
        invokedUnsafeReentrantWriteCount += 1
        if let result = stubbedUnsafeReentrantWriteUpdatesResult {
            _ = try? updates(result.0)
        }
        return stubbedUnsafeReentrantWriteResult as! T
    }

    var invokedConcurrentRead = false
    var invokedConcurrentReadCount = 0
    var stubbedConcurrentReadValueResult: (Database, Void)?
    var stubbedConcurrentReadResult: DatabaseFuture<Any>!

    func concurrentRead<T>(_ value: @escaping (Database) throws -> T) -> DatabaseFuture<T> {
        invokedConcurrentRead = true
        invokedConcurrentReadCount += 1
        if let result = stubbedConcurrentReadValueResult {
            _ = try? value(result.0)
        }
        return stubbedConcurrentReadResult as! DatabaseFuture<T>
    }

    var invokedSpawnConcurrentRead = false
    var invokedSpawnConcurrentReadCount = 0
    var stubbedSpawnConcurrentReadValueResult: (Result<Database, Error>, Void)?

    func spawnConcurrentRead(_ value: @escaping (Result<Database, Error>) -> Void) {
        invokedSpawnConcurrentRead = true
        invokedSpawnConcurrentReadCount += 1
        if let result = stubbedSpawnConcurrentReadValueResult {
            value(result.0)
        }
    }

    var invokedClose = false
    var invokedCloseCount = 0
    var stubbedCloseError: Error?

    func close() throws {
        invokedClose = true
        invokedCloseCount += 1
        if let error = stubbedCloseError {
            throw error
        }
    }

    var invokedInterrupt = false
    var invokedInterruptCount = 0

    func interrupt() {
        invokedInterrupt = true
        invokedInterruptCount += 1
    }

    var invokedRead = false
    var invokedReadCount = 0
    var stubbedReadValueResult: (Database, Void)?
    var stubbedReadError: Error?
    var stubbedReadResult: Any!

    // SR-15150 Async overloading in protocol implementation fails
    func read<T>(_ value: (Database) throws -> T) throws -> T {
        invokedRead = true
        invokedReadCount += 1
        if let result = stubbedReadValueResult {
            _ = try? value(result.0)
        }
        if let error = stubbedReadError {
            throw error
        }
        return stubbedReadResult as! T
    }

    var invokedAsyncRead = false
    var invokedAsyncReadCount = 0
    var stubbedAsyncReadValueResult: (Result<Database, Error>, Void)?

    func asyncRead(_ value: @escaping (Result<Database, Error>) -> Void) {
        invokedAsyncRead = true
        invokedAsyncReadCount += 1
        if let result = stubbedAsyncReadValueResult {
            value(result.0)
        }
    }

    var invokedUnsafeRead = false
    var invokedUnsafeReadCount = 0
    var stubbedUnsafeReadValueResult: (Database, Void)?
    var stubbedUnsafeReadError: Error?
    var stubbedUnsafeReadResult: Any!

    // SR-15150 Async overloading in protocol implementation fails
    func unsafeRead<T>(_ value: (Database) throws -> T) throws -> T {
        invokedUnsafeRead = true
        invokedUnsafeReadCount += 1
        if let result = stubbedUnsafeReadValueResult {
            _ = try? value(result.0)
        }
        if let error = stubbedUnsafeReadError {
            throw error
        }
        return stubbedUnsafeReadResult as! T
    }

    var invokedAsyncUnsafeRead = false
    var invokedAsyncUnsafeReadCount = 0
    var stubbedAsyncUnsafeReadValueResult: (Result<Database, Error>, Void)?

    func asyncUnsafeRead(_ value: @escaping (Result<Database, Error>) -> Void) {
        invokedAsyncUnsafeRead = true
        invokedAsyncUnsafeReadCount += 1
        if let result = stubbedAsyncUnsafeReadValueResult {
            value(result.0)
        }
    }

    var invokedUnsafeReentrantRead = false
    var invokedUnsafeReentrantReadCount = 0
    var stubbedUnsafeReentrantReadValueResult: (Database, Void)?
    var stubbedUnsafeReentrantReadError: Error?
    var stubbedUnsafeReentrantReadResult: Any!

    func unsafeReentrantRead<T>(_ value: (Database) throws -> T) throws -> T {
        invokedUnsafeReentrantRead = true
        invokedUnsafeReentrantReadCount += 1
        if let result = stubbedUnsafeReentrantReadValueResult {
            _ = try? value(result.0)
        }
        if let error = stubbedUnsafeReentrantReadError {
            throw error
        }
        return stubbedUnsafeReentrantReadResult as! T
    }

    var invoked_add = false
    var invoked_addCount = 0
    var stubbed_addResult: DatabaseCancellable!

    func _add<Reducer: ValueReducer>(
        observation: ValueObservation<Reducer>,
        scheduling scheduler: ValueObservationScheduler,
        onChange: @escaping (Reducer.Value) -> Void)
        -> DatabaseCancellable {
        invoked_add = true
        invoked_addCount += 1
        return stubbed_addResult
    }
}
