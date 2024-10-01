import UIKit

public typealias MessageContentOpeningCompletion = () -> Void

/// View with content injected into message cell
public protocol MessageContentViewProtocol: UIView {
    var guid: String? { get set }

    /// Add border for light content
    var shouldAddBorder: Bool { get }

    /// Add semitransparent pad view under info
    var shouldAddInfoViewPad: Bool { get }

    /// Create view in initial state
    init()

    /// Reset view to initial state
    func reset()

    /// Calculate content width constrained by max container width and reserved area in the bottom-right corner
    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat

    /// Update info view frame (e. g. to display pad view)
    /// Given frame rect contains margin
    func updateInfoViewFrame(_ frame: CGRect)

    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool
}
