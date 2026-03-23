import Foundation
import FirebaseFirestore

class RoomService {
    static let shared = RoomService()
    private let db = Firestore.firestore()
    private let collectionName = "rooms"
    
    private init() {}
    
    // Lấy danh sách phòng từ Firestore, có hỗ trợ lọc theo Loại phòng
    func fetchRooms(loaiPhong: String?, completion: @escaping ([PhongTro]?, Error?) -> Void) {
        var query: Query = db.collection(collectionName)
        
        // Nếu loaiPhong không phải là "Tất cả", ta sẽ thêm bộ lọc (where clause)
        if let type = loaiPhong, type != "Tất cả" {
            query = query.whereField("loaiPhong", isEqualTo: type)
        }
        
        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Lỗi khi tải danh sách phòng: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            var rooms: [PhongTro] = []
            
            for document in querySnapshot!.documents {
                do {
                    // Tự động map từ JSON Document vào Swift Struct bằng Codable
                    let room = try document.data(as: PhongTro.self)
                    rooms.append(room)
                } catch {
                    print("Lỗi map model cho phòng \(document.documentID): \(error)")
                }
            }
            
            // Xếp theo ngày đăng mới nhất nếu thích, hiện tại lấy thô
            completion(rooms, nil)
        }
    }
    
    // Chèn cục Dữ liệu giả định lên Firestore để test giao diện
    func seedSampleData() {
        let sampleRooms = [
            PhongTro(tieuDe: "Căn hộ Studio cao cấp Q1 Tân Định", giaThue: 5500000, dienTich: 25.0, diaChi: "123 Trần Quang Khải, Quận 1, TP. HCM", loaiPhong: "Studio", hinhAnh: ["https://picsum.photos/400/300?random=1"], moTa: "Phòng thoáng mát, full nội thất", tienIch: ["Máy lạnh", "Tủ lạnh", "Giường", "Wifi"], ngayDang: Date(), idNguoiDang: "admin", trangThai: "Đang rảnh"),
            PhongTro(tieuDe: "Phòng đơn giá rẻ sinh viên", giaThue: 2000000, dienTich: 15.0, diaChi: "45/2 Làng Đại Học, Thủ Đức", loaiPhong: "Phòng đơn", hinhAnh: ["https://picsum.photos/400/300?random=2"], moTa: "Sạch sẽ, an ninh, giờ giấc tự do", tienIch: ["Quạt", "Wifi miễn phí"], ngayDang: Date(), idNguoiDang: "admin", trangThai: "Đang rảnh"),
            PhongTro(tieuDe: "Gác lửng đẹp Quận 7", giaThue: 3500000, dienTich: 30.0, diaChi: "Đường số 9, Tân Phú, Q7", loaiPhong: "Gác lửng", hinhAnh: ["https://picsum.photos/400/300?random=3"], moTa: "Phù hợp gia đình nhỏ, người đi làm", tienIch: ["Tủ bếp", "Gác đúc", "Chỗ để xe"], ngayDang: Date(), idNguoiDang: "admin", trangThai: "Đang rảnh"),
            PhongTro(tieuDe: "Phòng đôi rộng rãi Bình Thạnh", giaThue: 4500000, dienTich: 40.0, diaChi: "Bạch Đằng, Bình Thạnh", loaiPhong: "Phòng đôi", hinhAnh: ["https://picsum.photos/400/300?random=4"], moTa: "Khu vực dân trí cao, gần trung tâm", tienIch: ["Máy giặt", "Ban công", "Nội thất cơ bản"], ngayDang: Date(), idNguoiDang: "admin", trangThai: "Đang rảnh"),
            PhongTro(tieuDe: "Studio view Landmark 81", giaThue: 8000000, dienTich: 35.0, diaChi: "Nguyễn Hữu Cảnh, Bình Thạnh", loaiPhong: "Studio", hinhAnh: ["https://picsum.photos/400/300?random=5"], moTa: "Khu VIP an ninh đa lớp, hồ bơi riêng", tienIch: ["Hồ bơi", "Gym", "Full nội thất"], ngayDang: Date(), idNguoiDang: "admin", trangThai: "Đang rảnh")
        ]
        
        let batch = db.batch()
        
        for room in sampleRooms {
            let docRef = db.collection(collectionName).document()
            do {
                try batch.setData(from: room, forDocument: docRef)
            } catch {
                print("Lỗi tạo mẫu \(room.tieuDe): \(error)")
            }
        }
        
        batch.commit { error in
            if let err = error {
                print("Lỗi ghi Seed Data: \(err.localizedDescription)")
            } else {
                print("✅ Đã chèn 5 bản ghi mẫu lên Firestore thành công!")
            }
        }
    }
}
