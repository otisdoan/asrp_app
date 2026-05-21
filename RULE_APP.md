# 🚨 APP FRONTEND RULES (BẮT BUỘC)

Tài liệu này định nghĩa các quy chuẩn và nguyên tắc phát triển bắt buộc áp dụng riêng cho ứng dụng di động Flutter (`fe_asrp_app`), tương đương và đồng bộ với các quy chuẩn bên phía Web.

---

## 1. UI (Giao diện người dùng)
* **Chỉ sử dụng Material Design / Material 3** (hoặc Cupertino khi cần thiết) được tùy biến theo thiết kế hệ thống (Custom Design System).
* **Không dùng trực tiếp các giá trị màu sắc/kích thước cứng (hardcoded)**:
  * Phải sử dụng lớp tiện ích quản lý màu tập trung `AppColors` trong `lib/core/theme/app_colors.dart` (ví dụ: màu đỏ cam trầm `AppColors.primary`, màu nền nhạt `AppColors.bgMain`, màu chữ xám `AppColors.textSecondary`, v.v.).
  * Tận dụng `Theme.of(context)` để thiết lập phông chữ, màu sắc đồng bộ giúp dễ dàng hỗ trợ chuyển đổi Light/Dark Mode trong tương lai.
* **Luôn thiết kế Responsive cho mọi loại thiết bị di động**:
  * **Tránh lỗi tràn màn hình (Pixel Overflow)**: Không hardcode kích thước rộng/cao cố định (`width`, `height`) cho các widget chứa văn bản biến động hoặc màn hình có kích thước thay đổi.
  * **Co giãn linh hoạt**: Sử dụng các widget hỗ trợ co giãn như `Flexible`, `Expanded`, `Spacer`, `LayoutBuilder`, hoặc sử dụng `MediaQuery` để điều chỉnh UI theo tỷ lệ tương đối giữa màn hình điện thoại nhỏ (se, mini) và màn hình lớn (pro max, tablet).
  * Sử dụng các widget cuộn như `SingleChildScrollView`, `ListView` đối với mọi giao diện chứa danh sách hoặc các biểu mẫu (Forms) để không bị tràn khi mở bàn phím ảo.
  * Luôn bao bọc nội dung chính trong `SafeArea` ở các góc viền màn hình để tránh bị che khuất bởi tai thỏ (notch), camera đục lỗ hoặc thanh điều hướng hệ thống (home bar).

---

