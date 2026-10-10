# Water-Volume

Nguyên mẫu đầu tiên của ứng dụng giám sát chất lượng nước ao nuôi thuỷ sản
(tháng 8/2025). Chỉ có một màn hình Flutter, đọc thẳng bảng `water_quality`
trên Supabase rồi vẽ biểu đồ.

Tôi làm bản này để thử xem đường dữ liệu ESP32 -> Supabase -> ứng dụng có chạy
được không, trước khi viết lại thành bản hoàn chỉnh.

Bản hoàn chỉnh: [aquaoracle-app](https://github.com/Vuduykhang2306/aquaoracle-app),
có nhiều màn hình, dự báo bằng PatchTST và chatbot Gemini.

Firmware: [Esp32_AquaOracle_Programm](https://github.com/Vuduykhang2306/Esp32_AquaOracle_Programm)

## Ghi chú bảo mật

Bản gốc hardcode Supabase URL và anon key trong `lib/main.dart`. Tôi đã viết
lại lịch sử git bằng `git filter-repo` để gỡ chúng ra, và Supabase project cũ
đã bị xoá.

## Trạng thái

Đã ngừng phát triển, để lại làm tham khảo.
