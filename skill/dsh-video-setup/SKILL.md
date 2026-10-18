---
name: dsh-video-setup
description: "Cai va sua viec xem video trong DSH (DeepSeek Harness) tren may moi, dac biet la macOS/MacBook: sidebar phat duoc .mp4/.webm/.mov/.mkv/.avi co keo tien do (HTTP Range), va khung phat inline trong chat. Dung khi nguoi dung noi 'cai xem video trong dsh', 'dsh khong xem duoc video', 'sidebar khong phat video', 'chuyen dsh sang macbook', 'dsh video preview', hoac khi can kiem tra vi sao video trong DSH khong phat / khong keo duoc thanh tien do."
whenToUse: "Nguoi dung muon DSH xem/phat duoc video, muon chuyen bo cai dat xem video cua DSH sang may khac (MacBook), hoac dang gap loi video trong sidebar/in chat. Khong dung cho viec dung video bang reelcrew/ffmpeg."
---

# Cai "xem video trong DSH"

Bo 3 plugin: `dsh-better-sidebar` (khung sidebar + service `ctx.betterSidebar`), `dsh-video-preview` (trinh xem video trong sidebar + host route `/video/*` co HTTP Range), `@wisdoverse/dsh-inline-media-viewer` (chieu media ngay trong luot chat, toi da 48 MiB).

## Nguyen tac

- **Khong sua DSH**: chi cai plugin vao **profile** (`~/.dsh/profiles/<ten>/`), khong sua `node_modules/@deepseek-ai/*`.
- **Thu tu bat buoc**: `dsh-better-sidebar` phai duoc cai va nam trong `bundles` **truoc** `dsh-video-preview`, vi `dsh-video-preview` can service `ctx.betterSidebar` luc nap.
- **Phien ban**: DSH `0.2.0-rc.2` + `dsh-better-sidebar@0.25.0`. DSH `0.1.7-rc.*` phai dung `dsh-better-sidebar@0.22.1`. Lenh cai DSH phai ghi ro so phien ban (`@0.2.0-rc.2`), vi npm tag `latest` van la dong 0.1.7.
- **Phai khoi dong lai `dsh web`** sau khi cai (co route host moi), roi hard refresh trinh duyet (`Cmd+Shift+R`).
- Do la `dsh --version`, khong doan.

## Trinh tu

### 1. Do hien trang

```bash
node -v && pnpm -v && dsh --version
ls ~/.dsh/profiles/web/package.json && cat ~/.dsh/profiles/web/package.json
dsh plugin --profile web list
```

Neu `dsh` khong co tren PATH: `npm i -g @deepseek-ai/dsh@0.2.0-rc.2` (can Node >= 20, pnpm >= 10).

### 2. Cai

```bash
dsh plugin --profile web add dsh-better-sidebar@0.25.0
dsh plugin --profile web add dsh-video-preview@0.1.4
dsh plugin --profile web add @wisdoverse/dsh-inline-media-viewer@1.0.12
```

Lenh `dsh plugin ... add` tu tao profile neu chua co, tu them vao `dependencies` **va** `dsh.profile.bundles`. Khong can sua tay `cordis.patch.yml`.

Neu khong co mang: cai tu tarball, `dsh plugin --profile web add file:/duong/dan/dsh-video-preview-0.1.4.tgz`. Kit `dsh-video-macbook` co san `vendor/` va script `scripts/install-dsh-video.sh --offline`.

### 3. Khoi dong lai va kiem tra

```bash
dsh --profile web          # dung URL co token ma lenh nay in ra
```

Trong trinh duyet: hard refresh (`Cmd+Shift+R`) -> mo sidebar -> mo cay file -> bam file `.mp4`.

Kiem tra bang may (khong can nhin):

```bash
node ~/.dsh/profiles/web/node_modules/dsh-video-preview/test/route.test.mjs   # mong doi: 19 route checks passed
```

Kiem tra song: lay URL co token tu `dsh web`, roi

- `curl -s -c jar "$BASE/?token=$TOKEN" -o /dev/null -w '%{http_code}'` -> `303`
- `curl -s -b jar -o /dev/null -w '%{http_code}' -H 'Range: bytes=0-1023' -G --data-urlencode "sessionId=x" --data-urlencode "cwd=<thu muc video>" --data-urlencode "path=<file.mp4>" "$BASE/video"` -> `206`

Xem `references/kiem-tra-nhanh.md` de co lenh day du va y nghia tung ket qua.

### 4. Sua loi

Bang chan doan day du o `references/loi-thuong-gap.md`. Vai loi hay gap:

| Hien tuong | Nguyen nhan | Cach sua |
|---|---|---|
| Khong thay sidebar | Bundle bi DSH tu choi vi lech phien ban, hoac thieu trong `bundles` | Doc log khoi dong: `skipping profile bundle ... incompatible`. Doi dung phien ban plugin theo DSH, roi `dsh plugin --profile web add ...` lai |
| Hai sidebar | Mount trung id (vua co dong mount tay trong `cordis.patch.yml`, vua co bundle) | Xoa dong mount tay `better-sidebar` trong `~/.dsh/profiles/web/cordis.patch.yml` |
| Bam file mp4 ra man hinh chu / tai file | `dsh-video-preview` chua nap | Kiem bundle co trong `bundles`, khoi dong lai `dsh web`, hard refresh |
| Phat duoc nhung khong keo duoc thanh tien do | Route `/video` tra `200` thay vi `206` (hoac dang di qua `/sidebar/file`) | Kiem tra bang curl o buoc 3; khoi dong lai `dsh web` de nap lai route host |
| `curl http://127.0.0.1:3080/` tra 401 | Thieu token/cookie, khong phai loi cai dat | Dung dung URL co `?token=` ma `dsh web` in ra |
| Video > 48 MiB khong hien trong chat | Gioi han cua plugin inline | Xem qua sidebar (khong gioi han dung luong) |

## Gioi han phai noi ro voi nguoi dung

- Chat inline: toi da 48 MiB/file, chi voi file trong workspace cua session. Video render ODG (38-90 MB) **khong** hien inline duoc, phai xem qua sidebar.
- Codec: trinh duyet phai giai ma duoc (H.264 mp4 OK; vai kieu HEVC/AV1 se bao loi trong khung phat, khi do dung link tai).
- Route `/video/*` chi doc file **trong thu muc lam viec cua session**; muon mo video o dau thi mo DSH o thu muc cha cua video.
- Tu `dsh-better-sidebar` v0.23.0, cac route **cua sidebar** (fs, media, html, upload, archive) bo kiem tra workspace, doc/ghi duoc moi path ma tai khoan OS co quyen. Chi chay DSH o loopback hoac mang tin cay, dung mo ra Internet.
- Khong bao gio chua API key/token/cookie trong file cau hinh mang sang may khac.

## Nguon

- `dsh-better-sidebar`: https://github.com/omdsh-dev/DSH-better-sidebar
- `dsh-video-preview`: https://github.com/zemul/dsh-video-preview
- `dsh-inline-media-viewer`: https://github.com/Wisdoverse/dsh-inline-media-viewer-plugin
- Kien truc DSH (profile, bundle, client bundle): `references/kien-truc.md`
