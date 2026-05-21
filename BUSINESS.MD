# BUSINESS.MD — BMC Phở Express

> **Nền tảng nhà hàng thông minh** (Smart Restaurant Platform)

---

## 1. Tổng quan dự án

**BMC Phở Express** là một nền tảng đặt món ăn thông minh, kết hợp giữa:
- **Ứng dụng đặt món cho khách hàng** (tương tự GrabFood/ShopeeFood nhưng chỉ hỗ trợ **tự đến lấy**, không giao hàng)
- **Hệ thống POS cho nhân viên** (đặt món tại bàn trong nhà hàng)
- **Quản lý chuỗi nhà hàng** (nhiều chi nhánh)

### Đặc điểm kinh doanh chính:
| Đặc điểm | Mô tả |
|-----------|--------|
| Mô hình | Chuỗi nhà hàng + Marketplace |
| Giao hàng | ❌ Không có — Khách đặt online, tự đến lấy |
| Thanh toán | QR Code tại quán |
| Thị trường | TP. Hồ Chí Minh, Việt Nam |
| Tiền tệ | VNĐ |
| Ngôn ngữ | Tiếng Việt |

---

## 2. Chi nhánh

| Chi nhánh | Địa chỉ |
|-----------|----------|
| Quận 1 | Tầng 1 |
| Quận 3 | Tầng Trệt |
| Phú Nhuận | Tầng 2 |

---

## 3. Đối tượng người dùng

| Vai trò | Mô tả | Chức năng chính |
|---------|--------|-----------------|
| **Customer** | Khách hàng cuối | Duyệt menu, đặt món, thanh toán QR, nhận đơn |
| **Staff** | Nhân viên nhà hàng | Chọn bàn, đặt món cho khách tại chỗ |
| **Admin** | Quản lý | Quản lý nhà hàng, menu, đơn hàng |

---

## 4. Danh mục sản phẩm

### Danh mục chính:
| Danh mục | Số lượng món | Ảnh đại diện |
|----------|-------------|--------------|
| Phở | 12 món | pho.jpg |
| Bún | 8 món | pho_bo.png |
| Cơm | 10 món | com.webp |
| Đồ uống | 7 món | tra_sua.jpg |
| Tráng miệng | 5 món | tra_sua.jpg |

### Sản phẩm nổi bật:
| Sản phẩm | Giá | Đã bán |
|----------|-----|--------|
| Phở bò đặc biệt (flagship) | 95.000đ | 1.240 |
| Bún bò Huế | 80.000đ | 985 |
| Cơm gà Hải Nam | 75.000đ | 763 |
| Sinh tố bơ | 45.000đ | — |

### Combo:
| Combo | Thành phần | Giá | Tiết kiệm |
|-------|-----------|-----|-----------|
| Combo Phở Đồng Quê | Phở bò + Nước mía + Bánh quẩy | 115.000đ | 15.000đ |
| Combo Bún Huế Đặc Biệt | Bún bò Huế + Trà đá + Chè đậu | 105.000đ | 15.000đ |

### Khoảng giá: 10.000đ – 185.000đ

---

## 5. Tính năng chi tiết sản phẩm

Mỗi sản phẩm có:
- **Size**: Nhỏ / Vừa / Lớn
- **Topping**: Thêm thịt, trứng, rau...
- **Tùy chỉnh**: Độ cay, lượng nước dùng, độ béo
- **Thông tin dinh dưỡng**: Calories, protein, carbs, fat, sodium, fiber
- **Tag chế độ ăn**: Low-carb, Keto, Chay...
- **Thông tin dị ứng**
- **Đánh giá & review**
- **Gợi ý kết hợp** (AI-powered)
- **Xuất xứ nguyên liệu**

---

## 6. Luồng người dùng (User Flows)

### A. Xác thực (Authentication)
```
Đăng nhập (Email/SĐT + Mật khẩu)
    → Đăng ký
    → Quên mật khẩu (OTP 6 số)
    → Đặt lại mật khẩu
    → Đăng nhập Google (Firebase Auth)
    → Khảo sát Onboarding (người dùng mới)
```

