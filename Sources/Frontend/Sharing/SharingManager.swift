import UIKit
import Contacts
import UniformTypeIdentifiers
import MobileCoreServices

public final class Sharing {
    public static let manager = Sharing()
    private let groupName = Configuration.sharingGroupName
    private lazy var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)
    
    private init() { }

    public func share(text: String) {
        self.showSharingControl(with: [text])
    }
    
    public func share(videoData: Data) {
        self.saveDataToFile(data: videoData, fileName: "video.mp4")
    }
    
    public func share(audioData: Data) {
        self.saveDataToFile(data: audioData, fileName: "audio.mp3")
    }
    
    public func share(imageData: Data) {
        self.saveDataToFile(data: imageData, fileName: "image.png")
    }

    public func share(data: Data?) {
        guard let data = data else {
            return
        }
        self.showSharingControl(with: [data])
    }
    
    public func share(latitude: Double, longitude: Double) {
        var items = [AnyObject]()
        let URLString = "https://maps.apple.com?ll=\(latitude),\(longitude)"
        if let url = NSURL(string: URLString) {
            items.append(url)
        }
        let locationVCardString = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "PRODID:-//Joseph Duffy//Blog Post Example//EN",
            "N:;Shared Location;;;",
            "FN:Shared Location",
            "item1.URL;type=pref:\(URLString)",
            "item1.X-ABLabel:map url",
            "END:VCARD"
        ].joined(separator: "\n")
        
        guard let vCardData: NSSecureCoding = locationVCardString.data(using: .utf8) as NSSecureCoding? else { return }

        let vCardActivity = NSItemProvider(item: vCardData, typeIdentifier: kUTTypeVCard as String)
        items.append(vCardActivity)
            
        self.showSharingControl(with: items)
    }
    
    public func share(contact: CNContact?) {
        guard let contact = contact else {
            return
        }
        guard let def = self.containerURL else { return }
        var isDirectory: ObjCBool = true
        do {
            let directoryPath = def.appendingPathComponent("files")
            let fileName = "\(CNContactFormatter().string(from: contact) ?? "Contact")).vcf"
            let contactData = try CNContactVCardSerialization.data(with: [contact])
            if FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
                try contactData.write(to: directoryPath.appendingPathComponent(fileName), options: .atomicWrite)
            } else {
                try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: false)
                try contactData.write(to: directoryPath.appendingPathComponent(fileName), options: .atomicWrite)
            }
            self.showSharingControl(with: [directoryPath.appendingPathComponent(fileName)])
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "[Share export] failed due to: \(error).")
        }
    }

    private func showSharingControl(with items: [Any]) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activity.excludedActivityTypes = [.assignToContact, .print]
        activity.completionWithItemsHandler = { _, _, _, _ in
            self.cleanTemporaryFolder()
        }
        let rootVC = UIWindow.keyWindow?
            .rootViewController?
            .topmostPresentedOrSelf
        rootVC?.present(activity, animated: true)
    }
    
    private func saveDataToFile(data: Data, fileName: String) {
        guard let def = self.containerURL else { return }
        var isDirectory: ObjCBool = true
        do {
            let directoryPath  = def.appendingPathComponent("files")
            if FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
                try data.write(to: directoryPath.appendingPathComponent(fileName), options: .atomic)
            } else {
                try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: false)
                try data.write(to: directoryPath.appendingPathComponent(fileName), options: .atomic)
            }
            self.showSharingControl(with: [directoryPath.appendingPathComponent(fileName)])
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "[Share export] failed due to: \(error).")
        }
    }
    
    private func cleanTemporaryFolder() {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)
        var content: [URL] = []
        do {
            if let container = container {
                let directoryPath = container.appendingPathComponent("files")
                content = try FileManager.default.contentsOfDirectory(
                    at: directoryPath,
                    includingPropertiesForKeys: nil
                )
            }
            for url in content {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]
            
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            
            log(sender: self, "[Share export] failed due to: \(error).")
        }
    }
}
