import UIKit
import Foundation

class ChiTietPhongVC: UIViewController {
    
    var phong: PhongTro!
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblTieuDe: UILabel!
    @IBOutlet weak var lblGia: UILabel!
    @IBOutlet weak var lblDiaChi: UILabel!
    @IBOutlet weak var lblDienTich: UILabel!
    @IBOutlet weak var lblTienIch: UILabel!
    @IBOutlet weak var lblMoTa: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chi tiết phòng"
        
        if phong != nil {
            bindData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = UIColor(hex: "#FF6600")
    }
    
    private func bindData() {
        lblTieuDe.text = phong.tieuDe
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        let formattedGia = formatter.string(from: NSNumber(value: phong.giaThue)) ?? "\(phong.giaThue) ₫"
        lblGia.text = formattedGia.replacingOccurrences(of: "₫", with: "đ") + "/tháng"
        
        lblDiaChi.text = "📍 \(phong.diaChi)"
        lblDienTich.text = "📐 Diện tích: \(Int(phong.dienTich)) m²"
        
        if phong.tienIch.isEmpty {
            lblTienIch.text = "(Chưa cập nhật tiện ích)"
        } else {
            lblTienIch.text = phong.tienIch.map { "✔️ " + $0 }.joined(separator: "\n")
        }
        
        lblMoTa.text = phong.moTa.isEmpty ? "(Chưa có mô tả chi tiết)" : phong.moTa
        
        if let urlStr = phong.hinhAnh.first, let url = URL(string: urlStr) {
            loadImage(url: url)
        }
    }
    
    @IBAction func btnLienHeTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Liên Hệ", message: "Số điện thoại chủ nhà đang được ẩn.\nVui lòng gọi: 1900 xxxx", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Gọi ngay", style: .default, handler: { _ in
            if let url = URL(string: "tel://19000000") {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        present(alert, animated: true)
    }
    
    private func loadImage(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imgView.image = image
                }
            }
        }.resume()
    }
}
