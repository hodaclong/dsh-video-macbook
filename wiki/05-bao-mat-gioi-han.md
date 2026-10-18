# 05. Bảo mật và giới hạn

Đọc mục này trước khi mở DSH ra ngoài `127.0.0.1`.

## 1. Cảnh báo quan trọng của `dsh-better-sidebar` (từ v0.23.0)

Từ phiên bản 0.23.0, các route của sidebar **không còn kiểm tra đường dẫn nằm trong workspace** nữa. Cụ thể, các route sau đọc/ghi được **mọi đường dẫn mà tài khoản macOS đang chạy DSH có quyền**:

- `/sidebar/fs/tree`, `/sidebar/fs/trees`, `/sidebar/fs/read`, `/sidebar/fs/write`, `/sidebar/fs/rename`, `/sidebar/fs/remove`, `/sidebar/fs/mkdir`
- `/sidebar/file` (media), `/sidebar/html` (xem trước HTML), `/sidebar/upload`
- `archive.build` (nén thư mục bất kỳ)

Hệ quả: bất kỳ ai gọi được các route này đều có thể đọc file trong `~/.ssh`, `~/.dsh/.credentials.yaml`, ảnh trong `~/Pictures`... Đây là **thiết kế có chủ ý** của plugin (để làm việc với file ngoài dự án), không phải lỗi, nhưng phải biết.

Giảm rủi ro:

1. Chỉ chạy `dsh web` trên loopback (mặc định `127.0.0.1`).
2. Nếu buộc phải mở qua mạng (LAN, Tailscale), dùng `--trusted-host <host>` và chỉ tin máy của mình. Không bao giờ để lộ ra Internet công cộng.
3. Không cài extension lạ vào profile, vì plugin chạy được mã trên host.
4. Trên macOS, cân nhắc chạy DSH bằng tài khoản người dùng ít quyền nếu dùng ở nơi không tin cậy.

## 2. Route `/video/*` thì chặt hơn

`dsh-video-preview` **vẫn** kiểm tra an toàn:

- Bắt buộc `Host` là loopback (hoặc host trong `trustedHosts`).
- Từ chối request có `Sec-Fetch-Site: cross-site`.
- Nếu có `Origin` thì phải khớp host.
- `path` phải là đường dẫn tuyệt đối, và phải **nằm trong thư mục làm việc của session** (chống `..` vượt rào).
- Chỉ cho `GET` và `HEAD` (`POST` trả `405`).

Đã đo thật: request tới `C:/Windows/win.ini` với `cwd=D:/01-video-ai` trả `403`.

Điểm cần biết: route này **không đòi cookie**, chỉ dựa vào Host fence. Nghĩa là một tiến trình khác trên cùng máy vẫn gọi được nếu biết `sessionId` và đường dẫn. Với máy cá nhân một người dùng thì chấp nhận được; với máy nhiều người dùng thì không nên mở DSH.

## 3. Giới hạn kỹ thuật

| Giới hạn | Con số | Ghi chú |
|---|---|---|
| Media inline trong chat | 48 MiB / file | Của `@wisdoverse/dsh-inline-media-viewer`. Video ODG 38-90 MB không hiện inline |
| Media qua route sidebar cũ `/sidebar/file` | `mediaLimit`, mặc định 20 MB | Không áp cho `/video`. Muốn xem ảnh lớn thì tăng `mediaLimit` |
| Video qua `/video` | Không giới hạn dung lượng | Kiểm thật với file 56,6 MB |
| Codec | Trình duyệt quyết định | H.264/AAC `.mp4` an toàn nhất |
| Số input video | Trình duyệt mở nhiều thẻ video sẽ tốn RAM | Không mở 10 tab video cùng lúc |

## 4. Chuyện API key khi mang cấu hình sang máy khác

Kit này **không chứa**:

- `~/.dsh/.credentials.yaml`
- API key ElevenLabs, Lark, Composio, router model...
- Cookie, token phiên

Trong `config/cordis.patch.sample.yml` chỉ có **tên biến môi trường** (`apiKeyEnv: ROUTER_API_KEY`), không có giá trị. Trên MacBook phải tự đặt biến môi trường hoặc đăng nhập lại.

Khi nào ĐỪNG chép `cordis.patch.yml` từ máy này sang máy khác: khi file đó chứa bất kỳ chuỗi key/token thật nào. Máy Windows hiện tại đã kiểm: file này **chỉ** tham chiếu tên biến môi trường, không có key. Tuy vậy, cách an toàn nhất là **chép mẫu** trong `config/` rồi tự điền, đừng chép nguyên file thật.

## 5. Chạy DSH ở chế độ quyền nào

DSH có sẵn các preset quyền (`read-only`, `workspace-write`, `danger-full-access`). Với việc xem video thì không cần quyền ghi gì cả: **`read-only` là đủ**. Chỉ khi cần agent sửa file dự án mới nâng lên `workspace-write`.

Cấu hình mẫu nằm ở `config/cordis.patch.sample.yml` mục 2.

## 6. Ghi chú pháp lý và an toàn dữ liệu

- Kit chỉ tham chiếu tới các package **công khai trên npm**, không kèm mã nguồn đã sửa. Tarball trong `vendor/` là bản tải nguyên từ npm, chỉ để cài offline.
- Không có dữ liệu video cá nhân trong zip. Muốn xem video trên MacBook thì chép video sang, mở DSH ở thư mục chứa video.
