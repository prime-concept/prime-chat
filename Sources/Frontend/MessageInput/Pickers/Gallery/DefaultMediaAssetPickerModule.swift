import UIKit
import Photos

final class DefaultMediaAssetPickerModule: UIViewController, PickerModule {
    static var listItem = Optional(PickerListItem(icon: UIImage(), title: "photo.video".localized))

    private lazy var tableView = self.makeTableView()
    private lazy var dataSource = PhotoAlbumsListDataSource(output: self)

    private var themeProvider: ThemeProvider?

    static var resultContentTypes: [MessageContent.Type] {
        return [ImageContent.self, VideoContent.self]
    }

    weak var pickerDelegate: PickerDelegate?

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

        self.setupNavigationItem()

        self.setupView()

        self.themeProvider = ThemeProvider(
            onThemeUpdate: { [weak self] theme in
                self?.view.backgroundColor = theme.palette.imagePickerBackground
                self?.tableView.separatorColor = theme.palette.imagePickerAlbumsSeparator
            }
        )
    }

    // MARK: - Private API

    private func setupView() {
        guard let view = self.view else {
            return
        }

        let tableView = self.tableView
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        tableView.delegate = self.dataSource
        tableView.dataSource = self.dataSource
    }

    private func makeTableView() -> UITableView {
        let tableView = UITableView()

        tableView.register(
            PhotoAlbumTableViewCell.self,
            forCellReuseIdentifier: PhotoAlbumTableViewCell.reuseIdentifier
        )

        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.tableFooterView = UIView()

        return tableView
    }

    private func setupNavigationItem() {
        self.navigationItem.title = "albums".localized
        self.navigationItem.setLeftBarButton(
            UIBarButtonItem(
                title: "cancel".localized,
                style: .plain,
                target: self,
                action: #selector(self.cancelButtonClicked)
            ),
            animated: true
        )
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            assertionFailure("Expected to always work")
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @objc
    private func cancelButtonClicked() {
        self.dismiss(animated: true)
    }
}

extension DefaultMediaAssetPickerModule: PhotoAlbumsListDataSourceOutputProtocol {
    func presentAssets(title: String, assets: [PHAsset]) {
        let controller = PhotoAlbumViewController(
            title: title,
            assets: assets
        )
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func requestTableViewReload() {
        self.tableView.reloadData()
    }

    func closeModule() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    func showDeniedPermissionAlert() {
        let alertController = UIAlertController(
            title: "error".localized,
            message: "media.permission".localized,
            preferredStyle: .alert
        )

        let openSettingsAction = UIAlertAction(title: "open.settings".localized, style: .default) { [weak self] _ in
            self?.openAppSettings()
        }
        alertController.addAction(openSettingsAction)

        let closeAction = UIAlertAction(title: "close".localized, style: .cancel) { [weak self] _ in
            self?.closeModule()
        }
        alertController.addAction(closeAction)

        self.topmostPresentedOrSelf.present(alertController, animated: true)
    }
}

extension DefaultMediaAssetPickerModule: PhotoAlbumViewControllerDelegate {
    func didSelectMediaAssets(_ mediaAssets: [MediaAsset]) {
        self.dismiss(animated: true) { [weak pickerDelegate] in
            let attachments: [ContentSender] = mediaAssets.map {
                if $0.type == .photo {
                    return ImageContentSender(image: $0.image, name: $0.name, messageContent: $0.data)
                } else {
                    return VideoContentSender(
                        previewImage: $0.image,
                        name: $0.name,
                        messageContent: $0.data,
                        duration: $0.duration ?? 0
                    )
                }
            }
            pickerDelegate?.attachContent(senders: attachments)
        }
    }
}
