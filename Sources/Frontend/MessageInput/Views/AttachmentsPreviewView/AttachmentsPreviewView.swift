import UIKit
import Photos

final class AttachmentsPreviewView: UIView {
    var onRemoveAttachment: ((String) -> Void)?

    private enum Appearance {
        static let collectionViewInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        static let collectionViewItemSpacing: CGFloat = 5
        static let collectionViewItemSize = CGSize(width: 70, height: 70)
        static let collectionViewItemRadius: CGFloat = 8
        static let collectionViewItemButtonCloseSize = CGSize(width: 24, height: 24)
        static let shadowHeight: CGFloat = 1.0 / UIScreen.main.scale
    }

    private lazy var collectionView = self.makeCollectionView()
    private lazy var shadowView = UIView()
    private var themeProvider: ThemeProvider?
    private var attachments: [AttachmentPreview] = []

    init(frame: CGRect, shouldHideShadow: Bool) {
        super.init(frame: .zero)
        self.themeProvider = ThemeProvider(themeUpdatable: self)

        self.setupView(shouldHideShadow: shouldHideShadow)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func update(with attachments: [AttachmentPreview]) {
        self.attachments = attachments
        self.collectionView.reloadData()
    }

    // MARK: - Private

    private func setupView(shouldHideShadow: Bool) {
        let shadowView = self.shadowView
        self.addSubview(shadowView)

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        shadowView.heightAnchor.constraint(equalToConstant: Appearance.shadowHeight).isActive = true
        shadowView.isHidden = shouldHideShadow

        let collectionView = self.collectionView

        self.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Appearance.collectionViewItemSpacing
        layout.minimumLineSpacing = Appearance.collectionViewItemSpacing
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(
            PreviewPhotoItemCollectionViewCell.self,
            forCellWithReuseIdentifier: PreviewPhotoItemCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PreviewVideoItemCollectionViewCell.self,
            forCellWithReuseIdentifier: PreviewVideoItemCollectionViewCell.reuseIdentifier
        )
        collectionView.backgroundColor = .clear

        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = true

        collectionView.contentInset = Appearance.collectionViewInsets
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDelegateFlowLayout

extension AttachmentsPreviewView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return Appearance.collectionViewItemSize
    }
}

// MARK: - UICollectionViewDataSource

extension AttachmentsPreviewView: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.attachments.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let attachment = self.attachments[safe: indexPath.item] else {
            fatalError("Asset not exists")
        }

        switch attachment.mediaAssetType {
        case .photo:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PreviewPhotoItemCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? PreviewPhotoItemCollectionViewCell else {
                fatalError("Incorrect cell type")
            }
            cell.configure(with: attachment) { [weak self] in
                self?.onRemoveAttachment?(attachment.id)
            }
            return cell
        case .video:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PreviewVideoItemCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? PreviewVideoItemCollectionViewCell else {
                fatalError("Incorrect cell type")
            }
            cell.configure(with: attachment) { [weak self] in
                self?.onRemoveAttachment?(attachment.id)
            }
            return cell
        }
    }
}

// MARK: - ThemeUpdatable

extension AttachmentsPreviewView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.shadowView.backgroundColor = theme.palette.senderBorderShadow
    }
}
