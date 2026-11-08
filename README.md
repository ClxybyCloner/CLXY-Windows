<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,4f8cff,7c5cff&height=210&section=header&text=CLXY&fontSize=95&fontColor=ffffff&animation=fadeIn&fontAlignY=40&desc=Cloner%20Xray%20for%20Windows&descSize=22&descAlignY=66" alt="CLXY" width="100%"/>
</p>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=24&duration=2800&pause=900&color=7C5CFF&center=true&vCenter=true&width=640&lines=Fast.+Private.+Yours.;One+click+to+connect.;Windows+x64+%E2%80%94+ready+to+run." alt="Fast. Private. Yours." />
</p>

<p align="center">
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases/latest"><img src="https://img.shields.io/github/v/release/ClxybyCloner/CLXY-Windows?label=latest&color=7c5cff" alt="Latest release"></a>
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases"><img src="https://img.shields.io/github/downloads/ClxybyCloner/CLXY-Windows/total?label=downloads" alt="Total downloads"></a>
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows&logoColor=white" alt="Windows 10/11">
  <img src="https://img.shields.io/badge/arch-x64-4f8cff" alt="x64">
</p>

<p align="center"><b>The Windows download and update channel for the CLXY desktop app.</b><br/>
<sub>Installer, portable ZIP, Go core source, checksums, and release notes.</sub></p>

<p align="center">
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/CLXY-Windows-Setup-x64.exe"><b>Download app installer: CLXY 1.0.14 (x64)</b></a><br/>
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/CLXY-Windows-core-source-v1.0.14.zip">GPLv3 Go core source only (v1.0.14, not the app)</a><br/>
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.11/CLXY-1.0.11-Windows-x64.zip">Older portable ZIP (v1.0.11, not updated)</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/ClxybyCloner/CLXY-Windows/releases/tag/v1.0.14">Release details</a>
  &nbsp;·&nbsp;
  <a href="#-verify-your-download">Verify your download</a>
</p>

> **Unsigned installer:** this build has no publisher signature, so Windows may show an
> unknown-publisher / SmartScreen warning. CI built the installer, checked its version metadata,
> installed and launched the app, then uninstalled it. Live Windows sign-in and VPN/proxy traffic
> were not tested. v1.0.14 fixes the updater download link only. It does not claim to fix HTTP 406.

<p align="center">
  <img src="windows-preview.png" alt="CLXY running on Windows, showing its dark first-run sign-in screen" width="820">
</p>
<p align="center"><sub>CLXY on Windows during a launch check. The screenshot shows the sign-in screen. It does not demonstrate a working VPN connection.</sub></p>

---

## 📥 Download

| | |
|---|---|
| Release | **1.0.14** (app version `1.0.14+128`) |
| Platform | Windows 10 / 11, **x64** |
| App installer | [`CLXY-Windows-Setup-x64.exe`](https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/CLXY-Windows-Setup-x64.exe) · 20,159,265 bytes |
| GPLv3 Go core source only, not the app | [`CLXY-Windows-core-source-v1.0.14.zip`](https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/CLXY-Windows-core-source-v1.0.14.zip) · 1,082,940 bytes |
| Older portable ZIP (v1.0.11) | [`CLXY-1.0.11-Windows-x64.zip`](https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.11/CLXY-1.0.11-Windows-x64.zip) · 24,156,912 bytes |
| Code signing | Unsigned, no Authenticode certificate |
| Checksums | [`SHA256SUMS.txt`](https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/SHA256SUMS.txt) · [checksum history](CHECKSUMS.txt) |

