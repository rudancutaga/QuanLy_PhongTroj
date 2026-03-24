import UIKit
import FirebaseFirestore

class AdminPhongVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - IBOutlet (kết nối từ Storyboard)
    @IBOutlet weak var tableView: UITableView!
    
    private var rooms: [PhongTro] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Quản lý Phòng"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RoomCell")
        
        loadRooms()
    }
    
    private func loadRooms() {
        RoomService.shared.fetchRooms(loaiPhong: "Tất cả") { [weak self] fetchedRooms, error in
            if let fetchedRooms = fetchedRooms {
                self?.rooms = fetchedRooms
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RoomCell")
        let room = rooms[indexPath.row]
        cell.textLabel?.text = room.tieuDe
        cell.detailTextLabel?.text = "Mã QL: \(room.id ?? "Unknown")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let room = rooms[indexPath.row]
            if let docId = room.id {
                let db = Firestore.firestore()
                db.collection("rooms").document(docId).delete { [weak self] error in
                    if error == nil {
                        self?.rooms.remove(at: indexPath.row)
                        self?.tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
}
