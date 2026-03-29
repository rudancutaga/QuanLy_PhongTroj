//
//  HomeVC.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    // Các ô danh mục (giờ là UIButton)
    @IBOutlet weak var cat1Btn: UIButton!   // Phòng đơn
    @IBOutlet weak var cat2Btn: UIButton!   // Studio
    @IBOutlet weak var cat3Btn: UIButton!   // Phòng đôi
    @IBOutlet weak var cat4Btn: UIButton!   // Gác lửng

    @IBOutlet weak var xemTatCaButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet private weak var searchContainerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var featuredCardView: UIView!
    @IBOutlet private weak var featuredImageContainerView: UIView!
    @IBOutlet private weak var featuredHeartImageView: UIImageView!
    @IBOutlet private weak var featuredTitleLabel: UILabel!
    @IBOutlet private weak var featuredPriceLabel: UILabel!
    @IBOutlet private weak var featuredPriceSuffixLabel: UILabel!

    private let db = Firestore.firestore()
    private let categories = ["Phòng đơn", "Studio", "Phòng đôi", "Gác lửng"]
    private let defaultLocationText = "Quận 1, TP. Hồ Chí Minh"
    private let featuredImageView = UIImageView()
    private var cityTrailingConstraint: NSLayoutConstraint?
    private var featuredRoom: PhongTro?
    private var didTriggerFeaturedSeed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sv = scrollView, let b1 = cat1Btn, let b2 = cat2Btn, let b3 = cat3Btn, let b4 = cat4Btn else {
            print("❌ Lỗi CRASH: Một trong số IBOutlets bị nil trong HomeVC. viewDidLoad chạy nhưng Storyboard chưa map xong!")
            return
        }

        setupSearchUI()
        setupCategoryButtons(
            scrollView: sv,
            buttons: [b1, b2, b3, b4]
        )
        setupHeader()
        setupFeaturedCard()
        loadHeaderProfile()
        loadFeaturedRoom()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadHeaderProfile()
        loadFeaturedRoom()
    }

    private func setupSearchUI() {
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.borderStyle = .none
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Tìm kiếm phòng...",
            attributes: [.foregroundColor: UIColor.systemGray3]
        )

        searchContainerView.layer.cornerRadius = 18
        searchContainerView.layer.cornerCurve = .continuous
        searchContainerView.layer.borderWidth = 1
        searchContainerView.layer.borderColor = UIColor.systemGray6.cgColor
        searchContainerView.layer.shadowColor = UIColor.black.cgColor
        searchContainerView.layer.shadowOpacity = 0.05
        searchContainerView.layer.shadowRadius = 12
        searchContainerView.layer.shadowOffset = CGSize(width: 0, height: 6)

        let tap = UITapGestureRecognizer(target: self, action: #selector(focusSearch))
        tap.cancelsTouchesInView = false
        searchContainerView.addGestureRecognizer(tap)

        xemTatCaButton.setTitleColor(UIColor(hex: "#FF6600"), for: .normal)
        xemTatCaButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }

    private func setupCategoryButtons(scrollView: UIScrollView, buttons: [UIButton]) {
        scrollView.isUserInteractionEnabled = true
        scrollView.delaysContentTouches = false

        buttons.forEach { button in
            button.isUserInteractionEnabled = true
            button.isExclusiveTouch = true
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: #selector(catBtnTapped(_:)), for: .touchUpInside)
        }

        cat1Btn.superview?.isUserInteractionEnabled = true
        cat1Btn.superview?.superview?.isUserInteractionEnabled = true
        if let catScroll = cat1Btn.superview?.superview as? UIScrollView {
            catScroll.delaysContentTouches = false
        }
    }

    private func setupHeader() {
        cityLabel.text = defaultLocationText
        cityLabel.numberOfLines = 1
        cityLabel.lineBreakMode = .byTruncatingTail

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemGray3
        avatarImageView.backgroundColor = .white

        if avatarImageView.gestureRecognizers?.isEmpty ?? true {
            let tap = UITapGestureRecognizer(target: self, action: #selector(openAccountTab))
            avatarImageView.addGestureRecognizer(tap)
        }

        cityTrailingConstraint?.isActive = false
        cityTrailingConstraint = cityLabel.trailingAnchor.constraint(lessThanOrEqualTo: avatarImageView.leadingAnchor, constant: -16)
        cityTrailingConstraint?.isActive = true
    }

    private func setupFeaturedCard() {
        featuredCardView.backgroundColor = .white
        featuredCardView.layer.cornerRadius = 22
        featuredCardView.layer.cornerCurve = .continuous
        featuredCardView.layer.shadowColor = UIColor.black.cgColor
        featuredCardView.layer.shadowOpacity = 0.08
        featuredCardView.layer.shadowRadius = 14
        featuredCardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        featuredImageContainerView.layer.cornerRadius = 22
        featuredImageContainerView.layer.cornerCurve = .continuous
        featuredImageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        featuredImageContainerView.clipsToBounds = true

        if featuredImageView.superview == nil {
            featuredImageView.translatesAutoresizingMaskIntoConstraints = false
            featuredImageView.contentMode = .scaleAspectFill
            featuredImageView.clipsToBounds = true
            featuredImageContainerView.insertSubview(featuredImageView, at: 0)

            NSLayoutConstraint.activate([
                featuredImageView.topAnchor.constraint(equalTo: featuredImageContainerView.topAnchor),
                featuredImageView.leadingAnchor.constraint(equalTo: featuredImageContainerView.leadingAnchor),
                featuredImageView.trailingAnchor.constraint(equalTo: featuredImageContainerView.trailingAnchor),
                featuredImageView.bottomAnchor.constraint(equalTo: featuredImageContainerView.bottomAnchor)
            ])
        }

        featuredHeartImageView.image = UIImage(systemName: "heart")
        featuredHeartImageView.tintColor = UIColor(hex: "#FF6600")
        featuredPriceSuffixLabel.textColor = .systemGray

        if featuredCardView.gestureRecognizers?.isEmpty ?? true {
            let tap = UITapGestureRecognizer(target: self, action: #selector(openFeaturedRoom))
            featuredCardView.addGestureRecognizer(tap)
        }

        configureFeaturedPlaceholder(for: nil)
    }

    private func loadHeaderProfile() {
        cityLabel.text = defaultLocationText

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.tintColor = .systemGray3
            return
        }

        db.collection("Users").document(currentUserId).getDocument { [weak self] document, _ in
            guard let self = self else { return }
            let data = document?.data()

            if let customLocation = (data?["diaChi"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !customLocation.isEmpty {
                DispatchQueue.main.async {
                    self.cityLabel.text = customLocation
                }
            }

            if let avatarURL = data?["avatarUrl"] as? String,
               let url = URL(string: avatarURL) {
                self.loadImage(from: url, into: self.avatarImageView)
            } else {
                DispatchQueue.main.async {
                    self.avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
                    self.avatarImageView.tintColor = .systemGray3
                }
            }
        }
    }

    private func loadFeaturedRoom() {
        RoomService.shared.fetchRooms(loaiPhong: "Tất cả") { [weak self] rooms, _ in
            guard let self = self else { return }

            if let room = rooms?.first {
                DispatchQueue.main.async {
                    self.updateFeaturedCard(with: room)
                }
                return
            }

            guard !self.didTriggerFeaturedSeed else { return }
            self.didTriggerFeaturedSeed = true
            RoomService.shared.ensureSampleDataIfNeeded { [weak self] _ in
                self?.loadFeaturedRoom()
            }
        }
    }

    private func updateFeaturedCard(with room: PhongTro) {
        featuredRoom = room
        featuredTitleLabel.text = room.tieuDe
        featuredPriceLabel.text = formatPrice(room.giaThue)
        featuredPriceSuffixLabel.text = room.trangThai == "Đã thuê" ? "/đã thuê" : "/tháng"
        configureFeaturedPlaceholder(for: room.loaiPhong)
        featuredImageView.image = nil

        guard let imageURLString = room.hinhAnh.first,
              let url = URL(string: imageURLString) else {
            featuredImageView.image = nil
            return
        }

        loadImage(from: url, into: featuredImageView)
    }

    private func configureFeaturedPlaceholder(for roomType: String?) {
        let color: UIColor

        switch roomType {
        case "Phòng đơn":
            color = UIColor(hex: "#FFE9D6")
        case "Studio":
            color = UIColor(hex: "#ECEBFF")
        case "Phòng đôi":
            color = UIColor(hex: "#E6F7EE")
        case "Gác lửng":
            color = UIColor(hex: "#FFE7EF")
        default:
            color = UIColor.systemGray5
        }

        featuredImageContainerView.backgroundColor = color
        if featuredImageView.image == nil {
            featuredImageView.backgroundColor = color
        }
    }

    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        return (formatter.string(from: NSNumber(value: price)) ?? "\(price) ₫")
            .replacingOccurrences(of: "₫", with: "đ")
    }

    @objc private func focusSearch() {
        searchTextField.becomeFirstResponder()
    }

    @objc private func openAccountTab() {
        tabBarController?.selectedIndex = 3
    }

    @objc private func openFeaturedRoom() {
        guard let room = featuredRoom else {
            xemTatCaTapped(xemTatCaButton)
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "ChiTietPhongVC") as? ChiTietPhongVC else {
            return
        }

        detailVC.phong = room
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - IBAction từ storyboard (Cat1-Btn..Cat4-Btn đều dùng chung action này)
    @IBAction func catBtnTapped(_ sender: UIButton) {
        var tenLoai = ""

        if let configTitle = sender.configuration?.title {
            tenLoai = configTitle
        } else if let attrTitle = sender.configuration?.attributedTitle?.description {
            tenLoai = attrTitle
        } else if let normalTitle = sender.title(for: .normal) {
            tenLoai = normalTitle
        }

        if tenLoai.isEmpty {
            if sender == cat1Btn { tenLoai = categories[0] }
            else if sender == cat2Btn { tenLoai = categories[1] }
            else if sender == cat3Btn { tenLoai = categories[2] }
            else if sender == cat4Btn { tenLoai = categories[3] }
        }

        guard !tenLoai.isEmpty else { return }

        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                sender.transform = .identity
            }

            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DanhSachPhongVC") as? DanhSachPhongVC {
                vc.loaiPhong = tenLoai
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    @IBAction func xemTatCaTapped(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DanhSachPhongVC") as? DanhSachPhongVC {
            vc.loaiPhong = "Tất cả"
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDanhSachPhong",
           let vc = segue.destination as? DanhSachPhongVC,
           let loai = sender as? String {
            vc.loaiPhong = loai
        }
    }
}

extension HomeVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let kw = textField.text, !kw.trimmingCharacters(in: .whitespaces).isEmpty else { return true }

        if let vc = storyboard?.instantiateViewController(withIdentifier: "DanhSachPhongVC") as? DanhSachPhongVC {
            vc.loaiPhong = "Tất cả"
            vc.searchQuery = kw.trimmingCharacters(in: .whitespaces).lowercased()
            navigationController?.pushViewController(vc, animated: true)
        }
        return true
    }
}
