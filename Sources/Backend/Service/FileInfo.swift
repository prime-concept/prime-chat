struct FileInfo {
    let uuid: String
    let privacy: Privacy
    let remotePath: String?

    var fileName: String?
    var defaultExtension: String?

    var pathInCache: String?

    var cacheKey: String {
        var cacheKey = self.uuid

        if let fileName = fileName,
           !cacheKey.hasSuffix(fileName) {
            cacheKey += "/"
            cacheKey += fileName
        }

        if let defaultExtension = defaultExtension,
           !self.hasPathExtension(cacheKey) {
            cacheKey += "."
            cacheKey += defaultExtension
        }

        return cacheKey
    }

    init(
        uuid: String,
        privacy: Privacy = .private,
        remotePath: String? = nil,
        fileName: String? = nil,
        defaultExtension: String? = nil
    ) {
        self.uuid = uuid
        self.privacy = privacy
        self.remotePath = remotePath
        self.fileName = fileName
        self.defaultExtension = defaultExtension
    }

    init?(
        remotePath: String,
        privacy: Privacy = .private,
        defaultExtension: String? = nil
    ) {
        let components = remotePath.split(separator: "/")
        guard let uuid = components[safe: 1] ?? components.last  else {
            return nil
        }

        self.uuid = String(uuid)
        self.privacy = privacy
        self.remotePath = remotePath
        self.defaultExtension = defaultExtension
    }

    init(uploadedFile: UploadedFile) {
        self.uuid = uploadedFile.uuid
        self.privacy = uploadedFile.privacy == .public ? .public : .private
        self.remotePath = uploadedFile.path
        self.defaultExtension = nil
    }

    enum Privacy: String {
        case `private`
        case `public`
    }

    private func hasPathExtension(_ path: String) -> Bool {
        path.replacingOccurrences(
            of: "^.*?\\/.+?\\.\\w+$",
            with: "",
            options: .regularExpression
        ).isEmpty
    }
}
