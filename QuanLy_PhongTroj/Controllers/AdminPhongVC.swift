import UIKit
import FirebaseAuth
import FirebaseFirestore

private struct RoomRenterInfo {
    let userId: String
    let displayName: String
    let username: String
    let phoneNumber: String?
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

class AdminPhongVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateView: UIStackView!
    @IBOutlet private weak var emptyStateLabel: UILabel!
    @IBOutlet private weak var seedButton: UIButton!

    private var rooms: [PhongTro] = []
    private var renterInfoByUserId: [String: RoomRenterInfo] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        loadRooms()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadRooms()
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background
        seedButton.setTitleColor(AdminPalette.accent, for: .normal)
        seedButton.backgroundColor = AdminPalette.accentSoft
        seedButton.layer.cornerRadius = 20
        seedButton.layer.cornerCurve = .continuous
        seedButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        emptyStateLabel.text = "Chưa có bài đăng nào.\nBạn có thể nạp dữ liệu mẫu hoặc tạo phòng mới."
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.estimatedRowHeight = 280
        tableView.rowHeight = UITableView.automaticDimension

        let nib = UINib(nibName: "PhongCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PhongCell.reuseID)
    }

    @IBAction private func addRoomTapped(_ sender: UIButton) {
        presentEditor(for: nil)
    }

