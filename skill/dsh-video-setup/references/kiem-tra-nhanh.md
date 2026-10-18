# Kiem tra nhanh (do bang may, khong can nhin)

Moi so duoi day la ket qua **do that** tren may Windows ngay 18/10/2026, DSH 0.2.0-rc.2, profile `web`.

## 1. Danh sach plugin

```bash
dsh plugin --profile web list
```

Mong doi (it nhat 3 dong nay):

```
├── @wisdoverse/dsh-inline-media-viewer@1.0.12
├── dsh-better-sidebar@0.25.0
├── dsh-video-preview@0.1.4
```

## 2. Profile co dung bundle va dung thu tu

```bash
node -e "const j=require(process.env.HOME+'/.dsh/profiles/web/package.json');console.log(j.dsh.profile.bundles)"
```

Mong doi: `['@deepseek-ai/dsh-base','@deepseek-ai/dsh-web-app','dsh-better-sidebar','dsh-video-preview','@wisdoverse/dsh-inline-media-viewer']`.
Dieu bat buoc: `dsh-better-sidebar` dung **truoc** `dsh-video-preview`.

## 3. Test route /video cua plugin (khong can chay server)

```bash
node ~/.dsh/profiles/web/node_modules/dsh-video-preview/test/route.test.mjs
```

Ket qua that:

```
✓ GET 200            ✓ content-type video/mp4   ✓ accept-ranges bytes
✓ full body equals file   ✓ range 206   ✓ content-range   ✓ slice 0..99
✓ open-ended range 206    ✓ slice 100..end   ✓ suffix range 206
✓ suffix slice       ✓ unsatisfiable 416   ✓ 416 content-range */
✓ outside-cwd 403    ✓ relative path 400   ✓ cross-site 403
✓ HEAD 200           ✓ HEAD empty body   ✓ POST 405
19 route checks passed
```

19/19 nghia la: phat duoc, keo duoc tien do, chan duoc path ngoai workspace, chan cross-site.

## 4. Kiem tra song (server dang chay)

Lay URL ma `dsh web` in ra, dang `http://127.0.0.1:3080/?token=<TOKEN>`.

```bash
BASE=http://127.0.0.1:3080
TOKEN=<dan token vao day>
JAR=$(mktemp)

# 4.1 doi token lay cookie -> 303
curl -s -c "$JAR" -o /dev/null -w '%{http_code}\n' "$BASE/?token=$TOKEN"

# 4.2 HTML co preload du 3 bundle client
curl -s -b "$JAR" -L "$BASE/" | grep -o 'plugins/??[^"]*' | tr ',' '\n' | grep -E 'dsh-better-sidebar|dsh-video-preview|inline-media'

# 4.3 tai duoc bundle client (thay &amp; bang & truoc khi goi)
curl -s -b "$JAR" -o /dev/null -w '%{http_code}\n' "$BASE/plugins/??dsh-video-preview/client.js&rev=<REV>"
```

Ket qua that tren may Windows (profile sach, chi cai 3 plugin):

| Lenh | Ket qua |
|---|---|
| `GET /?token=...` | `303` (dat cookie) |
| preload trong HTML | co `dsh-video-preview`, `dsh-better-sidebar`, `@wisdoverse/dsh-inline-media-viewer` |
| combo bundle client | `200`, 10.439.895 byte, trong do co chuoi `registerFileViewer` |
| `GET /video` (khong Range) | `200`, `content-type: video/mp4`, `accept-ranges: bytes`, `content-length: 59316371` |
| `GET /video` + `Range: bytes=0-1023` | `206`, `content-range: bytes 0-1023/59316371`, `content-length: 1024` |
| `GET /video` + `Range: bytes=-2048` | `206`, `content-range: bytes 59314323-59316370/59316371` |
| `GET /video` voi path ngoai cwd (`C:/Windows/win.ini`) | `403` |

Con so `59316371` = 56,6 MB, tuc la **vuot xa** `mediaLimit` 20 MB cua sidebar. Chung minh route `/video` khong bi gioi han dung luong.

Dang curl day du cho mot file that:

```bash
VIDEO=/duong/dan/clip.mp4
CWD=$(dirname "$VIDEO")
curl -s -b "$JAR" -o /dev/null -D - -H 'Range: bytes=0-1023' -G \
  --data-urlencode "sessionId=verify" \
  --data-urlencode "cwd=$CWD" \
  --data-urlencode "path=$VIDEO" \
  "$BASE/video"
```

Luu y ve tham so: route `/video` nhan `sessionId`, `path` (bat buoc), `cwd` (tuy chon, dung khi `sessionId` khong ton tai). Khi `sessionId` la session that, DSH lay thu muc lam viec tu header cua session do.

## 5. Kiem bang mat (khong do bang may duoc)

1. Mo sidebar, mo cay file, bam mot file `.mp4`.
2. Khung phat hien ra, co thanh tien do. Keo tới giua clip: phai nhay ngay (seek = `206`).
3. Thu doi toc do va toan man hinh.
4. Trong chat, nhac mot file nho (`< 48 MiB`) va xem no co hien khung phat khong.

Khong tu nhan la video "chay muot" neu chua nhin bang mat.
