import UIKit
import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChiTietPhongVC: UIViewController {
    
    var phong: PhongTro!
    private var isSaved = false
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblTieuDe: UILabel!
    @IBOutlet weak var lblGia: UILabel!
    @IBOutlet weak var lblDiaChi: UILabel!
    @IBOutlet weak var lblDienTich: UILabel!
    @IBOutlet weak var lblTienIch: UILabel!
    @IBOutlet weak var lblMoTa: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chi tiết phòng"
        
        // Thêm nút Back giả lập khi Modal
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(closeModal))
        }
        
        setupFavoriteButton()
        
        if phong != nil {
            bindData()
        }
    }
    
    @objc private func closeModal() {
        dismiss(animated: true)
    }
    
    private func setupFavoriteButton() {
        let heartImage = UIImage(systemName: isSaved ? "heart.fill" : "heart")
        let favButton = UIBarButtonItem(image: heartImage, style: .plain, target: self, action: #selector(toggleFavorite))
        favButton.tintColor = isSaved ? .systemRed : UIColor(hex: "#FF6600")
        navigationItem.rightBarButtonItem = favButton
        checkFavoriteStatus()
    }
    
    private func checkFavoriteStatus() {
        guard let userId = Auth.auth().currentUser?.uid, let roomId = phong.id else { return }
        Firestore.firestore().collection("Users").document(userId).collection("savedRooms").document(roomId).getDocument { [weak self] doc, _ in
            if let doc = doc, doc.exists {
                self?.isSaved = true
            } else {
                self?.isSaved = false
            }
            self?.updateFavoriteIcon()
        }
    }
    
    @objc private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid, let roomId = phong.id else {
            hienThongBaoChuaDangNhap()
            return
        }
        isSaved.toggle()
        updateFavoriteIcon()
        
        let docRef = Firestore.firestore().collection("Users").document(userId).collection("savedRooms").document(roomId)
        if isSaved {
            docRef.setData(["savedAt": Timestamp()])
        } else {
            docRef.delete()
        }
    }
    
    private func updateFavoriteIcon() {
        let heartImage = UIImage(systemName: isSaved ? "heart.fill" : "heart")
        navigationItem.rightBarButtonItem?.image = heartImage
        navigationItem.rightBarButtonItem?.tintColor = isSaved ? .systemRed : UIColor(hex: "#FF6600")
    }
    
    private func hienThongBaoChuaDangNhap() {
        let alert = UIAlertController(title: "Thông báo", message: "Vui lòng đăng nhập để lưu phòng", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = UIColor(hex: "#FF6600")
    }
    
    private func bindData() {
        lblTieuDe.text = phong.tieuDe
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        let formattedGia = formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫"
        lblGia.text = formattedGia.replacingOccurrences(of: "₫", with: "đ") + "/tháng"
        
        lblDiaChi.text = "📍 \(phong.diaChi)"
        lblDienTich.text = "📐 Diện tích: \(Int(phong.dienTich)) m²"
        
        if phong.tienIch.isEmpty {
            lblTienIch.text = "(Chưa cập nhật tiện ích)"
        } else {
            lblTienIch.text = phong.tienIch.map { "✔️ " + $0 }.joined(separator: "\n")
        }
        
        lblMoTa.text = phong.moTa.isEmpty ? "(Chưa có mô tả chi tiết)" : phong.moTa
        
        if let urlStr = phong.hinhAnh.first, let url = URL(string: urlStr) {
            loadImage(url: url)
        }
    }
    
    @IBAction func btnLienHeTapped(_ sender: Any) {
        let db = Firestore.firestore()
        let idNguoiDang = phong.idNguoiDang
        
        let loadingAlert = UIAlertController(title: "Đang xử lý...", message: "Đang lấy thông tin liên hệ.", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        db.collection("Users").document(idNguoiDang).getDocument { [weak self] doc, err in
            loadingAlert.dismiss(animated: true) {
                var phoneNumber = "19000000"
                var ownerName = "Chủ nhà"
                if let data = doc?.data() {
                    if let phone = data["soDienThoai"] as? String, !phone.isEmpty { phoneNumber = phone }
                    if let name = data["hoTen"] as? String { ownerName = name }
                }
                let message = (phoneNumber == "19000000") ? "Chủ nhà chưa cập nhật SĐT.\nVui lòng gọi tổng đài hỗ trợ: \(phoneNumber)" : "Số điện thoại: \(phoneNumber)"
                let alert = UIAlertController(title: "Liên Hệ: \(ownerName)", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Gọi ngay", style: .default, handler: { _ in
                    if let url = URL(string: "tel://\(phoneNumber)") { UIApplication.shared.open(url) }
                }))
                alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
                self?.present(alert, animated: true)
            }
        }
    }

    @IBAction func btnChatTapped(_ sender: Any) {
        guard Auth.auth().currentUser != nil else {
            let alert = UIAlertController(title: "Cần đăng nhập", message: "Vui lòng đăng nhập để bắt đầu cuộc trò chuyện với chủ phòng.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
            alert.addAction(UIAlertAction(title: "Đăng nhập", style: .default, handler: { _ in
                AppNavigator.shared.route(to: .login)
            }))
            present(alert, animated: true)
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            chatVC.room = self.phong
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    private func loadImage(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imgView.image = image
                }
            }
        }.resume()
    }
}
