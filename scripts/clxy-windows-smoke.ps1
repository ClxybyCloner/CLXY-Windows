# Private, no-account Windows smoke test. It never installs a service, changes the
# system proxy, signs in, or claims a live VPN test.
#Requires -Version 7
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Package,
    [Parameter(Mandatory)][string]$Zip,
    [string]$Results = "$env:RUNNER_TEMP\clxy-smoke",
    [int]$TimeoutSeconds = 45
)
$ErrorActionPreference = 'Stop'
$package = (Resolve-Path $Package).Path
$zipPath = (Resolve-Path $Zip).Path
New-Item -ItemType Directory -Force $Results | Out-Null
$data = Join-Path $Results 'isolated-user-data'
New-Item -ItemType Directory -Force $data | Out-Null
$jsonPath = Join-Path $Results 'smoke-results.json'
$started = Get-Date
$checks = [ordered]@{}
$process = $null
function Record([string]$Name, [bool]$Passed, [string]$Detail) { $checks[$Name] = [ordered]@{ passed = $Passed; detail = $Detail } }
function Fail([string]$Message) { throw $Message }
function Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Amd64([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 64) { Fail "binary is too small to be a Windows PE image: $Path" }
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3c)
    if ($peOffset -lt 0 -or $peOffset + 6 -gt $bytes.Length) { Fail "invalid PE header offset: $Path" }
    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    if ($machine -ne 0x8664) { Fail "binary is not AMD64 (machine=0x$('{0:X4}' -f $machine)): $Path" }
}
function Save-AppWindowScreenshot([System.Diagnostics.Process]$Process, [string]$Path) {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    if (-not ('CLXYWindowCapture' -as [type])) {
        $captureSource = @'
using System;
using System.Runtime.InteropServices;
public struct CLXYRECT { public int Left; public int Top; public int Right; public int Bottom; }
public static class CLXYWindowCapture {
  [DllImport("user32.dll", EntryPoint="GetWindowLongW", SetLastError=true)] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
  [DllImport("user32.dll", EntryPoint="SetWindowLongW", SetLastError=true)] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int value);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out CLXYRECT rect);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll", EntryPoint="FindWindowW", CharSet=CharSet.Unicode, SetLastError=true)] public static extern IntPtr FindWindow(string className, string windowName);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd, int command);
  public static int MakeBorderless(IntPtr hWnd) {
    int old = GetWindowLong(hWnd, -16);
    int style = (old & ~0x00CF0000) | unchecked((int)0x80000000) | 0x10000000;
    SetWindowLong(hWnd, -16, style);
    return old;
  }
}
'@
        Add-Type -TypeDefinition $captureSource -Language CSharp
    }
    $Process.Refresh()
    $handle = $Process.MainWindowHandle
    if ($handle -eq [IntPtr]::Zero) { throw 'app has no visible main window handle' }
    $oldRect = New-Object CLXYRECT
    if (-not [CLXYWindowCapture]::GetWindowRect($handle, [ref]$oldRect)) { throw 'GetWindowRect failed' }
    $oldStyle = [CLXYWindowCapture]::GetWindowLong($handle, -16)
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $width = 412; $height = 915
    if ($screen.Width -lt $width) { throw "runner display is too narrow for the $width-pixel app window ($($screen.Width))" }
    $shortfall = [Math]::Max(0, $height - $screen.Height)
    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $taskbar = [CLXYWindowCapture]::FindWindow('Shell_TrayWnd', $null)
    $taskbarWasVisible = $taskbar -ne [IntPtr]::Zero -and [CLXYWindowCapture]::IsWindowVisible($taskbar)
    try {
        if ($taskbarWasVisible) {
            [void][CLXYWindowCapture]::ShowWindow($taskbar, 0)
            Start-Sleep -Milliseconds 300
        }
        [void][CLXYWindowCapture]::MakeBorderless($handle)
        [void][CLXYWindowCapture]::SetWindowPos($handle, [IntPtr]::Zero, $screen.X, $screen.Y, $width, $height, 0x0020 -bor 0x0040 -bor 0x0004)
        [void][CLXYWindowCapture]::SetForegroundWindow($handle)
        Start-Sleep -Milliseconds 900
        $visibleHeight = [Math]::Min($height, $screen.Height)
        $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, [System.Drawing.Size]::new($width, $visibleHeight), [System.Drawing.CopyPixelOperation]::SourceCopy)
        if ($shortfall -gt 0) {
            # Show the otherwise clipped bottom segment, then stitch at native pixel size.
            [void][CLXYWindowCapture]::SetWindowPos($handle, [IntPtr]::Zero, $screen.X, $screen.Y - $shortfall, $width, $height, 0x0020 -bor 0x0040 -bor 0x0004)
            Start-Sleep -Milliseconds 700
            $sourceY = $screen.Y + $screen.Height - $shortfall
            $graphics.CopyFromScreen($screen.X, $sourceY, 0, $screen.Height, [System.Drawing.Size]::new($width, $shortfall), [System.Drawing.CopyPixelOperation]::SourceCopy)
        }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose(); $bitmap.Dispose()
        [void][CLXYWindowCapture]::SetWindowLong($handle, -16, $oldStyle)
        [void][CLXYWindowCapture]::SetWindowPos($handle, [IntPtr]::Zero, $oldRect.Left, $oldRect.Top, $oldRect.Right - $oldRect.Left, $oldRect.Bottom - $oldRect.Top, 0x0020 -bor 0x0040 -bor 0x0004)
        if ($taskbarWasVisible) { [void][CLXYWindowCapture]::ShowWindow($taskbar, 5) }
    }
}
function Click-AppUpdateButton([System.Diagnostics.Process]$Process) {
    $Process.Refresh()
    $handle = $Process.MainWindowHandle
    if ($handle -eq [IntPtr]::Zero) { throw 'app has no visible main window handle for update click' }
    [void][CLXYWindowCapture]::SetForegroundWindow($handle)
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    Start-Sleep -Milliseconds 200
}
try {
    $app = Join-Path $package 'clxy.exe'
    $core = Join-Path $package 'core\arman-vpn-core.exe'
    $tun = Join-Path $package 'core\arman-vpn-tun.exe'
    foreach ($expected in @($app, $core, $tun)) {
        if (-not (Test-Path -LiteralPath $expected -PathType Leaf)) { Fail "required exact runtime binary is missing: $expected" }
        Assert-Amd64 $expected
    }
    foreach ($wrong in @('core\clxy-core.exe', 'core\clxy-tun.exe')) {
        if (Test-Path -LiteralPath (Join-Path $package $wrong)) { Fail "wrong runtime filename is packaged: $wrong" }
    }
    Record 'exact_runtime_filenames' $true 'clxy.exe, core/arman-vpn-core.exe, core/arman-vpn-tun.exe'

    $forbidden = Get-ChildItem -LiteralPath $package -Recurse -Force -File | Where-Object {
        $_.Name -match '(?i)(credentials?|local-api\.token|signing[-_.]?key|secret|\.pem$|\.key$|\.pfx$|\.p12$)'
    }
    if ($forbidden) { Fail "credential or signing material is packaged: $($forbidden.FullName -join ', ')" }
    Record 'package_has_no_private_material' $true 'no credentials, tokens, signing keys, or user data files'

    $tunVersion = & $tun -version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tunVersion)) { Fail "TUN -version failed or returned no output: $tunVersion" }
    Record 'tun_version' $true ($tunVersion.Trim() -replace '\s+', ' ')

    $manifestPath = Join-Path $package 'SHA256SUMS.txt'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { Fail 'SHA256SUMS.txt is missing' }
    $manifestLines = Get-Content -LiteralPath $manifestPath | Where-Object { $_.Trim() }
    foreach ($line in $manifestLines) {
        if ($line -notmatch '^([0-9a-fA-F]{64})\s{2}(.+)$') { Fail "invalid SHA256SUMS.txt line: $line" }
        $expectedHash = $Matches[1].ToLowerInvariant()
        $relative = $Matches[2] -replace '/', '\\'
        $file = Join-Path $package $relative
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Fail "manifest file is missing: $relative" }
        if ((Hash $file) -ne $expectedHash) { Fail "SHA-256 mismatch: $relative" }
    }
    Record 'package_file_hashes' $true "$($manifestLines.Count) manifest entries verified"

    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $names = @($archive.Entries | ForEach-Object { $_.FullName -replace '\\', '/' })
        foreach ($requiredEntry in @('CLXY/clxy.exe', 'CLXY/core/arman-vpn-core.exe', 'CLXY/core/arman-vpn-tun.exe', 'CLXY/SHA256SUMS.txt')) {
            if ($names -notcontains $requiredEntry) { Fail "ZIP is missing exact entry: $requiredEntry" }
        }
        if ($names -contains 'CLXY/core/clxy-core.exe' -or $names -contains 'CLXY/core/clxy-tun.exe') { Fail 'ZIP contains a wrong clxy core/TUN filename' }
        $zipSize = (Get-Item -LiteralPath $zipPath).Length
        if ($zipSize -le 0) { Fail 'ZIP is empty' }
        Record 'zip_integrity' $true "ZIP readable; $($names.Count) entries; $zipSize bytes"
    } finally { $archive.Dispose() }

    $zipExtractRoot = Join-Path $Results 'zip-extract'
    if (Test-Path -LiteralPath $zipExtractRoot) { Remove-Item -LiteralPath $zipExtractRoot -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $zipExtractRoot)
    $zipBundle = Join-Path $zipExtractRoot 'CLXY'
    $zipManifest = Join-Path $zipBundle 'SHA256SUMS.txt'
    if (-not (Test-Path -LiteralPath $zipManifest -PathType Leaf)) { Fail 'extracted ZIP is missing SHA256SUMS.txt' }
    $zipManifestLines = Get-Content -LiteralPath $zipManifest | Where-Object { $_.Trim() }
    foreach ($line in $zipManifestLines) {
        if ($line -notmatch '^([0-9a-fA-F]{64})\s{2}(.+)$') { Fail "invalid ZIP manifest line: $line" }
        $expectedHash = $Matches[1].ToLowerInvariant()
        $relative = $Matches[2] -replace '/', '\\'
        $file = Join-Path $zipBundle $relative
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Fail "ZIP is missing manifest file: $relative" }
        if ((Hash $file) -ne $expectedHash) { Fail "ZIP content SHA-256 mismatch: $relative" }
    }
    $packageFileCount = @(Get-ChildItem -LiteralPath $package -Recurse -File).Count
    $zipFileCount = @(Get-ChildItem -LiteralPath $zipBundle -Recurse -File).Count
    if ($packageFileCount -ne $zipFileCount) { Fail "ZIP file count differs from package directory: $zipFileCount vs $packageFileCount" }
    Record 'zip_content_hashes' $true "$($zipManifestLines.Count) extracted ZIP file hashes verified; $zipFileCount total files"

    # The upstream config defaults are loopback-only. The smoke process uses a
    # private data directory, so generated dashboard/proxy ports cannot affect a user's settings.
    $null = & $core -list-accounts -data-dir $data 2>&1
    if (Test-Path (Join-Path $data 'config.json')) {
        $configPath = Join-Path $data 'config.json'
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $dashboardPort = Get-Random -Minimum 20000 -Maximum 50000
        $proxyPort = Get-Random -Minimum 50000 -Maximum 60000
        $config.dashboard.listen = "127.0.0.1:$dashboardPort"
        $config.proxy.listen = "127.0.0.1:$proxyPort"
        if (-not $config.system_proxy) { $config | Add-Member -NotePropertyName system_proxy -NotePropertyValue ([pscustomobject]@{}) -Force }
        $config.system_proxy.mode = 'tun'
        $config | ConvertTo-Json -Depth 30 | Set-Content $configPath -Encoding utf8
    } else { Fail 'core did not create an isolated config.json' }
    $testSettings = [ordered]@{ language = 'en'; theme = 'dark'; close = 'quit'; welcome_done = $true; autostart = $false; auto_connect = $false }
    $testSettings | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $data 'app-settings.json') -Encoding utf8
    $updateActionPath = Join-Path $data 'smoke-update-action.txt'
    $process = Start-Process -FilePath $app -ArgumentList @("--data-dir=$data", "--clxy-smoke-update-notice=$updateActionPath") -WorkingDirectory $package -PassThru
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $api = $null
    $token = $null
    $dataCandidate = Join-Path $data 'local-api.token'
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) { Fail "app exited during startup with code $($process.ExitCode)" }
        if (Test-Path $dataCandidate) { $token = (Get-Content $dataCandidate -Raw).Trim() }
        if ($token) {
            try {
                $r = Invoke-WebRequest -Uri "http://$($config.dashboard.listen)/api/status" -Headers @{ 'X-Local-Token' = $token } -UseBasicParsing -TimeoutSec 2
                if ($r.StatusCode -eq 200) { $api = $r }
            } catch { }
        }
        if ($api) { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not $api) { Fail 'authenticated loopback core API did not become ready' }
    Record 'app_stays_alive' $true "PID $($process.Id)"
    Record 'authenticated_loopback_status' $true "HTTP $($api.StatusCode)"
    $coreChild = Get-Process -Name 'arman-vpn-core' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $coreChild) { Fail 'app did not start its bundled core process' }
    $corePid = $coreChild.Id
    Record 'core_child_started' $true "PID $corePid"
    $status = $api.Content | ConvertFrom-Json
    if ($status.system_proxy -ne 'tun' -or -not $status.tun_supported) { Fail "TUN mode/helper was not selected and detected by the Windows core (mode=$($status.system_proxy), supported=$($status.tun_supported))" }
    if ($status.tun -and $status.tun.on) { Fail 'TUN unexpectedly started in a no-account smoke test' }
    Record 'tun_mode_selected_without_activation' $true 'isolated config selects TUN and the bundled helper is detected; no TUN service or live VPN was started'

    $accounts = & $core -list-accounts -data-dir $data 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Fail "no-account listing failed: $accounts" }
    if ($accounts -match '(?i)\b(account|accounts)\b' -and $accounts -notmatch '(?i)no accounts|none|0 accounts') { Fail "isolated data directory unexpectedly contains account output: $accounts" }
    Record 'no_account_behavior' $true 'isolated data directory has no signed-in account; no live VPN assertion made'

    $screenshotPath = Join-Path $Results 'app-window-screenshot.png'
    try {
        Save-AppWindowScreenshot -Process $process -Path $screenshotPath
        Record 'app_window_screenshot' $true '412x915 app window captured at native client size with a mocked update notice; no account data or live connection'
        Write-Host "Saved $screenshotPath"
    } catch {
        Record 'app_window_screenshot' $false $_.Exception.Message
        Write-Warning "App-window screenshot unavailable: $($_.Exception.Message)"
    }

    Click-AppUpdateButton -Process $process
    $actionVersion = $null
    for ($i = 0; $i -lt 20; $i++) {
        if (Test-Path -LiteralPath $updateActionPath) {
            $actionVersion = (Get-Content -LiteralPath $updateActionPath -Raw).Trim()
            break
        }
        Start-Sleep -Milliseconds 100
    }
    if ($actionVersion -ne '1.0.18') { Fail "one-click update action did not record mock version 1.0.18 (got '$actionVersion')" }
    Record 'update_notice_one_click' $true 'mock update 1.0.18 selected; smoke mode performed no network request or installation'

    if (-not $process.CloseMainWindow()) { Fail 'could not request graceful close of the app window' }
    Record 'app_quit_requested' $true 'isolated app-settings.json selects Quit for this smoke run only'
    if (-not $process.WaitForExit(10000)) { Stop-Process -Id $process.Id -Force; Fail 'app did not exit after the window close request' }
    $coreStopped = $false
    for ($i = 0; $i -lt 50; $i++) {
        if (-not (Get-Process -Id $corePid -ErrorAction SilentlyContinue)) { $coreStopped = $true; break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $coreStopped) { Fail 'core process remained active after the app quit' }
    Record 'clean_process_shutdown' $true "app exit code $($process.ExitCode); core PID $corePid stopped"
} catch {
    Record 'failure' $false $_.Exception.Message
    throw
} finally {
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
    $result = [ordered]@{ test = 'clxy-windows-smoke'; started_utc = $started.ToUniversalTime().ToString('o'); checks = $checks; live_vpn_test = $false; service_install_attempted = $false; note = 'No account was used; system proxy, Wintun, WFP, registry, and Windows service state were not modified.' }
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding utf8
    Write-Host "Saved $jsonPath"
}
