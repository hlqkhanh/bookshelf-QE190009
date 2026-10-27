# BookShelf — QE190009

Hồ Lê Quốc Khánh — PRM393, FALL 2026.

Ứng dụng Flutter Android dùng Firebase Authentication Email/Password và Cloud Firestore thật. Chỉ collection `books` lưu dữ liệu app. Không có admin SDK hoặc service-account key.

## Chạy ứng dụng

1. Cài Flutter stable (dự án được tạo với Flutter 3.47.8 / Dart 3.13.7), Android SDK, JDK 21.
2. Tạo Firebase project, đăng ký Android application ID `com.prm393.bookshelf`.
3. Đặt cấu hình client tải từ Firebase vào `android/app/google-services.json`. File cấu hình của chủ dự án hiện đã được thêm; khi dùng project khác chỉ cần thay file này.
4. Firebase Console → Authentication → Sign-in method: bật Email/Password.
5. Firestore Database: tạo database Standard `(default)` ở Production mode. Mở Rules, dán toàn bộ `firestore.rules`, Publish. Hoặc dùng Firebase CLI:

```powershell
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project bookshelf-d1ae3
```

6. Trong thư mục dự án:

```powershell
flutter pub get
flutter run
```

SDK tải trong workspace hiện tại có thể gọi bằng `..\.tools\flutter\bin\flutter.bat` nếu máy chưa thêm Flutter vào PATH. Không đưa thư mục `.tools` vào repo hay ZIP.

## Chức năng

- Home public; Register/Login thật, validation đúng thông điệp đề, lỗi Firebase nằm dưới nút submit.
- Auth gate chờ phiên đăng nhập; List không quay lại form bằng Back; logout xóa trạng thái riêng của tài khoản.
- Add và Edit dùng chung form; title, author, genre, status, rating, notes được validate khi submit và kiểm tra lại khi sửa.
- Firestore snapshots cập nhật List/Detail; favorite và Delete lưu thật.
- List sắp theo title không phân biệt hoa/thường, rồi author. Genre/status/favorites/search kết hợp tức thì; Clear đặt lại tất cả.
- Summary tính trên kết quả đang hiển thị; thứ tự breakdown theo số lượng rồi To Read/Reading/Finished.
- Detail có view/edit/Save/Cancel/Delete confirmation.

## Chống trùng ngay tại Firestore

Document id bắt buộc:

```
<uid>__<SHA256(trim(lower(title)))>_<SHA256(trim(lower(author)))>
```

Hai SHA256 được biểu diễn hex chữ thường và tính riêng để tránh nhập nhằng dấu phân cách trong tên sách. Rules tự tính lại từ dữ liệu, do đó ghi duplicate bằng document id tùy ý bị từ chối. Transaction của app đọc document trước khi tạo và trả lỗi duplicate; hai người dùng có thể lưu cùng sách. Khi đổi title/author làm thay đổi ID, app dùng transaction chuyển document, giữ createdAt/favorite, không tạo collection phụ. Grader ghi trực tiếp cần dùng canonical ID cho dữ liệu hợp lệ; có thể tạo ID bằng hàm `bookId` trong `lib/models/book.dart` hoặc công cụ Node bên dưới.

`rating` có thể vắng mặt hoặc null (chưa đánh giá), nếu có giá trị phải là integer 0..5. `notes` có thể vắng mặt hoặc string tối đa 300 ký tự. Rules yêu cầu đúng ownership, id, kiểu dữ liệu, enum, độ dài, timestamp; chặn các field ngoài schema. `createdAt` không đổi sau khi update. Chỉ query theo `userId == uid` được đọc; query toàn collection bị từ chối. Không cần composite index, lọc/sắp xếp thực hiện trên stream riêng của user.

Tạo ID cho một lệnh ghi trực tiếp hợp lệ:

```powershell
node tools/book-id.mjs USER_UID "Dune" "Frank Herbert"
```

## Kiểm thử

```powershell
flutter analyze
flutter test
cd rules-tests
npm ci
cd ..
.\rules-tests\node_modules\.bin\firebase.cmd emulators:exec --only firestore --project demo-bookshelf "npm --prefix rules-tests test"
```

Rules tests chạy với project demo trong emulator, không ghi dữ liệu vào Firebase thật. Các lỗi PERMISSION_DENIED trong log của ca negative là điều mong đợi. Xem `docs/verification.md` để biết phạm vi đã xác minh và phần cần chạy thực tế.

## Build, báo cáo, ZIP

```powershell
flutter build apk --release
Copy-Item docs/report.example.json report.local.json
# Điền URL repo, URL APK public, tài khoản test và danh sách ảnh chụp thật trong report.local.json.
powershell -ExecutionPolicy Bypass -File tools/create-report.ps1
powershell -ExecutionPolicy Bypass -File tools/package-source.ps1 -StudentCode QE190009
```

APK: `build/app/outputs/flutter-apk/app-release.apk`. Build release dùng debug signing của template để cài APK cho bài thực hành; nếu phát hành lên cửa hàng cần cấu hình release signing riêng.

Upload APK vào GitHub Releases (tag v1.1), lấy download URL và điền vào báo cáo. Repo phải Public. ZIP ở `submission/QE190009.zip`, `pubspec.yaml` ngay top level, có lockfile và rules. Script dùng allowlist, bỏ cache/build/.git/node_modules/khóa ký/private keys. Báo cáo Word thật ở `submission/QE190009.docx`, tự nhúng ảnh có caption từ danh sách JSON. Không có ảnh thì ghi rõ DRAFT. `report.local.json` chứa mật khẩu test và bị gitignore; chỉ chia sẻ tài khoản test dành cho grader trong báo cáo nộp.

Checklist ảnh: `docs/screenshot-checklist.md`. Chụp từ app chạy thật, không dùng mockup. Nên tạo 5 sách ở ít nhất 2 status, test đủ filter, logout/login tài khoản thứ hai và đóng/mở app trước khi nộp.

## Đưa lên GitHub sau khi tạo repository trống

Chạy trong `bookshelf`, thay URL repository bằng URL thật:

```powershell
git init
git add .
git commit -m "Build BookShelf for PRM393 practical exam"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/bookshelf-QE190009.git
git push -u origin main
```

Không chạy git add từ thư mục cha vì có Flutter SDK và đề bài. File `google-services.json` là cấu hình client công khai được đề cho phép; tuyệt đối không thêm service-account JSON.
