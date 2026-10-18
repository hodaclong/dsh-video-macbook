# 00. Tổng quan: xem video trong DSH

Cập nhật: 18/10/2026. Nguồn: một máy Windows đang chạy DSH `0.2.0-rc.2`, profile `web` (DSH home mặc định `%USERPROFILE%\.dsh`, trên macOS là `~/.dsh`).

## 1. "Xem video trong DSH" nghĩa là gì

DSH gốc (bundle `@deepseek-ai/dsh-base` + `@deepseek-ai/dsh-web-app`) không có sẵn chỗ phát video. Muốn xem video ngay trong DSH thì phải cài thêm plugin. Có **hai đường**, hai plugin khác nhau, chạy độc lập:

| Đường | Plugin | Cách dùng | Giới hạn |
|---|---|---|---|
| **A. Sidebar** (khuyến nghị cho video ODG) | `dsh-better-sidebar` + `dsh-video-preview` | Mở sidebar, mở cây file, bấm vào file `.mp4` là hiện khung phát có thanh tiến độ | Không giới hạn dung lượng. Cần container/codec mà trình duyệt giải mã được (H.264 mp4 thì OK) |
| **B. Trong khung chat** | `@wisdoverse/dsh-inline-media-viewer` | Nhắc đường dẫn file video trong câu trả lời, DSH tự chèn khung phát ngay dưới lượt chat đó | **Tối đa 48 MiB mỗi file**. Video render của ODG thường 40-90 MB nên phần lớn KHÔNG hiện được inline, phải dùng đường A |

Vì video render ODG (38-87 MB) vượt mốc 48 MiB của plugin inline, **đường A (sidebar) là đường chính**. Đường B chỉ tiện cho clip ngắn, ảnh, audio.

## 2. Bộ plugin đang chạy trên máy Windows

| Vai trò | Package | Phiên bản |
|---|---|---|
| Bắt buộc | `dsh-better-sidebar` | 0.25.0 |
| Bắt buộc | `dsh-video-preview` | 0.1.4 |
| Bắt buộc (đường B) | `@wisdoverse/dsh-inline-media-viewer` | 1.0.12 |
| Tùy chọn | `dshmarket` (chợ plugin trong GUI) | 1.66.9 |
| Tùy chọn | `dsh-client-ui-skins` (đổi skin) | 0.1.16 |
| Tùy chọn (đang tắt) | `open-sea-skin` | 1.2.3 |

Phụ thuộc: `dsh-video-preview` cần `dsh-better-sidebar >= 0.4.0`; dòng `dsh-better-sidebar 0.24+` cần DSH `0.2.0-rc.2+` (DSH `0.1.7` phải dùng `dsh-better-sidebar@0.22.1`).

## 3. Đã đo được gì (và chưa đo được gì)

Đo bằng máy trên Windows, ngày 18/10/2026:

- `dsh plugin --profile web list` → đúng 6 package, đúng phiên bản.
- `node test/route.test.mjs` trong `dsh-video-preview` → **19/19 route checks passed**: `GET 200`, `content-type video/mp4`, `accept-ranges bytes`, `range 206`, `content-range`, `suffix range 206`, `416` khi range vô lý, `403` khi path ngoài cwd, `405` khi POST, `HEAD 200`.
- Cả 3 plugin đều có bundle client đã build sẵn trong `node_modules` (đúng dạng `window.__ModuleLoader__.load(...)`).

Chưa kiểm bằng mắt: bấm phát video trong trình duyệt. Phần này phải do người dùng nhìn tận mắt, xem [03-kiem-tra-sau-cai.md](03-kiem-tra-sau-cai.md) mục "Kiểm bằng mắt".

## 4. Đường đi tắt

1. Cài DSH + Node + pnpm trên MacBook: [02-cai-dat-macbook.md](02-cai-dat-macbook.md)
2. Hoặc để DSH tự cài bằng skill: chép `skill/dsh-video-setup/` vào `~/.dsh/skills/` rồi bảo DSH "cài xem video trong sidebar".
3. Kiểm tra: [03-kiem-tra-sau-cai.md](03-kiem-tra-sau-cai.md)
4. Lỗi gặp phải: [04-loi-thuong-gap.md](04-loi-thuong-gap.md)
5. Trước khi mở DSH ra ngoài mạng LAN: đọc [05-bao-mat-gioi-han.md](05-bao-mat-gioi-han.md)
