import UIKit
import FirebaseFirestore
import FirebaseAuth

class YeuThichVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - IBOutlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Data
    private var savedRooms: [PhongTro] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadSavedRooms()
    }
    
    // MARK: - UI Configuration
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PhongCell", bundle: nil), forCellReuseIdentifier: "PhongCell")
    }
    
    // MARK: - Data Fetching
    private func loadSavedRooms() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showEmptyState()
            return
        }
        
        activityIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = true
        
        let db = Firestore.firestore()
        db.collection("Users").document(userId).collection("savedRooms").getDocuments { [weak self] snapshot, _ in
            guard let self = self else { return }
            
            guard let docs = snapshot?.documents, !docs.isEmpty else {
                self.savedRooms = []
                self.showEmptyState()
                return
            }
            
            let roomIds = docs.map { $0.documentID }
            let idsToFetch = Array(roomIds.prefix(10))
            
            db.collection("rooms").whereField(FieldPath.documentID(), in: idsToFetch).getDocuments { snaps, error in
                self.activityIndicator.stopAnimating()
                
                if let roomDocs = snaps?.documents, !roomDocs.isEmpty {
                    self.savedRooms = roomDocs.compactMap { doc -> PhongTro? in
                        var p = try? doc.data(as: PhongTro.self)
                        p?.id = doc.documentID
                        return p
                    }
                    
                    if self.savedRooms.isEmpty {
                        self.showEmptyState()
                    } else {
                        self.tableView.isHidden = false
                        self.emptyStateView.isHidden = true
                        self.tableView.reloadData()
                    }
                } else {
                    self.savedRooms = []
                    self.showEmptyState()
                }
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
        return savedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhongCell", for: indexPath) as? PhongCell else {
            return UITableViewCell()
        }
        cell.configure(with: savedRooms[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ChiTietPhongVC") as? ChiTietPhongVC {
            vc.phong = savedRooms[indexPath.row]
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}
