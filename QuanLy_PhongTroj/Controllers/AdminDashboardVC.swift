import UIKit
import FirebaseFirestore

class AdminDashboardVC: UIViewController {
    
    // Giao diện
    private let titleLabel = UILabel()
    private let roomsCountLabel = UILabel()
    private let usersCountLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        
        setupUI()
        fetchStatistics()
    }
    
    private func setupUI() {
        titleLabel.text = "Thống Kê Hệ Thống"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = UIColor(hex: "#FF6600")
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, roomsCountLabel, usersCountLabel])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func fetchStatistics() {
        roomsCountLabel.text = "Đang tải số lượng phòng..."
        usersCountLabel.text = "Đang tải số lượng người dùng..."
        
        let db = Firestore.firestore()
        
        db.collection("rooms").getDocuments { [weak self] snapshot, _ in
            if let count = snapshot?.documents.count {
                self?.roomsCountLabel.text = "🏢 Tổng số phòng trọ đăng tải: \(count)"
                self?.roomsCountLabel.font = .systemFont(ofSize: 18, weight: .medium)
            } else {
                self?.roomsCountLabel.text = "🏢 Lỗi tải dữ liệu phòng"
            }
        }
        
        db.collection("Users").getDocuments { [weak self] snapshot, _ in
            if let count = snapshot?.documents.count {
                self?.usersCountLabel.text = "👥 Tổng số tài khoản đăng ký: \(count)"
                self?.usersCountLabel.font = .systemFont(ofSize: 18, weight: .medium)
            } else {
                self?.usersCountLabel.text = "👥 Lỗi tải dữ liệu user"
            }
        }
    }
}