## 2. Hệ thống màu sắc (Color System Rules)
Dựa theo quy chuẩn thương hiệu [COLOR.md](file:///Users/otisdoan/Documents/asrp/fe_asrp/COLOR.md), toàn bộ ứng dụng phải tuân thủ nghiêm ngặt bảng màu và cách áp dụng sau thông qua `AppColors` (`lib/core/theme/app_colors.dart`):

### 🌈 Bảng màu cốt lõi (Color Palette)
* **🔴 Primary (Thương hiệu chính - Kích thích ăn uống)**:
  * `AppColors.primary` (`#D84315`): Màu cam đỏ trầm. Dùng cho CTA chính (Đặt món, Thêm vào giỏ), hiển thị giá tiền, các điểm nhấn/highlight cực kỳ quan trọng thu hút sự chú ý.
  * `AppColors.primaryHover` (`#BF360C`) & `AppColors.primaryActive` (`#9A2E0A`): Dùng cho các trạng thái phản hồi xúc giác (touch/tap splash feedback).
* **🟠 Secondary (Thương hiệu phụ - Tạo điểm nhấn nhẹ)**:
  * `AppColors.secondary` (`#FF6F3C`): Màu cam sáng. Dùng cho các icons, hover, hoặc điểm nhấn viền nhẹ.
* **🟡 Accent (Nổi bật phụ)**:
  * `AppColors.accent` (`#FFA726`): Màu vàng cam. Dùng cho các nhãn/badge Best seller hoặc các vùng thông tin nổi bật trung bình.
* **⚪ Background System (Hệ thống màu nền)**:
  * `AppColors.bgMain` (`#FDFDFD`): Nền chính của trang. **Nghiêm cấm dùng màu trắng tinh 100% (#FFFFFF) cho toàn bộ màn hình**.
  * `AppColors.bgSoft` (`#FFF4F0`): Nền cam rất nhạt. Dùng làm nền xen kẽ để tạo chiều sâu trực quan, tăng độ ấm áp và cảm giác ngon miệng (appetizing).
  * `AppColors.bgWarm` (`#F5EDE9`): Nền ấm áp trung tính. Dùng cho các phân mục đặc biệt như Combo.
* **⚫ Text System (Hệ thống chữ)**:
  * `AppColors.textPrimary` (`#2D2D2D`): Chữ chính. **TUYỆT ĐỐI KHÔNG dùng màu đen thuần (#000000)** để tránh cảm giác thô cứng.
  * `AppColors.textSecondary` (`#6B7280`) & `AppColors.textTertiary` (`#9CA3AF`): Chữ phụ, mô tả và placeholder.
* **🟢 State & Border**:
  * `AppColors.success` (`#2E7D32`), `AppColors.error` (`#E24B4A`).
  * `AppColors.divider` / `AppColors.outlineVariant` (`#E5E7EB`).

### 📐 Quy tắc phân bổ màu sắc (Color Usage Rules)
* **Áp dụng tỷ lệ vàng 60–30–10**:
  * **60% Nền**: Sử dụng `bgMain` kết hợp tinh tế với `bgSoft`.
  * **30% Phụ**: Màu chữ `textPrimary`, `textSecondary` và màu trung tính.
  * **10% Nhấn (Primary)**: Chỉ sử dụng màu đỏ cam trầm (`#D84315`) cho các chi tiết cốt lõi (nút mua hàng, giá tiền, highlight hành động). **Không lạm dụng màu cam đỏ bừa bãi** làm mỏi mắt người dùng.
* **🔘 Nút hành động (CTA Button)**:
  * **Primary Button**: Nền `AppColors.primary`, chữ trắng (`#FFFFFF`). Trạng thái nhấn (splash/highlight) sử dụng `primaryActive`.
  * **Secondary Button**: Nền `AppColors.bgSoft` (`#FFF4F0`), chữ `AppColors.primary` (`#D84315`), đường viền siêu nhẹ.
* **💰 Hiển thị giá tiền (Price Display)**:
  * Bắt buộc sử dụng màu `AppColors.primary` (`#D84315`).
  * Định dạng phông chữ `fontWeight: FontWeight.w600` hoặc `FontWeight.bold`, kích thước nổi bật hơn text mô tả xung quanh.
* **🏷️ Hệ thống nhãn (Badge System)**:
  * **HOT / PROMO**: Nền cam đỏ nhạt `AppColors.badgeHotBg` (`#FAECE7`), chữ `AppColors.badgeHotText` (`#993C1D`).
  * **BEST SELLER**: Nền vàng nhạt `AppColors.badgeBestBg` (`#FAEEDA`), chữ `AppColors.badgeBestText` (`#854F0B`).
  * **DISCOUNT**: Nền xanh lá nhạt `AppColors.successContainer` (`#E8F5E9`), chữ xanh lá đậm `AppColors.success` (`#2E7D32`).
* **🧱 Card UI (Khung thẻ món ăn)**:
  * Nền thẻ: Màu trắng tinh `#FFFFFF` để phân tách rõ rệt với nền trang (`bgMain`/`bgSoft`).
  * Đường viền: Sử dụng màu border mỏng nhẹ (`#F0F1F3`).
  * Đổ bóng (Shadow): Rất nhẹ để tạo cảm giác nổi tinh tế (sử dụng `BoxShadow` mờ nhẹ, độ phân tán thấp, màu đen trong suốt cao: `rgba(0,0,0,0.06)`). Tuyệt đối không dùng bóng đổ đen đặc hoặc sẫm màu.
* **🔍 Ô tìm kiếm / Input**:
  * Nền: Trắng `#FFFFFF`. Viền mặc định: `#E5E7EB`.
  * Khi người dùng focus: Chuyển màu viền sang `AppColors.secondary` (`#FF6F3C`) để phản hồi trực quan sinh động.
* **🎨 Quy tắc sử dụng Gradient (Dải màu)**:
  * Sử dụng dải màu chuyển tiếp từ `AppColors.primary` (`#D84315`) sang `AppColors.secondary` (`#FF6F3C`).
  * **Chỉ áp dụng cho**: Các Banner quảng cáo, Header chính của trang Shop, hoặc các nút khuyến mãi đặc biệt kích thích vị giác người dùng.

### 🚫 Những điều tuyệt đối cấm (Anti-patterns)
* ❌ **Không dùng màu nguyên thủy** (như màu đỏ tươi `#FF0000`, cam chói `#FFA500`, xanh lá thuần `#00FF00`).
* ❌ **Không lạm dụng màu đỏ cam (primary)**: Không dùng màu này làm nền cho các khối nội dung lớn (card, danh mục) để tránh gây rối mắt và mệt thị giác.
* ❌ **Không dùng màu xanh lục / xanh lam làm tông chính** (giảm kích thích vị giác và thèm ăn của khách hàng).
* ❌ **Không dùng màu đen thuần `#000000`** cho bất kỳ dòng chữ nào.

---

## 3. Structure (Cấu trúc thư mục)
Dự án được xây dựng dựa trên kiến trúc phân lớp sạch sẽ (Clean Architecture) rút gọn trong Flutter. Cần tuân thủ tuyệt đối cấu trúc sau:

* **`lib/presentation/pages/` (Chỉ chứa UI Màn hình chính)**:
  * Là nơi khai báo `Scaffold`, xử lý cấu trúc toàn trang, kết nối điều hướng (`GoRouter`) và lắng nghe dữ liệu từ các Providers.
  * **Nghiêm cấm**: Không xử lý logic tính toán phức tạp hay lưu trữ trạng thái lâu dài tại đây.
* **`lib/presentation/widgets/` (Chỉ chứa UI Components)**:
  * Widget dùng riêng cho một màn hình cụ thể: Đặt trong thư mục con tương ứng (ví dụ: `widgets/shop/` cho trang Shop).
  * Widget dùng lại ở nhiều nơi (Custom Button, Custom Input, Loading Skeleton, Bottom Sheet chung): Phải đưa vào `widgets/common/`.
  * **Nghiêm cấm**: Widgets tuyệt đối chỉ có chức năng hiển thị UI và nhận tương tác, không chứa logic nghiệp vụ hay gọi trực tiếp API.
* **`lib/providers/` (State Management - Chỉ chứa Trạng thái)**:
  * Sử dụng **Riverpod (`StateNotifierProvider`, `NotifierProvider`, `FutureProvider`)** để quản lý trạng thái tập trung (tương đương với Redux Toolkit bên Web).
  * **Nghiêm cấm**: Không thực hiện các cuộc gọi API thô bằng Dio trực tiếp trong Notifier. Notifier chỉ nhận trạng thái, gọi qua lớp Repository và cập nhật trạng thái tương ứng.
* **`lib/data/repositories/` (Lớp Dữ liệu - Tương đương API Service)**:
  * Nơi chứa các class Repository đảm nhận việc giao tiếp với `DioClient` để gọi API hoặc lấy dữ liệu local (Secure Storage).
  * Nơi lưu trữ Mock Data (`mock_data.dart`) phục vụ quá trình phát triển nhanh và kiểm thử khi API thực tế chưa hoàn thiện.
* **`lib/data/models/` (Lớp Định nghĩa Dữ liệu)**:
  * Chứa các class dữ liệu bất biến (immutable models) định nghĩa cấu trúc JSON nhận về từ API.
  * Chứa các hàm ánh xạ dữ liệu `fromJson` và `toJson` chuẩn hóa để tránh lỗi kiểu dữ liệu (Type Safety).

---

## 4. API (Giao tiếp Mạng)
* **Không gọi API trực tiếp trong UI Widgets/Pages**: Không viết các hàm gọi HTTP bất đồng bộ trong hàm `build()` hoặc `initState()` của UI.
* **Luôn qua Repositories + Riverpod Providers**:
  * Tận dụng thuộc tính `AsyncValue` của Riverpod (`ref.watch(provider).when(...)`) để xử lý đầy đủ và nhất quán 3 trạng thái bất đồng bộ: `data` (khi thành công), `loading` (hiển thị Shimmer loading skeleton), và `error` (hiển thị thông báo lỗi) - tương đương với TanStack Query bên React.
  * Luôn sử dụng `DioClient` được khởi tạo tập trung tại `lib/core/network/dio_client.dart`. Tuyệt đối không tự khởi tạo `Dio()` đơn lẻ trong Repository, để đảm bảo cơ chế tự động đính kèm `Authorization` Bearer token và cơ chế tự động Refresh Token thông qua Interceptors hoạt động chuẩn xác.

---

## 5. Form (Biểu mẫu & Xác thực)
* **Luôn dùng `Form` widget + `TextFormField` tiêu chuẩn của Flutter**:
  * Quản lý trạng thái và giá trị nhập liệu bằng `TextEditingController` kết hợp với `FocusNode` để cung cấp trải nghiệm chuyển tiếp bàn phím mượt mà.
  * **Bắt buộc**: Phải giải phóng tài nguyên bằng cách gọi `.dispose()` cho toàn bộ các `TextEditingController` và `FocusNode` trong hàm `dispose()` của `State` để ngăn ngừa triệt để lỗi rò rỉ bộ nhớ (Memory Leak).
* **Xác thực dữ liệu (Validation)**:
  * Sử dụng thuộc tính `validator` tích hợp sẵn trong `TextFormField`.
  * Không viết các đoạn code kiểm tra Regex phức tạp trực tiếp tại UI. Hãy viết các hàm validator dùng chung (như validate email, số điện thoại, mật khẩu dài tối thiểu, trường bắt buộc) và đặt chúng trong `lib/core/utils/` để tái sử dụng thống nhất (tương đương với việc khai báo schema qua Zod bên Web).
  * Định dạng hiển thị dữ liệu nhập (như số tiền tệ Việt Nam VNĐ, ngày tháng năm) sử dụng thư viện `intl`.

---

## 6. Reuse (Tái sử dụng mã nguồn)
* **UI Component dùng lại** → Đưa vào `lib/presentation/widgets/common/`.
* **Hàm tiện ích xử lý định dạng dữ liệu (Formatting, Utilities)** → Đưa vào `lib/core/utils/` (ví dụ: `currency_formatter.dart`, `date_formatter.dart`).
* **Hằng số cấu hình hệ thống** → Đưa vào `lib/core/constants/` (ví dụ: `api_constants.dart` quản lý các endpoint, `app_constants.dart` quản lý key lưu trữ local).

---

## 7. Clean Code (Quy tắc viết code sạch)
* **Không viết logic nghiệp vụ trong UI**:
  * UI chỉ đóng vai trò lắng nghe trạng thái (`ref.watch`) và kích hoạt sự kiện (`ref.read(...notifier).action()`).
  * Tất cả các tính toán logic (ví dụ: cộng dồn số lượng giỏ hàng, tính tổng tiền sau chiết khấu, kiểm tra điều kiện áp mã giảm giá) phải được thực hiện trong Notifier của Provider hoặc lớp Repository.
* **Tối ưu hóa Rebuild**:
  * Thêm từ khóa `const` trước các constructor của Widget tĩnh để tối ưu bộ nhớ và hiệu năng dựng hình của Flutter.
  * Chia nhỏ các cây widget phức tạp, cồng kềnh thành các Widget con kế thừa `ConsumerWidget` thay vì viết các phương thức `build` quá dài.
* **Linting & Code Generation**:
  * Luôn tuân thủ quy tắc phân tích tĩnh từ `analysis_options.yaml` (dựa trên `flutter_lints`). Giải quyết triệt để mọi cảnh báo (warnings) trước khi tạo Pull Request.
  * Khi thay đổi các chú thích sinh mã (Annotations) của Riverpod, chạy lệnh sau để cập nhật mã nguồn sinh ra tự động:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
