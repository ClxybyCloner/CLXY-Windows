# Builds the private, portable CLXY Windows x64 package without Inno Setup or signing.
# The upstream source root and Go import paths remain unchanged. The runtime contract
# is exact: core\arman-vpn-core.exe and core\arman-vpn-tun.exe.
#Requires -Version 7
[CmdletBinding()]
param(
    [string]$AppVersion = '1.0.17',
    [string]$OutputRoot = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $OutputRoot) { $OutputRoot = Join-Path $root 'dist' }
$dist = [IO.Path]::GetFullPath($OutputRoot)
$packageName = "CLXY-$AppVersion-Windows-x64"
$bundle = Join-Path $dist $packageName
$stage = Join-Path $dist ".clxy-stage-$AppVersion"
$zip = Join-Path $dist "$packageName.zip"
$sourceZip = Join-Path $dist "CLXY-$AppVersion-Source.zip"
$sourceTar = Join-Path $dist ".clxy-source-$AppVersion.tar"
$sourceTree = Join-Path $dist ".clxy-source-$AppVersion"

function Invoke-Checked([string]$File, [string[]]$Arguments, [string]$WorkingDirectory = $root) {
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $File $($Arguments -join ' ')" }
}

New-Item -ItemType Directory -Force $dist | Out-Null
foreach ($path in @($bundle, $stage, $zip, $sourceZip, $sourceTar, $sourceTree)) {
    if (Test-Path -LiteralPath $path) { throw "Output already exists: $path" }
}

$appDir = Join-Path $root 'app'
$coreDir = Join-Path $root 'core'
$release = Join-Path $appDir 'build\windows\x64\runner\Release'

Push-Location $appDir
try {
    foreach ($stale in @('build\flutter_assets', 'build\windows\x64\runner\Release\data\flutter_assets')) {
        if (Test-Path $stale) { Remove-Item -LiteralPath $stale -Recurse -Force }
    }
    Invoke-Checked 'flutter' @('pub', 'get') $appDir
    Invoke-Checked 'flutter' @('gen-l10n') $appDir
    Invoke-Checked 'flutter' @('build', 'windows', '--release', '--no-pub', "--dart-define=APP_VERSION=$AppVersion", '--dart-define=CLXY_PRIVATE_TEST=true') $appDir
} finally { Pop-Location }
if (-not (Test-Path -LiteralPath $release)) { throw "Flutter release directory was not produced: $release" }

New-Item -ItemType Directory -Force $bundle | Out-Null
Get-ChildItem -LiteralPath $release -Force | Copy-Item -Destination $bundle -Recurse -Force
$appExe = Join-Path $bundle 'clxy.exe'
if (-not (Test-Path -LiteralPath $appExe)) { throw 'Flutter build did not contain the expected CLXY app executable clxy.exe' }
if (-not (Test-Path (Join-Path $bundle 'd3dcompiler_47.dll'))) {
    throw 'd3dcompiler_47.dll is missing; the Windows SDK runtime copy in app/windows/CMakeLists.txt must be available'
}

$coreOut = Join-Path $bundle 'core'
New-Item -ItemType Directory -Force $coreOut | Out-Null
$public = & "$PSScriptRoot\signing-key.ps1"
Push-Location $coreDir
try {
    $env:APP_VERSION = $AppVersion
    # Keep upstream resource generation and the official Windows gVisor build tag.
    Invoke-Checked 'go' @('generate', './cmd/arman-vpn-core') $coreDir
    $coreFlags = "-s -w -X github.com/armanlife/arman-vpn-client/core/internal/version.Current=$AppVersion"
    if ($public) { $coreFlags += " -X github.com/armanlife/arman-vpn-client/core/internal/signing.Key=$public" }
    Invoke-Checked 'go' @('build', '-mod=vendor', '-trimpath', '-ldflags', $coreFlags, '-o', (Join-Path $coreOut 'arman-vpn-core.exe'), './cmd/arman-vpn-core') $coreDir
    Invoke-Checked 'go' @('generate', './cmd/arman-vpn-tun') $coreDir
    & "$PSScriptRoot\build-windows-tun.ps1" -Version $AppVersion -Out $coreOut -PublicKey $public
    if ($LASTEXITCODE -ne 0) { throw 'TUN build failed' }
} finally {
    Remove-Item Env:APP_VERSION -ErrorAction SilentlyContinue
    Pop-Location
}