### B. Khảo sát Onboarding (5 bước cá nhân hóa)
1. **Sở thích ẩm thực**: Cơm, Bún, Phở, Trà sữa, Gà rán, BBQ...
2. **Thời gian ăn**: Sáng, Trưa, Tối, Khuya, Xế chiều
3. **Ngân sách**: Dưới 50k, 50k-100k, 100k-200k, Trên 200k
4. **Ưu tiên**: Nhanh, Rẻ, Voucher, Ngon, Healthy, Đóng gói đẹp, Nổi tiếng
5. **Chế độ ăn**: Eat clean, Keto, Chay, Thuần chay, Ít đường, Ít cay, Không hành

### C. Luồng đặt món (Customer)
```
Trang chủ → Duyệt banner/danh mục/deal/quán
    → Tìm kiếm & lọc theo danh mục
    → Xem chi tiết quán → Menu, đánh giá, khoảng cách
    → Xem chi tiết sản phẩm → Chọn size, topping, tùy chỉnh
    → Thêm vào giỏ hàng
    → Xem giỏ hàng → Điều chỉnh số lượng, ghi chú
    → Checkout → Chọn thời gian nhận, xác nhận QR
    → Theo dõi đơn hàng
```

### D. Trạng thái đơn hàng
```
Chờ thanh toán → Chờ xác nhận → Chờ nhận đơn → Chờ đánh giá → (Trả hàng)
```

### E. Luồng nhân viên (Staff)
```
Chọn bàn (1-20 bàn) → Duyệt menu theo danh mục
    → Thêm nhanh món vào đơn
    → Xem tổng đơn → Xác nhận (gửi bếp kèm số bàn)
```

---

## 7. Tính năng ứng dụng

### Khách hàng:
- ✅ Banner khuyến mãi carousel (ảnh thật)
- ✅ Gợi ý AI ("Bạn hay gọi", "Hay kết hợp", "Phổ biến nhất")
- ✅ Duyệt danh mục với ảnh thật
- ✅ Bộ lọc nhanh (Đang hot, Món mới, Best seller, Combo tiết kiệm)
- ✅ Xếp hạng Best Seller
- ✅ Deal/Combo tiết kiệm
- ✅ Quán gần đây (GPS-based)
- ✅ Quán đánh giá cao (> 4.5 sao)
- ✅ Tìm kiếm với autocomplete
- ✅ Lọc nâng cao (Lọc theo, Tùy chọn quán, Giá, Loại ẩm thực)
- ✅ Chi tiết sản phẩm đầy đủ (dinh dưỡng, dị ứng, review)
- ✅ Giỏ hàng với tính giảm giá
- ✅ Đặt lịch nhận hàng
- ✅ Thanh toán QR Code
- ✅ Lịch sử đơn hàng
- ✅ Chương trình loyalty (tích điểm, ưu đãi sinh nhật 15%)
- ✅ Hạng thành viên (Gold, Silver...)

### Nhân viên:
- ✅ Chọn bàn (20 bàn)
- ✅ Tìm kiếm nhanh menu
- ✅ Lọc theo danh mục
- ✅ Thêm/bớt món nhanh
- ✅ Tổng đơn kèm số bàn
- ✅ Hiển thị thông tin chi nhánh

### Thanh toán viên:
- ✅ Trang cashier riêng

---

## 8. Chương trình khách hàng thân thiết

| Tính năng | Chi tiết |
|-----------|----------|
| Tích điểm | Mỗi đơn hàng tích điểm loyalty |
| Hạng thành viên | Gold, Silver... |
| Ưu đãi sinh nhật | Giảm 15% |
| Mini promos | Hiển thị trên trang chủ |

---

## 9. Thiết kế & Thương hiệu

