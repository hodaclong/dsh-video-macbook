# vendor/ - tarball de cai offline

Cac file trong thu muc nay la **ban tai nguyen tu npm** (`npm pack`), dung cho `bash scripts/install-dsh-video.sh --offline` khi may MacBook khong co mang. Khong co gi bi sua doi.

| File | Package | Byte | SHA256 |
|---|---|---|---|
| `dsh-better-sidebar-0.25.0.tgz` | `dsh-better-sidebar@0.25.0` | 4.412.751 | `3cf573803d65f566cf7c480b452711b231aa21a1f6d016e4929b61afb00043f4` |
| `dsh-video-preview-0.1.4.tgz` | `dsh-video-preview@0.1.4` | 11.335 | `acc654f7396f3a12dc360299ad29f938b286d87341ed93d77dc98ea64fbd6f83` |
| `wisdoverse-dsh-inline-media-viewer-1.0.12.tgz` | `@wisdoverse/dsh-inline-media-viewer@1.0.12` | 20.855 | `2fdaea07837f87a356c443691c764a9b309b2eca007e84a95490bbd641e0e80e` |

Kiem tra lai:

```bash
shasum -a 256 vendor/*.tgz      # macOS
```

hoac PowerShell:

```powershell
Get-ChildItem vendor\*.tgz | Get-FileHash -Algorithm SHA256
```

## Luu y

- Cai offline ghi `dependencies` thanh `file:<duong dan tuyet doi toi kit>/vendor/...tgz`. **Khong xoa, khong di chuyen kit** sau khi cai offline, neu khong pnpm se mat nguon package. Muon chuyen sang kieu cai binh thuong thi chay lai `bash scripts/install-dsh-video.sh` khong kem `--offline`.
- Cai offline van can pnpm tai cac **dependency phu** cua plugin neu chung chua co trong store cua may. Neu hoan toan khong co mang, cach chac an nhat la chay `pnpm fetch` hoac cai truoc khi mat mang.
- `dsh-better-sidebar` ban npm nho hon ban trong `node_modules` (4,4 MB so voi 16,9 MB) vi npm pack khong kem file dev; phan chay that van du.
