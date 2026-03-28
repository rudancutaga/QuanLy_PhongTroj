import Foundation
import FirebaseFirestore

class RoomService {
    static let shared = RoomService()
    private let db = Firestore.firestore()
    private let collectionName = "rooms"
    private let placeholderImage = "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80"
    
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
                    var room = try document.data(as: PhongTro.self)
                    room.id = document.documentID
                    rooms.append(room)
                } catch {
                    print("Lỗi map model cho phòng \(document.documentID): \(error)")
                }
            }
            
            rooms.sort { lhs, rhs in
                (lhs.ngayDang ?? .distantPast) > (rhs.ngayDang ?? .distantPast)
            }

            completion(rooms, nil)
        }
    }

    func saveRoom(_ room: PhongTro, completion: @escaping (Error?) -> Void) {
        let docRef: DocumentReference

        if let roomId = room.id, !roomId.isEmpty {
            docRef = db.collection(collectionName).document(roomId)
        } else {
            docRef = db.collection(collectionName).document()
        }

        var roomToSave = room
        roomToSave.id = docRef.documentID

        if roomToSave.ngayDang == nil {
            roomToSave.ngayDang = Date()
        }

        if roomToSave.hinhAnh.isEmpty {
            roomToSave.hinhAnh = [placeholderImage]
        }

        do {
            try docRef.setData(from: roomToSave) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func deleteRoom(id: String, completion: @escaping (Error?) -> Void) {
        db.collection(collectionName).document(id).delete(completion: completion)
    }

    func ensureSampleDataIfNeeded(completion: ((Error?) -> Void)? = nil) {
        db.collection(collectionName).limit(to: 1).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion?(error)
                return
            }

            guard let self = self else {
                completion?(nil)
                return
            }

            if let documents = snapshot?.documents, !documents.isEmpty {
                completion?(nil)
                return
            }

            self.seedSampleData(completion: completion)
        }
    }
    
    // Chèn cục Dữ liệu giả định lên Firestore để test giao diện
    func seedSampleData(completion: ((Error?) -> Void)? = nil) {
        let sampleRooms: [(id: String, room: PhongTro)] = [
            (
                "sample-studio-q1",
                PhongTro(
                    id: "sample-studio-q1",
                    tieuDe: "Căn hộ Studio cao cấp Q1 Tân Định",
                    giaThue: 5_500_000,
                    dienTich: 25.0,
                    diaChi: "123 Trần Quang Khải, Quận 1, TP. HCM",
                    loaiPhong: "Studio",
                    hinhAnh: ["https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80"],
                    moTa: "Phòng thoáng mát, full nội thất, phù hợp người đi làm hoặc cặp đôi trẻ.",
                    tienIch: ["Máy lạnh", "Tủ lạnh", "Giường", "Wifi"],
                    ngayDang: Date(),
                    idNguoiDang: "admin-seed",
                    trangThai: "Đang rảnh"
                )
            ),
            (
                "sample-phong-don-thu-duc",
                PhongTro(
                    id: "sample-phong-don-thu-duc",
                    tieuDe: "Phòng đơn giá rẻ sinh viên",
                    giaThue: 2_000_000,
                    dienTich: 15.0,
                    diaChi: "45/2 Làng Đại Học, Thủ Đức",
                    loaiPhong: "Phòng đơn",
                    hinhAnh: ["https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80"],
                    moTa: "Sạch sẽ, an ninh, giờ giấc tự do, gần trường và trạm xe buýt.",
                    tienIch: ["Quạt", "Wifi miễn phí"],
                    ngayDang: Date(),
                    idNguoiDang: "admin-seed",
                    trangThai: "Đang rảnh"
                )
            ),
            (
                "sample-gac-lung-q7",
                PhongTro(
                    id: "sample-gac-lung-q7",
                    tieuDe: "Gác lửng đẹp Quận 7",
                    giaThue: 3_500_000,
                    dienTich: 30.0,
                    diaChi: "Đường số 9, Tân Phú, Q7",
                    loaiPhong: "Gác lửng",
                    hinhAnh: ["https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80"],
                    moTa: "Không gian rộng, có gác lửng và khu bếp, phù hợp gia đình nhỏ.",
                    tienIch: ["Tủ bếp", "Gác đúc", "Chỗ để xe"],
                    ngayDang: Date(),
                    idNguoiDang: "admin-seed",
                    trangThai: "Đang rảnh"
                )
            ),
            (
                "sample-phong-doi-binh-thanh",
                PhongTro(
                    id: "sample-phong-doi-binh-thanh",
                    tieuDe: "Phòng đôi rộng rãi Bình Thạnh",
                    giaThue: 4_500_000,
                    dienTich: 40.0,
                    diaChi: "Bạch Đằng, Bình Thạnh",
                    loaiPhong: "Phòng đôi",
                    hinhAnh: ["https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80"],
                    moTa: "Khu vực dân trí cao, gần trung tâm, có cửa sổ thoáng.",
                    tienIch: ["Máy giặt", "Ban công", "Nội thất cơ bản"],
                    ngayDang: Date(),
                    idNguoiDang: "admin-seed",
                    trangThai: "Đang rảnh"
                )
            ),
            (
                "sample-studio-landmark",
                PhongTro(
                    id: "sample-studio-landmark",
                    tieuDe: "Studio view Landmark 81",
                    giaThue: 8_000_000,
                    dienTich: 35.0,
                    diaChi: "Nguyễn Hữu Cảnh, Bình Thạnh",
                    loaiPhong: "Studio",
                    hinhAnh: ["https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80"],
                    moTa: "Khu VIP an ninh đa lớp, hồ bơi và gym nội khu.",
                    tienIch: ["Hồ bơi", "Gym", "Full nội thất"],
                    ngayDang: Date(),
                    idNguoiDang: "admin-seed",
                    trangThai: "Đang rảnh"
                )
            )
        ]
        
        let batch = db.batch()
        
        for item in sampleRooms {
            let docRef = db.collection(collectionName).document(item.id)
            do {
                try batch.setData(from: item.room, forDocument: docRef)
            } catch {
                print("Lỗi tạo mẫu \(item.room.tieuDe): \(error)")
            }
        }
        
        batch.commit { error in
            if let err = error {
                print("Lỗi ghi Seed Data: \(err.localizedDescription)")
                completion?(err)
            } else {
                print("✅ Đã chèn 5 bản ghi mẫu lên Firestore thành công!")
                completion?(nil)
            }
        }
    }
}
