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
        
        logoutBtn.layer.cornerRadius = 8
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
                self.roleLabel.text = role.uppercased()
            } else {
                self.showEmptyState()
            }
        }
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
            
            // Cách hiện đại và an toàn hơn (hỗ trợ SceneDelegate)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "DangNhapVC")
            
            window.rootViewController = loginVC
            
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
            
        } catch {
            print("Lỗi đăng xuất: \(error.localizedDescription)")
            // Có thể show alert lỗi nếu cần
        }
    }
}
