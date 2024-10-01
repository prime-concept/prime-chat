import UIKit
import Photos

protocol PhotoAlbumViewControllerDelegate: AnyObject {
    func didSelectMediaAssets(_ assets: [MediaAsset])
}

final class PhotoAlbumViewController: UIViewController {
    private enum Appearance {
        static let interItemSpacing: CGFloat = 2
    }

    private lazy var collectionView = self.makeCollectionView()
    private lazy var actionsView = self.makeActionsView()

    private lazy var photosDataSource = PhotoAlbumDataSource(output: self)

    weak var delegate: PhotoAlbumViewControllerDelegate?

    private var themeProvider: ThemeProvider?

    init(title: String, assets: [PHAsset]) {
        super.init(nibName: nil, bundle: nil)

        self.navigationItem.title = title
        self.photosDataSource.update(with: assets)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.themeProvider = ThemeProvider(
            onThemeUpdate: { [weak self] theme in
                self?.view.backgroundColor = theme.palette.imagePickerBackground
            }
        )
    }

    // MARK: - Private API

    private func setupView() {
        guard let view = self.view else {
            return
        }

        let collectionView = self.collectionView
        let actionsView = self.actionsView

        collectionView.delegate = self.photosDataSource
        collectionView.dataSource = self.photosDataSource

        view.addSubview(self.collectionView)
        view.addSubview(self.actionsView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: actionsView.topAnchor).isActive = true

        actionsView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            actionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            actionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        actionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        actionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Appearance.interItemSpacing
        layout.minimumLineSpacing = Appearance.interItemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(
            PhotoItemCollectionViewCell.self,
            forCellWithReuseIdentifier: PhotoItemCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            VideoItemCollectionViewCell.self,
            forCellWithReuseIdentifier: VideoItemCollectionViewCell.reuseIdentifier
        )
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive

        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.contentInset = UIEdgeInsets(
            top: Appearance.interItemSpacing,
            left: 0,
            bottom: Appearance.interItemSpacing,
            right: 0
        )

        return collectionView
    }

    private func makeActionsView() -> PhotosActionsView {
        let view = PhotosActionsView()

        view.cancelButtonClicked = { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }

        view.sendButtonClicked = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.photosDataSource.getSelectedMediaAssets { mediaAssets in
                strongSelf.dismiss(animated: true) {
                    strongSelf.delegate?.didSelectMediaAssets(mediaAssets)
                }
            }
        }

        return view
    }
}

extension PhotoAlbumViewController: PhotoAlbumDataSourceOutputProtocol {
    func didSelectMediaAssets(count: Int) {
        self.actionsView.count = count
    }

    func mediaAssetItemSize(width: CGFloat) -> CGSize {
        let itemsPerRow = 3

        var width = (width - CGFloat(itemsPerRow - 1) * Appearance.interItemSpacing) / CGFloat(itemsPerRow)
        width = min(UIScreen.main.bounds.width, width)

        return CGSize(
            width: width,
            height: PhotoItemCollectionViewCell.height
        )
    }

    func requestCollectionViewReload() {
        self.collectionView.reloadData()
    }
}
