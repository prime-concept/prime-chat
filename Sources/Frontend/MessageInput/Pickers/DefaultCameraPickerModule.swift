import UIKit
import Photos

final class DefaultCameraPickerModule: UIViewController, PickerModule {
    static var listItem: PickerListItem? {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
        ? Optional(PickerListItem(icon: UIImage(), title: "camera".localized))
        : nil
    }

    static let shouldPresentWithNavigationController = false
    static let modalPresentationStyle: UIModalPresentationStyle = .overFullScreen

    static var resultContentTypes: [MessageContent.Type] {
        return [ImageContent.self, VideoContent.self]
    }

    weak var pickerDelegate: PickerDelegate?

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        return imagePicker
    }()

    var viewController: UIViewController {
        return self
    }

    init(dependencies: PickerModuleDependencies) {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addChild(self.imagePicker)

        self.imagePicker.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.imagePicker.view)
        self.imagePicker.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.imagePicker.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.imagePicker.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.imagePicker.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
}

extension DefaultCameraPickerModule: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let currentTimeStamp = Date().timeIntervalSince1970 * 1000

        if let image = info[.originalImage] as? UIImage {
            let normalizedImage = image.normalizeImage()
            let imageData = normalizedImage.jpegData(compressionQuality: 0.6)

            let attachment = ImageContentSender(
                image: normalizedImage,
                name: "photo_\(currentTimeStamp)",
                messageContent: imageData ?? Data()
            )
            self.pickerDelegate?.attachContent(senders: [attachment])
            return
        }

        if let videoURL = info[.mediaURL] as? URL {
            let urlAsset = AVURLAsset(url: videoURL)
            let url = urlAsset.url
            let data = try? Data(contentsOf: url)

            // TODO: need to show loader beacuse of long preview image generation
            urlAsset.generateThumbnail { image in
                let attachment = VideoContentSender(
                    previewImage: image ?? UIImage(),
                    name: "video_\(currentTimeStamp).mp4",
                    messageContent: data ?? Data(),
                    duration: urlAsset.duration.seconds
                )
                DispatchQueue.main.async { [weak self] in
                    self?.pickerDelegate?.attachContent(senders: [attachment])
                }
                return
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension UIImage {
    func normalizeImage() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError("Should get image from current image context")
        }
        UIGraphicsEndImageContext()
        return image
    }
}
