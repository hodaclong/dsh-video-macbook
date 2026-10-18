<#
.SYNOPSIS
  Cai "xem video trong DSH" tren Windows (ban PowerShell cua install-dsh-video.sh).

.DESCRIPTION
  Cai 3 plugin vao profile web, kiem tra bundles, chep skill vao %USERPROFILE%\.dsh\skills.
  Chay lai nhieu lan khong hong.

.PARAMETER Profile
  Ten profile, mac dinh "web".

.PARAMETER Offline
  Cai tu vendor\*.tgz thay vi tai tu npm.

.PARAMETER DryRun
  Chi in lenh, khong chay.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\Install-DshVideo.ps1
  powershell -ExecutionPolicy Bypass -File scripts\Install-DshVideo.ps1 -Profile macvid -DryRun
#>
[CmdletBinding()]
param(
  [string]$Profile = 'web',
  [switch]$Offline,
  [switch]$DryRun,
  [switch]$SkipSkill
)

$ErrorActionPreference = 'Stop'
$KitDir = Split-Path -Parent $PSScriptRoot
$DshHomeDir = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$Pkgs = @(
  'dsh-better-sidebar@0.25.0',
  'dsh-video-preview@0.1.4',
  '@wisdoverse/dsh-inline-media-viewer@1.0.12'
)
$DshWant = '0.2.0-rc.2'

function Say  ($m) { Write-Host $m }
function Step ($m) { Write-Host "`n== $m ==" }
function Ok   ($m) { Write-Host "  [OK]   $m" }
function Warn ($m) { Write-Host "  [CANH BAO] $m" -ForegroundColor Yellow }
function Bad  ($m) { Write-Host "  [LOI]  $m" -ForegroundColor Red }

Step '0. Kiem tra moi truong'
$dsh = Get-Command dsh -ErrorAction SilentlyContinue
if (-not $dsh) { Bad "Khong thay lenh 'dsh'. Cai: npm i -g @deepseek-ai/dsh@$DshWant"; exit 1 }
Ok "dsh: $($dsh.Source)"
$ver = (& dsh --version 2>&1 | Out-String).Trim()
if ($ver -eq $DshWant) { Ok "phien ban DSH: $ver" } else { Warn "DSH dang la $ver (kit do tren $DshWant)" }
if (Get-Command node -ErrorAction SilentlyContinue) { Ok "node: $(node -v)" } else { Bad 'Khong thay node (can >= 20)'; exit 1 }
if (Get-Command pnpm -ErrorAction SilentlyContinue) { Ok "pnpm: $(pnpm -v)" } else { Warn 'Khong thay pnpm tren PATH; DSH se tu goi qua shim cua no' }

Step "1. Cai 3 plugin vao profile '$Profile'"
foreach ($spec in $Pkgs) {
  if ($Offline) {
    $name = $spec.Substring(0, $spec.LastIndexOf('@'))
    $v = $spec.Substring($spec.LastIndexOf('@') + 1)
    $tgz = Get-ChildItem (Join-Path $KitDir 'vendor') -Filter "*$v*.tgz" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $tgz) { Bad "khong thay tarball cho $name@$v trong vendor\"; exit 1 }
    Say "  -> dsh plugin --profile $Profile add file:$($tgz.FullName)"
    if (-not $DryRun) { & dsh plugin --profile $Profile add "file:$($tgz.FullName)" } else { Say '  (dry-run)' }
  } else {
    Say "  -> dsh plugin --profile $Profile add $spec"
    if (-not $DryRun) { & dsh plugin --profile $Profile add $spec } else { Say '  (dry-run)' }
  }
}

Step '2. Kiem tra danh sach bundle cua profile'
$pkgJson = Join-Path $DshHomeDir "profiles\$Profile\package.json"
if (Test-Path $pkgJson) {
  if ($DryRun) { Say "  (dry-run) kiem tra $pkgJson" } else {
    $js = @'
const fs = require('fs')
const file = process.argv[2]
const wanted = ['dsh-better-sidebar', 'dsh-video-preview', '@wisdoverse/dsh-inline-media-viewer']
const json = JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''))
json.dsh = json.dsh || {}; json.dsh.profile = json.dsh.profile || {}
const bundles = json.dsh.profile.bundles || []
const missing = wanted.filter((n) => !bundles.includes(n))
if (missing.length > 0) {
  const head = bundles.filter((n) => !wanted.includes(n))
  const ordered = ['dsh-better-sidebar', 'dsh-video-preview']
  const tail = bundles.filter((n) => wanted.includes(n) && !ordered.includes(n))
  json.dsh.profile.bundles = [...head, ...ordered, ...tail, ...missing.filter((n) => n === '@wisdoverse/dsh-inline-media-viewer')]
  fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n', 'utf8')
  console.log('  [OK]   da them vao bundles: ' + missing.join(', '))
} else { console.log('  [OK]   bundles da du 3 plugin') }
'@
    $tmp = Join-Path $env:TEMP 'dsh-bundles-check.js'
    Set-Content -Path $tmp -Value $js -Encoding UTF8
    node $tmp $pkgJson
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
} else { Warn "chua thay $pkgJson (profile chua duoc tao)" }

Step '3. Chep skill cho DSH'
$skillSrc = Join-Path $KitDir 'skill\dsh-video-setup'
$skillDst = Join-Path $DshHomeDir 'skills\dsh-video-setup'
if ($SkipSkill) { Warn 'bo qua theo -SkipSkill' }
elseif (Test-Path $skillSrc) {
  if ($DryRun) { Say "  (dry-run) chep $skillSrc -> $skillDst" } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillDst) | Out-Null
    if (Test-Path $skillDst) { Remove-Item $skillDst -Recurse -Force }
    Copy-Item $skillSrc $skillDst -Recurse
    Ok "skill: $skillDst"
  }
} else { Warn "khong thay $skillSrc" }

Step '4. Xong. Lam tiep'
Say "  1) Khoi dong lai DSH:  dsh plugin --profile $Profile list   (kiem tra)  roi  dsh web"
Say '  2) Trinh duyet: Ctrl + Shift + R'
Say '  3) Mo sidebar -> cay file -> bam mot file .mp4'
Say "  4) Kiem tra lai: bash scripts/verify.sh --profile $Profile"
