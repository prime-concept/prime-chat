import UIKit

final class StylizedNavigationContoller: UINavigationController {
    private var themeProvider: ThemeProvider?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }
}

// MARK: - ThemeUpdatable

extension StylizedNavigationContoller: ThemeUpdatable {
    func update(with theme: Theme) {
        self.navigationBar.barTintColor = theme.palette.navigationBarBackground
        self.navigationBar.titleTextAttributes = [
            .foregroundColor: theme.palette.navigationBarText,
            .font: theme.fontProvider.navigationTitle.font
        ]
        self.navigationBar.tintColor = theme.palette.navigationBarTint
    }
}
