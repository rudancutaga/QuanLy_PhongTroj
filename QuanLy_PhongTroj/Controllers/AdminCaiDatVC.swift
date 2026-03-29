import UIKit
import FirebaseAuth
import FirebaseFirestore

class AdminCaiDatVC: UIViewController {
    @IBOutlet private weak var profileCardView: UIView!
    @IBOutlet private weak var sessionCardView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var logoutButton: UIButton!

    private let sessionTitleLabel = UILabel()
    private let autoLoginTitleLabel = UILabel()
    private let autoLoginStateLabel = UILabel()
    private let autoLoginDescriptionLabel = UILabel()
    private let autoLoginSwitch = UISwitch()
    private let refreshProfileButton = UIButton(type: .system)
    private var profileCardHeightConstraint: NSLayoutConstraint?
    private var sessionCardHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupSessionSettingsCard()
        loadCurrentProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateAutoLoginUI()
        loadCurrentProfile()
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background
        profileCardView.applyAdminCardStyle()
        sessionCardView.applyAdminCardStyle()

        profileCardHeightConstraint?.isActive = false
        profileCardHeightConstraint = profileCardView.heightAnchor.constraint(equalToConstant: 126)
        profileCardHeightConstraint?.isActive = true

        roleLabel.text = "Quyền: ADMIN"
        emailLabel.text = "Tài khoản nội bộ"
        nameLabel.text = "Quản trị viên"
    }

    private func loadCurrentProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            nameLabel.text = "Quản trị viên"
            emailLabel.text = "Chưa có phiên đăng nhập"
            roleLabel.text = "Quyền: ADMIN"
            return
        }

        emailLabel.text = currentUser.email ?? "Tài khoản nội bộ"
        Firestore.firestore().collection("Users").document(currentUser.uid).getDocument { [weak self] document, _ in
            let data = document?.data()
            let name = data?["hoTen"] as? String
            let username = data?["tenDangNhap"] as? String
            let role = (data?["role"] as? String ?? "admin").uppercased()
            let isActive = data?["isActive"] as? Bool ?? true

            DispatchQueue.main.async {
                self?.nameLabel.text = name?.isEmpty == false ? name : (username ?? "Quản trị viên")
                let statusText = isActive ? "Đang hoạt động" : "Tạm khóa"
                self?.roleLabel.text = "Quyền: \(role) • \(statusText)"
            }
        }
    }

    private func setupSessionSettingsCard() {
        sessionCardView.subviews.forEach { $0.removeFromSuperview() }

        sessionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        sessionTitleLabel.textColor = .label
        sessionTitleLabel.text = "Tùy chọn phiên"

        autoLoginTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        autoLoginTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        autoLoginTitleLabel.textColor = .label
        autoLoginTitleLabel.text = "Tự động đăng nhập"

        autoLoginStateLabel.translatesAutoresizingMaskIntoConstraints = false
        autoLoginStateLabel.font = .systemFont(ofSize: 13, weight: .bold)
        autoLoginStateLabel.textAlignment = .right

        autoLoginSwitch.translatesAutoresizingMaskIntoConstraints = false
        autoLoginSwitch.onTintColor = AdminPalette.accent
        autoLoginSwitch.addTarget(self, action: #selector(handleAutoLoginChanged(_:)), for: .valueChanged)

        autoLoginDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        autoLoginDescriptionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        autoLoginDescriptionLabel.textColor = AdminPalette.textSecondary
        autoLoginDescriptionLabel.numberOfLines = 0

        refreshProfileButton.translatesAutoresizingMaskIntoConstraints = false
        refreshProfileButton.setTitle("Làm mới hồ sơ admin", for: .normal)
        refreshProfileButton.setTitleColor(AdminPalette.accent, for: .normal)
        refreshProfileButton.backgroundColor = AdminPalette.accentSoft
        refreshProfileButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        refreshProfileButton.layer.cornerRadius = 18
        refreshProfileButton.layer.cornerCurve = .continuous
        refreshProfileButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        refreshProfileButton.addTarget(self, action: #selector(handleRefreshProfile), for: .touchUpInside)

        logoutButton.removeFromSuperview()
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.backgroundColor = AdminPalette.destructive
        logoutButton.layer.cornerRadius = 20
        logoutButton.layer.cornerCurve = .continuous
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.setTitle("Đăng xuất", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        logoutButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let headerRow = UIStackView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 12

        let settingLabelsStack = UIStackView(arrangedSubviews: [autoLoginTitleLabel, autoLoginStateLabel])
        settingLabelsStack.axis = .vertical
        settingLabelsStack.alignment = .leading
        settingLabelsStack.spacing = 4

        headerRow.addArrangedSubview(settingLabelsStack)
        headerRow.addArrangedSubview(UIView())
        headerRow.addArrangedSubview(autoLoginSwitch)

        let mainStack = UIStackView(arrangedSubviews: [
            sessionTitleLabel,
            headerRow,
            autoLoginDescriptionLabel,
            refreshProfileButton,
            logoutButton
        ])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 14

        sessionCardView.addSubview(mainStack)

        sessionCardHeightConstraint?.isActive = false
        sessionCardHeightConstraint = sessionCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 250)
        sessionCardHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: sessionCardView.topAnchor, constant: 22),
            mainStack.leadingAnchor.constraint(equalTo: sessionCardView.leadingAnchor, constant: 22),
            mainStack.trailingAnchor.constraint(equalTo: sessionCardView.trailingAnchor, constant: -22),
            mainStack.bottomAnchor.constraint(equalTo: sessionCardView.bottomAnchor, constant: -22)
        ])

        updateAutoLoginUI()
    }

    private func updateAutoLoginUI() {
        let autoLoginEnabled = AppSessionPreferences.isAutoLoginEnabled
        autoLoginSwitch.setOn(autoLoginEnabled, animated: false)
        autoLoginStateLabel.text = autoLoginEnabled ? "Đang bật" : "Đang tắt"
        autoLoginStateLabel.textColor = autoLoginEnabled ? AdminPalette.accent : AdminPalette.textSecondary
        autoLoginDescriptionLabel.text = autoLoginEnabled
            ? "Ứng dụng sẽ tự vào lại khu admin nếu phiên Firebase hiện tại vẫn còn hợp lệ."
            : "Ứng dụng sẽ quay về màn hình đăng nhập ở lần mở kế tiếp. Bạn sẽ không bị tự đăng nhập nữa."
    }

    @objc private func handleRefreshProfile() {
        loadCurrentProfile()
        let alert = UIAlertController(
            title: "Đã làm mới",
            message: "Thông tin quản trị viên đã được cập nhật lại từ hệ thống.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleAutoLoginChanged(_ sender: UISwitch) {
        AppSessionPreferences.isAutoLoginEnabled = sender.isOn
        updateAutoLoginUI()

        if sender.isOn {
            return
        }

        let alert = UIAlertController(
            title: "Đã tắt tự động đăng nhập",
            message: "Từ lần mở app tiếp theo, hệ thống sẽ yêu cầu bạn đăng nhập lại.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
        present(alert, animated: true)
    }

    @IBAction func handleLogout(_ sender: UIButton) {
        presentAdminLogoutConfirmation()
    }
}
