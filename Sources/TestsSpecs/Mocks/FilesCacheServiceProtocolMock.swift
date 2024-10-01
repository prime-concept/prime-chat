import Foundation

final class FilesCacheServiceProtocolMock: FilesCacheServiceProtocol {

    var invokedExistsFile = false
    var invokedExistsFileCount = 0
    var invokedExistsFileParameters: (file: FileInfo, Void)?
    var invokedExistsFileParametersList = [(file: FileInfo, Void)]()
    var stubbedExistsFileResult: URL!

    func exists(file: FileInfo) -> URL? {
        invokedExistsFile = true
        invokedExistsFileCount += 1
        invokedExistsFileParameters = (file, ())
        invokedExistsFileParametersList.append((file, ()))
        return stubbedExistsFileResult
    }

    var invokedExistsCacheKey = false
    var invokedExistsCacheKeyCount = 0
    var invokedExistsCacheKeyParameters: (cacheKey: String, Void)?
    var invokedExistsCacheKeyParametersList = [(cacheKey: String, Void)]()
    var stubbedExistsCacheKeyResult: URL!

    func exists(cacheKey: String) -> URL? {
        invokedExistsCacheKey = true
        invokedExistsCacheKeyCount += 1
        invokedExistsCacheKeyParameters = (cacheKey, ())
        invokedExistsCacheKeyParametersList.append((cacheKey, ()))
        return stubbedExistsCacheKeyResult
    }

    var invokedRetrieveFile = false
    var invokedRetrieveFileCount = 0
    var invokedRetrieveFileParameters: (file: FileInfo, Void)?
    var invokedRetrieveFileParametersList = [(file: FileInfo, Void)]()
    var stubbedRetrieveFileResult: Data!

    func retrieve(file: FileInfo) -> Data? {
        invokedRetrieveFile = true
        invokedRetrieveFileCount += 1
        invokedRetrieveFileParameters = (file, ())
        invokedRetrieveFileParametersList.append((file, ()))
        return stubbedRetrieveFileResult
    }

    var invokedRetrieveCacheKey = false
    var invokedRetrieveCacheKeyCount = 0
    var invokedRetrieveCacheKeyParameters: (cacheKey: String, Void)?
    var invokedRetrieveCacheKeyParametersList = [(cacheKey: String, Void)]()
    var stubbedRetrieveCacheKeyResult: Data!

    func retrieve(cacheKey: String) -> Data? {
        invokedRetrieveCacheKey = true
        invokedRetrieveCacheKeyCount += 1
        invokedRetrieveCacheKeyParameters = (cacheKey, ())
        invokedRetrieveCacheKeyParametersList.append((cacheKey, ()))
        return stubbedRetrieveCacheKeyResult
    }

    var invokedSaveCacheKey = false
    var invokedSaveCacheKeyCount = 0
    var invokedSaveCacheKeyParameters: (cacheKey: String, data: Data)?
    var invokedSaveCacheKeyParametersList = [(cacheKey: String, data: Data)]()
    var stubbedSaveCacheKeyResult: URL!

    func save(cacheKey: String, data: Data) -> URL? {
        invokedSaveCacheKey = true
        invokedSaveCacheKeyCount += 1
        invokedSaveCacheKeyParameters = (cacheKey, data)
        invokedSaveCacheKeyParametersList.append((cacheKey, data))
        return stubbedSaveCacheKeyResult
    }

    var invokedSaveFile = false
    var invokedSaveFileCount = 0
    var invokedSaveFileParameters: (file: FileInfo, data: Data)?
    var invokedSaveFileParametersList = [(file: FileInfo, data: Data)]()
    var stubbedSaveFileResult: URL!

    func save(file: FileInfo, data: Data) -> URL? {
        invokedSaveFile = true
        invokedSaveFileCount += 1
        invokedSaveFileParameters = (file, data)
        invokedSaveFileParametersList.append((file, data))
        return stubbedSaveFileResult
    }

    var invokedErase = false
    var invokedEraseCount = 0

    func erase() {
        invokedErase = true
        invokedEraseCount += 1
    }
}