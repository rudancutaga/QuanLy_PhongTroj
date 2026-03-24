import UIKit
import FirebaseAuth
import FirebaseFirestore

class TinNhanVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - IBOutlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateView: UIView!
    
    // MARK: - Data
    private var conversations: [Any] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadMessages()
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        // Register cell if needed
    }
    
    // MARK: - Load Data
    private func loadMessages() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showEmptyState()
            return
        }
        
        activityIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = true
        
        let db = Firestore.firestore()
        db.collection("Conversations").whereField("participants", arrayContains: userId).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            if let docs = snapshot?.documents, !docs.isEmpty {
                self.conversations = docs
                self.tableView.isHidden = false
                self.tableView.reloadData()
            } else {
                self.conversations = []
                self.showEmptyState()
            }
        }
    }
    
    private func showEmptyState() {
        activityIndicator.stopAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = false
    }
    
    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        if let doc = conversations[indexPath.row] as? QueryDocumentSnapshot {
            let data = doc.data()
            let lastMsg = data["lastMessage"] as? String ?? "Bấm để xem chi tiết"
            cell.textLabel?.text = "Hội thoại: \(doc.documentID)"
            cell.detailTextLabel?.text = lastMsg
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let doc = conversations[indexPath.row] as! QueryDocumentSnapshot
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            chatVC.conversationId = doc.documentID
            // Lấy otherUserId từ participants
            if let participants = doc.data()["participants"] as? [String] {
                let currentUid = Auth.auth().currentUser?.uid ?? ""
                chatVC.otherUserId = participants.first(where: { $0 != currentUid })
            }
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}
