# QuanLy_PhongTroj

Ứng dụng iOS quản lý phòng trọ dùng `UIKit + Firebase`, đã được ghép thành một dự án hoàn chỉnh gồm:

- Người dùng: đăng ký, đăng nhập, xem danh sách phòng, tìm kiếm, xem chi tiết, lưu yêu thích, chat, cập nhật hồ sơ.
- Quản trị viên: dashboard thống kê, quản lý phòng trọ (thêm/sửa/xóa), quản lý người dùng (đổi quyền, khóa/mở tài khoản), đăng xuất.
- Dữ liệu: Firestore cho phòng, người dùng, hội thoại; Storage cho avatar.

## Công nghệ

- iOS 15+
- Swift + UIKit + Storyboard
- CocoaPods
- Firebase Auth
- Firebase Firestore
- Firebase Storage

## Cấu trúc chính

```text
QuanLy_PhongTroj/
├── Controllers/
├── Models/
├── Services/
├── Base.lproj/Main.storyboard
├── GoogleService-Info.plist
└── Info.plist
```

## Chức năng đã hoàn thiện

### 1. Luồng đăng nhập và phân quyền

- Tự điều hướng khi mở app:
  - Chưa đăng nhập -> `DangNhapVC`
  - Đăng nhập user -> `MainTabBarController`
  - Đăng nhập admin -> `AdminTabBarController`
- Tài khoản bị khóa sẽ không được vào hệ thống.

### 2. Người dùng

- Đăng ký tài khoản mới.
- Đăng nhập bằng username nội bộ, map sang email Firebase.
- Xem danh sách phòng theo loại, tìm kiếm, sắp xếp.
- Xem chi tiết phòng, lưu vào yêu thích.
- Chat với chủ phòng.
- Cập nhật hồ sơ và avatar.

### 3. Quản trị viên

- Dashboard thống kê số phòng, loại phòng, số user, admin, tài khoản hoạt động/tạm khóa.
- Màn hình quản lý phòng có thể:
  - Seed dữ liệu mẫu
  - Thêm phòng mới
  - Sửa phòng hiện có
  - Xóa phòng
- Màn hình quản lý người dùng có thể:
  - Đổi `role` giữa `user` và `admin`
  - Khóa / mở tài khoản bằng `isActive`

## Firestore collections

### `Users/{uid}`

```json
{
  "hoTen": "Nguyen Van A",
  "tenDangNhap": "nguyenvana",
  "role": "user",
  "isActive": true,
  "soDienThoai": "0900000000",
  "avatarUrl": "https://...",
  "ngayTao": "Timestamp"
}
```

### `Users/{uid}/savedRooms/{roomId}`

```json
{
  "savedAt": "Timestamp"
}
```

### `rooms/{roomId}`

```json
{
  "tieuDe": "Studio full nội thất",
  "giaThue": 4500000,
  "dienTich": 28,
  "diaChi": "Quận 10, TP.HCM",
  "loaiPhong": "Studio",
  "hinhAnh": ["https://..."],
  "moTa": "Phòng mới, sạch sẽ",
  "tienIch": ["Wifi", "Máy lạnh"],
  "ngayDang": "Timestamp",
  "idNguoiDang": "uid_nguoi_dang",
  "trangThai": "Đang rảnh"
}
```

### `Conversations/{conversationId}`

```json
{
  "participants": ["uid1", "uid2"],
  "lastMessage": "Xin chao",
  "lastMessageTime": "Timestamp"
}
```

### `Conversations/{conversationId}/messages/{messageId}`

```json
{
  "senderId": "uid1",
  "text": "Tin nhan",
  "timestamp": "Timestamp"
}
```

## Tài khoản admin

- Đăng ký username là `admin` để hệ thống lưu `role = admin`.
- Sau đó đăng nhập lại để vào tab quản trị.

## Chạy dự án

### 1. Cài pod

```bash
pod install
```

### 2. Mở workspace

```bash
open QuanLy_PhongTroj.xcworkspace
```

### 3. Nếu build bằng terminal

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
-workspace QuanLy_PhongTroj.xcworkspace \
-scheme QuanLy_PhongTroj \
-destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Firebase

- Đã có file `GoogleService-Info.plist` trong project.
- Rule mẫu được đặt tại:
  - `firestore.rules`
  - `storage.rules`
  - `firestore.indexes.json`
  - `firebase.json`

## Ghi chú

- Khi danh sách phòng trống, app có thể tự seed dữ liệu mẫu.
- Màn `AdminPhongVC` có thêm nút `Seed` để nạp lại dữ liệu phòng mẫu.
- Khóa tài khoản bằng `isActive = false` an toàn hơn việc xóa doc người dùng trong khi Firebase Auth vẫn còn tài khoản.
