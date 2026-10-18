# dsh-video-macbook

Bộ cài + tài liệu để **DSH xem được video ngay trong giao diện web** (sidebar và trong chat), đóng gói từ máy Windows của Sếp để mang sang MacBook.

Xuất ngày 18/10/2026. Nguồn: DSH `0.2.0-rc.2`, profile `web`, 3 plugin đã chạy thật.

## Làm gì được sau khi cài

- Bấm file `.mp4 / .webm / .mov / .mkv / .avi` trong sidebar là phát được, **kéo được thanh tiến độ** (route `/video` trả HTTP `206`), không giới hạn dung lượng.
- File video nhỏ hơn 48 MiB nhắc trong chat thì hiện khung phát inline.
- Video render của ODG (38-90 MB) xem qua sidebar, vì plugin inline chỉ nhận tới 48 MiB.

## Cài trong 3 lệnh

```bash
npm i -g @deepseek-ai/dsh@0.2.0-rc.2
cd ~/Downloads/dsh-video-macbook
bash scripts/install-dsh-video.sh
dsh --profile web
```

Rồi trong trình duyệt bấm `Cmd + Shift + R`, mở sidebar, bấm một file `.mp4`.

Không có mạng thì cài từ tarball kèm sẵn: `bash scripts/install-dsh-video.sh --offline`. Lưu ý: ở chế độ offline, `package.json` ghi đường dẫn `file:` trỏ vào thư mục kit, nên **đừng xoá hay di chuyển thư mục kit** sau khi cài; muốn cài lại kiểu bình thường thì chạy `bash scripts/install-dsh-video.sh` (không có `--offline`).

Trên Windows, bản PowerShell cần bật bypass execution policy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Install-DshVideo.ps1
```

## Kiểm tra

```bash
bash scripts/verify.sh --profile web
# kiểm sống, chứng minh route /video trả 206:
bash scripts/verify.sh --profile web --url "http://127.0.0.1:3080/?token=<TOKEN>" --video "/duong/dan/clip.mp4"
```

## Đọc gì trước

| Muốn biết | Đọc |
|---|---|
| Tổng quan, chọn đường nào cho video của mình | [wiki/00-tong-quan.md](wiki/00-tong-quan.md) |
| Cài trên MacBook từng bước | [wiki/02-cai-dat-macbook.md](wiki/02-cai-dat-macbook.md) |
| Kiểm tra đã ăn chưa | [wiki/03-kiem-tra-sau-cai.md](wiki/03-kiem-tra-sau-cai.md) |
| Lỗi gặp phải | [wiki/04-loi-thuong-gap.md](wiki/04-loi-thuong-gap.md) |
| Trước khi mở DSH ra khỏi máy | [wiki/05-bao-mat-gioi-han.md](wiki/05-bao-mat-gioi-han.md) |
| Trong gói có gì, chuyển sang Mac thế nào | [wiki/06-goi-cai-dat.md](wiki/06-goi-cai-dat.md) |

## Dùng skill cho DSH

`scripts/install-dsh-video.sh` tự chép skill vào `~/.dsh/skills/dsh-video-setup/`. Sau đó trong DSH chỉ cần nói:

> cài xem video trong sidebar

DSH sẽ đọc skill và tự làm theo. Skill cũng chứa bảng chẩn đoán lỗi, dùng được khi video không phát.

## Phạm vi và điều chưa kiểm

Đã đo bằng máy: cài đặt, danh sách bundle, bundle client được phục vụ (`200`), route `/video` (`200` / `206` / `416` / `403`, test 19/19), file 56,6 MB vượt giới hạn 20 MB của sidebar.

**Chưa** kiểm: hình ảnh thật trong trình duyệt (cần Sếp nhìn), và toàn bộ luồng trên macOS (bộ này đóng gói từ Windows, chưa có máy Mac để chạy thử). Xem [wiki/03-kiem-tra-sau-cai.md](wiki/03-kiem-tra-sau-cai.md) mục C.

## Không có trong gói

API key, token, cookie, `~/.dsh/.credentials.yaml`, video/ảnh dự án. Xem [wiki/06-goi-cai-dat.md](wiki/06-goi-cai-dat.md).
