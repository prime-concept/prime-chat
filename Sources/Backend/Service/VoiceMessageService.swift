import Foundation
import AVKit

protocol VoiceMessageServiceProtocol: AnyObject {
    var storageBaseURL: URL? { get set }
    var authState: AuthState? { get set }
    var isInRecording: Bool { get }

    var onRecordingCompletion: ((Data?) -> Void)? { get set }
    var isRecordingAllowed: Bool { get }

    func requestRecordPermission(completion: @escaping ((Bool) -> Void))
    func startRecording()
    func stopRecording()

    func makeVoiceMessagePlayer(file: FileInfo, completion: @escaping (VoiceMessagePlayer?) -> Void)
}

final class VoiceMessageService: NSObject, VoiceMessageServiceProtocol {
    private static let queue = DispatchQueue(label: "VoiceMessageService.default")

    private var tmpFileURL: URL = {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("chat_sdk")
            .appendingPathExtension("m4a")
        let path = url.absoluteString
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }

        return url
    }()

    private var audioRecorder: AVAudioRecorder?

    private func setupAudioRecorder() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String: Any]

        self.audioRecorder = try? AVAudioRecorder(url: self.tmpFileURL, settings: settings)
        self.audioRecorder?.delegate = self
    }

    private func setupAudioSession() throws {
        try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
        try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        try self.audioSession.setActive(true)
    }

    private lazy var audioSession = AVAudioSession.sharedInstance()

    @ThreadSafe
    private var voiceMessagePlayers: [String: VoiceMessagePlayer] = [:]

    private let sharedPlayer: AVPlayer
    private var onCurrentPlayTimeChangeGlobal: ((Int) -> Void)?

    var isInRecording: Bool {
        return self.audioRecorder?.isRecording ?? false
    }
    var isRecordingAllowed: Bool {
        self.audioSession.recordPermission == .granted
    }

    var onRecordingCompletion: ((Data?) -> Void)?

    var storageBaseURL: URL?
    var authState: AuthState?

    override init() {
        self.sharedPlayer = AVPlayer(playerItem: nil)

        super.init()

        sharedPlayer.automaticallyWaitsToMinimizeStalling = false

        do {
            try self.setupAudioSession()
            self.setupAudioRecorder()
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function) ",
                "details": "Unable to setup audio session",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "Unable to setup audio session: \(error)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestRecordPermission(completion: @escaping ((Bool) -> Void)) {
        self.audioSession.requestRecordPermission(completion)
    }

    func startRecording() {
        self.audioSession.requestRecordPermission { isAllowed in
            guard isAllowed else {
                return
            }

            self.setupAudioRecorder()
            self.audioRecorder?.deleteRecording()
            self.audioRecorder?.record()
        }
    }

    func stopRecording() {
        self.audioRecorder?.stop()
    }

    func makeVoiceMessagePlayer(file: FileInfo, completion: @escaping (VoiceMessagePlayer?) -> Void) {
        Self.queue.async { [weak self] in
            let voiceMessagePlayer = self?.makeVoiceMessagePlayerInternal(file: file)

            DispatchQueue.main.async {
                completion(voiceMessagePlayer)
            }
        }
    }

    // MARK: - Private

    private func makeVoiceMessagePlayerInternal(file: FileInfo) -> VoiceMessagePlayer? {
        if let voiceMessagePlayer = self.voiceMessagePlayers[file.cacheKey] {
            return voiceMessagePlayer
        }

        let sharedPlayerItem: AVPlayerItem

        if let path = file.pathInCache {
            let fullURL = URL(fileURLWithPath: path)
            let asset = AVURLAsset(url: fullURL)
            sharedPlayerItem = AVPlayerItem(asset: asset)
        } else {
            guard let baseURL = self.storageBaseURL, let bearerToken = self.authState?.bearerToken else {
                return nil
            }

            let fullURL = baseURL.appendingPathComponent("files/\(file.privacy.rawValue)/\(file.uuid)")
            let headers: [String: String] = [
                "Authorization": bearerToken
            ]

            log(sender: self, "voice message service: created item, url = \(fullURL.absoluteString)")

            let options = ["AVURLAssetHTTPHeaderFieldsKey": headers]

            let asset = AVURLAsset(url: fullURL, options: options)
            sharedPlayerItem = AVPlayerItem(asset: asset)
        }
        
        let voiceMessagePlayer = self.makeVoiceMessagePlayer(with: sharedPlayerItem, file)
        self.voiceMessagePlayers[file.cacheKey] = voiceMessagePlayer

        return voiceMessagePlayer
    }

    private func makeVoiceMessagePlayer(with sharedPlayerItem: AVPlayerItem, _ file: FileInfo) -> VoiceMessagePlayer {
        let voiceMessagePlayer = VoiceMessagePlayer(item: sharedPlayerItem, sharedPlayer: self.sharedPlayer, file: file)
        return voiceMessagePlayer
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceMessageService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else {
            self.onRecordingCompletion?(nil)
            return
        }

        let resultFile = self.tmpFileURL
        DispatchQueue.global(qos: .default).async {
            let data = try? Data(contentsOf: resultFile)
            try? FileManager.default.removeItem(at: resultFile)
            DispatchQueue.main.async { [weak self] in
                self?.onRecordingCompletion?(data)
            }
        }
    }
}

final class DummyVoiceMessageService: VoiceMessageServiceProtocol {
    var storageBaseURL: URL?
    var authState: AuthState?
    var isInRecording: Bool = false
    var onRecordingCompletion: ((Data?) -> Void)?
    var isRecordingAllowed: Bool = false
    func requestRecordPermission(completion: @escaping ((Bool) -> Void)) {}
    func startRecording() {}
    func stopRecording() {}
    func makeVoiceMessagePlayer(file: FileInfo, completion: @escaping (VoiceMessagePlayer?) -> Void) {}
}
