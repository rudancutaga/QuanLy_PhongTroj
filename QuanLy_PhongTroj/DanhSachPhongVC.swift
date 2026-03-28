import UIKit

// MARK: - Cell cho phòng (dùng XIB PhongCell.xib)
class PhongCell: UITableViewCell {
    static let reuseID = "PhongCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var imgPlaceholder: UIView!
    @IBOutlet weak var iconImgView: UIImageView!
    @IBOutlet weak var heartImgView: UIImageView!
    @IBOutlet weak var lblTen: UILabel!
    @IBOutlet weak var lblGia: UILabel!
    @IBOutlet weak var lblThang: UILabel!
    @IBOutlet weak var lblDiaChi: UILabel!
    @IBOutlet weak var lblDienTich: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    func configure(with phong: PhongTro) {
        lblTen.text = phong.tieuDe
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        lblGia.text = (formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫").replacingOccurrences(of: "₫", with: "đ")
        
        lblDiaChi.text = "📍 \(phong.diaChi)"
        lblDienTich.text = "📐 \(Int(phong.dienTich)) m²  •  \(phong.tienIch.count) tiện ích"

        let color: UIColor
        switch phong.loaiPhong {
        case "Phòng đơn":
            color = UIColor(hex: "#FF6600")
            iconImgView.image = UIImage(systemName: "person.fill")
        case "Studio":
            color = UIColor(hex: "#5856D6")
            iconImgView.image = UIImage(systemName: "building.2")
        case "Phòng đôi":
            color = UIColor(hex: "#34C759")
            iconImgView.image = UIImage(systemName: "person.2.fill")
        case "Gác lửng":
            color = UIColor(hex: "#FF2D55")
            iconImgView.image = UIImage(systemName: "building")
        default:
            color = .systemGray3
            iconImgView.image = UIImage(systemName: "house.fill")
        }
        imgPlaceholder.backgroundColor = color.withAlphaComponent(0.15)
        iconImgView.tintColor = color
    }
}

// MARK: - DanhSachPhongVC (UITableViewController – dùng storyboard)
class DanhSachPhongVC: UITableViewController {

    // Set bởi HomeVC trong prepare(for:sender:)
    var loaiPhong: String = "Tất cả"
    var searchQuery: String?

    private var danhSachPhong: [PhongTro] = []
    private var didTriggerSeed = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        filterAndSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func filterAndSetup() {
        title = (loaiPhong == "Tất cả") ? "Tất cả phòng" : loaiPhong

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: "#FF6600")

        tableView.backgroundColor = UIColor(red: 0.976, green: 0.976, blue: 0.984, alpha: 1)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 280
        
        // Đăng ký XIB thay vì code thuần
        let nib = UINib(nibName: "PhongCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PhongCell.reuseID)

        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 36))
        header.backgroundColor = .clear
        let lbl = UILabel(frame: CGRect(x: 20, y: 8, width: 300, height: 20))
        lbl.text = "Đang tải dữ liệu Cloud..."
        lbl.tag = 999
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        header.addSubview(lbl)
        tableView.tableHeaderView = header
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortTapped))
        navigationItem.rightBarButtonItem = sortButton
        
        loadDataFromCloud()
    }
    
    @objc private func sortTapped() {
        let alert = UIAlertController(title: "Sắp xếp", message: "Chọn tiêu chí sắp xếp", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Giá: Thấp đến Cao", style: .default, handler: { _ in
            self.danhSachPhong.sort { $0.giaThue < $1.giaThue }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Giá: Cao đến Thấp", style: .default, handler: { _ in
            self.danhSachPhong.sort { $0.giaThue > $1.giaThue }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Diện tích: Nhỏ đến Lớn", style: .default, handler: { _ in
            self.danhSachPhong.sort { $0.dienTich < $1.dienTich }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Diện tích: Lớn đến Nhỏ", style: .default, handler: { _ in
            self.danhSachPhong.sort { $0.dienTich > $1.dienTich }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }

    private func loadDataFromCloud() {
        RoomService.shared.fetchRooms(loaiPhong: loaiPhong) { [weak self] rooms, error in
            guard let self = self else { return }
            if let arr = rooms {
                if arr.isEmpty, self.searchQuery == nil, !self.didTriggerSeed {
                    self.didTriggerSeed = true
                    RoomService.shared.ensureSampleDataIfNeeded { _ in
                        self.loadDataFromCloud()
                    }
                    return
                }

                if let query = self.searchQuery, !query.isEmpty {
                    self.danhSachPhong = arr.filter {
                        $0.tieuDe.lowercased().contains(query) ||
                        $0.diaChi.lowercased().contains(query) ||
                        $0.loaiPhong.lowercased().contains(query)
                    }
                    self.title = "Tìm kiếm: \(query)"
                } else {
                    self.danhSachPhong = arr
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let lbl = self.tableView.tableHeaderView?.viewWithTag(999) as? UILabel
                lbl?.text = "\(self.danhSachPhong.count) phòng hiện có"
            }
        }
    }

    // MARK: - TableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return danhSachPhong.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhongCell.reuseID, for: indexPath) as! PhongCell
        cell.configure(with: danhSachPhong[indexPath.row])
        return cell
    }

    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let phong = danhSachPhong[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChiTietPhongVC") as! ChiTietPhongVC
        vc.phong = phong
        navigationController?.pushViewController(vc, animated: true)
    }
}
