# Loi thuong gap va cach sua

## Bang chan doan nhanh

| Hien tuong | Nguyen nhan (da gap that) | Cach sua |
|---|---|---|
| Khong thay sidebar ben phai | Bundle bi DSH tu choi luc boot (lech phien ban), hoac thieu trong `dsh.profile.bundles` | Doc log boot tim `skipping profile bundle ... incompatible`; doi dung phien ban, chay lai `dsh plugin --profile web add <pkg>` |
| Sidebar hien **hai lan** | Mount trung id: vua co bundle `dsh-better-sidebar`, vua co dong `insert` tay trong `cordis.patch.yml` | Xoa dong `insert` thu cong cho `better-sidebar` trong `~/.dsh/profiles/web/cordis.patch.yml`, khoi dong lai |
| Bam file `.mp4` hien man hinh chu hoac chi co nut tai | `dsh-video-preview` chua nap (hoac bi DSH tu choi) | Kiem `bundles` co `dsh-video-preview`, phai **sau** `dsh-better-sidebar`; khoi dong lai `dsh web`; hard refresh |
| Phat duoc nhung khong keo duoc thanh tien do | Route tra `200` thay vi `206`, tuc khong di qua `/video` | Kiem bang curl (xem `kiem-tra-nhanh.md`); khoi dong lai `dsh web` de nap lai route host |
| Khung phat hien ra nhung bao "khong ho tro dinh dang" | Trinh duyet khong giai ma duoc codec (HEVC/H.265, AV1, mot so .mov, .mkv) | Doi sang ban H.264/AAC (`.mp4`), hoac dung link tai; DSH van phuc vu file binh thuong |
| Video > 48 MiB khong hien trong chat | Gioi han cua `@wisdoverse/dsh-inline-media-viewer` | Xem qua sidebar (khong gioi han dung luong) |
| File nho cung khong hien trong chat | File nam ngoai workspace cua session | Mo DSH o thu muc cha cua file, hoac chuyen file vao do |
| `curl http://127.0.0.1:3080/` tra `401` | Thieu token/cookie | Dung dung URL co `?token=` do `dsh web` in ra. Khong phai loi cai dat |
| `curl .../plugins/<id>/client.js` tra `404` | Tham so `rev` sai, hoac id sai | Lay nguyen URL combo trong HTML (`grep -o 'plugins/??[^"]*'`), thay `&amp;` thanh `&`. Id la **ten package**, khong phai entry id |
| `bash: install-dsh-video.sh: No such file or directory` tren Windows | Goi bang WSL bash thay vi Git Bash | Dung `"C:\Program Files\Git\bin\bash.exe"`, hoac chay trong Git Bash |
| `npm.ps1 cannot be loaded because running scripts is disabled` | Execution policy cua PowerShell | Goi qua `cmd /c "npm ..."`, hoac dung Git Bash |
| `dsh: profile "X" does not exist` | Profile chua duoc tao | `dsh plugin --profile X add <package>` (lenh nay tu tao profile), roi moi `dsh --profile X` |
| `dsh --profile X web` bao `too many arguments` | `web` la lenh rieng, khong phai tham so | Dung `dsh web` (profile web), hoac `dsh --profile X` (khong them chu `web`) |
| `dsh web` bao `profile "web" does not exist` | Chua co profile web | Tao bang `dsh plugin --profile web add <package>`, hoac chay `dsh web` mot lan de DSH khoi tao template |
| Boot loi `SyntaxError: Unexpected token '﻿'` khi doc `package.json` | File JSON bi ghi kem BOM (thuong do `Set-Content -Encoding UTF8` cua PowerShell) | Ghi lai khong BOM: `node -e "fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n','utf8')"` |
| `EACCES` / `permission denied` khi cai global tren macOS | npm global dir thuoc root | Dung nvm, hoac `sudo npm i -g ...` (khuyen nghi nvm) |
| `pnpm: command not found` sau khi cai bang corepack | corepack chua `enable` | `corepack enable pnpm` hoac `npm i -g pnpm` |

## Cach doc log boot

```bash
dsh web 2>&1 | tee ~/dsh-boot.log
grep -iE 'skipping|incompatible|bundle|error' ~/dsh-boot.log
```

DSH in ro ten bundle bi bo qua va ly do. Day la noi nhanh nhat de biet plugin nao khong nap duoc.

## Cach kiem tra profile ma khong khoi dong GUI

```bash
dsh plugin --profile web list
```

Lenh nay in danh sach package kem phien ban, va bao loi neu profile hong.

## Khi bi DSH tu choi vi lech phien ban

DSH chan bundle khi `peerDependencies` cua plugin khong khop runtime, vi du:

```
dsh: installation rejected: Plugin @deepseek-ai/dsh-web-app@0.0.1-rc.1 is incompatible with dsh 0.2.0-rc.2:
peerDependencies {"@deepseek-ai/dsh-bash-env":"^0.0.1-rc.1", ...}
dsh: to accept the risk, run: dsh plugin --profile macvid allow-version <pkg>@<ver> --dsh-version 0.2.0-rc.2 --accept-risk
```

Hai cach xu ly, theo thu tu uu tien:

1. **Doi phien ban cho khop** (nen lam). Vi du voi DSH `0.2.0-rc.2` thi dung `dsh-better-sidebar@0.25.0`; voi DSH `0.1.7-rc.2` thi dung `0.22.1`.
2. **Mien tru** bang `dsh plugin ... allow-version ... --accept-risk` **chi khi biet ro minh dang lam gi**. Lenh nay tat kiem tra an toan; DSH co the crash hoac hong du lieu.

Luu y: `@deepseek-ai/dsh-base` va `@deepseek-ai/dsh-web-app` la bundle **thuoc ve ban cai DSH**, khong phai package cai tu npm. Profile ten `web` tu dong co 2 bundle nay. Neu tu tao profile ten khac (vi du `macvid`), phai them `@deepseek-ai/dsh-web-app` vao `bundles` bang tay; dung co `dsh plugin add @deepseek-ai/dsh-web-app` vi npm se tra ve ban 0.0.1-rc.1 khong khop.
