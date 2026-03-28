import UIKit
import FirebaseFirestore

class AdminDashboardVC: UIViewController {

    @IBOutlet private weak var roomCardView: UIView!
    @IBOutlet private weak var userCardView: UIView!
    @IBOutlet private weak var roomTotalLabel: UILabel!
    @IBOutlet private weak var userTotalLabel: UILabel!
    @IBOutlet weak var roomsCountLabel: UILabel!
    @IBOutlet weak var usersCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        fetchStatistics()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background
        roomCardView.applyAdminCardStyle()
        userCardView.applyAdminCardStyle()
        roomTotalLabel.textColor = AdminPalette.accent
        userTotalLabel.textColor = .systemBlue
        roomTotalLabel.text = "--"
        userTotalLabel.text = "--"
        roomsCountLabel.text = "Đang tải số lượng phòng..."
        usersCountLabel.text = "Đang tải số lượng người dùng..."
    }

    @IBAction private func openRoomsTab(_ sender: UIControl) {
        switchToAdminTab(index: 1)
    }

    @IBAction private func openUsersTab(_ sender: UIControl) {
        switchToAdminTab(index: 2)
    }

    private func switchToAdminTab(index: Int) {
        guard let tabBarController = tabBarController else { return }

        if let navigationController = tabBarController.viewControllers?[index] as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
        }

        tabBarController.selectedIndex = index
    }

    private func fetchStatistics() {
        roomTotalLabel.text = "..."
        userTotalLabel.text = "..."
        roomsCountLabel.text = "Đang tải số lượng phòng..."
        usersCountLabel.text = "Đang tải số lượng người dùng..."

        let db = Firestore.firestore()

        db.collection("rooms").getDocuments { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let docs = snapshot?.documents {
                let count = docs.count
                var stats: [String: Int] = [:]

                for doc in docs {
                    let type = doc.data()["loaiPhong"] as? String ?? "Khác"
                    stats[type, default: 0] += 1
                }

                let details = stats
                    .sorted { $0.value > $1.value }
                    .map { "• \($0.key): \($0.value) phòng" }
                    .joined(separator: "\n")

                DispatchQueue.main.async {
                    self.roomTotalLabel.text = "\(count)"
                    self.roomsCountLabel.text = details.isEmpty ? "Chưa có bài đăng nào trong hệ thống." : details
                }
            } else {
                DispatchQueue.main.async {
                    self.roomTotalLabel.text = "--"
                    self.roomsCountLabel.text = "Không tải được dữ liệu phòng."
                }
            }
        }

        db.collection("Users").getDocuments { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let docs = snapshot?.documents {
                let count = docs.count
                let adminCount = docs.filter { ($0.data()["role"] as? String ?? "user") == "admin" }.count
                let activeCount = docs.filter { ($0.data()["isActive"] as? Bool ?? true) }.count
                let userCount = count - adminCount
                let inactiveCount = count - activeCount

                DispatchQueue.main.async {
                    self.userTotalLabel.text = "\(count)"
                    self.usersCountLabel.text = """
                    • Quản trị viên: \(adminCount)
                    • Người dùng thường: \(userCount)
                    • Đang hoạt động: \(activeCount)
                    • Tạm khóa: \(inactiveCount)
                    """
                }
            } else {
                DispatchQueue.main.async {
                    self.userTotalLabel.text = "--"
                    self.usersCountLabel.text = "Không tải được dữ liệu thành viên."
                }
            }
        }
    }
}