### Bảng màu:
| Màu | Hex | Mục đích |
|-----|-----|----------|
| Primary | `#D84315` | Cam đỏ đậm — kích thích thèm ăn |
| Secondary | `#FF6F3C` | Cam sáng |
| Accent | `#FFA726` | Vàng cam — badge, highlight |
| Background | `#FDFDFD` | Trắng ngà (không bao giờ trắng tinh) |
| Soft BG | `#FFF4F0` | Hồng đào ấm |
| Text Primary | `#2D2D2D` | Đen nhẹ (không bao giờ đen tuyệt đối) |

### Triết lý thiết kế:
- Tỷ lệ màu **60-30-10** (60% nền, 30% text/neutral, 10% primary accent)
- Tông màu **ấm, kích thích thèm ăn** — không dùng xanh dương/xanh lá làm màu chính
- Material Design 3 với design system tùy chỉnh
- Responsive cho mọi thiết bị di động
- Font: **Be Vietnam Pro** (Google Fonts)

### Hệ thống badge:
| Loại | Màu nền |
|------|---------|
| HOT/PROMO | Cam đỏ ấm |
| BEST SELLER | Vàng gold |
| DISCOUNT | Xanh lá |
| NEW | Tím |

---

## 10. Kiến trúc kỹ thuật

### Tech Stack:
| Thành phần | Công nghệ |
|-----------|-----------|
| Framework | Flutter (SDK ^3.5.0) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Network | Dio (interceptors cho auth token) |
| Auth | Firebase Auth + Google Sign-In |
| Storage | Flutter Secure Storage |
| Charts | fl_chart |
| Location | Geolocator |

### Kiến trúc: Clean Architecture
```
presentation (UI)
    → providers (State Management)
        → data/repositories (Data Layer)
            → models (Domain)
```

### Routes:
| Route | Trang |
|-------|-------|
| `/` | Trang chủ (duyệt quán) |
| `/login` | Đăng nhập |
| `/register` | Đăng ký |
| `/forgot-password` | Quên mật khẩu |
| `/reset-password` | Đặt lại mật khẩu |
| `/onboarding` | Khảo sát Onboarding |
| `/staff` | Trang nhân viên |
| `/cashier` | Trang thu ngân |
| `/search` | Tìm kiếm (hỗ trợ filter category) |
| `/profile` | Hồ sơ cá nhân |

---

## 11. Tài nguyên hình ảnh

| File | Mô tả | Sử dụng |
|------|--------|---------|
| `pho.jpg` | Ảnh phở | Banner, danh mục Phở, store cards |
| `pho_bo.png` | Ảnh phở bò | Banner, danh mục Bún, store cards |
| `com.webp` | Ảnh cơm | Banner, danh mục Cơm, store cards |
| `tra_sua.jpg` | Ảnh trà sữa | Banner, danh mục Đồ uống, store cards |

---

## 12. Tóm tắt Business Model Canvas

| Thành phần | Nội dung |
|-----------|----------|
| **Khách hàng mục tiêu** | Người dùng smartphone tại TP.HCM muốn đặt món nhanh, tự đến lấy |
| **Giá trị cốt lõi** | Đặt món nhanh, không chờ đợi, thanh toán QR tiện lợi, cá nhân hóa AI |
| **Kênh phân phối** | App mobile (iOS + Android) |
| **Nguồn doanh thu** | Bán đồ ăn trực tiếp + Marketplace commission từ quán đối tác |
| **Đối tác chính** | Các quán ăn/nhà hàng đối tác trên nền tảng |
| **Hoạt động chính** | Vận hành chuỗi BMC Phở Express + Quản lý marketplace |
| **Tài nguyên chính** | App, hệ thống POS, chuỗi nhà hàng, đội ngũ nhân viên |
| **Cấu trúc chi phí** | Vận hành nhà hàng, phát triển app, marketing |
| **Lợi thế cạnh tranh** | Không phí giao hàng, thanh toán QR nhanh, AI gợi ý, loyalty program |

---

*Cập nhật lần cuối: 21/05/2026*
