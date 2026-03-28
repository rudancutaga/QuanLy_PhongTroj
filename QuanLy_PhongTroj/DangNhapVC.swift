//
//  DangNhapVC.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class DangNhapVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tenDangNhapTF: UITextField!
    @IBOutlet weak var matKhauTF: UITextField!
    @IBOutlet weak var dangNhapBT: UIButton!
    @IBOutlet weak var dangKyBT: UIButton!
    @IBOutlet weak var lblThongBao: UILabel!

    // MARK: - Vòng đời View
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Cài đặt giao diện
    func setupUI() {
        // Tô màu cam cho NavigationBar thủ công trong view
        if let navBar = view.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar {
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(hex: "#FF6600")
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 18)
            ]
            navBar.standardAppearance = navAppearance
            navBar.scrollEdgeAppearance = navAppearance
            navBar.tintColor = .white
        }
        // Cũng set cho UINavigationController nếu được embed
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#FF6600")
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        title = "ĐĂNG NHẬP"

        // Ẩn thông báo lỗi ban đầu
        lblThongBao.isHidden = true
        lblThongBao.textColor = .systemRed
        lblThongBao.textAlignment = .center

        // TextField mật khẩu - ẩn ký tự
        matKhauTF.isSecureTextEntry = true

        // Placeholder
        tenDangNhapTF.placeholder = "Tên đăng nhập"
        matKhauTF.placeholder = "Mật khẩu"

        // Nút ĐĂNG NHẬP - dùng UIButtonConfiguration (iOS 15+)
        var configNhap = UIButton.Configuration.filled()
        configNhap.title = "ĐĂNG NHẬP"
        configNhap.baseBackgroundColor = UIColor(hex: "#FF6600")
        configNhap.baseForegroundColor = .white
        configNhap.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.boldSystemFont(ofSize: 16); return a
        }
        configNhap.cornerStyle = .medium
        dangNhapBT.configuration = configNhap

        // Nút ĐĂNG KÝ - viền cam, nền trắng
        var configKy = UIButton.Configuration.bordered()
        configKy.title = "ĐĂNG KÝ"
        configKy.baseBackgroundColor = .white
        configKy.baseForegroundColor = UIColor(hex: "#FF6600")
        configKy.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.boldSystemFont(ofSize: 16); return a
        }
        configKy.cornerStyle = .medium
        configKy.background.strokeColor = UIColor(hex: "#FF6600")
        configKy.background.strokeWidth = 2
        dangKyBT.configuration = configKy

        // Ẩn bàn phím khi bấm ra ngoài
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Ẩn bàn phím
    @objc func anBanPhim() {
        view.endEditing(true)
    }

    // MARK: - Xử lý Đăng Nhập
    @IBAction func dangNhap(_ sender: UIButton) {
        guard let tenDangNhap = tenDangNhapTF.text, !tenDangNhap.isEmpty,
              let matKhau = matKhauTF.text, !matKhau.isEmpty else {
            hienThongBao("Vui lòng nhập đầy đủ thông tin!")
            return
        }

        // Định dạng lại email như lúc đăng ký
        let emailDangNhap = "\(tenDangNhap)@quanlyphongtro.com"
        
        setLoading(true, for: sender, title: "Đang xử lý...")
        lblThongBao.isHidden = true
        
        Auth.auth().signIn(withEmail: emailDangNhap, password: matKhau) { authResult, error in
            self.setLoading(false, for: sender, title: "ĐĂNG NHẬP")
            
            if let err = error {
                let errStr = (err as NSError).code == AuthErrorCode.wrongPassword.rawValue || 
                             (err as NSError).code == AuthErrorCode.userNotFound.rawValue
                             ? "Sai tên đăng nhập hoặc mật khẩu!" 
                             : "Lỗi đăng nhập: \(err.localizedDescription)"
                
                self.hienThongBao(errStr)
                return
            }
            
            // Thành công
            self.lblThongBao.isHidden = true
            self.dangNhapThanhCong()
        }
    }

    // Nút ĐĂNG KÝ dùng Segue "show" trực tiếp sang DangKyVC trong Storyboard


    // MARK: - Hiển thị thông báo lỗi
    func hienThongBao(_ noiDung: String) {
        lblThongBao.text = noiDung
        lblThongBao.isHidden = false
    }

    private func setLoading(_ loading: Bool, for button: UIButton, title: String) {
        button.isEnabled = !loading
        if button.configuration != nil {
            button.configuration?.title = title
        } else {
            button.setTitle(title, for: .normal)
        }
    }

    // MARK: - Đăng nhập thành công
    func dangNhapThanhCong() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Gọi Firestore để lấy thông tin phân quyền (role)
        let db = Firestore.firestore()
        db.collection("Users").document(currentUser.uid).getDocument { (document, error) in
            // Mặc định là user nếu không lấy được quyền
            let role = document?.data()?["role"] as? String ?? "user"
            let isActive = document?.data()?["isActive"] as? Bool ?? true

            guard isActive else {
                try? Auth.auth().signOut()
                self.hienThongBao("Tài khoản của bạn đang bị tạm khóa. Vui lòng liên hệ quản trị viên.")
                return
            }
            
            let alert = UIAlertController(title: "Thành công",
                                          message: "Chào mừng bạn đến với Quản Lý Phòng Trọ!",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                RoomService.shared.ensureSampleDataIfNeeded()
                let roleToRoute = (role == "admin" || self.tenDangNhapTF.text?.lowercased() == "admin") ? "admin" : "user"
                AppNavigator.shared.routeToRole(roleToRoute)
            }))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Extension: UIColor từ mã Hex
extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgbValue & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