> 🗂️ This repository provides binary downloads and documentation. Installers live as
> [Release assets](https://github.com/ClxybyCloner/CLXY-Windows/releases), not in git history.
> GitHub's **Code → Download ZIP** and auto-generated *Source code* archives contain only this
> documentation repository's files. The v1.0.14 Go core source is a separate GPLv3 Release asset.
> It contains only the Go core source, not the installable app, Flutter interface, or installer project.

---

## ⚡ Install on Windows

1. **Download** the [installer](#-download) above.
2. **Verify its SHA-256** ([how-to below](#-verify-your-download)) before running it.
3. **Open it** and follow the prompts (per-user install). If SmartScreen appears, see [the security notes](#-windows-security-warnings) first.
4. **Launch CLXY** from the installer or the Start menu.
5. Read [what CLXY is](#-what-clxy-is) before signing in or connecting.

The app installs to `%LOCALAPPDATA%\Programs\CLXY` and keeps its private account data,
settings, and logs in a `user-data` folder beside it. Treat that folder as private.

### 📦 Portable copy

The portable build remains v1.0.11. v1.0.14 does not include a new portable ZIP. Use the
[older download](#-download), verify its hash, extract the `CLXY` folder, and run `clxy.exe`.
Keep the folder writable. The app stores its private `user-data` right beside the executable.

---

## ✅ Verify your download

In PowerShell, from your download folder:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\CLXY-Windows-Setup-x64.exe
Get-FileHash -Algorithm SHA256 -LiteralPath .\CLXY-Windows-core-source-v1.0.14.zip
```

The result must match the hash published in the
[v1.0.14 release](https://github.com/ClxybyCloner/CLXY-Windows/releases/tag/v1.0.14)
and in [`SHA256SUMS.txt`](https://github.com/ClxybyCloner/CLXY-Windows/releases/download/v1.0.14/SHA256SUMS.txt):

```text
773f2ea92ace4ff661de1cf7e47ba4c0d3847ff75c06cdc88d42a260efc29157  CLXY-Windows-Setup-x64.exe
bf35983172b070dc1acbf2f70319380c59efd979b05dc26df6c5c65dfefacbaf  CLXY-Windows-core-source-v1.0.14.zip
```

A matching hash proves the file is exactly what we published. It is *not* a security audit
or a publisher signature.

---

## 🛡️ Windows security warnings

- The installer is **unsigned**. A successful install test does not establish SmartScreen reputation or publisher identity.
- Only proceed if you trust this repository **and** the checksum matches.
- **Never** disable Defender, antivirus, or your organization's security policy to install it. If you're unsure about a warning, stop.

---

## 🔄 How updates work

CLXY checks this repository's latest stable release **after each successful VPN connection**
(including reconnects). When a newer build is found, the app shows a notice with a
**Download** button. Installed copies fetch the installer. The last portable ZIP is v1.0.11;
v1.0.14 does not include a newer portable package.
Downloading and installing always stay *your* choice: **CLXY never auto-installs updates.**

---

## 🧭 What CLXY is

CLXY is an independent, unofficial Windows desktop client. It uses a Flutter interface with a
bundled Go core that starts locally and talks to the app over loopback. The package includes
the sign-in/onboarding UI, desktop integration, and the required legal notices
([`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md), [`LICENSE`](LICENSE)).

### Flutter UI and Go networking core

The Windows client uses Flutter for its desktop interface and runs a companion Go process for networking. The app controls the core through a local loopback API, while the core provides a local SOCKS5/HTTP proxy. For outbound connections, it supports encrypted HTTP/2 CONNECT over TCP and HTTP/3 CONNECT over QUIC, with an HTTP/2 fallback if an HTTP/3 connection cannot be established.

```text
Flutter desktop UI
  └─ local loopback API → Go core
       ├─ local SOCKS5 / HTTP proxy
       └─ HTTP/2 CONNECT over TCP or HTTP/3 CONNECT over QUIC
```

CLXY is an independent third-party client; account and upstream-service access are external
dependencies. Publishing this installer does **not** provide an account or guarantee service
access. The upstream proxy is TCP-only on web ports **80, 443, 8080, and 8443**. UDP-dependent
apps and other ports may not work. Don't assume every app's traffic is protected just because
the desktop app is open.

---

## مسیریابی پیشرفته VPN (Advanced VPN Routing)

در این معماری، از ترکیب فناوری Xray و زیرساخت Mozilla VPN برای ایجاد یک مسیر ارتباطی چندلایه استفاده میشود. هدف، افزایش انعطافپذیری در مدیریت ترافیک، جداسازی مسیرهای ارتباطی و کنترل دقیقتر ترافیک ورودی و خروجی است.

ویژگیها:

* مسیریابی چندلایه: ایجاد زنجیره ارتباطی میان لایه ورودی و خروجی VPN.
* یکپارچهسازی Mozilla VPN: استفاده از زیرساخت WireGuard برای مدیریت مسیر خروجی.
* مسیریابی هوشمند: امکان هدایت ترافیک بر اساس سیاستهای تعریفشده.
* مدیریت تونل اختصاصی: کنترل مستقل مسیر ارتباطی و وضعیت تونل خروجی.
* محافظت از IP: جلوگیری از افشای آدرس IP اصلی در شرایط قطع تونل.
* مدیریت خطا و بازیابی: پیشبینی سازوکارهای کنترل اتصال و بازیابی مسیر ارتباطی.

ساختار ارتباطی:

VLESS → Xray Core → Linux Routing → Mozilla VPN → Internet

این ساختار با هدف ایجاد یک زیرساخت ارتباطی منعطف، قابل توسعه و قابل مدیریت طراحی شده است.

-----

### Advanced VPN Routing

This architecture combines Xray technology with the Mozilla VPN infrastructure to establish a multi-layered network communication path. Its primary goal is to improve traffic management flexibility, isolate network routes, and provide more precise control over inbound and outbound traffic.

Features:

* Multi-Layer Routing: Establishes a chained communication path between the VPN ingress and egress layers.
* Mozilla VPN Integration: Leverages WireGuard infrastructure to manage outbound traffic routing.
* Smart Traffic Routing: Directs traffic based on predefined routing policies.
* Dedicated Tunnel Management: Provides independent control over the outbound tunnel and its connection status.
* IP Leak Protection: Prevents exposure of the original server IP in the event of a tunnel failure.
* Fault Handling & Recovery: Incorporates mechanisms for connection monitoring and automatic route recovery.

Network Architecture:

VLESS → Xray Core → Linux Routing → Mozilla VPN → Internet

This architecture is designed to provide a flexible, scalable, and manageable networking infrastructure.

---

## ❓ FAQ

**Is the source code here?**
This repository contains release downloads and documentation. The v1.0.14 release includes a separate GPLv3 source archive for the Go core only. It is not the installable app and does not include the Flutter interface or installer project.

**Installer or portable?**
Installer for a normal setup (Start-menu entry, per-user install). Portable if you want a
folder you can carry around or run without installing. The available portable ZIP is v1.0.11.

**Where are my settings?**
In the `user-data` folder next to the app (installed or portable). Back it up if it matters to you.

**Windows 7 / 8 / ARM?**
Not supported. The target is **Windows 10/11 on x64**. This release has no ARM64 or 32-bit package.

**The dashboard looks cramped in a small window.**
It keeps the desktop layout when resized. Press <kbd>Ctrl</kbd>+<kbd>+</kbd> /
<kbd>Ctrl</kbd>+<kbd>−</kbd> to zoom.

**Older versions?**
They stay on the [Releases page](https://github.com/ClxybyCloner/CLXY-Windows/releases),
with their checksums in [`CHECKSUMS.txt`](CHECKSUMS.txt).

---

## 📜 Release history

Full notes for every build live in [`CHANGELOG.md`](CHANGELOG.md), newest first.

## 💬 Support

- 🌐 [clonerr.ir](https://clonerr.ir)
- ✈️ Telegram: [@cloner42](https://t.me/cloner42)

## 📄 Terms

The Go core included with v1.0.14 is covered by GPL version 3.0. Its separate source archive includes
the core source, GPL license, build instructions, and dependency notices. The project's MIT notice remains in [`LICENSE`](LICENSE), and
third-party components are listed in [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,7c5cff,4f8cff&height=130&section=footer&animation=fadeIn" alt="" width="100%"/>
</p>
<p align="center"><sub>Made with 💙 for the CLXY community</sub></p>
