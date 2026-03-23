import UIKit
import FirebaseAuth

class AdminCaiDatVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func handleLogout(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let dangNhapVC = storyboard.instantiateViewController(withIdentifier: "DangNhapVC")
                window.rootViewController = dangNhapVC
                window.makeKeyAndVisible()
            }
        } catch {
            print("Lỗi đăng xuất: \(error.localizedDescription)")
        }
    }
}
