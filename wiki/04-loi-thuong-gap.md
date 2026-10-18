# 04. Lỗi thường gặp

Bảng đầy đủ nằm trong skill: `skill/dsh-video-setup/references/loi-thuong-gap.md`. Dưới đây là các lỗi hay gặp nhất, kèm lỗi đã gặp thật khi đóng gói bộ này.

## Lỗi khi cài

### 1. `npm.ps1 cannot be loaded because running scripts is disabled` (Windows PowerShell)

Không phải lỗi DSH, mà là execution policy của PowerShell chặn file `.ps1` của npm.

```powershell
cmd /c "npm --version"
cmd /c "pnpm --version"
```

Hoặc dùng Git Bash.

### 2. `dsh: profile "web" does not exist`

Profile chưa được tạo. Tạo bằng chính lệnh cài plugin:

```bash
dsh plugin --profile web add dsh-better-sidebar@0.25.0
```

DSH sẽ in `dsh: initialized profile web` rồi mới cài. Sau đó `dsh web` chạy được.

### 3. `dsh --profile macvid web` báo `too many arguments. Expected 0 arguments but got 1: web.`

`web` là **lệnh riêng**, không phải tham số. Đúng:

```bash
dsh web                      # dùng profile tên web
dsh --profile macvid         # dùng profile khác, KHÔNG thêm chữ web
```

### 4. `SyntaxError: Unexpected token '﻿' ... is not valid JSON`

File `package.json` của profile bị ghi kèm BOM (thường do `Set-Content -Encoding UTF8` của PowerShell). Sửa bằng cách ghi lại không BOM:

```powershell
node -e "const fs=require('fs');const p=process.argv[1];const j=JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n','utf8')" "C:\Users\<ten>\.dsh\profiles\web\package.json"
```

### 5. DSH từ chối plugin vì lệch phiên bản

Log có dạng:

```
dsh: installation rejected: Plugin @deepseek-ai/dsh-web-app@0.0.1-rc.1 is incompatible with dsh 0.2.0-rc.2
dsh: to accept the risk, run: dsh plugin --profile <x> allow-version ... --accept-risk
```

Cách sửa đúng là **dùng đúng phiên bản** (`dsh-better-sidebar@0.25.0` cho DSH `0.2.0-rc.2`; `0.22.1` cho DSH `0.1.7-rc.2`), không phải tắt kiểm tra an toàn. Lệnh `allow-version ... --accept-risk` chỉ dùng khi biết rõ hậu quả: DSH có thể crash hoặc hỏng dữ liệu.

Lưu ý riêng: `@deepseek-ai/dsh-base` và `@deepseek-ai/dsh-web-app` thuộc về **bản cài DSH**, không cài từ npm. Profile tên `web` tự có 2 bundle này. Nếu tạo profile tên khác thì phải tự thêm `@deepseek-ai/dsh-web-app` vào `bundles` (nhưng đừng `dsh plugin add` nó, npm sẽ trả về bản 0.0.1-rc.1 không khớp).

### 6. Sidebar hiện hai lần

Có cả bundle `dsh-better-sidebar` **và** một dòng `insert` mount tay trong `~/.dsh/profiles/web/cordis.patch.yml`. Xóa dòng mount tay đó, khởi động lại.

## Lỗi khi dùng

### 7. Bấm file `.mp4` mà chỉ thấy chữ hoặc nút tải

`dsh-video-preview` chưa nạp. Kiểm:

```bash
node -e "const j=require(process.env.HOME+'/.dsh/profiles/web/package.json');console.log(j.dsh.profile.bundles)"
```

Phải thấy `dsh-video-preview`, và nó phải đứng **sau** `dsh-better-sidebar`. Rồi khởi động lại `dsh web` (route host chỉ nạp lúc boot) và `Cmd+Shift+R` trong trình duyệt.

### 8. Phát được nhưng không kéo được thanh tiến độ

Nghĩa là request không đi qua route `/video` (route này mới trả `206`), hoặc server chưa được khởi động lại. Kiểm bằng curl ở [03-kiem-tra-sau-cai.md](03-kiem-tra-sau-cai.md) mục B.

### 9. `curl http://127.0.0.1:3080/` trả `401`

Bình thường. DSH yêu cầu token: phải dùng đúng URL có `?token=` mà `dsh web` in ra. Token đổi mỗi lần chạy.

### 10. Video dài/nặng không hiện trong chat

Giới hạn 48 MiB của plugin inline. Xem qua sidebar.

### 11. Khung phát báo không hỗ trợ định dạng

Trình duyệt không giải mã được codec (HEVC/H.265, AV1, vài kiểu `.mov`/`.mkv`). Xuất lại H.264/AAC trong `.mp4`, hoặc dùng nút tải.

### 12. Trên Windows, gọi script bằng `bash` báo `No such file or directory`

`bash` trong PATH là WSL, không thấy đường dẫn `D:\`. Dùng Git Bash thật:

```powershell
& "C:\Program Files\Git\bin\bash.exe" -c "cd /d/01-video-ai/dsh-video-macbook && bash scripts/install-dsh-video.sh"
```

Thêm nữa: đừng truyền script dài qua `bash -c "..."` từ PowerShell khi đường dẫn có dấu cách, Git Bash sẽ cắt tham số ở dấu cách. Viết script ra file `.sh` rồi gọi theo file.
