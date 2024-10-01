import UIKit
import CoreLocation
import MapKit

class BaseLocationViewController: UIViewController {
    enum PresentationType {
        case pick
        case fix(CLLocationCoordinate2D)

        fileprivate var canPickLocation: Bool {
            switch self {
            case .pick:
                return true
            case .fix:
                return false
            }
        }
    }

    private enum Appearance {
        static let pinSize = CGSize(width: 44, height: 44)
        static let pickViewInsets = UIEdgeInsets(top: 0, left: 15, bottom: 15, right: 15)
        static let appleLogoInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        static let controlViewInsets = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 15)
        static let segmentedControlInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }

    private(set) lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.showsUserLocation = true
        view.showsCompass = false
        view.showsTraffic = false
        view.showsBuildings = true
        view.showsPointsOfInterest = true

        view.delegate = self
        return view
    }()

    private lazy var pinAnnotation = MKPointAnnotation()
    private lazy var pinAnnotationView = MKPinAnnotationView(annotation: self.pinAnnotation, reuseIdentifier: nil)

    private lazy var locationPickView: LocationPickView = {
        let view = LocationPickView()

        switch self.presentationType {
        case .pick:
            view.title = "send.geolocation".localized
        case .fix:
            view.title = "location".localized
            view.isUserInteractionEnabled = false
        }

        return view
    }()

    private var typeSegmentControlHeightConstraint: NSLayoutConstraint?

    private lazy var typeSegmentedControl: UISegmentedControl = {
        let view = UISegmentedControl(items: ["map", "satellite", "hybrid"].map(\.localized))
        view.selectedSegmentIndex = 0
        view.addTarget(self, action: #selector(self.typeSegmentChanged), for: .valueChanged)
        return view
    }()

    private lazy var typeSegmentedControlContainerView: UIView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        let view = UIView()

        view.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        visualEffectView.contentView.addSubview(self.typeSegmentedControl)

        return view
    }()

    private lazy var locationControlView = LocationControlView()

    private let presentationType: PresentationType

    private var themeProvider: ThemeProvider?

    init(presentationType: PresentationType) {
        self.presentationType = presentationType

        super.init(nibName: nil, bundle: nil)

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSubviews()
        self.setupNavigationItem()

        switch self.presentationType {
        case .pick:
            self.focusOnUserLocation(animated: false)
        case .fix(let point):
            self.focusOnLocation(coordinate: point, animated: false)
            self.geocodeLocation()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bottomInset: CGFloat
        if #available(iOS 11.0, *) {
            bottomInset = self.view.bounds.height - self.locationPickView.frame.minY - self.view.safeAreaInsets.bottom
        } else {
            bottomInset = self.view.bounds.height - self.locationPickView.frame.minY
        }
        self.mapView.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Appearance.appleLogoInsets.left,
            bottom: bottomInset,
            right: Appearance.appleLogoInsets.right
        )
    }

    func requestDismissAndSend() { }

    func requestGeocode(location: CLLocation, completion: @escaping (String) -> Void) { }

    func focusOnUserLocation(animated: Bool) { }

    func focusOnLocation(coordinate: CLLocationCoordinate2D, animated: Bool) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        self.mapView.setRegion(region, animated: animated)
    }

    // MARK: - Private

    @objc
    private func typeSegmentChanged() {
        switch self.typeSegmentedControl.selectedSegmentIndex {
        case 0:
            self.mapView.mapType = .standard
        case 1:
            self.mapView.mapType = .satellite
        case 2:
            self.mapView.mapType = .hybrid
        default:
            break
        }
    }

    @objc
    private func cancelButtonClicked() {
        self.dismiss(animated: true, completion: nil)
    }

    private func geocodeLocation() {
        let coordinate = self.pinAnnotation.coordinate
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        self.locationPickView.reset()
        self.requestGeocode(location: location) { [weak self] name in
            self?.locationPickView.update(locationName: name)
        }
    }

    private func toggleTypeSegmentedControl() {
        let value = self.typeSegmentControlHeightConstraint?.constant ?? 0

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        if value == 0 {
            self.typeSegmentControlHeightConstraint?.constant = self.typeSegmentedControl.intrinsicContentSize.height
            + Appearance.segmentedControlInsets.top
            + Appearance.segmentedControlInsets.bottom
        } else {
            self.typeSegmentControlHeightConstraint?.constant = 0
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    // swiftlint:disable:next function_body_length
    private func setupSubviews() {
        guard let view = self.viewIfLoaded else {
            return
        }

        let mapView = self.mapView
        let pickView = self.locationPickView
        let controlView = self.locationControlView
        let typeContainerView = self.typeSegmentedControlContainerView
        let typeSegmentedControl = self.typeSegmentedControl

        view.backgroundColor = .white
        view.addSubview(mapView)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        mapView.addAnnotation(self.pinAnnotation)
        switch self.presentationType {
        case .pick:
            self.pinAnnotation.coordinate = mapView.centerCoordinate
        case .fix(let point):
            self.pinAnnotation.coordinate = point
        }

        view.addSubview(pickView)
        pickView.translatesAutoresizingMaskIntoConstraints = false
        pickView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pickView.leadingAnchor
            .constraint(equalTo: view.leadingAnchor, constant: Appearance.pickViewInsets.left)
            .isActive = true
        pickView.trailingAnchor
            .constraint(equalTo: view.trailingAnchor, constant: -Appearance.pickViewInsets.right)
            .isActive = true
        if #available(iOS 11.0, *) {
            pickView.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Appearance.pickViewInsets.bottom)
                .isActive = true
        } else {
            pickView.bottomAnchor
                .constraint(equalTo: view.bottomAnchor, constant: -Appearance.pickViewInsets.bottom)
                .isActive = true
        }

        view.addSubview(typeContainerView)
        typeContainerView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            typeContainerView.topAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
                .isActive = true
        } else {
            typeContainerView.topAnchor
                .constraint(equalTo: self.topLayoutGuide.bottomAnchor)
                .isActive = true
        }
        typeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        typeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.typeSegmentControlHeightConstraint = typeContainerView.heightAnchor.constraint(equalToConstant: 0)
        self.typeSegmentControlHeightConstraint?.isActive = true

        typeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = typeSegmentedControl.topAnchor
            .constraint(equalTo: typeContainerView.topAnchor, constant: Appearance.segmentedControlInsets.top)
        topConstraint.priority = .defaultLow
        topConstraint.isActive = true

        typeSegmentedControl.leadingAnchor
            .constraint(equalTo: typeContainerView.leadingAnchor, constant: Appearance.segmentedControlInsets.left)
            .isActive = true
        typeSegmentedControl.trailingAnchor
            .constraint(equalTo: typeContainerView.trailingAnchor, constant: -Appearance.segmentedControlInsets.right)
            .isActive = true

        let bottomConstraint = typeSegmentedControl.bottomAnchor
            .constraint(equalTo: typeContainerView.bottomAnchor, constant: -Appearance.segmentedControlInsets.bottom)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true

        view.addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.trailingAnchor
            .constraint(equalTo: view.trailingAnchor, constant: -Appearance.controlViewInsets.right)
            .isActive = true
        controlView.topAnchor
            .constraint(equalTo: typeContainerView.bottomAnchor, constant: Appearance.controlViewInsets.top)
            .isActive = true

        self.locationControlView.onInfoButtonTap = { [weak self] in
            self?.toggleTypeSegmentedControl()
        }

        self.locationControlView.onPositionButtonTap = { [weak self] in
            self?.focusOnUserLocation(animated: true)
        }

        self.locationPickView.onTap = { [weak self] in
            self?.requestDismissAndSend()
        }
    }

    private func setupNavigationItem() {
        let item = UIBarButtonItem(
            title: self.presentationType.canPickLocation ? "cancel".localized : "close".localized,
            style: .plain,
            target: self,
            action: #selector(self.cancelButtonClicked)
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: ThemeProvider.current.palette.navigationBarText,
            .font: ThemeProvider.current.fontProvider.navigationButton.font
        ]
        item.setTitleTextAttributes(attributes, for: .normal)
        item.setTitleTextAttributes(attributes, for: .highlighted)

        self.navigationItem.setLeftBarButton(item, animated: true)
    }
}

// MARK: - ThemeUpdatable

extension BaseLocationViewController: ThemeUpdatable {
    func update(with theme: Theme) {
        self.mapView.tintColor = theme.palette.locationMapTint
        self.typeSegmentedControlContainerView.backgroundColor = theme.palette.locationControlBackground
    }
}

// MARK: - MKMapViewDelegate

extension BaseLocationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            return self.pinAnnotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        guard self.presentationType.canPickLocation else {
            return
        }

        UIView.performWithoutAnimation {
            self.pinAnnotation.coordinate = mapView.centerCoordinate
        }

        self.pinAnnotationView.setDragState(.none, animated: true)
        self.pinAnnotationView.setDragState(.starting, animated: true)

        self.locationPickView.reset()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard self.presentationType.canPickLocation else {
            return
        }

        UIView.performWithoutAnimation {
            self.pinAnnotation.coordinate = mapView.centerCoordinate
        }

        self.pinAnnotationView.setDragState(.ending, animated: true)
        self.pinAnnotationView.setDragState(.none, animated: true)

        self.geocodeLocation()
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        guard self.presentationType.canPickLocation else {
            return
        }

        UIView.performWithoutAnimation {
            self.pinAnnotation.coordinate = mapView.centerCoordinate
        }
    }
}
