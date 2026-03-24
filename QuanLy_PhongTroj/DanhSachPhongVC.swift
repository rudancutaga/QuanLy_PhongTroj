<<<<<<< HEAD
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
=======
//
//  DanhSachPhongVC.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 19/3/26.
//

import UIKit

// Đã xoá PhongModel. Sử dụng Struct PhongTro kết nối Firebase Firestore.

// MARK: - Cell cho phòng
class PhongCell: UITableViewCell {
    static let reuseID = "PhongCell"

    private let cardView      = UIView()
    private let imgPlaceholder = UIView()
    private let iconImgView   = UIImageView()
    private let lblTen        = UILabel()
    private let lblGia        = UILabel()
    private let lblThang      = UILabel()
    private let lblDiaChi     = UILabel()
    private let lblDienTich   = UILabel()
    private let heartImgView  = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with phong: PhongTro) {
        lblTen.text      = phong.tieuDe
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
<<<<<<< HEAD
        lblGia.text = (formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫").replacingOccurrences(of: "₫", with: "đ")
        
        lblDiaChi.text = "📍 \(phong.diaChi)"
=======
        lblGia.text      = (formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫").replacingOccurrences(of: "₫", with: "đ")
        
        lblDiaChi.text   = "📍 \(phong.diaChi)"
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
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
<<<<<<< HEAD
=======

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle  = .none

        // Card
        cardView.backgroundColor    = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius  = 8
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Image area
        imgPlaceholder.layer.cornerRadius = 12
        imgPlaceholder.clipsToBounds      = true
        imgPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(imgPlaceholder)

        // Room icon (large centered)
        iconImgView.contentMode = .scaleAspectFit
        iconImgView.translatesAutoresizingMaskIntoConstraints = false
        imgPlaceholder.addSubview(iconImgView)

        // Heart
        heartImgView.image       = UIImage(systemName: "heart")
        heartImgView.tintColor   = UIColor(hex: "#FF6600")
        heartImgView.contentMode = .scaleAspectFit
        heartImgView.translatesAutoresizingMaskIntoConstraints = false
        imgPlaceholder.addSubview(heartImgView)

        // Labels
        lblTen.font          = UIFont.boldSystemFont(ofSize: 16)
        lblTen.numberOfLines = 2
        lblTen.translatesAutoresizingMaskIntoConstraints = false

        lblGia.font      = UIFont.boldSystemFont(ofSize: 15)
        lblGia.textColor = UIColor(hex: "#FF6600")
        lblGia.translatesAutoresizingMaskIntoConstraints = false

        lblThang.text      = "/tháng"
        lblThang.font      = UIFont.systemFont(ofSize: 12)
        lblThang.textColor = .secondaryLabel
        lblThang.translatesAutoresizingMaskIntoConstraints = false

        lblDiaChi.font          = UIFont.systemFont(ofSize: 13)
        lblDiaChi.textColor     = .secondaryLabel
        lblDiaChi.numberOfLines = 2
        lblDiaChi.translatesAutoresizingMaskIntoConstraints = false

        lblDienTich.font      = UIFont.systemFont(ofSize: 12)
        lblDienTich.textColor = .secondaryLabel
        lblDienTich.translatesAutoresizingMaskIntoConstraints = false

        [lblTen, lblGia, lblThang, lblDiaChi, lblDienTich].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            imgPlaceholder.topAnchor.constraint(equalTo: cardView.topAnchor),
            imgPlaceholder.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imgPlaceholder.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imgPlaceholder.heightAnchor.constraint(equalToConstant: 140),

            iconImgView.centerXAnchor.constraint(equalTo: imgPlaceholder.centerXAnchor),
            iconImgView.centerYAnchor.constraint(equalTo: imgPlaceholder.centerYAnchor),
            iconImgView.widthAnchor.constraint(equalToConstant: 52),
            iconImgView.heightAnchor.constraint(equalToConstant: 52),

            heartImgView.topAnchor.constraint(equalTo: imgPlaceholder.topAnchor, constant: 12),
            heartImgView.trailingAnchor.constraint(equalTo: imgPlaceholder.trailingAnchor, constant: -16),
            heartImgView.widthAnchor.constraint(equalToConstant: 22),
            heartImgView.heightAnchor.constraint(equalToConstant: 22),

            lblTen.topAnchor.constraint(equalTo: imgPlaceholder.bottomAnchor, constant: 12),
            lblTen.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            lblTen.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            lblGia.topAnchor.constraint(equalTo: lblTen.bottomAnchor, constant: 6),
            lblGia.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            lblThang.lastBaselineAnchor.constraint(equalTo: lblGia.lastBaselineAnchor),
            lblThang.leadingAnchor.constraint(equalTo: lblGia.trailingAnchor, constant: 4),

            lblDiaChi.topAnchor.constraint(equalTo: lblGia.bottomAnchor, constant: 6),
            lblDiaChi.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            lblDiaChi.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            lblDienTich.topAnchor.constraint(equalTo: lblDiaChi.bottomAnchor, constant: 4),
            lblDienTich.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            lblDienTich.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            lblDienTich.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
}

// MARK: - DanhSachPhongVC (UITableViewController – dùng storyboard)
class DanhSachPhongVC: UITableViewController {

    // Set bởi HomeVC trong prepare(for:sender:)
    var loaiPhong: String = "Tất cả"
<<<<<<< HEAD
    var searchQuery: String?
=======
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7

    private var danhSachPhong: [PhongTro] = []

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
<<<<<<< HEAD
        title = (loaiPhong == "Tất cả") ? "Tất cả phòng" : loaiPhong

=======

        // Navigation
        title = (loaiPhong == "Tất cả") ? "Tất cả phòng" : loaiPhong

        // Appearance
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
<<<<<<< HEAD
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
=======
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: "#FF6600")

        // TableView
        tableView.backgroundColor  = UIColor(red: 0.976, green: 0.976, blue: 0.984, alpha: 1)
        tableView.separatorStyle   = .none
        tableView.rowHeight        = UITableView.automaticDimension
        tableView.estimatedRowHeight = 280
        tableView.register(PhongCell.self, forCellReuseIdentifier: PhongCell.reuseID)

        // Header đếm số phòng
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 36))
        header.backgroundColor = .clear
        let lbl = UILabel(frame: CGRect(x: 20, y: 8, width: 300, height: 20))
        lbl.text      = "Đang tải dữ liệu Cloud..."
        lbl.tag       = 999
        lbl.font      = UIFont.systemFont(ofSize: 14)
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
        lbl.textColor = .secondaryLabel
        header.addSubview(lbl)
        tableView.tableHeaderView = header
        
<<<<<<< HEAD
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

=======
        loadDataFromCloud()
    }
    
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
    private func loadDataFromCloud() {
        RoomService.shared.fetchRooms(loaiPhong: loaiPhong) { [weak self] rooms, error in
            guard let self = self else { return }
            if let arr = rooms {
<<<<<<< HEAD
                if let query = self.searchQuery, !query.isEmpty {
                    self.danhSachPhong = arr.filter { $0.tieuDe.lowercased().contains(query) || $0.diaChi.lowercased().contains(query) }
                    self.title = "Tìm kiếm: \(query)"
                } else {
                    self.danhSachPhong = arr
                }
=======
                self.danhSachPhong = arr
>>>>>>> a78f26ec288c437ce49f2d46ec28adfe56c268a7
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
