# 06. Trong gói cài đặt có gì

Tên gói: `dsh-video-macbook-<ngày>.zip` (ví dụ `dsh-video-macbook-2026-10-18.zip`). Kèm file `.sha256`.

## Cấu trúc

```
dsh-video-macbook/
├── README.md                     Bắt đầu ở đây
├── wiki/                         Tài liệu tiếng Việt, đọc theo số
│   ├── 00-tong-quan.md           Xem video trong DSH là gì, 2 đường, giới hạn
│   ├── 01-kien-truc-xem-video.md Vì sao 3 plugin này, luồng dữ liệu
│   ├── 02-cai-dat-macbook.md     Cài từng bước trên MacBook
│   ├── 03-kiem-tra-sau-cai.md    Kiểm bằng máy / kiểm sống / kiểm bằng mắt
│   ├── 04-loi-thuong-gap.md      Lỗi và cách sửa
│   ├── 05-bao-mat-gioi-han.md    Cảnh báo bảo mật, giới hạn 48 MiB, API key
│   └── 06-goi-cai-dat.md         File này
├── skill/
│   └── dsh-video-setup/          Skill cho DSH (chép vào ~/.dsh/skills/)
│       ├── SKILL.md
│       └── references/
│           ├── kiem-tra-nhanh.md
│           ├── kien-truc.md
│           └── loi-thuong-gap.md
├── scripts/
│   ├── install-dsh-video.sh      Cài (macOS/Linux/Git Bash), có --offline, --dry-run
│   ├── verify.sh                 Kiểm tra 6 nhóm, có --url để kiểm sống
│   └── Install-DshVideo.ps1      Bản PowerShell cho Windows
├── config/
│   ├── plugin-manifest.json      Danh sách plugin + phiên bản đã ghim + lý do
│   ├── profile-package.template.json  Mẫu package.json của profile web
│   └── cordis.patch.sample.yml   Mẫu cấu hình (chỉ có TÊN biến môi trường)
├── vendor/                       Tarball npm để cài offline (tùy chọn)
└── dist/                         Chỗ chứa file zip xuất ra
```

## Cấu hình đã ghim (không đổi nếu không có lý do)

| Thành phần | Phiên bản | Vì sao ghim |
|---|---|---|
| `@deepseek-ai/dsh` | `0.2.0-rc.2` | npm tag `latest` vẫn là dòng `0.1.7-rc.2`; `dsh-better-sidebar 0.24+` cần `0.2.0-rc.2+` |
| `dsh-better-sidebar` | `0.25.0` | Bản mới nhất chạy được với DSH `0.2.0-rc.2`. Với DSH `0.1.7` dùng `0.22.1` |
| `dsh-video-preview` | `0.1.4` | Cần `dsh-better-sidebar >= 0.4.0` |
| `@wisdoverse/dsh-inline-media-viewer` | `1.0.12` | Bản đang chạy thật, có giới hạn 48 MiB |

## Cách chuyển sang MacBook

**Cách 1 (khuyến nghị): clone từ GitHub**

```bash
git clone https://github.com/hodaclong/dsh-video-macbook.git
cd dsh-video-macbook
bash scripts/install-dsh-video.sh
```

**Cách 2: dùng file zip**

1. Chép `dsh-video-macbook-<ngày>.zip` sang MacBook (AirDrop, USB, cloud).
2. Kiểm tra toàn vẹn: `shasum -a 256 -c dsh-video-macbook-<ngày>.zip.sha256`
3. Giải nén: `unzip dsh-video-macbook-<ngày>.zip -d ~/Downloads/`
4. Làm theo [02-cai-dat-macbook.md](02-cai-dat-macbook.md).

## Gói này KHÔNG chứa gì

- Không có API key, token, cookie, mật khẩu, `~/.dsh/.credentials.yaml`.
- Không có video, ảnh hay dữ liệu dự án riêng của người dùng.
- Không có `~/.dsh/profiles/web/pnpm-lock.yaml` của máy Windows (lockfile riêng của từng máy, tạo lại khi cài).
- Không sửa gì trong bộ skill reelcrew (`~/.reelcrew`).

## Tạo lại zip

```bash
cd /d/01-video-ai
zip -r dsh-video-macbook/dist/dsh-video-macbook-$(date +%Y-%m-%d).zip dsh-video-macbook \
  -x 'dsh-video-macbook/dist/*' -x 'dsh-video-macbook/.git/*' -x 'dsh-video-macbook/.rehearse.sh'
shasum -a 256 dist/dsh-video-macbook-*.zip > dist/dsh-video-macbook-*.zip.sha256
```
