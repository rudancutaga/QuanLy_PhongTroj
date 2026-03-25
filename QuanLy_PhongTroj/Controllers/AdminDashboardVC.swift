import UIKit
import FirebaseFirestore

class AdminDashboardVC: UIViewController {
    
    // MARK: - IBOutlets (kết nối từ Storyboard)
    @IBOutlet weak var roomsCountLabel: UILabel!
    @IBOutlet weak var usersCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchStatistics()
    }
    
    private func fetchStatistics() {
        roomsCountLabel.text = "Đang tải số lượng phòng..."
        usersCountLabel.text = "Đang tải số lượng người dùng..."
        
        let db = Firestore.firestore()
        
        db.collection("rooms").getDocuments { [weak self] snapshot, _ in
            if let docs = snapshot?.documents {
                let count = docs.count
                var stats: [String: Int] = [:]
                
                for doc in docs {
                    let type = doc.data()["loaiPhong"] as? String ?? "Khác"
                    stats[type, default: 0] += 1
                }
                
                var details = "🏢 Tổng số phòng trọ đăng tải: \(count)\n\n"
                for (type, num) in stats.sorted(by: { $0.value > $1.value }) {
                    details += "• \(type): \(num) phòng\n"
                }
                
                self?.roomsCountLabel.numberOfLines = 0
                self?.roomsCountLabel.text = details.trimmingCharacters(in: .whitespacesAndNewlines)
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
