#!/usr/bin/env bash
# verify.sh - kiem tra "xem video trong DSH" da cai dung chua.
#
#   bash scripts/verify.sh --profile web
#   bash scripts/verify.sh --profile web --url "http://127.0.0.1:3080/?token=..." --video "/duong/dan/clip.mp4"
#
# --url: URL co token ma `dsh web` in ra, de kiem tra song (route /video, bundle client).
# --video: file mp4 that de thu HTTP Range (nên la file > 20 MB de chung minh khong bi gioi han).
# Exit code 0 = tat ca PASS, 1 = co FAIL.
set -u

PROFILE="web"
URL=""
VIDEO=""
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
PASS=0
FAIL=0
SKIP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --url) URL="${2:-}"; shift 2 ;;
    --video) VIDEO="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Tham so la khong hieu: $1" >&2; exit 2 ;;
  esac
done

p() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
f() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }
s() { SKIP=$((SKIP+1)); printf '  [SKIP] %s\n' "$*"; }
hdr() { printf '\n== %s ==\n' "$*"; }

PROFILE_DIR="$DSH_HOME_DIR/profiles/$PROFILE"

hdr "1. DSH"
if command -v dsh >/dev/null 2>&1; then
  p "dsh co tren PATH: $(command -v dsh)"
  p "phien ban: $(dsh --version 2>/dev/null)"
else
  f "khong thay lenh 'dsh' tren PATH (cai: npm i -g @deepseek-ai/dsh@0.2.0-rc.2)"
fi

hdr "2. package.json cua profile '$PROFILE'"
PKG_JSON="$PROFILE_DIR/package.json"
if [ -f "$PKG_JSON" ]; then
  p "co $PKG_JSON"
  node - "$PKG_JSON" <<'NODE'
const fs = require('fs')
const file = process.argv[2]
const json = JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''))
const deps = json.dependencies || {}
const bundles = (json.dsh && json.dsh.profile && json.dsh.profile.bundles) || []
const need = [
  ['dsh-better-sidebar', /^0\.(2[4-9]|[3-9]\d)/],
  ['dsh-video-preview', /^0\./],
  ['@wisdoverse/dsh-inline-media-viewer', /^1\./],
]
let fail = 0
for (const [name, range] of need) {
  if (deps[name] === undefined) { console.log(`  [FAIL] thieu dependency ${name}`); fail++; }
  else {
    const depVer = String(deps[name]).replace(/^[\^~>=<\s]+/, '')
    if (!range.test(depVer)) { console.log(`  [CANH BAO] ${name}@${deps[name]} khac phien ban kit do (xem config/plugin-manifest.json)`); }
    else console.log(`  [PASS] dependency ${name}@${deps[name]}`)
  }
  if (!bundles.includes(name)) { console.log(`  [FAIL] thieu trong bundles: ${name}`); fail++; }
  else console.log(`  [PASS] bundles co ${name}`)
}
const iSidebar = bundles.indexOf('dsh-better-sidebar')
const iVideo = bundles.indexOf('dsh-video-preview')
if (iSidebar !== -1 && iVideo !== -1) {
  if (iSidebar < iVideo) console.log('  [PASS] thu tu dung: better-sidebar truoc video-preview')
  else { console.log('  [FAIL] thu tu sai: video-preview phai nam SAU better-sidebar'); fail++ }
}
process.exit(fail === 0 ? 0 : 1)
NODE
  if [ $? -eq 0 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
else
  f "khong thay $PKG_JSON (profile chua tao)"
fi

hdr "3. Package da tai ve node_modules"
for name in dsh-better-sidebar dsh-video-preview "@wisdoverse/dsh-inline-media-viewer"; do
  dir="$PROFILE_DIR/node_modules/$name"
  if [ -d "$dir" ]; then
    ver="$(node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).version)" "$dir/package.json" 2>/dev/null || echo '?')"
    p "$name@$ver"
  else
    f "khong thay $dir"
  fi
done

hdr "4. Bundle client da build san"
check_client() {
  file="$1"; label="$2"
  if [ -f "$file" ]; then
    first="$(head -c 4000 "$file" | tr -d '\r\n')"
    case "$first" in
      *__ModuleLoader__*) p "$label: dung dang bundle client ($(wc -c < "$file" | tr -d ' ') byte)" ;;
      *) f "$label: co file nhung khong thay __ModuleLoader__ trong 4000 byte dau" ;;
    esac
  else
    f "$label: khong thay $file"
  fi
}
check_client "$PROFILE_DIR/node_modules/dsh-video-preview/client.js" "dsh-video-preview"
check_client "$PROFILE_DIR/node_modules/dsh-better-sidebar/lib/client.js" "dsh-better-sidebar"
check_client "$PROFILE_DIR/node_modules/@wisdoverse/dsh-inline-media-viewer/client/client.js" "@wisdoverse/dsh-inline-media-viewer"

