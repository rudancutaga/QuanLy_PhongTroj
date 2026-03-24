import UIKit
import FirebaseFirestore

struct UserApp {
    var id: String
    var tenDangNhap: String
    var role: String
}

class AdminUserVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
<<<<<<< HEAD
    // MARK: - IBOutlet (kết nối từ Storyboard)
    @IBOutlet weak var tableView: UITableView!
    
=======
    private let tableView = UITableView()
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
    private var users: [UserApp] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Quản lý Người Dùng"
<<<<<<< HEAD
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        
        loadUsers()
=======
        view.backgroundColor = .systemBackground
        
        setupTableView()
        loadUsers()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
    }
    
    private func loadUsers() {
        let db = Firestore.firestore()
        db.collection("Users").getDocuments { [weak self] snapshot, error in
            if let docs = snapshot?.documents {
                self?.users = docs.compactMap { doc in
                    let data = doc.data()
                    let ten = data["tenDangNhap"] as? String ?? "Không rõ"
                    let role = data["role"] as? String ?? "user"
                    return UserApp(id: doc.documentID, tenDangNhap: ten, role: role)
                }
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UserCell")
        let user = users[indexPath.row]
        cell.textLabel?.text = "👤 " + user.tenDangNhap
        cell.detailTextLabel?.text = "Phân quyền: \(user.role.uppercased())"
        
        if user.role == "admin" {
            cell.detailTextLabel?.textColor = UIColor(hex: "#FF6600")
        } else {
            cell.detailTextLabel?.textColor = .darkGray
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let user = users[indexPath.row]
<<<<<<< HEAD
=======
            // Chặn tính năng Xoá Admin
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
            if user.role != "admin" {
                let db = Firestore.firestore()
                db.collection("Users").document(user.id).delete { [weak self] error in
                    if error == nil {
                        self?.users.remove(at: indexPath.row)
                        self?.tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            } else {
                let alert = UIAlertController(title: "Hạn chế", message: "Không thể xoá tài khoản Quản trị viên (Admin).", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}