    @IBAction private func seedSampleData(_ sender: UIButton) {
        RoomService.shared.seedSampleData { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(title: "Không thể seed dữ liệu", message: error.localizedDescription)
                    return
                }

                self.loadRooms()
            }
        }
    }

    private func presentEditor(for room: PhongTro?) {
        let editor = RoomFormViewController(room: room)
        editor.hidesBottomBarWhenPushed = true
        editor.onSaved = { [weak self] in
            self?.loadRooms()
        }

        if let navigationController = navigationController {
            navigationController.pushViewController(editor, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: editor)
            navigationController.isNavigationBarHidden = true
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true)
        }
    }

    private func showRoomActions(for room: PhongTro) {
        var actions: [AdminSheetAction] = []

        if isRoomRented(room) {
            actions.append(AdminSheetAction(title: "Xem người thuê") { [weak self] in
                self?.presentRenterInfo(for: room)
            })
        }

        actions.append(contentsOf: [
            AdminSheetAction(title: "Xem chi tiết phòng") { [weak self] in
                self?.openRoomDetail(room)
            },
            AdminSheetAction(title: "Sửa bài đăng") { [weak self] in
                self?.presentEditor(for: room)
            },
            AdminSheetAction(
                title: "Xóa bài đăng này",
                titleColor: AdminPalette.destructive
            ) { [weak self] in
                self?.confirmDelete(room)
            }
        ])

        let sheet = AdminActionSheetController(
            title: "Quản lý bài đăng",
            subtitle: room.tieuDe,
            actions: actions
        )
        present(sheet, animated: true)
    }

    private func openRoomDetail(_ room: PhongTro) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "ChiTietPhongVC") as? ChiTietPhongVC else {
            return
        }
        detailVC.phong = room
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func confirmDelete(_ room: PhongTro) {
        let alert = UIAlertController(
            title: "Xóa bài đăng",
            message: "Bạn có chắc muốn xóa \"\(room.tieuDe)\" không?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            self?.deleteRoom(room)
        })
        present(alert, animated: true)
    }

    private func deleteRoom(_ room: PhongTro) {
        guard let docId = room.id else { return }

        RoomService.shared.deleteRoom(id: docId) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(title: "Không thể xóa phòng", message: error.localizedDescription)
                    return
                }

                self.rooms.removeAll { $0.id == docId }
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }

    private func loadRooms() {
        RoomService.shared.fetchRooms(loaiPhong: "Tất cả") { [weak self] fetchedRooms, _ in
            guard let self = self else { return }

            self.rooms = fetchedRooms ?? []
            self.loadRenterInfosIfNeeded()

            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }

    private func loadRenterInfosIfNeeded() {
        let renterIds = Set(
            rooms.compactMap { room -> String? in
                guard isRoomRented(room), let userId = room.nguoiThueId, !userId.isEmpty else { return nil }
                return userId
            }
        )

        guard !renterIds.isEmpty else {
            renterInfoByUserId = [:]
            return
        }

        let userIdChunks = Array(renterIds).chunked(into: 10)
        let group = DispatchGroup()
        var renterInfo: [String: RoomRenterInfo] = [:]

        for chunk in userIdChunks {
            group.enter()
            Firestore.firestore().collection("Users").whereField(FieldPath.documentID(), in: chunk).getDocuments { snapshot, _ in
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    let username = (data["tenDangNhap"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let fullName = (data["hoTen"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let phone = (data["soDienThoai"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

                    renterInfo[document.documentID] = RoomRenterInfo(
                        userId: document.documentID,
                        displayName: fullName?.isEmpty == false ? fullName! : (username?.isEmpty == false ? username! : "Người dùng"),
                        username: username?.isEmpty == false ? username! : "Không rõ",
                        phoneNumber: phone?.isEmpty == false ? phone : nil
                    )
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.renterInfoByUserId = renterInfo
            self?.tableView.reloadData()
        }
    }

    private func isRoomRented(_ room: PhongTro) -> Bool {
        room.trangThai?.trimmingCharacters(in: .whitespacesAndNewlines) == "Đã thuê"
    }

    private func presentRenterInfo(for room: PhongTro) {
        guard isRoomRented(room) else {
            showAlert(title: "Phòng chưa được thuê", message: "Hiện chưa có người thuê cho phòng này.")
            return
        }

        guard let renterId = room.nguoiThueId, !renterId.isEmpty else {
            showAlert(
                title: "Chưa có dữ liệu người thuê",
                message: "Phòng đã được đánh dấu là đã thuê nhưng chưa lưu người thuê cụ thể."
            )
            return
        }

        let renter = renterInfoByUserId[renterId]
        let rentedDateText = formatRentDate(room.ngayThue)
        var messageLines = [
            "Tên hiển thị: \(renter?.displayName ?? "Đang tải...")",
            "Tên đăng nhập: \(renter?.username ?? renterId)"
        ]

        if let phoneNumber = renter?.phoneNumber {
            messageLines.append("Số điện thoại: \(phoneNumber)")
        }

        if let rentedDateText {
            messageLines.append("Ngày thuê: \(rentedDateText)")
        }

        let alert = UIAlertController(
            title: "Người đang thuê phòng",
            message: messageLines.joined(separator: "\n"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func formatRentDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !rooms.isEmpty
        emptyStateLabel.text = rooms.isEmpty
            ? "Chưa có bài đăng nào.\nBạn có thể nạp dữ liệu mẫu hoặc tạo phòng mới."
            : nil
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PhongCell.reuseID, for: indexPath) as? PhongCell else {
            return UITableViewCell()
        }

        let room = rooms[indexPath.row]
        cell.configure(with: room)
        cell.heartImgView.image = UIImage(systemName: "heart")
        cell.heartImgView.tintColor = AdminPalette.accent
        cell.selectionStyle = .none

        if isRoomRented(room) {
            let renterName = room.nguoiThueId.flatMap { renterInfoByUserId[$0]?.displayName } ?? "Chưa xác định"
            cell.lblDienTich.numberOfLines = 2
            cell.lblDienTich.text = "📐 \(Int(room.dienTich)) m²  •  \(room.tienIch.count) tiện ích  •  Đã thuê\n👤 Người thuê: \(renterName)"
        } else {
            cell.lblDienTich.numberOfLines = 1
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showRoomActions(for: rooms[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Xóa") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            self.deleteRoom(self.rooms[indexPath.row])
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

final class RoomFormViewController: UIViewController {

    var onSaved: (() -> Void)?

    private let room: PhongTro?
    private let roomTypes = ["Phòng đơn", "Studio", "Phòng đôi", "Gác lửng"]

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var typeButtons: [UIButton] = []
    private var selectedRoomType = "Phòng đơn"

    private let tieuDeField = AdminInsetTextField()
    private let giaField = AdminInsetTextField()
    private let dienTichField = AdminInsetTextField()
    private let diaChiField = AdminInsetTextField()
    private let imageURLField = AdminInsetTextField()
    private let trangThaiField = AdminInsetTextField()
    private let tienIchField = AdminInsetTextField()
    private let moTaTextView = UITextView()

    init(room: PhongTro?) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
        selectedRoomType = room?.loaiPhong ?? "Phòng đơn"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        populateForm()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupLayout() {
        view.backgroundColor = AdminPalette.background

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = makeHeaderButton(
            title: "Hủy",
            titleColor: .label,
            backgroundColor: UIColor(white: 0.96, alpha: 1),
            action: #selector(closeTapped)
        )

        let saveButton = makeHeaderButton(
            title: room == nil ? "Lên bài" : "Lưu",
            titleColor: .white,
            backgroundColor: .systemBlue,
            action: #selector(saveTapped)
        )

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = room == nil ? "Đăng tin mới" : "Cập nhật bài đăng"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18

        view.addSubview(headerView)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        headerView.addSubview(cancelButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            cancelButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),

            saveButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            saveButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cancelButton.trailingAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            headerView.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])

        configure(field: tieuDeField, placeholder: "VD: Phòng trọ khép kín mới xây")
        configure(field: giaField, placeholder: "VD: 2500000", keyboardType: .numberPad)
        configure(field: dienTichField, placeholder: "VD: 20.0", keyboardType: .decimalPad)
        configure(field: diaChiField, placeholder: "VD: 123 Đường A, Quận B")
        configure(field: tienIchField, placeholder: "VD: Wifi, Điều hoà, Chỗ để xe")
        configure(field: imageURLField, placeholder: "Dán URL ảnh đại diện")
        configure(field: trangThaiField, placeholder: "VD: Đang rảnh / Đã thuê")

        moTaTextView.translatesAutoresizingMaskIntoConstraints = false
        moTaTextView.font = .systemFont(ofSize: 16)
        moTaTextView.backgroundColor = .white
        moTaTextView.layer.cornerRadius = 18
        moTaTextView.layer.cornerCurve = .continuous
        moTaTextView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        moTaTextView.heightAnchor.constraint(equalToConstant: 160).isActive = true

        let typeStack = UIStackView()
        typeStack.translatesAutoresizingMaskIntoConstraints = false
        typeStack.axis = .horizontal
        typeStack.spacing = 8
        typeStack.distribution = .fillEqually

        for (index, type) in roomTypes.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(type, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.layer.cornerRadius = 18
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: #selector(typeButtonTapped(_:)), for: .touchUpInside)
            typeButtons.append(button)
            typeStack.addArrangedSubview(button)
        }

        [
            makeSection(title: "TIÊU ĐỀ BÀI ĐĂNG", contentView: tieuDeField),
            makeSection(title: "LOẠI PHÒNG", contentView: typeStack),
            makeSection(title: "GIÁ THUÊ (VND)", contentView: giaField),
            makeSection(title: "DIỆN TÍCH (M2)", contentView: dienTichField),
            makeSection(title: "ĐỊA CHỈ CHI TIẾT", contentView: diaChiField),
            makeSection(title: "TÓM TẮT MÔ TẢ", contentView: moTaTextView),
            makeSection(title: "DANH SÁCH TIỆN ÍCH (NGĂN CÁCH DẤU PHẨY)", contentView: tienIchField),
            makeSection(title: "URL ẢNH ĐẠI DIỆN", contentView: imageURLField),
            makeSection(title: "TRẠNG THÁI", contentView: trangThaiField)
        ].forEach { stackView.addArrangedSubview($0) }

        updateTypeButtons()
    }

    private func makeHeaderButton(
        title: String,
        titleColor: UIColor,
        backgroundColor: UIColor,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 25
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeSection(title: String, contentView: UIView) -> UIView {
        let section = UIStackView()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.axis = .vertical
        section.spacing = 10

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel

        section.addArrangedSubview(label)
        section.addArrangedSubview(contentView)
        return section
    }

    private func configure(field: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = placeholder
        field.keyboardType = keyboardType
        field.font = .systemFont(ofSize: 16)
        field.backgroundColor = .white
        field.layer.cornerRadius = 18
        field.layer.cornerCurve = .continuous
        field.heightAnchor.constraint(equalToConstant: 54).isActive = true
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func closeTapped() {
        if let navigationController = navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func typeButtonTapped(_ sender: UIButton) {
        selectedRoomType = roomTypes[sender.tag]
        updateTypeButtons()
    }

    private func updateTypeButtons() {
        for (index, button) in typeButtons.enumerated() {
            let isSelected = roomTypes[index] == selectedRoomType
            button.setTitleColor(isSelected ? .label : AdminPalette.textSecondary, for: .normal)
            button.backgroundColor = isSelected ? .white : UIColor(white: 0.96, alpha: 1)
            button.layer.borderColor = isSelected ? UIColor.systemGray5.cgColor : UIColor.clear.cgColor
            button.layer.shadowOpacity = isSelected ? 0.06 : 0
            button.layer.shadowRadius = 10
            button.layer.shadowOffset = CGSize(width: 0, height: 5)
        }
    }

    private func populateForm() {
        guard let room else { return }

        tieuDeField.text = room.tieuDe
        giaField.text = String(Int(room.giaThue))
        dienTichField.text = String(room.dienTich)
        diaChiField.text = room.diaChi
        imageURLField.text = room.hinhAnh.first
        trangThaiField.text = room.trangThai ?? "Đang rảnh"
        tienIchField.text = room.tienIch.joined(separator: ", ")
        moTaTextView.text = room.moTa
        selectedRoomType = room.loaiPhong
        updateTypeButtons()
    }

    @objc private func saveTapped() {
        guard
            let tieuDe = tieuDeField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !tieuDe.isEmpty,
            let diaChi = diaChiField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !diaChi.isEmpty,
            let giaText = giaField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let gia = Double(giaText),
            let dienTichText = dienTichField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let dienTich = Double(dienTichText)
        else {
            showAlert(title: "Thiếu dữ liệu", message: "Vui lòng nhập đủ tiêu đề, giá thuê, diện tích và địa chỉ.")
            return
        }

        let tienIch = tienIchField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        let imageURL = imageURLField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let statusText = trangThaiField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trangThai = (statusText?.isEmpty == false) ? statusText! : "Đang rảnh"
        let preservedRenterId = trangThai == "Đã thuê" ? room?.nguoiThueId : nil
        let preservedRentDate = trangThai == "Đã thuê" ? room?.ngayThue : nil

        let roomToSave = PhongTro(
            id: room?.id,
            tieuDe: tieuDe,
            giaThue: gia,
            dienTich: dienTich,
            diaChi: diaChi,
            loaiPhong: selectedRoomType,
            hinhAnh: imageURL.isEmpty ? [] : [imageURL],
            moTa: moTaTextView.text.trimmingCharacters(in: .whitespacesAndNewlines),
            tienIch: tienIch,
            ngayDang: room?.ngayDang ?? Date(),
            idNguoiDang: room?.idNguoiDang ?? Auth.auth().currentUser?.uid ?? "admin-manual",
            trangThai: trangThai,
            nguoiThueId: preservedRenterId,
            ngayThue: preservedRentDate
        )

        navigationItem.rightBarButtonItem?.isEnabled = false

        RoomService.shared.saveRoom(roomToSave) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(title: "Không thể lưu phòng", message: error.localizedDescription)
                    return
                }

                self.onSaved?()

                if let navigationController = self.navigationController, navigationController.viewControllers.first != self {
                    navigationController.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class AdminInsetTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 14, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 14, dy: 0)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 14, dy: 0)
    }
}
