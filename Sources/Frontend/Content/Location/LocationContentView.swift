import UIKit
import MapKit

final class LocationContentView: UIView {
    static let height: CGFloat = 120

    var guid: String?

    private static let snapshotter = MapSnapshotter()

    private lazy var mapImageView = UIImageView()

    private var previousSize: CGSize?
    private var currentCoordinate: CLLocationCoordinate2D?
    private var needsSnapshot = false

    private var themeProvider: ThemeProvider?

    var onTap: (() -> Void)?

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.gestureRecognized(_:)))
        return recognizer
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.setupSubviews()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.mapImageView.frame = self.bounds
        self.refreshSnapshot()
    }

    func update(coordinate: CLLocationCoordinate2D) {
        self.currentCoordinate = coordinate
        self.needsSnapshot = true

        self.setNeedsLayout()
    }

    // MARK: - Private

    @objc
    private func gestureRecognized(_ recognizer: UITapGestureRecognizer) {
        self.onTap?()
    }

    private func refreshSnapshot() {
        let bounds = self.bounds
        if (bounds.isEmpty || self.previousSize == bounds.size) && !self.needsSnapshot {
            return
        }

        guard let coordinate = self.currentCoordinate else {
            return
        }

        self.previousSize = bounds.size
        self.needsSnapshot = false

        Self.snapshotter.makeSnapshotWithPinAtCenter(coordinate: coordinate, size: bounds.size) { [weak self] image in
            guard let image = image else {
                return
            }

            UIView.performWithoutAnimation {
                self?.mapImageView.image = image
            }
        }
    }

    private func setupSubviews() {
        self.addSubview(self.mapImageView)
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
}

// MARK: - ThemeUpdatable

extension LocationContentView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.mapImageView.backgroundColor = theme.palette.locationBubbleEmpty
    }
}

// MARK: - MessageContentViewProtocol

extension LocationContentView: MessageContentViewProtocol {
    var shouldAddBorder: Bool {
        return true
    }

    var shouldAddInfoViewPad: Bool {
        return true
    }

    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat {
        return width * 0.9
    }

    func reset() {
        self.mapImageView.image = nil
    }

    func updateInfoViewFrame(_ frame: CGRect) { }

    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}

// MARK: - Snapshotter

private final class MapSnapshotter {
    static let requestQueue = DispatchQueue(label: "MapSnapshotter.request")
    static let snapshotQueue = DispatchQueue(label: "MapSnapshotter.snapshot")

    private var cache = Cache<CacheCoordinateKey, UIImage>()

    func makeSnapshotWithPinAtCenter(
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        if let cachedImage = self.cache[.init(coordinate: coordinate, size: size)] {
            completion(cachedImage)
            return
        }

        guard let pinImage = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil).image else {
            completion(nil)
            return
        }

        Self.requestQueue.async {
            let options = MKMapSnapshotter.Options()
            options.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            options.scale = UIScreen.main.scale
            options.size = size

            let snapshotter = MKMapSnapshotter(options: options)

            snapshotter.start(with: Self.snapshotQueue) { [weak self] (snapshot, error) in
                if error != nil {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                guard let snapshot = snapshot else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let image = snapshot.image

                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                defer {
                    UIGraphicsEndImageContext()
                }

                image.draw(at: .zero)
                let pinDrawPoint = CGPoint(
                    x: image.size.width / 2,
                    y: image.size.height / 2 - pinImage.size.height / 2
                )
                pinImage.draw(at: pinDrawPoint)

                if let compositeImage = UIGraphicsGetImageFromCurrentImageContext() {
                    self?.cache[.init(coordinate: coordinate, size: size)] = compositeImage

                    DispatchQueue.main.async { completion(compositeImage) }
                    return
                }

                DispatchQueue.main.async { completion(nil) }
                return
            }
        }
    }

    private struct CacheCoordinateKey: Hashable {
        let coordinate: CLLocationCoordinate2D
        let size: CGSize

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.coordinate.longitude)
            hasher.combine(self.coordinate.latitude)
            hasher.combine(self.size.width)
            hasher.combine(self.size.height)
        }

        static func == (lhs: CacheCoordinateKey, rhs: CacheCoordinateKey) -> Bool {
            return lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.size == rhs.size
        }
    }
}
