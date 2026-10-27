# Ảnh cần chụp từ phiên chạy thật

Không dùng ảnh mockup hoặc ảnh của tính năng chưa chạy. Đăng nhập tài khoản test của bạn; chỉ các màn public, Login/Register và trạng thái rỗng dùng phiên phù hợp như đề.

1. Firebase console — Authentication: Users có tài khoản test.
2. Firebase console — Firestore data: books có ít nhất 3 documents của tài khoản test.
3. Firebase console — Security Rules: rules đã Published.
4. Register screen — validation: submit form trống.
5. Register screen — success: thấy Registration successful (SnackBar).
6. Login screen: form trống.
7. List screen — after login: email, Logout, ít nhất 3 sách (chụp cuộn nhiều ảnh nếu cần).
8. Add Book form — validation: submit trống/sai.
9. Add Book form — success: Book added và sách mới (có thể chụp thêm phần danh sách).
10. Filters and search — Genre filter.
11. Filters and search — Status filter.
12. Filters and search — Favorites only.
13. Filters and search — Search; kèm ghi chú điều kiện lọc và kết quả.
14. Summary: Books, Favorites, ít nhất hai trạng thái.
15. Detail screen — view mode: đủ title, author, genre, status, rating, notes.
16. Detail screen — edit mode, validation: sửa thành dữ liệu sai rồi Save.
17. Detail screen — after Save: giá trị đã lưu.
18. Favorite toggle — before.
19. Favorite toggle — after.
20. Delete — before (và dialog Cancel/Delete nếu được).
21. Delete — after: sách biến mất khỏi List.
22. Empty state: tài khoản thứ hai, No books found.

Trong report.local.json, screenshots là danh sách theo đúng thứ tự:

```json
{
  "caption": "List screen — after login",
  "path": "screenshots/07-list.png",
  "note": "Tài khoản test có 5 sách."
}
```

Đường dẫn tương đối được tính từ file JSON. Chỉ thêm ảnh đã chụp thật. Script tạo report đặt caption ngay trước ảnh. Không có ảnh thì report được ghi rõ DRAFT và chưa đủ điều kiện nộp.
