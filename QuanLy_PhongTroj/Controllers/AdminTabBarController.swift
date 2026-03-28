import UIKit

enum AdminPalette {
    static let accent = UIColor(hex: "#FF6A00")
    static let accentSoft = UIColor(hex: "#FFF0E5")
    static let background = UIColor(red: 0.973, green: 0.973, blue: 0.984, alpha: 1)
    static let card = UIColor.white
    static let border = UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1)
    static let textSecondary = UIColor(red: 0.53, green: 0.53, blue: 0.58, alpha: 1)
    static let destructive = UIColor(red: 1, green: 0.35, blue: 0.3, alpha: 1)
}

extension UIView {
    func applyAdminCardStyle(cornerRadius: CGFloat = 24) {
        backgroundColor = AdminPalette.card
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = AdminPalette.border.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }
}

final class AdminCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        applyAdminCardStyle()
    }
}

struct AdminSheetAction {
    let title: String
    let titleColor: UIColor
    let backgroundColor: UIColor
    let handler: (() -> Void)?

    init(
        title: String,
        titleColor: UIColor = .label,
        backgroundColor: UIColor = UIColor(white: 0.95, alpha: 0.92),
        handler: (() -> Void)? = nil
    ) {
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.handler = handler
    }
}

final class AdminActionSheetController: UIViewController {
    private let sheetTitle: String
    private let subtitle: String?
    private let actions: [AdminSheetAction]

    private let dimView = UIView()
    private let containerView = UIView()
    private let stackView = UIStackView()

    init(title: String, subtitle: String? = nil, actions: [AdminSheetAction]) {
        self.sheetTitle = title
        self.subtitle = subtitle
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    private func setupLayout() {
        view.backgroundColor = .clear

        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        dimView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSheet))
        dimView.addGestureRecognizer(tap)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        containerView.layer.cornerRadius = 30
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor

        let tipView = UIView()
        tipView.translatesAutoresizingMaskIntoConstraints = false
        tipView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        tipView.layer.cornerRadius = 4
        tipView.transform = CGAffineTransform(rotationAngle: .pi / 4)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 14

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = sheetTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AdminPalette.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        view.addSubview(dimView)
        view.addSubview(containerView)
        view.addSubview(tipView)
        containerView.addSubview(stackView)

        stackView.addArrangedSubview(titleLabel)
        if let subtitle, !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            stackView.addArrangedSubview(subtitleLabel)
        }

        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(action.titleColor, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = action.backgroundColor
            button.layer.cornerRadius = 22
            button.layer.cornerCurve = .continuous
            button.heightAnchor.constraint(equalToConstant: 54).isActive = true
            button.addTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 28),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: 28),
            containerView.widthAnchor.constraint(equalToConstant: 272),

            tipView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 7),
            tipView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            tipView.widthAnchor.constraint(equalToConstant: 18),
            tipView.heightAnchor.constraint(equalToConstant: 18),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 26),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.18) {
            self.dimView.alpha = 1
        }
    }

    @objc private func closeSheet() {
        dismiss(animated: true)
    }

    @objc private func handleAction(_ sender: UIButton) {
        let action = actions[sender.tag]
        dismiss(animated: true) {
            action.handler?()
        }
    }
}

final class AdminPrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AdminPalette.accent
        tintColor = .white
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.shadowColor = AdminPalette.accent.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 10)
    }
}

class AdminTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard
            let dashboard = storyboard.instantiateViewController(withIdentifier: "AdminDashboardVC") as? AdminDashboardVC,
            let rooms = storyboard.instantiateViewController(withIdentifier: "AdminPhongVC") as? AdminPhongVC,
            let users = storyboard.instantiateViewController(withIdentifier: "AdminUserVC") as? AdminUserVC,
            let messages = storyboard.instantiateViewController(withIdentifier: "AdminMessagesVC") as? AdminMessagesVC,
            let settings = storyboard.instantiateViewController(withIdentifier: "AdminCaiDatVC") as? AdminCaiDatVC
        else {
            return
        }

        viewControllers = [
            wrap(dashboard, title: "Tổng quan", image: "chart.bar", selectedImage: "chart.bar.fill"),
            wrap(rooms, title: "QL Phòng", image: "building.2", selectedImage: "building.2.fill"),
            wrap(users, title: "QL User", image: "person.3", selectedImage: "person.3.fill"),
            wrap(messages, title: "Tin nhắn", image: "message", selectedImage: "message.fill"),
            wrap(settings, title: "Cài đặt", image: "gearshape", selectedImage: "gearshape.fill")
        ]
    }

    private func wrap(_ controller: UIViewController, title: String, image: String, selectedImage: String) -> UIViewController {
        controller.title = title
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.isNavigationBarHidden = true
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: UIImage(systemName: selectedImage)
        )
        return navigationController
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear

        let normalText = [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        let selectedText = [NSAttributedString.Key.foregroundColor: AdminPalette.accent]

        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray2
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalText
        appearance.stackedLayoutAppearance.selected.iconColor = AdminPalette.accent
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedText

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.tintColor = AdminPalette.accent
        tabBar.unselectedItemTintColor = .systemGray2
        tabBar.layer.cornerRadius = 28
        tabBar.layer.cornerCurve = .continuous
        tabBar.layer.borderWidth = 1
        tabBar.layer.borderColor = AdminPalette.border.cgColor
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.08
        tabBar.layer.shadowRadius = 22
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -6)
        tabBar.clipsToBounds = false
    }
}