hdr "5. Test route /video (Range/206) cua dsh-video-preview"
TEST="$PROFILE_DIR/node_modules/dsh-video-preview/test/route.test.mjs"
if [ -f "$TEST" ]; then
  out="$(node "$TEST" 2>&1 | tail -n 2)"
  case "$out" in
    *"19 route checks passed"*) p "19 route checks passed" ;;
    *) f "test route khong dat: $out" ;;
  esac
else
  s "khong thay test/route.test.mjs"
fi

hdr "6. Kiem tra song (tuy chon, can --url)"
if [ -z "$URL" ]; then
  s "khong truyen --url, bo qua phan kiem tra song"
else
  command -v curl >/dev/null 2>&1 || { s "khong thay curl"; }
  base="$(printf '%s' "$URL" | sed -E 's#(https?://[^/]+).*#\1#')"
  token="$(printf '%s' "$URL" | sed -nE 's/.*[?&]token=([^&]+).*/\1/p')"
  jar="$(mktemp)"
  if [ -z "$token" ]; then
    f "URL khong co token (dung URL ma 'dsh web' in ra)"
  else
    code="$(curl -s -c "$jar" -o /dev/null -w '%{http_code}' "$base/?token=$token")"
    [ "$code" = "303" ] && p "doi token lay cookie: 303" || f "doi token: http=$code (mong doi 303)"

    html="$(curl -s -b "$jar" -L "$base/")"
    for id in dsh-better-sidebar dsh-video-preview "@wisdoverse/dsh-inline-media-viewer"; do
      case "$html" in
        *"$id/client.js"*) p "HTML preload co bundle: $id" ;;
        *) f "HTML preload KHONG co bundle: $id" ;;
      esac
    done

    combo="$(printf '%s' "$html" | grep -o 'plugins/??[^"]*' | head -n 1 | sed 's/&amp;/\&/g')"
    if [ -n "$combo" ]; then
      code="$(curl -s -b "$jar" -o /dev/null -w '%{http_code}' "$base/$combo")"
      [ "$code" = "200" ] && p "tai bundle client combo: 200" || f "tai bundle client combo: http=$code"
    else
      s "khong tim thay combo bundle trong HTML"
    fi

    if [ -n "$VIDEO" ]; then
      size="$(wc -c < "$VIDEO" 2>/dev/null | tr -d ' ')"
      cwd_dir="$(cd "$(dirname "$VIDEO")" && pwd)"
      code="$(curl -s -b "$jar" -o /dev/null -w '%{http_code}' -H 'Range: bytes=0-1023' -G \
        --data-urlencode "sessionId=verify" --data-urlencode "cwd=$cwd_dir" --data-urlencode "path=$VIDEO" \
        "$base/video")"
      [ "$code" = "206" ] && p "GET /video co Range: 206 (file $size byte)" || f "GET /video co Range: http=$code (mong doi 206)"
      cr="$(curl -s -b "$jar" -o /dev/null -D - -H 'Range: bytes=0-1023' -G \
        --data-urlencode "sessionId=verify" --data-urlencode "cwd=$cwd_dir" --data-urlencode "path=$VIDEO" \
        "$base/video" | tr -d '\r' | grep -i '^content-range:')"
      [ -n "$cr" ] && p "$cr" || f "thieu header content-range"
      code="$(curl -s -b "$jar" -o /dev/null -w '%{http_code}' -G \
        --data-urlencode "sessionId=verify" --data-urlencode "cwd=$cwd_dir" --data-urlencode "path=/" \
        "$base/video")"
      [ "$code" = "403" ] || [ "$code" = "400" ] && p "chan path ngoai workspace: http=$code" || f "path ngoai workspace: http=$code (mong doi 400/403)"
    else
      s "khong truyen --video, bo qua thu Range tren file that"
    fi
  fi
  rm -f "$jar"
fi

hdr "Ket qua"
printf '  PASS=%s  FAIL=%s  SKIP=%s\n' "$PASS" "$FAIL" "$SKIP"
printf '  Kiem bang mat (khong do bang may duoc): mo sidebar, bam file .mp4, thu keo thanh tien do.\n'
[ "$FAIL" -eq 0 ] || exit 1
exit 0