$required = @('clxy.exe', 'core\arman-vpn-core.exe', 'core\arman-vpn-tun.exe', 'd3dcompiler_47.dll')
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $bundle $relative))) { throw "Required package file is missing: $relative" }
}

Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $bundle 'LICENSE')
Copy-Item -LiteralPath (Join-Path $root 'scripts\CLXY-Portable.cmd') -Destination (Join-Path $bundle 'CLXY-Portable.cmd')
Copy-Item -LiteralPath (Join-Path $root 'scripts\README-PORTABLE.txt') -Destination (Join-Path $bundle 'README-PORTABLE.txt')
Copy-Item -LiteralPath (Join-Path $root 'licenses') -Destination (Join-Path $bundle 'licenses') -Recurse
New-Item -ItemType Directory -Force (Join-Path $bundle 'licenses\go-vendor') | Out-Null
Get-ChildItem -LiteralPath (Join-Path $coreDir 'vendor') -Recurse -File | Where-Object { $_.Name -match '^(?i)(LICENSE|COPYING|NOTICE)(\..*)?$' } | ForEach-Object {
    $relative = $_.FullName.Substring((Join-Path $coreDir 'vendor').Length).TrimStart('\', '/')
    $target = Join-Path (Join-Path $bundle 'licenses\go-vendor') $relative
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}
$flutterCmd = Get-Command 'flutter' -ErrorAction Stop
$flutterRoot = Split-Path (Split-Path $flutterCmd.Source -Parent) -Parent
if (Test-Path (Join-Path $flutterRoot 'LICENSE')) {
    New-Item -ItemType Directory -Force (Join-Path $bundle 'licenses\flutter-sdk') | Out-Null
    Copy-Item -LiteralPath (Join-Path $flutterRoot 'LICENSE') -Destination (Join-Path $bundle 'licenses\flutter-sdk\LICENSE')
}
$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
$pubHosted = Join-Path $pubCache 'hosted\pub.dev'
if (Test-Path $pubHosted) {
    Get-ChildItem -LiteralPath $pubHosted -Recurse -File | Where-Object { $_.Name -match '^(?i)(LICENSE|COPYING|NOTICE)(\..*)?$' } | ForEach-Object {
        $relative = $_.FullName.Substring($pubHosted.Length).TrimStart('\', '/')
        $target = Join-Path (Join-Path $bundle 'licenses\flutter-packages') $relative
        New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}
Get-ChildItem -LiteralPath (Join-Path $appDir 'assets') -Recurse -File | Where-Object { $_.Name -match '^(?i)(LICENSE|COPYING|NOTICE|OFL)(\..*)?$' } | ForEach-Object {
    $relative = $_.FullName.Substring((Join-Path $appDir 'assets').Length).TrimStart('\', '/')
    $target = Join-Path (Join-Path $bundle 'licenses\app-assets') $relative
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}
$legalNotices = @"
CLXY Windows portable package

This release uses core v1.0.17. The core keeps its required runtime
filenames: core/arman-vpn-core.exe and core/arman-vpn-tun.exe.

The GNU GPL v3 text is in LICENSE. Third-party license texts are in licenses/.
The corresponding source is supplied separately as CLXY-$AppVersion-Source.zip.
Branding note: This is an unofficial client and is not affiliated with Mozilla.
No account data, credentials, access tokens, or private signing keys are included.
Run CLXY-Portable.cmd to keep user data in user-data beside the program.
TUN service installation and live VPN routing require a user's Windows machine
and account; this build does not claim either has been tested here.
"@
$legalNotices | Set-Content -LiteralPath (Join-Path $bundle 'LEGAL-NOTICES.txt') -Encoding utf8

# A deterministic manifest lets smoke tests verify files without installing a service.
$manifest = foreach ($file in Get-ChildItem -LiteralPath $bundle -File -Recurse | Sort-Object FullName) {
    $relative = $file.FullName.Substring($bundle.Length).TrimStart('\', '/') -replace '\\', '/'
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $relative"
}
$manifest | Set-Content -LiteralPath (Join-Path $bundle 'SHA256SUMS.txt') -Encoding ascii
Push-Location $coreDir
try {
    & go run ./tools/sign (Join-Path $bundle 'SHA256SUMS.txt')
    if ($LASTEXITCODE -ne 0) { throw 'signing SHA256SUMS.txt failed' }
} finally { Pop-Location }

# Stage a clean CLXY-branded folder, excluding runtime/user data.
New-Item -ItemType Directory -Force (Join-Path $stage 'CLXY') | Out-Null
Get-ChildItem -LiteralPath $bundle -Force | Where-Object { $_.Name -notin @('user-data', 'portable') } |
    Copy-Item -Destination (Join-Path $stage 'CLXY') -Recurse -Force
Compress-Archive -LiteralPath (Join-Path $stage 'CLXY') -DestinationPath $zip -CompressionLevel Optimal
# The updater verifies the outer archive, not the inner smoke manifest.
# Keep the version comment required by core/internal/update and sign this list.
$outerSums = Join-Path $dist 'SHA256SUMS.txt'
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"# Arman VPN version: $AppVersion`n$zipHash  $packageName.zip" | Set-Content -LiteralPath $outerSums -Encoding ascii
Push-Location $coreDir
try {
    & go run ./tools/sign $outerSums
    if ($LASTEXITCODE -ne 0) { throw 'signing outer SHA256SUMS.txt failed' }
} finally { Pop-Location }

# Export tracked source only, then fail if private runtime data or key material was committed.
# Source code for token handling and key generation stays in the corresponding-source archive.
Invoke-Checked 'git' @('archive', '--format=tar', "--output=$sourceTar", 'HEAD') $root
New-Item -ItemType Directory -Force $sourceTree | Out-Null
Invoke-Checked 'tar' @('-xf', $sourceTar, '-C', $sourceTree) $root
# Never place the signing seed in the bundle or corresponding-source archive.
# Scan bytes so the decoded seed is covered too, without logging it.
$secretText = $env:ARMAN_VPN_SIGNING_KEY
if (-not $secretText) { throw 'ARMAN_VPN_SIGNING_KEY is required for the approved package' }
$secretBytes = [Text.Encoding]::UTF8.GetBytes($secretText)
$seedBytes = [Convert]::FromBase64String($secretText.Trim())
function Test-SecretBytes([string]$Path, [byte[]]$Needle) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($Needle.Length -eq 0 -or $bytes.Length -lt $Needle.Length) { return $false }
    for ($i = 0; $i -le $bytes.Length - $Needle.Length; $i++) {
        $match = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) { if ($bytes[$i + $j] -ne $Needle[$j]) { $match = $false; break } }
        if ($match) { return $true }
    }
    return $false
}
$scanFiles = @(Get-ChildItem -LiteralPath $bundle -Recurse -File) + @(Get-ChildItem -LiteralPath $sourceTree -Recurse -File)
foreach ($file in $scanFiles) {
    if ($file.Name -like '*.signing-key' -or (Test-SecretBytes $file.FullName $secretBytes) -or (Test-SecretBytes $file.FullName $seedBytes)) {
        throw "Signing material leaked into build output: $($file.FullName)"
    }
}
$forbiddenSourceFiles = Get-ChildItem -LiteralPath $sourceTree -Recurse -File | Where-Object {
    $_.Name -match '(?i)^(local-api\.token|credentials?\.json|\.env(?:\..*)?|.*\.(?:pfx|p12))$'
}
if ($forbiddenSourceFiles) { throw "Private runtime data or credential files are tracked in source: $($forbiddenSourceFiles.FullName -join ', ')" }
foreach ($textFile in (Get-ChildItem -LiteralPath $sourceTree -Recurse -File | Where-Object { $_.Extension -in @('.go', '.dart', '.ps1', '.json', '.txt', '.md', '.yml', '.yaml', '.pem') })) {
    if (Select-String -LiteralPath $textFile.FullName -Pattern '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----' -Quiet) {
        throw "Private key material found in source export: $($textFile.FullName)"
    }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $sourceTree,
    $sourceZip,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)
$sourceArchive = [System.IO.Compression.ZipFile]::OpenRead($sourceZip)
try {
    $sourceEntries = @($sourceArchive.Entries | ForEach-Object { $_.FullName -replace '\\', '/' })
    foreach ($requiredSource in @('LICENSE', '.github/workflows/clxy-windows-private.yml', 'app/pubspec.lock', 'core/go.mod', 'core/go.sum', 'core/vendor/modules.txt', 'scripts/clxy-build-windows.ps1', 'scripts/CLXY-Portable.cmd', 'licenses/Wintun-Prebuilt-0.14.1-LICENSE.txt')) {
        if ($sourceEntries -notcontains $requiredSource) { throw "Corresponding source ZIP is missing: $requiredSource" }
    }
    if ($sourceArchive.Entries.Count -lt 1000) { throw 'Corresponding source ZIP is unexpectedly incomplete (too few entries)' }
} finally { $sourceArchive.Dispose() }

Remove-Item -LiteralPath $stage, $sourceTar, $sourceTree -Recurse -Force
Write-Host "Built $zip"
Write-Host "Built $sourceZip"
