import UIKit
import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChiTietPhongVC: UIViewController {
    
    var phong: PhongTro!
    private var isSaved = false
    private let rentButton = UIButton(type: .system)
    private let availableStatus = "Đang rảnh"
    private let rentedStatus = "Đã thuê"
    private var didSetupBottomActions = false
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblTieuDe: UILabel!
    @IBOutlet weak var lblGia: UILabel!
    @IBOutlet weak var lblDiaChi: UILabel!
    @IBOutlet weak var lblDienTich: UILabel!
    @IBOutlet weak var lblTienIch: UILabel!
    @IBOutlet weak var lblMoTa: UILabel!
    @IBOutlet private weak var actionStackView: UIStackView!
    @IBOutlet private weak var chatButton: UIButton!
    @IBOutlet private weak var contactButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chi tiết phòng"
        
        // Thêm nút Back giả lập khi Modal
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(closeModal))
        }
        
        setupBottomActions()
        setupFavoriteButton()
        
        if phong != nil {
            bindData()
            refreshRoomState()
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
        if phong != nil {
            updateRentButtonState()
        }
    }
    
    private func bindData() {
        let roomStatus = normalizedRoomStatus()
        lblTieuDe.text = phong.tieuDe
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        let formattedGia = formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫"
        lblGia.text = formattedGia.replacingOccurrences(of: "₫", with: "đ") + (roomStatus == rentedStatus ? "/đã thuê" : "/tháng")
        lblGia.textColor = roomStatus == rentedStatus ? .systemGray : UIColor(hex: "#FF6600")
        
        lblDiaChi.text = "📍 \(phong.diaChi)"
        lblDienTich.numberOfLines = 0
        lblDienTich.text = "📐 Diện tích: \(Int(phong.dienTich)) m²\n🏷️ Trạng thái: \(roomStatus)"
        
        if phong.tienIch.isEmpty {
            lblTienIch.text = "(Chưa cập nhật tiện ích)"
        } else {
            lblTienIch.text = phong.tienIch.map { "✔️ " + $0 }.joined(separator: "\n")
        }
        
        lblMoTa.text = phong.moTa.isEmpty ? "(Chưa có mô tả chi tiết)" : phong.moTa
        
        if let urlStr = phong.hinhAnh.first, let url = URL(string: urlStr) {
            loadImage(url: url)
        }

        updateRentButtonState()
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

    @objc private func btnThuePhongTapped() {
        guard let currentUser = Auth.auth().currentUser else {
            let alert = UIAlertController(
                title: "Cần đăng nhập",
                message: "Vui lòng đăng nhập để thuê phòng.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
            alert.addAction(UIAlertAction(title: "Đăng nhập", style: .default) { _ in
                AppNavigator.shared.route(to: .login)
            })
            present(alert, animated: true)
            return
        }

        if phong.idNguoiDang == currentUser.uid {
            showAlert(title: "Không thể thuê", message: "Bạn không thể tự thuê phòng do chính mình đăng.")
            return
        }

        if normalizedRoomStatus() == rentedStatus {
            showAlert(title: "Phòng đã được thuê", message: "Phòng này hiện đã có người thuê. Bạn hãy chọn phòng khác nhé.")
            return
        }

        let alert = UIAlertController(
            title: "Thuê phòng",
            message: "Bạn muốn xác nhận thuê phòng này ngay bây giờ?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Thuê ngay", style: .default) { [weak self] _ in
            self?.performRentRoom(for: currentUser.uid)
        })
        present(alert, animated: true)
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

    private func setupBottomActions() {
        guard !didSetupBottomActions else { return }
        didSetupBottomActions = true

        chatButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        contactButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)

        configureRentButton()

        let rowStack = UIStackView(arrangedSubviews: [chatButton, contactButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.distribution = .fillEqually
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.heightAnchor.constraint(equalToConstant: 60).isActive = true

        actionStackView.arrangedSubviews.forEach {
            actionStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        actionStackView.axis = .vertical
        actionStackView.alignment = .fill
        actionStackView.distribution = .fill
        actionStackView.spacing = 12
        actionStackView.addArrangedSubview(rentButton)
        actionStackView.addArrangedSubview(rowStack)

        rentButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        updateActionStackHeight(to: 126)
    }

    private func configureRentButton() {
        rentButton.translatesAutoresizingMaskIntoConstraints = false
        rentButton.backgroundColor = UIColor(hex: "#FF6600")
        rentButton.setTitleColor(.white, for: .normal)
        rentButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        rentButton.layer.cornerRadius = 14
        rentButton.layer.cornerCurve = .continuous
        rentButton.addTarget(self, action: #selector(btnThuePhongTapped), for: .touchUpInside)
    }

    private func updateActionStackHeight(to constant: CGFloat) {
        let candidateConstraints = actionStackView.constraints
            + view.constraints
            + (actionStackView.superview?.constraints ?? [])

        if let heightConstraint = candidateConstraints.first(where: {
            (($0.firstItem as? UIStackView) == actionStackView && $0.firstAttribute == .height) ||
            (($0.secondItem as? UIStackView) == actionStackView && $0.secondAttribute == .height)
        }) {
            heightConstraint.constant = constant
        }
    }

    private func refreshRoomState() {
        guard let roomId = phong.id else { return }

        Firestore.firestore().collection("rooms").document(roomId).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let snapshot, snapshot.exists, var latestRoom = try? snapshot.data(as: PhongTro.self) {
                latestRoom.id = snapshot.documentID
                DispatchQueue.main.async {
                    self.phong = latestRoom
                    self.bindData()
                }
            } else {
                DispatchQueue.main.async {
                    self.updateRentButtonState()
                }
            }
        }
    }

    private func normalizedRoomStatus() -> String {
        let status = phong.trangThai?.trimmingCharacters(in: .whitespacesAndNewlines)
        return status?.isEmpty == false ? status! : availableStatus
    }

    private func updateRentButtonState() {
        let currentUserId = Auth.auth().currentUser?.uid
        let roomStatus = normalizedRoomStatus()
        let isOwner = currentUserId == phong.idNguoiDang
        let isCurrentRenter = currentUserId != nil && currentUserId == phong.nguoiThueId

        if roomStatus == rentedStatus {
            rentButton.isEnabled = false
            rentButton.backgroundColor = .systemGray4
            rentButton.setTitle(isCurrentRenter ? "Bạn đã thuê phòng này" : "Phòng đã được thuê", for: .normal)
        } else if isOwner {
            rentButton.isEnabled = false
            rentButton.backgroundColor = .systemGray4
            rentButton.setTitle("Đây là phòng của bạn", for: .normal)
        } else {
            rentButton.isEnabled = true
            rentButton.backgroundColor = UIColor(hex: "#FF6600")
            rentButton.setTitle("Thuê phòng ngay", for: .normal)
        }

        rentButton.alpha = rentButton.isEnabled ? 1 : 0.88
    }

    private func performRentRoom(for userId: String) {
        guard let roomId = phong.id else {
            showAlert(title: "Không thể thuê phòng", message: "Không tìm thấy mã phòng để xử lý.")
            return
        }

        let loadingAlert = UIAlertController(
            title: "Đang xử lý...",
            message: "Hệ thống đang xác nhận thuê phòng cho bạn.",
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        let db = Firestore.firestore()
        let roomRef = db.collection("rooms").document(roomId)
        let userRentalRef = db.collection("Users").document(userId).collection("rentedRooms").document(roomId)

        db.runTransaction({ transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(roomRef)
                let currentStatus = (snapshot.data()?["trangThai"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? self.availableStatus

                if currentStatus == self.rentedStatus {
                    errorPointer?.pointee = NSError(
                        domain: "QuanLyPhongTroj.Rent",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "Phòng này vừa được người khác thuê trước bạn."]
                    )
                    return nil
                }

                let rentedAt = Timestamp(date: Date())
                transaction.updateData([
                    "trangThai": self.rentedStatus,
                    "nguoiThueId": userId,
                    "ngayThue": rentedAt
                ], forDocument: roomRef)

                transaction.setData([
                    "roomId": roomId,
                    "tieuDe": self.phong.tieuDe,
                    "giaThue": self.phong.giaThue,
                    "diaChi": self.phong.diaChi,
                    "loaiPhong": self.phong.loaiPhong,
                    "idNguoiDang": self.phong.idNguoiDang,
                    "trangThai": self.rentedStatus,
                    "rentedAt": rentedAt
                ], forDocument: userRentalRef, merge: true)

                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }) { [weak self] _, error in
            guard let self = self else { return }

            loadingAlert.dismiss(animated: true) {
                if let error = error {
                    self.refreshRoomState()
                    self.showAlert(title: "Thuê phòng chưa thành công", message: error.localizedDescription)
                    return
                }

                self.phong.trangThai = self.rentedStatus
                self.phong.nguoiThueId = userId
                self.phong.ngayThue = Date()
                self.bindData()

                let successAlert = UIAlertController(
                    title: "Thuê phòng thành công",
                    message: "Phòng đã được đánh dấu là đã thuê. Bạn có thể nhắn tin với chủ phòng để chốt lịch nhận phòng.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
                successAlert.addAction(UIAlertAction(title: "Nhắn tin", style: .default) { _ in
                    self.btnChatTapped(self.chatButton as Any)
                })
                self.present(successAlert, animated: true)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
