import Foundation
import FirebaseFirestore

struct PhongTro: Codable, Identifiable {
    @DocumentID var id: String?
    var tieuDe: String
    var giaThue: Double
    var dienTich: Double
    var diaChi: String
    var loaiPhong: String
    var hinhAnh: [String]
    var moTa: String
    var tienIch: [String]
    var ngayDang: Date?
    var idNguoiDang: String
    
    // Thêm các thuộc tính khác nếu cần sau này (ví dụ: trạng thái phòng)
    var trangThai: String? // "Đang rảnh", "Đã thuê"
    
    // CodingKeys giúp ánh xạ nếu tên biến Swift khác với field trên Firestore
    enum CodingKeys: String, CodingKey {
        case id
        case tieuDe
        case giaThue
        case dienTich
        case diaChi
        case loaiPhong
        case hinhAnh
        case moTa
        case tienIch
        case ngayDang
        case idNguoiDang
        case trangThai
    }
}
