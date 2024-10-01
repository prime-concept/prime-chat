import Foundation

// Based on https://gist.github.com/ndarville/3166060
enum DiffCalculator {
    static func diff(
        old oldItems: [MessagesListItemModelProtocol],
        new newItems: [MessagesListItemModelProtocol]
    ) -> CollectionDiff {
        if oldItems.isEmpty, newItems.isEmpty {
            return CollectionDiff(deleted: [], inserted: [], moved: [], updated: [])
        }

        if oldItems.isEmpty {
            return CollectionDiff(deleted: [], inserted: Array(newItems.indices), moved: [], updated: [])
        }

        if newItems.isEmpty {
            return CollectionDiff(deleted: Array(oldItems.indices), inserted: [], moved: [], updated: [])
        }

        var entries = [UniqueIdentifierType: Entry]()

        var newRecords = newItems.map { item -> Record in
            let entry = entries[item.uid] ?? Entry()
            entry.newCount += 1
            entries[item.uid] = entry

            return Record(entry: entry, reference: nil)
        }

        var oldRecords = oldItems.enumerated().map { (index, item) -> Record in
            let entry = entries[item.uid] ?? Entry()
            entry.oldIndices.append(index)
            entries[item.uid] = entry

            return Record(entry: entry, reference: nil)
        }

        newRecords.enumerated().forEach { (newIndex, newRecord) in
            let entry = newRecord.entry

            guard entry.newCount > 0, let oldIndex = entry.oldIndices.popFirst() else {
                return
            }

            newRecords[newIndex].reference = oldIndex
            oldRecords[oldIndex].reference = newIndex
        }

        var updated: [CollectionDiff.Index] = []
        var moved: [(CollectionDiff.Index, CollectionDiff.Index)] = []
        var deleted: [CollectionDiff.Index] = []
        var inserted: [CollectionDiff.Index] = []

        var offset = 0

        let deleteOffsets = oldRecords.enumerated().map { (oldIndex, oldRecord) -> Int in
            let deleteOffset = offset

            if oldRecord.reference == nil {
                deleted.append(oldIndex)
                offset += 1
            }

            return deleteOffset
        }

        offset = 0

        newRecords.enumerated().forEach { (newIndex, newRecord) in
            guard let oldIndex = newRecord.reference else {
                inserted.append(newIndex)
                offset += 1

                return
            }

            let deleteOffset = deleteOffsets[oldIndex]
            let insertOffset = offset

            let isMoved = (oldIndex - deleteOffset + insertOffset) != newIndex
            let isUpdated = newItems[newIndex].uid == oldItems[oldIndex].uid
            && !newItems[newIndex].isContentEqual(with: oldItems[oldIndex])
            if isUpdated {
                updated.append(newIndex)
            } else if isMoved {
                moved.append((oldIndex, newIndex))
            }
        }

        return CollectionDiff(deleted: deleted, inserted: inserted, moved: moved, updated: updated)
    }

    // MARK: - Types

    struct CollectionDiff {
        typealias Index = Int

        let deleted: [Index]
        let inserted: [Index]
        let moved: [(Index, Index)]
        let updated: [Index]

        var isEmpty: Bool {
            deleted.isEmpty && inserted.isEmpty && moved.isEmpty && updated.isEmpty
        }

        var count: Int {
            deleted.count + inserted.count + moved.count + updated.count
        }
    }

    private final class Entry {
        var newCount: Int = 0
        var oldIndices: ArraySlice<Int> = []
    }

    private struct Record {
        let entry: Entry
        var reference: Int?
    }
}
