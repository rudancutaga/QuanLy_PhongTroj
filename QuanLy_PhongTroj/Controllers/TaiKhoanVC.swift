import UIKit
import FirebaseAuth
import FirebaseFirestore

class TaiKhoanVC: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var loginBtn: UIButton! // Trong emptyStateView

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadUserData()
    }

    // MARK: - Setup UI
    private func setupUI() {
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.05
        
        avatar.layer.cornerRadius = 50
        avatar.clipsToBounds = true
        logoutBtn.layer.cornerRadius = 8
        loginBtn.addTarget(self, action: #selector(loginNowTapped), for: .touchUpInside)
    }


    // MARK: - Load User Data
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showEmptyState()
            return
        }
        
        activityIndicator.startAnimating()
        container.isHidden = true
        logoutBtn.isHidden = true
        emptyStateView.isHidden = true
        
        Firestore.firestore().collection("Users").document(userId).getDocument { [weak self] doc, err in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            if let data = doc?.data() {
                self.container.isHidden = false
                self.logoutBtn.isHidden = false
                
                self.nameLabel.text = data["hoTen"] as? String ?? "Người dùng ẩn danh"
                let role = data["role"] as? String ?? "user"
                let isActive = data["isActive"] as? Bool ?? true
                self.roleLabel.text = "\(role.uppercased()) • \(isActive ? "Hoạt động" : "Tạm khóa")"

                if let avatarUrl = data["avatarUrl"] as? String, let url = URL(string: avatarUrl) {
                    self.loadAvatar(from: url)
                } else {
                    self.avatar.image = UIImage(systemName: "person.crop.circle.fill")
                    self.avatar.tintColor = .systemGray4
                }
            } else {
                self.showEmptyState()
            }
        }
    }

    private func loadAvatar(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.avatar.image = image
            }
        }.resume()
    }
    
    private func showEmptyState() {
        activityIndicator.stopAnimating()
        container.isHidden = true
        logoutBtn.isHidden = true
        emptyStateView.isHidden = false
    }

    // MARK: - Logout
    @IBAction func logoutTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Đăng xuất", message: "Bạn có chắc chắn muốn đăng xuất?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive, handler: { [weak self] _ in
            self?.performLogout()
        }))
        present(alert, animated: true)
    }

    @IBAction func editProfileTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditProfileVC") as? EditProfileVC {
            editVC.modalPresentationStyle = .pageSheet
            present(editVC, animated: true)
        }
    }

    @objc private func performLogout() {
        do {
            try Auth.auth().signOut()
            AppNavigator.shared.route(to: .login)
        } catch {
            print("Lỗi đăng xuất: \(error.localizedDescription)")
            // Có thể show alert lỗi nếu cần
        }
    }

    @objc private func loginNowTapped() {
        AppNavigator.shared.route(to: .login)
    }
}
