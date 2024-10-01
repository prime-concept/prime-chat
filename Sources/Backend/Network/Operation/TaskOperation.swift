import Foundation

final class TaskOperation: AsyncOperation {
    var task: URLSessionTask?

    override func main() {
        self.task?.resume()
    }

    func finish() {
        self.state = .finished
    }
}
