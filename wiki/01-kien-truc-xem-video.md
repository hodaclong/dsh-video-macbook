# 01. Kiến trúc: vì sao cài 3 plugin là xem được video

## 1. DSH tổ chức theo profile + bundle

- DSH home: `~/.dsh` (Windows: `C:\Users\<ten>\.dsh`).
- Mỗi profile là một thư mục riêng: `~/.dsh/profiles/<tên>/`. Giao diện web dùng profile tên **`web`**.
- Trong profile có `package.json`:

```jsonc
{
  "dependencies": { /* các package plugin đã cài */ },
  "dsh": { "profile": { "bundles": [ /* thứ tự nạp plugin */ ] } }
}
```

- `bundles` là **thứ tự nạp**. `cordis.patch.yml` trong cùng thư mục là lớp ghi đè của người dùng, chạy **sau** tất cả bundle.
- Một package muốn tự cắm mình vào DSH thì khai trong `package.json` của nó:

```jsonc
"dsh": { "bundle": { "patch": "./cordis.patch.yml" }, "client": { "platform": "web" } }
```

Khi package có mặt trong `bundles`, DSH đọc `cordis.patch.yml` của nó và chèn dòng mount. Đó là lý do **không phải sửa file cấu hình bằng tay**: chỉ cần `dsh plugin --profile web add <package>`, DSH tự thêm vào `dependencies` **và** `bundles`.

Đã kiểm chứng: tạo profile trắng tên `macvid` rồi `dsh plugin --profile macvid add dsh-video-preview@0.1.4` → DSH tự in `dsh: initialized profile macvid` và tự thêm `dsh-video-preview` vào `bundles`.

## 2. Bốn mảnh ghép của việc xem video

```
┌──────────────────────── DSH Web GUI (trình duyệt) ────────────────────────┐
│  khung chat                         │  sidebar (do dsh-better-sidebar vẽ) │
│  [video inline]                     │  cây file → bấm .mp4 → [khung phát] │
└───────▲─────────────────────────────┴──────────────▲─────────────────────┘
        │ /inline-media/*                            │ /video/<path>
        │                                            │ (HTTP Range 206)
┌───────┴────────────────────────────────────────────┴─────────────────────┐
│  DSH host (tiến trình `dsh web`)                                          │
│   • dsh-better-sidebar: mở service ctx.betterSidebar + cây file + tab     │
│   • dsh-video-preview : đăng ký viewer 'video' + route /video/*           │
│   • @wisdoverse/dsh-inline-media-viewer: chiếu media trong lượt chat      │
└───────────────────────────────────────────────────────────────────────────┘
```

1. **`dsh-better-sidebar`** dựng thanh sidebar (cây file, tab, editor) và mở service `ctx.betterSidebar` cho plugin khác. Hai điểm mở rộng: `registerTab` (thêm tab) và `registerFileViewer` (thêm trình xem file). Sidebar gốc của DSH chỉ có image / pdf / markdown / html / code / binary-download, **không có video**.
2. **`dsh-video-preview`** gọi `ctx.betterSidebar.registerFileViewer` để đăng ký viewer id `video` cho các đuôi `.mp4 .m4v .webm .mov .qt .mkv .avi .wmv .flv .ogv .ogg .mpeg .mpg .3gp .3g2 .m2ts`, và tự mở một **host route `/video/*`** đọc file bằng `createReadStream`.
3. Vì sao phải có route riêng: route media sẵn có của sidebar (`/sidebar/file`) **không hỗ trợ HTTP Range** (đọc cả file vào RAM, trả `200`) nên không kéo được thanh tiến độ, lại còn bị chặn bởi `mediaLimit` (mặc định 20 MB). Route `/video/*` trả `206 Partial Content` (kèm `If-Range`, `bytes=-N`), không giới hạn dung lượng → seek, tua, đổi tốc độ, toàn màn hình đều chạy.
4. **`@wisdoverse/dsh-inline-media-viewer`** không liên quan tới sidebar: nó chiếu media **ngay trong lượt chat** khi đường dẫn được nhắc tới. File local bị giới hạn 48 MiB và phải nằm trong workspace của session.

## 3. Đường dẫn file trong sidebar tính từ đâu

Route `/video/*` nhận đường dẫn file và kiểm tra nằm trong **thư mục làm việc của session** (cwd), chống `..` vượt rào, chống cross-site bằng Host fence giống `/api`. Nghĩa là: muốn bấm mở video trong sidebar thì **session DSH phải đang mở ở thư mục chứa video** (hoặc thư mục cha của nó). Ví dụ mở DSH ở `D:\01-video-ai` thì mở được mọi video trong `videos\<slug>\renders\`.

Lưu ý ngược lại: từ `dsh-better-sidebar` v0.23.0, các route **của sidebar** (`/sidebar/fs/*`, `/sidebar/file`, `/sidebar/html`, upload, archive) **đã bỏ kiểm tra nằm trong workspace**, tức đọc/ghi được mọi path mà tài khoản macOS có quyền. Route `/video/*` của `dsh-video-preview` vẫn giữ kiểm tra cwd. Chi tiết rủi ro: [05-bao-mat-gioi-han.md](05-bao-mat-gioi-han.md).

## 4. Client bundle được phục vụ thế nào

Mỗi plugin có hai nửa: host (Node, đăng ký route/service) và client (bundle trình duyệt). DSH phục vụ client bundle tại `/plugins/<entry-id>/client.js`, và chỉ cho tải khi request đã qua cổng xác thực của DSH (xem mục 5). Nửa host đổi thì phải **khởi động lại `dsh web`**; nửa client đổi chỉ cần **hard refresh** (`Cmd+Shift+R`).

## 5. Vì sao `curl http://127.0.0.1:3080/` trả 401

`dsh web` khi khởi động in ra một URL có token, ví dụ `http://127.0.0.1:3080/?token=...`. Lần GET đầu tiên vào `/` kèm token sẽ được đặt cookie ký theo authority rồi chuyển hướng về `./`. Mọi request thiếu token/cookie đều nhận `401 unauthorized`. Đây **không phải lỗi cài đặt**. Muốn kiểm tra bằng dòng lệnh thì phải lấy URL có token do `dsh web` in ra, xem [03-kiem-tra-sau-cai.md](03-kiem-tra-sau-cai.md).
