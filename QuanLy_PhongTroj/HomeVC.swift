//
//  HomeVC.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit

class HomeVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    // Các ô danh mục (giờ là UIButton)
    @IBOutlet weak var cat1Btn: UIButton!   // Phòng đơn
    @IBOutlet weak var cat2Btn: UIButton!   // Studio
    @IBOutlet weak var cat3Btn: UIButton!   // Phòng đôi
    @IBOutlet weak var cat4Btn: UIButton!   // Gác lửng

    // Nút "Xem tất cả"
    @IBOutlet weak var xemTatCaButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!

    // Tag mapping: Cat1-Btn=0, Cat2-Btn=1, Cat3-Btn=2, Cat4-Btn=3
    private let categories = ["Phòng đơn", "Studio", "Phòng đôi", "Gác lửng"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cực kỳ cẩn thận: Kiểm tra an toàn trước khi force gán thuộc tính.
        guard let sv = scrollView, let b1 = cat1Btn, let b2 = cat2Btn, let b3 = cat3Btn, let b4 = cat4Btn else {
            print("❌ Lỗi CRASH: Một trong số IBOutlets bị nil trong HomeVC. viewDidLoad chạy nhưng Storyboard chưa map xong!")
            return
        }
        
        searchTextField?.delegate = self
        searchTextField?.returnKeyType = .search
        
        // 1. Force bật Interaction cho toàn bộ view cha để chắc chắn không ai cản trở
        sv.isUserInteractionEnabled = true
        sv.delaysContentTouches = false
        
        // Đảm bảo StackView và Cat-Scroll (superview của nút) đều tương tác được
        b1.superview?.isUserInteractionEnabled = true
        b1.superview?.superview?.isUserInteractionEnabled = true
        if let catScroll = b1.superview?.superview as? UIScrollView {
            catScroll.delaysContentTouches = false
        }
        
        // 2. Gán lại cứng Target-Action để đè lên Storyboard nếu bị lỗi liên kết
        let buttons = [b1, b2, b3, b4]
        for btn in buttons {
            btn.isUserInteractionEnabled = true
            btn.isExclusiveTouch = true
            // Xoá action cũ phòng rác
            btn.removeTarget(nil, action: nil, for: .allEvents)
            // Cài đặt action mới chắc chắn
            btn.addTarget(self, action: #selector(catBtnTapped(_:)), for: .touchUpInside)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - IBAction từ storyboard (Cat1-Btn..Cat4-Btn đều dùng chung action này)
    @IBAction func catBtnTapped(_ sender: UIButton) {
        // Lấy title của thẻ cấu hình mới nhất của iOS 15+
        var tenLoai = ""
        
        if let configTitle = sender.configuration?.title {
            tenLoai = configTitle
        } else if let attrTitle = sender.configuration?.attributedTitle?.description {
            tenLoai = attrTitle
        } else if let normalTitle = sender.title(for: .normal) {
            tenLoai = normalTitle
        }
        
        // Nếu không lấy được bằng các cách trên, thử lấy theo UIButton refer:
        if tenLoai.isEmpty {
            if sender == cat1Btn { tenLoai = "Phòng đơn" }
            else if sender == cat2Btn { tenLoai = "Studio" }
            else if sender == cat3Btn { tenLoai = "Phòng đôi" }
            else if sender == cat4Btn { tenLoai = "Gác lửng" }
        }
        
        if tenLoai.isEmpty { return }

        // Hiệu ứng nhấn nhẹ
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                sender.transform = .identity
            }
            
            // Push trực tiếp thay vì phụ thuộc Segue Storyboard
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DanhSachPhongVC") as? DanhSachPhongVC {
                vc.loaiPhong = tenLoai
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    // MARK: - Nút Xem tất cả (kết nối từ storyboard)
    @IBAction func xemTatCaTapped(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DanhSachPhongVC") as? DanhSachPhongVC {
            vc.loaiPhong = "Tất cả"
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Prepare segue
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
