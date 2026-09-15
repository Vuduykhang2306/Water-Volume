# Water-Volume

Nguyên mẫu đầu tiên của ứng dụng giám sát chất lượng nước ao nuôi thuỷ sản
(tháng 8/2025). Một màn hình Flutter duy nhất, đọc thẳng bảng `water_quality`
trên Supabase và vẽ biểu đồ.

Đây là bước thử nghiệm để xác nhận đường dữ liệu ESP32 -> Supabase -> ứng dụng có
chạy được, trước khi viết lại thành sản phẩm hoàn chỉnh.

**Bản hoàn chỉnh:** [aquaoracle-app](https://github.com/Vuduykhang2306/aquaoracle-app)
— nhiều màn hình, dự báo bằng PatchTST, chatbot Gemini.
**Firmware:** [Esp32_AquaOracle_Programm](https://github.com/Vuduykhang2306/Esp32_AquaOracle_Programm)

## Ghi chú bảo mật

Bản gốc hardcode Supabase URL và anon key trong `lib/main.dart`. Lịch sử git đã
được viết lại bằng `git filter-repo` để gỡ; Supabase project cũ đã bị xoá.

## Trạng thái

Đã ngưng phát triển, giữ lại để tham chiếu.
