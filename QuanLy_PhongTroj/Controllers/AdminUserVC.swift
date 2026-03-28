import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct UserApp {
    var id: String
    var hoTen: String
    var tenDangNhap: String
    var role: String
    var isActive: Bool
}

class AdminUserVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let secondaryAppName = "AdminUserCreationApp"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private var users: [UserApp] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        loadUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadUsers()
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminUserCell.self, forCellReuseIdentifier: AdminUserCell.reuseID)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.rowHeight = 92

        emptyLabel.text = "Chưa có tài khoản nào trong hệ thống."
        emptyLabel.textColor = AdminPalette.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
    }

    @IBAction private func handleQuickAdd(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Thêm người dùng",
            message: "Tạo nhanh tài khoản mới ngay trong khu quản trị.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Họ và tên"
            textField.autocapitalizationType = .words
        }
        alert.addTextField { textField in
            textField.placeholder = "Tên đăng nhập"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        alert.addTextField { textField in
            textField.placeholder = "Mật khẩu"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Xác nhận mật khẩu"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tạo User", style: .default) { [weak self, weak alert] _ in
            self?.handleCreateUser(from: alert, role: "user")
        })
        alert.addAction(UIAlertAction(title: "Tạo Admin", style: .default) { [weak self, weak alert] _ in
            self?.handleCreateUser(from: alert, role: "admin")
        })
        present(alert, animated: true)
    }

    private func handleCreateUser(from alert: UIAlertController?, role: String) {
        guard let fields = alert?.textFields, fields.count >= 4 else { return }

        let hoTen = fields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tenDangNhap = fields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let matKhau = fields[2].text ?? ""
        let xacNhan = fields[3].text ?? ""

        guard !hoTen.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập họ và tên.")
            return
        }

        guard !tenDangNhap.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập tên đăng nhập.")
            return
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let isValidUsername = tenDangNhap.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        guard isValidUsername else {
            showAlert(
                title: "Tên đăng nhập chưa hợp lệ",
                message: "Chỉ dùng chữ không dấu, số, dấu chấm, gạch dưới hoặc gạch ngang."
            )
            return
        }

        guard matKhau.count >= 6 else {
            showAlert(title: "Mật khẩu quá ngắn", message: "Mật khẩu phải có ít nhất 6 ký tự.")
            return
        }

        guard matKhau == xacNhan else {
            showAlert(title: "Xác nhận chưa khớp", message: "Mật khẩu xác nhận không trùng khớp.")
            return
        }

        createUser(hoTen: hoTen, tenDangNhap: tenDangNhap, matKhau: matKhau, role: role)
    }

    private func createUser(hoTen: String, tenDangNhap: String, matKhau: String, role: String) {
        let db = Firestore.firestore()
        db.collection("Users").whereField("tenDangNhap", isEqualTo: tenDangNhap).limit(to: 1).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Không thể kiểm tra tài khoản", message: error.localizedDescription)
                return
            }

            if snapshot?.documents.isEmpty == false {
                self.showAlert(title: "Tên đăng nhập đã tồn tại", message: "Vui lòng chọn tên đăng nhập khác.")
                return
            }

            let auth: Auth
            do {
                auth = try self.secondaryAuth()
            } catch {
                self.showAlert(title: "Không thể tạo tài khoản", message: error.localizedDescription)
                return
            }

            let email = "\(tenDangNhap)@quanlyphongtro.com"
            auth.createUser(withEmail: email, password: matKhau) { [weak self] result, error in
                guard let self = self else { return }

                if let nsError = error as NSError? {
                    let message: String
                    if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        message = "Tên đăng nhập này đã tồn tại."
                    } else {
                        message = nsError.localizedDescription
                    }
                    try? auth.signOut()
                    self.showAlert(title: "Không thể tạo tài khoản", message: message)
                    return
                }

                guard let user = result?.user else {
                    try? auth.signOut()
                    self.showAlert(title: "Không thể tạo tài khoản", message: "Không nhận được dữ liệu người dùng mới.")
                    return
                }

                let userData: [String: Any] = [
                    "hoTen": hoTen,
                    "tenDangNhap": tenDangNhap,
                    "role": role,
                    "isActive": true,
                    "ngayTao": Timestamp(date: Date())
                ]

                db.collection("Users").document(user.uid).setData(userData) { [weak self] error in
                    guard let self = self else { return }
                    defer { try? auth.signOut() }

                    if let error = error {
                        user.delete(completion: nil)
                        self.showAlert(title: "Không thể lưu hồ sơ", message: error.localizedDescription)
                        return
                    }

                    self.loadUsers()
                    self.showAlert(
                        title: "Đã tạo tài khoản",
                        message: "Tài khoản \(tenDangNhap) đã được tạo với quyền \(role.uppercased())."
                    )
                }
            }
        }
    }

    private func secondaryAuth() throws -> Auth {
        if let app = FirebaseApp.app(name: Self.secondaryAppName) {
            return Auth.auth(app: app)
        }

        guard let options = FirebaseApp.app()?.options else {
            throw NSError(
                domain: "AdminUserVC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Không đọc được cấu hình Firebase hiện tại."]
            )
        }

        FirebaseApp.configure(name: Self.secondaryAppName, options: options)

        guard let app = FirebaseApp.app(name: Self.secondaryAppName) else {
            throw NSError(
                domain: "AdminUserVC",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Không khởi tạo được phiên Firebase phụ để tạo tài khoản."]
            )
        }

        return Auth.auth(app: app)
    }

    private func loadUsers() {
        let db = Firestore.firestore()
        db.collection("Users").getDocuments { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let docs = snapshot?.documents {
                self.users = docs.compactMap { doc in
                    let data = doc.data()
                    let hoTen = data["hoTen"] as? String ?? "Chưa cập nhật"
                    let ten = data["tenDangNhap"] as? String ?? "Không rõ"
                    let role = data["role"] as? String ?? "user"
                    let isActive = data["isActive"] as? Bool ?? true
                    return UserApp(id: doc.documentID, hoTen: hoTen, tenDangNhap: ten, role: role, isActive: isActive)
                }.sorted {
                    $0.tenDangNhap.localizedCaseInsensitiveCompare($1.tenDangNhap) == .orderedAscending
                }
            } else {
                self.users = []
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.emptyLabel.isHidden = !self.users.isEmpty
            }
        }
    }

    private func presentActions(for user: UserApp) {
        let isCurrentUser = user.id == Auth.auth().currentUser?.uid
        var actions: [AdminSheetAction] = [
            AdminSheetAction(title: "Đổi Tên Hiển Thị") { [weak self] in
                self?.promptRename(for: user)
            }
        ]

        if !isCurrentUser {
            let roleTitle = user.role == "admin" ? "Hạ xuống User" : "Nâng cấp lên Admin"
            actions.append(AdminSheetAction(title: roleTitle) { [weak self] in
                self?.updateRole(for: user, role: user.role == "admin" ? "user" : "admin")
            })

            let statusTitle = user.isActive ? "Tạm khóa tài khoản" : "Mở lại tài khoản"
            actions.append(
                AdminSheetAction(
                    title: statusTitle,
                    titleColor: user.isActive ? AdminPalette.destructive : AdminPalette.accent
                ) { [weak self] in
                    self?.updateActiveStatus(for: user, isActive: !user.isActive)
                }
            )
        }

        let sheet = AdminActionSheetController(
            title: "Mức Quyền: \(user.role.uppercased())",
            subtitle: "Tài khoản: \(user.tenDangNhap)",
            actions: actions
        )
        present(sheet, animated: true)
    }

    private func promptRename(for user: UserApp) {
        let alert = UIAlertController(title: "Đổi tên hiển thị", message: user.tenDangNhap, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Tên hiển thị mới"
            textField.text = user.hoTen
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self, weak alert] _ in
            let newName = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !newName.isEmpty else { return }
            self?.updateDisplayName(for: user, name: newName)
        })
        present(alert, animated: true)
    }

    private func updateDisplayName(for user: UserApp, name: String) {
        Firestore.firestore().collection("Users").document(user.id).updateData(["hoTen": name]) { [weak self] error in
            guard error == nil else { return }
            self?.loadUsers()
        }
    }

    private func updateRole(for user: UserApp, role: String) {
        Firestore.firestore().collection("Users").document(user.id).updateData(["role": role]) { [weak self] error in
            guard error == nil else { return }
            self?.loadUsers()
        }
    }

    private func updateActiveStatus(for user: UserApp, isActive: Bool) {
        Firestore.firestore().collection("Users").document(user.id).updateData(["isActive": isActive]) { [weak self] error in
            guard error == nil else { return }
            self?.loadUsers()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminUserCell.reuseID, for: indexPath) as? AdminUserCell else {
            return UITableViewCell()
        }
        cell.configure(with: users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentActions(for: users[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let user = users[indexPath.row]
        let actionTitle = user.isActive ? "Khóa" : "Mở"

        let toggleAction = UIContextualAction(style: .normal, title: actionTitle) { [weak self] _, _, completion in
            self?.updateActiveStatus(for: user, isActive: !user.isActive)
            completion(true)
        }
        toggleAction.backgroundColor = user.isActive ? AdminPalette.destructive : AdminPalette.accent

        return UISwipeActionsConfiguration(actions: [toggleAction])
    }
}

final class AdminUserCell: UITableViewCell {
    static let reuseID = "AdminUserCell"

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .clear
        selectionStyle = .none

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray3
        avatarImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)

        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = .systemFont(ofSize: 15, weight: .medium)

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.tintColor = .systemGray3

        contentView.addSubview(container)
        container.addSubview(avatarImageView)
        container.addSubview(nameLabel)
        container.addSubview(roleLabel)
        container.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatarImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            avatarImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 34),
            avatarImageView.heightAnchor.constraint(equalToConstant: 34),

            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            roleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12)
        ])
    }

    func configure(with user: UserApp) {
        let isAdmin = user.role == "admin"

        nameLabel.text = user.tenDangNhap
        roleLabel.text = isAdmin ? "Quyền quản trị viên" : "Người dùng thông thường"

        if isAdmin {
            avatarImageView.tintColor = AdminPalette.accent
            roleLabel.textColor = AdminPalette.accent
        } else if !user.isActive {
            avatarImageView.tintColor = AdminPalette.destructive
            roleLabel.textColor = AdminPalette.destructive
            roleLabel.text = "Tài khoản đang tạm khóa"
        } else {
            avatarImageView.tintColor = .systemGray3
            roleLabel.textColor = AdminPalette.textSecondary
        }
    }
}
