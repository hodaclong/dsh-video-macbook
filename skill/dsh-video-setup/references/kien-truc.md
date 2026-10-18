# Kien truc: DSH nap plugin nhu the nao

## Profile

- `~/.dsh` la DSH home (`DSH_HOME`). Moi profile la mot thu muc `~/.dsh/profiles/<ten>/`.
- Giao dien web dung profile ten `web`. Lenh `dsh web` tuong duong `dsh --profile web`.
- Trong profile:
  - `package.json`: `dependencies` (package da cai) + `dsh.profile.bundles` (**thu tu nap**).
  - `cordis.patch.yml`: lop ghi de cua nguoi dung, chay **sau** tat ca bundle.
  - `node_modules/`: package da cai.
- Ten profile co y nghia: `web` nhan template `['@deepseek-ai/dsh-base','@deepseek-ai/dsh-web-app']`. Ten khac (vi du `macvid`) chi nhan `['@deepseek-ai/dsh-base']`, tuc **khong co giao dien web**. Muon ban sao chay duoc thi phai co `@deepseek-ai/dsh-web-app` trong `bundles`.

## Bundle tu chen minh

Package plugin khai trong `package.json` cua no:

```jsonc
"dsh": {
  "bundle": { "patch": "./cordis.patch.yml" },   // host: tu chen dong mount
  "client": { "inject": ["@deepseek-ai/dsh-client-runtime"], "platform": "web" }
}
```

Va `cordis.patch.yml` cua no chua dung mot dong `insert`:

```yaml
- insert:
    - id: video-preview
      name: 'dsh-video-preview'
```

`id` o day la **entry id**; `name` phai bang **ten package** de DSH tim ra bundle client. Vi vay `dsh plugin --profile web add <package>` la du: DSH tu them package vao `dependencies`, tu them vao `bundles`, roi luc boot tu doc patch cua package.

Da kiem chung: tao profile sach `macvid`, chay `dsh plugin --profile macvid add dsh-video-preview@0.1.4` -> DSH in `dsh: initialized profile macvid` va tu ghi `dsh-video-preview` vao `bundles`.

## Client bundle duoc phuc vu the nao

- Thu muc ao: `/plugins/<package-name>/client.js?rev=<rev>` cho tung chunk, va dang combo `/plugins/??<id1>/client.js,<id2>/client.js&rev=<rev1+rev2>` cho lo nap dau.
- Trang HTML in ra cac the `<link rel="preload" as="script" href="plugins/??...">`. Chi can grep HTML la biet plugin nao da duoc nap vao trinh duyet.
- Trong HTML that (profile sach, 3 plugin), combo dau tien chua: `dsh-video-preview`, `@wisdoverse/dsh-inline-media-viewer`; combo thu hai chua `dsh-better-sidebar`.
- `rev` la hash theo mtime/size cua file client: request sai `rev` tra `404`, khong phai `401`.

## Xac thuc

- `dsh web` sinh mot token moi lan chay, in ra URL `http://127.0.0.1:<port>/?token=<token>`.
- `GET /?token=...` hop le -> dat cookie ky theo authority -> `303` ve `./`. Thieu token/cookie -> `401 unauthorized`.
- Route cua plugin (vi du `/video`) khong doi cookie, nhung co **Host fence**: chi nhan Host loopback hoac host trong `trustedHosts`, va tu choi `Sec-Fetch-Site: cross-site`.

## Duong di cua mot lan bam video

1. Nguoi dung bam file trong cay file cua sidebar (client `dsh-better-sidebar`).
2. Sidebar tim viewer dang ky theo duoi file -> `video` (client `dsh-video-preview`) -> render `<video controls>`.
3. Trinh duyet goi `GET /video?sessionId=..&path=..` (kem `Range` khi keo tien do).
4. Host `dsh-video-preview` kiem tra Host fence -> lay cwd cua session -> kiem `path` nam trong cwd -> `createReadStream` tra `200` hoac `206`.
