//
//  DangKyVC.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class DangKyVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var hoTenTF: UITextField!
    @IBOutlet weak var tenDangNhapTF: UITextField!
    @IBOutlet weak var matKhauTF: UITextField!
    @IBOutlet weak var xacNhanMatKhauTF: UITextField!
    @IBOutlet weak var dangKyBT: UIButton!
    @IBOutlet weak var lblThongBao: UILabel!

    // MARK: - Vòng đời View
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Cài đặt giao diện
    func setupUI() {
        title = "ĐĂNG KÝ"

        // Navigation Bar màu cam
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

        // Ẩn thông báo ban đầu
        lblThongBao.isHidden = true
        lblThongBao.textAlignment = .center
        lblThongBao.numberOfLines = 0

        // Placeholder
        hoTenTF.placeholder = "Họ và tên"
        tenDangNhapTF.placeholder = "Tên đăng nhập"
        matKhauTF.placeholder = "Mật khẩu"
        xacNhanMatKhauTF.placeholder = "Xác nhận mật khẩu"

        // Ẩn ký tự mật khẩu
        matKhauTF.isSecureTextEntry = true
        xacNhanMatKhauTF.isSecureTextEntry = true

        // Nút ĐĂNG KÝ
        var config = UIButton.Configuration.filled()
        config.title = "ĐĂNG KÝ"
        config.baseBackgroundColor = UIColor(hex: "#FF6600")
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.boldSystemFont(ofSize: 16); return a
        }
        config.cornerStyle = .medium
        dangKyBT.configuration = config

        // Ẩn bàn phím khi bấm ra ngoài
        let tap = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Ẩn bàn phím
    @objc func anBanPhim() {
        view.endEditing(true)
    }

    // MARK: - Xử lý Đăng Ký
    @IBAction func dangKy(_ sender: UIButton) {
        // Kiểm tra không để trống
        guard let hoTen = hoTenTF.text, !hoTen.isEmpty else {
            hienThongBao("Vui lòng nhập họ và tên!", mauDo: true)
            return
        }
        guard let tenDangNhap = tenDangNhapTF.text, !tenDangNhap.isEmpty else {
            hienThongBao("Vui lòng nhập tên đăng nhập!", mauDo: true)
            return
        }
        guard let matKhau = matKhauTF.text, matKhau.count >= 6 else {
            hienThongBao("Mật khẩu phải có ít nhất 6 ký tự!", mauDo: true)
            return
        }
        guard let xacNhan = xacNhanMatKhauTF.text, xacNhan == matKhau else {
            hienThongBao("Mật khẩu xác nhận không khớp!", mauDo: true)
            return
        }

        // Đổi Tên Đăng Nhập thành chuẩn Email Firebase
        // Firebase yêu cầu đăng ký bằng email, do ứng dụng thiết kế là Username nên ta tuỳ biến nối thêm đuôi domain để thành email hợp lệ
        let emailDangKy = "\(tenDangNhap)@quanlyphongtro.com"
        
        // Disable nút đăng ký để tránh bấm nhiều lần
        dangKyBT.isEnabled = false
        dangKyBT.setTitle("Đang chờ...", for: .normal)
        self.lblThongBao.isHidden = true
        
        Auth.auth().createUser(withEmail: emailDangKy, password: matKhau) { authResult, error in
            // Bật lại nút sau khi xử lý xong
            self.dangKyBT.isEnabled = true
            self.dangKyBT.setTitle("ĐĂNG KÝ", for: .normal)
            
            if let err = error {
                let errStr = (err as NSError).code == AuthErrorCode.emailAlreadyInUse.rawValue 
                             ? "Tên đăng nhập này đã tồn tại!" 
                             : "Lỗi đăng ký: \(err.localizedDescription)"
                self.hienThongBao(errStr, mauDo: true)
                return
            }
            
            guard let user = authResult?.user else { return }
            
            // Lưu thêm thông tin Họ Tên và Phân Quyền vào Firestore Database
            let db = Firestore.firestore()
            
            // Mặc định đăng ký là user, nhưng hỗ trợ seed cho admin nếu đăng ký tên admin
            let roleToSave = tenDangNhap.lowercased() == "admin" ? "admin" : "user"
            
            db.collection("Users").document(user.uid).setData([
                "hoTen": hoTen,
                "tenDangNhap": tenDangNhap,
                "role": roleToSave,
                "ngayTao": Timestamp(date: Date())
            ]) { error in
                if let err = error {
                    print("⚠️ Cảnh báo: Lỗi lưu Firestore (thường do Security Rules chưa mở): \(err.localizedDescription)")
                } else {
                    print("✅ Lưu thông tin Họ tên thành công vào Database!")
                }
                
                // Dù lưu thông tin phụ có thành công hay không, tài khoản Auth đã được tạo
                // -> Vẫn cho hiển thị Popup Thành Công để người dùng không bị bối rối
                self.dangKyThanhCong(tenDangNhap: tenDangNhap)
            }
        }
    }

    // MARK: - Hiển thị thông báo
    func hienThongBao(_ noiDung: String, mauDo: Bool) {
        lblThongBao.text = noiDung
        lblThongBao.textColor = mauDo ? .systemRed : UIColor(hex: "#28A745")
        lblThongBao.isHidden = false
    }

    // MARK: - Đăng ký thành công
    func dangKyThanhCong(tenDangNhap: String) {
        let alert = UIAlertController(
            title: "Đăng Ký Thành Công",
            message: "Tài khoản '\(tenDangNhap)' đã được tạo. Vui lòng đăng nhập!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đăng Nhập Ngay", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
}

// MARK: - Extension UIColor (nếu chưa có ở file khác)
// Đã khai báo trong DangNhapVC.swift, không cần khai báo lại
