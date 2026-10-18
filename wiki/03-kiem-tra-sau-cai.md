# 03. Kiểm tra sau khi cài

Có 3 mức: kiểm bằng máy (làm được ngay), kiểm sống qua HTTP (cần server đang chạy), kiểm bằng mắt (Sếp nhìn).

## A. Kiểm bằng máy

```bash
bash scripts/verify.sh --profile web
```

Script in bảng PASS/FAIL. Kết quả mong đợi (đã chạy thật trên máy Windows ngày 18/10/2026, profile sạch chỉ có 3 plugin):

```
== 2. package.json cua profile 'web' ==
  [PASS] dependency dsh-better-sidebar@0.25.0
  [PASS] bundles co dsh-better-sidebar
  [PASS] dependency dsh-video-preview@0.1.4
  [PASS] bundles co dsh-video-preview
  [PASS] dependency @wisdoverse/dsh-inline-media-viewer@1.0.12
  [PASS] bundles co @wisdoverse/dsh-inline-media-viewer
  [PASS] thu tu dung: better-sidebar truoc video-preview
== 4. Bundle client da build san ==
  [PASS] dsh-better-sidebar: dung dang bundle client (1287896 byte)
  [PASS] dsh-video-preview: ...
  [PASS] @wisdoverse/dsh-inline-media-viewer: dung dang bundle client (23957 byte)
== 5. Test route /video (Range/206) cua dsh-video-preview ==
  [PASS] 19 route checks passed
```

## B. Kiểm sống qua HTTP (chứng minh mạnh nhất, không cần nhìn)

Chạy `dsh --profile web`, copy URL có token mà nó in ra, rồi:

```bash
bash scripts/verify.sh --profile web \
  --url "http://127.0.0.1:3080/?token=<TOKEN>" \
  --video "/duong/dan/mot-file.mp4"
```

Kết quả đã đo thật (profile sạch `macvid` trên cổng 3099):

| Phép thử | Kết quả | Ý nghĩa |
|---|---|---|
| `GET /?token=...` | `303` | Token đúng, đã đặt cookie |
| Preload trong HTML | có `dsh-better-sidebar`, `dsh-video-preview`, `@wisdoverse/dsh-inline-media-viewer` | Cả 3 nửa client được nạp vào trình duyệt |
| Tải combo bundle client | `200`, 10.439.895 byte, có chuỗi `registerFileViewer` | Sidebar + trình xem video thật sự có mặt |
| `GET /video` (không Range) | `200`, `content-type: video/mp4`, `accept-ranges: bytes`, `content-length: 59316371` | File 56,6 MB được phục vụ trọn vẹn, vượt mốc 20 MB của sidebar |
| `GET /video` + `Range: bytes=0-1023` | `206`, `content-range: bytes 0-1023/59316371` | **Kéo được thanh tiến độ** |
| `GET /video` + `Range: bytes=-2048` | `206`, `content-range: bytes 59314323-59316370/59316371` | Range kiểu đuôi file chạy đúng |
| `GET /video` với path `C:/Windows/win.ini` | `403` | Chặn đọc file ngoài thư mục làm việc |

## C. Kiểm bằng mắt (phải do Sếp làm)

1. Mở sidebar, mở cây file, bấm một file `.mp4`.
2. Khung phát hiện ra. Bấm play: hình và tiếng chạy.
3. Kéo thanh tiến độ tới giữa clip: phải nhảy ngay, không đứng chờ tải hết.
4. Thử toàn màn hình và đổi tốc độ phát.
5. Trong chat, nhắc một file video nhỏ hơn 48 MiB: có khung phát inline.

Tôi (agent) **chưa** nhìn được màn hình trình duyệt, nên không tự nhận là "video chạy mượt". Bằng chứng tôi có là các con số ở mục A và B.

## D. Nếu có bước nào FAIL

Xem [04-loi-thuong-gap.md](04-loi-thuong-gap.md), hoặc bảng dài hơn trong `skill/dsh-video-setup/references/loi-thuong-gap.md`.
