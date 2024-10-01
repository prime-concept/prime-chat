import Foundation

extension Array {
    // TODO: This needs to be tested
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < self.endIndex else {
            return nil
        }

        return self[index]
    }
}
