#!/usr/bin/env bash
# install-dsh-video.sh - cai "xem video trong DSH" (sidebar + inline) cho profile web.
#
# Chay duoc tren macOS (zsh/bash), Linux, va Windows Git Bash.
# Chay lai nhieu lan khong hong (idempotent).
#
#   bash scripts/install-dsh-video.sh                 # cai tu npm (can mang)
#   bash scripts/install-dsh-video.sh --offline       # cai tu vendor/*.tgz trong kit
#   bash scripts/install-dsh-video.sh --dry-run       # chi in lenh, khong chay
#   bash scripts/install-dsh-video.sh --profile web   # doi profile (mac dinh: web)
#   bash scripts/install-dsh-video.sh --skip-skill    # khong chep skill vao ~/.dsh/skills
#
set -u

PROFILE="web"
OFFLINE=0
DRY_RUN=0
SKIP_SKILL=0

DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Thu tu quan trong: better-sidebar TRUOC video-preview (video-preview can ctx.betterSidebar).
PKGS="dsh-better-sidebar@0.25.0 dsh-video-preview@0.1.4 @wisdoverse/dsh-inline-media-viewer@1.0.12"
DSH_WANT="0.2.0-rc.2"

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --offline) OFFLINE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --skip-skill) SKIP_SKILL=1; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Tham so la khong hieu: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s ==\n' "$*"; }
ok()   { printf '  [OK]   %s\n' "$*"; }
warn() { printf '  [CANH BAO] %s\n' "$*"; }
bad()  { printf '  [LOI]  %s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "  (dry-run) $*"; else "$@"; fi; }

step "0. Kiem tra moi truong"

command -v dsh >/dev/null 2>&1 || { bad "Khong thay lenh 'dsh'. Cai truoc: npm i -g @deepseek-ai/dsh@$DSH_WANT"; exit 1; }
ok "dsh: $(command -v dsh)"

DSH_VER="$(dsh --version 2>/dev/null | tr -d '[:space:]')"
if [ "$DSH_VER" = "$DSH_WANT" ]; then
  ok "phien ban DSH: $DSH_VER"
else
  warn "DSH dang la $DSH_VER, kit nay do tren $DSH_WANT"
  case "$DSH_VER" in
    0.1.7*) warn "DSH 0.1.7 thi phai dung dsh-better-sidebar@0.22.1, khong dung 0.25.0. Sua PKGS trong script nay truoc khi cai." ;;
    *)      warn "Neu bundle bi DSH tu choi (log ghi 'incompatible'), ha/nang phien ban plugin cho khop." ;;
  esac
fi

if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${NODE_MAJOR:-0}" -ge 20 ] 2>/dev/null; then ok "node: $(node -v)"; else bad "node $(node -v) qua cu, can >= 20"; exit 1; fi
else
  bad "Khong thay node. Cai Node >= 20 truoc."; exit 1
fi

if command -v pnpm >/dev/null 2>&1; then
  ok "pnpm: $(pnpm -v)"
else
  bad "Khong thay pnpm. Cai: npm i -g pnpm  (can >= 10)"; exit 1
fi

step "1. Cai 3 plugin vao profile '$PROFILE'"
if [ "$OFFLINE" = 1 ]; then
  ok "che do offline: dung tarball trong $KIT_DIR/vendor"
  for spec in $PKGS; do
    pkg="${spec%@*}"; ver="${spec##*@}"
    tgz="$KIT_DIR/vendor/${pkg//\//__}-$ver.tgz"
    [ -f "$tgz" ] || tgz="$(ls "$KIT_DIR"/vendor/*"$ver"*.tgz 2>/dev/null | head -n 1)"
    if [ -z "${tgz:-}" ] || [ ! -f "$tgz" ]; then
      bad "khong thay tarball cho $pkg@$ver trong vendor/"; exit 1
    fi
    # Tren Windows (Git Bash/MSYS) phai doi /d/... thanh D:/... truoc khi dua cho pnpm.
    if command -v cygpath >/dev/null 2>&1; then spec_path="$(cygpath -m "$tgz")"; else spec_path="$tgz"; fi
    say "  -> dsh plugin --profile $PROFILE add file:$spec_path"
    run dsh plugin --profile "$PROFILE" add "file:$spec_path" || { bad "cai $pkg that bai"; exit 1; }
  done
else
  for spec in $PKGS; do
    say "  -> dsh plugin --profile $PROFILE add $spec"
    run dsh plugin --profile "$PROFILE" add "$spec" || {
      bad "cai $spec that bai. Thu lai bang: bash scripts/install-dsh-video.sh --offline"; exit 1; }
  done
fi

step "2. Kiem tra danh sach bundle cua profile"
PKG_JSON="$DSH_HOME_DIR/profiles/$PROFILE/package.json"
if [ -f "$PKG_JSON" ]; then
  if [ "$DRY_RUN" = 1 ]; then
    say "  (dry-run) kiem tra bundles trong $PKG_JSON"
  else
    node - "$PKG_JSON" <<'NODE'
const fs = require('fs')
const file = process.argv[2]
const wanted = ['dsh-better-sidebar', 'dsh-video-preview', '@wisdoverse/dsh-inline-media-viewer']
let text = fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '')
const json = JSON.parse(text)
json.dsh = json.dsh || {}
json.dsh.profile = json.dsh.profile || {}
const bundles = json.dsh.profile.bundles || []
const missing = wanted.filter((name) => !bundles.includes(name))
if (missing.length > 0) {
  // better-sidebar phai dung truoc video-preview
  const head = bundles.filter((n) => !wanted.includes(n))
  const ordered = wanted.filter((n) => n !== '@wisdoverse/dsh-inline-media-viewer')
  const tail = bundles.filter((n) => wanted.includes(n) && !ordered.includes(n))
  json.dsh.profile.bundles = [...head, ...ordered, ...tail, ...missing.filter((n) => n === '@wisdoverse/dsh-inline-media-viewer')]
  fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n', 'utf8')
  console.log('  [OK]   da them vao bundles: ' + missing.join(', '))
} else {
  console.log('  [OK]   bundles da du 3 plugin')
}
NODE
  fi
else
  warn "chua thay $PKG_JSON (profile chua duoc tao)"
fi

step "3. Chep skill cho DSH"
SKILL_SRC="$KIT_DIR/skill/dsh-video-setup"
SKILL_DST="$DSH_HOME_DIR/skills/dsh-video-setup"
if [ "$SKIP_SKILL" = 1 ]; then
  warn "bo qua theo --skip-skill"
elif [ -d "$SKILL_SRC" ]; then
  run mkdir -p "$DSH_HOME_DIR/skills"
  if [ "$DRY_RUN" = 1 ]; then
    say "  (dry-run) chep $SKILL_SRC -> $SKILL_DST"
  else
    rm -rf "$SKILL_DST"
    cp -R "$SKILL_SRC" "$SKILL_DST"
    ok "skill: $SKILL_DST"
  fi
else
  warn "khong thay $SKILL_SRC"
fi

step "4. Xong. Lam tiep"
say "  1) Khoi dong lai DSH (bat buoc, vi co route host moi /video):"
say "       dsh --profile $PROFILE"
say "  2) Trong trinh duyet bam hard refresh: Cmd + Shift + R"
say "  3) Mo sidebar -> cay file -> bam mot file .mp4"
say "  4) Kiem tra lai bang: bash scripts/verify.sh --profile $PROFILE"
