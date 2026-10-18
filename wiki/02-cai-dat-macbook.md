# 02. Cài trên MacBook (từng bước)

Mục tiêu: mở `dsh web` trên MacBook, bấm một file `.mp4` trong sidebar là xem được, không giật, kéo được thanh tiến độ.

Thời gian: khoảng 10 đến 15 phút. Dung lượng tải: khoảng 30 MB.

## Bước 0. Chuẩn bị

| Thứ cần | Yêu cầu | Kiểm tra |
|---|---|---|
| macOS | 13 trở lên (Apple Silicon hoặc Intel) | `sw_vers` |
| Node.js | >= 20 | `node -v` |
| pnpm | >= 10 | `pnpm -v` |
| Terminal | Terminal.app hoặc iTerm | |
| Mạng | có, để tải package từ npm | |

Nếu chưa có Node:

```bash
# cách 1: Homebrew
brew install node

# cách 2: nvm (khuyến nghị, đổi version dễ)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
exec zsh
nvm install 22
nvm alias default 22
```

Nếu chưa có pnpm:

```bash
npm i -g pnpm
pnpm -v      # phải >= 10
```

## Bước 1. Cài DSH, ghim đúng phiên bản

```bash
npm i -g @deepseek-ai/dsh@0.2.0-rc.2
dsh --version        # phải in ra 0.2.0-rc.2
```

Vì sao phải ghi rõ số phiên bản: npm tag `latest` của DSH hiện vẫn là dòng `0.1.7-rc.2`, còn `0.2.0-rc.2` nằm ở tag `next`. Bản `dsh-better-sidebar` dòng 0.24+ chỉ chạy với DSH `0.2.0-rc.2+`; lắp lệch là DSH tự chặn cả bundle (log ghi `skipping profile bundle ... incompatible`) và sidebar biến mất.

Nếu MacBook cố tình dùng DSH `0.1.7-rc.2` thì đổi lại: cài `dsh-better-sidebar@0.22.1` (xem bảng ở [00-tong-quan.md](00-tong-quan.md)).

## Bước 2. Cài 3 plugin xem video

Giải nén zip, rồi trong thư mục kit:

```bash
cd ~/Downloads/dsh-video-macbook
bash scripts/install-dsh-video.sh
```

Script làm đúng 5 việc, chạy lại nhiều lần cũng không hỏng:

1. Kiểm tra `dsh`, phiên bản DSH, Node, pnpm.
2. `dsh plugin --profile web add dsh-better-sidebar@0.25.0`
3. `dsh plugin --profile web add dsh-video-preview@0.1.4`
4. `dsh plugin --profile web add @wisdoverse/dsh-inline-media-viewer@1.0.12`
5. Chép skill vào `~/.dsh/skills/dsh-video-setup/` (nếu có trong kit).

Muốn làm tay thì chạy đúng 3 lệnh trên, theo đúng thứ tự đó. `dsh-better-sidebar` phải cài **trước** `dsh-video-preview`, vì `dsh-video-preview` cần service `ctx.betterSidebar` có sẵn lúc nạp.

Script tự thêm cả 3 package vào `dependencies` và `bundles` trong `~/.dsh/profiles/web/package.json` (thực ra lệnh `dsh plugin ... add` của DSH đã tự làm, script chỉ kiểm lại và sửa nếu thiếu).

Nếu MacBook không có mạng: thêm cờ `--offline`, script cài từ tarball trong `vendor/`:

```bash
bash scripts/install-dsh-video.sh --offline
```

Đã chạy thử chế độ này trên máy Windows vào profile sạch: cả 3 package cài được từ tarball, `bundles` tự thêm đúng thứ tự. Một lưu ý: ở chế độ offline, `dependencies` trong `package.json` ghi đường dẫn `file:` trỏ vào thư mục kit, nên **đừng xoá hay di chuyển kit** sau khi cài. Muốn chuyển sang kiểu cài thường thì chạy lại `bash scripts/install-dsh-video.sh` không kèm `--offline`.

## Bước 3. Chạy DSH

```bash
# mở DSH ở đúng thư mục chứa video, ví dụ:
cd ~/Videos/odg          # hoặc thư mục dự án video
dsh --profile web
```

- DSH in ra một URL dạng `http://127.0.0.1:3080/?token=...` và tự mở trình duyệt. **Dùng đúng URL đó**, đừng gõ tay URL không có token, sẽ bị `401`.
- Lần đầu sau khi cài plugin host (route `/video`), phải **thoát và chạy lại `dsh --profile web`** một lần.
- Sau đó trong trình duyệt bấm **`Cmd + Shift + R`** (hard refresh) để nạp client bundle mới.

## Bước 4. Xem video

**Đường A, sidebar (đường chính):**

1. Trong DSH, mở/gắn sidebar (nút sidebar ở góc trên, hoặc mở tab **Files** trong sidebar).
2. Trong cây file, đi tới thư mục video, ví dụ `videos/sapa-3n2d.../renders/`.
3. Bấm vào file `.mp4`. Khung phát hiện ra, có: play/pause, kéo tiến độ, đổi tốc độ, âm lượng, toàn màn hình, và link **tải** ở dưới.
4. Kiểm nhanh HTTP Range: kéo thanh tiến độ tới giữa clip. Nếu seek được ngay thì route `/video/*` đang trả `206` đúng.

**Đường B, ngay trong chat:**

- Nhắc đường dẫn file trong tin nhắn, ví dụ: `renders/clip-30s.mp4`, DSH sẽ chèn khung phát ngay dưới lượt đó.
- Chỉ hiện với file **<= 48 MiB** và nằm trong workspace của session. Muốn chỉnh: Settings -> **Media preview**: bật/tắt auto-render, số item tối đa mỗi lượt (1-30), chiều cao tối đa (160-1200 px).

## Bước 5. Kiểm tra lại

```bash
bash scripts/verify.sh
```

Script in ra bảng PASS/FAIL cho: DSH có trên PATH, đúng phiên bản, 3 package có trong `package.json`, 3 package có trong `bundles`, thư mục package tồn tại trong `node_modules`, bundle client tồn tại, và chạy test route của `dsh-video-preview`.

## Bước 6. (Tùy chọn) Chuyển nốt cấu hình DSH

Kit **không** kèm API key, token, cookie. Trên MacBook phải tự khai lại model:

1. Mở `~/.dsh/profiles/web/cordis.patch.yml`.
2. Chép mẫu từ `config/cordis.patch.sample.yml`, sửa `baseURL` thành địa chỉ router thật, giữ `apiKeyEnv: ROUTER_API_KEY`.
3. Đặt biến môi trường trước khi chạy DSH:

```bash
echo 'export ROUTER_API_KEY="..."' >> ~/.zshrc
exec zsh
dsh --profile web
```

Xem thêm [05-bao-mat-gioi-han.md](05-bao-mat-gioi-han.md) mục "Khi nào ĐỪNG chép cấu hình".

## Gỡ cài đặt

```bash
dsh plugin --profile web remove dsh-video-preview @wisdoverse/dsh-inline-media-viewer
# giữ sidebar nếu vẫn muốn dùng cây file:
dsh plugin --profile web remove dsh-better-sidebar
rm -rf ~/.dsh/skills/dsh-video-setup
```
