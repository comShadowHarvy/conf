# Network Audit - Automated Local Network Security & Vulnerability Scanner

<div align="center">

```
   ███╗   ██╗███████╗████████╗     █████╗ ██╗   ██╗██████╗ ██╗████████╗
   ████╗  ██║██╔════╝╚══██╔══╝    ██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝
   ██╔██╗ ██║█████╗     ██║       ███████║██║   ██║██║  ██║██║   ██║   
   ██║╚██╗██║██╔══╝     ██║       ██╔══██║██║   ██║██║  ██║██║   ██║   
   ██║ ╚████║███████╗   ██║       ██║  ██║╚██████╔╝██████╔╝██║   ██║   
   ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   
```

**Multi-Protocol Discovery • Parallel Batch Scan • Smart Categorization • Active Risk Probes • Rogue Device Diffing • Interactive HTML Dashboard**

**Author:** ShadowHarvy  
**Version:** 2.0.0 (High-Speed Multi-Threaded Edition)  
**License:** MIT

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features (v2.0)](#-key-features-v20)
- [How It Works](#-how-it-works)
  - [Phase 1: Subnet Auto-Detection & Safety Guards](#phase-1-subnet-auto-detection--safety-guards)
  - [Phase 2: Multi-Protocol Discovery (ARP, ICMP, SSDP, mDNS)](#phase-2-multi-protocol-discovery)
  - [Phase 3: Parallel Port Scanning & Device Categorization](#phase-3-parallel-port-scanning--device-categorization)
  - [Phase 4: Targeted Vulnerability Scripting](#phase-4-targeted-vulnerability-scripting)
  - [Phase 5: Multi-Format Reporting & Rogue Device Diffing](#phase-5-multi-format-reporting--rogue-device-diffing)
- [Requirements & Installation](#-requirements--installation)
- [Usage & Examples](#-usage--examples)
- [Output Formats](#-output-formats)

---

## 🌟 Overview

`network_audit.sh` is a high-speed, automated network security auditing and inventory tool designed for personal networks, smart homes, homelabs, and private office subnets. It automatically discovers all active devices—even stealthy IoT devices that drop ICMP pings—identifies operating systems and manufacturers, classifies devices into functional categories (Routers, PCs, IoT, Mobile, Servers, Cameras), conducts active security probes on risky services (Redis, Docker APIs, Telnet, RTSP, Anonymous FTP), tracks network changes against prior audits to spot rogue devices, and outputs Markdown, JSON, and a standalone interactive dark-mode HTML dashboard.

---

## 🚀 Key Features (v2.0)

- ⚡ **High-Speed Parallel Batch Scanning**: Uses Nmap's parallel C++ batch scanning engine combined with Python thread pools (default 16 threads) for 5x–10x faster execution than sequential scanners.
- 📡 **Multi-Protocol Discovery**: Catches silent devices that ignore ICMP echo by broadcasting SSDP (UPnP) M-SEARCH and mDNS discovery queries alongside ARP sweeps.
- 🏷️ **Smart Device Categorization**: Automatically classifies devices into functional categories with intuitive icons:
  - 🌐 **Gateway / Router**
  - 💻 **Workstation / PC**
  - 📱 **Mobile / Tablet**
  - 💡 **Smart Home / IoT**
  - 🗄️ **Server / NAS / Homelab**
  - 📺 **Smart TV / Streaming Media**
  - 📷 **Security Camera**
  - 🖨️ **Printer / Office**
  - 🎮 **Gaming Console**
- 🛡️ **Active Security & Risk Probing**:
  - Live socket test for unauthenticated Redis servers (`PING` $\to$ `+PONG`).
  - Active probe for unauthenticated Docker daemon APIs on port 2375/2376 (root RCE risk).
  - Anonymous FTP login verification.
  - Plaintext protocol alerts (Telnet 23/2323, VNC 5900, HTTP without HTTPS).
  - RTSP IP camera feed detection (port 554).
  - Gateway UPnP WAN hole-punching vulnerability checks.
- 🚨 **Network Change & Rogue Device Diffing**: Compares current audit state against previous scans (`.network_audit_last.json`) to highlight new unknown devices, newly opened ports, and disconnected devices.
- 📊 **Triple-Format Reporting**:
  - **Interactive Dark-Mode HTML Dashboard**: Standalone single-file dashboard with live search, category filter pills, expandable host drawers, and print-to-PDF formatting (zero external CDN dependencies).
  - **Executive Markdown Report**: Clean tabular summaries with actionable step-by-step remediation guidance.
  - **Structured JSON Export**: Machine-readable output for home lab automations, CI/CD, and SIEM pipelines.
- 🛑 **Subnet Safety Guards**: Automatically detects wide subnets (e.g. `/16` or `/8` on Docker/VPNs) and constrains to a safe local `/24` unless explicitly overridden with `--force`.

---

## ⚙️ How It Works

### Phase 1: Subnet Auto-Detection & Safety Guards
Inspects the default kernel routing table (`ip -4 route show to default`) to resolve the primary network adapter, IP, gateway, and CIDR. If a wide subnet prefix is detected ($< /24$), it protects your machine by defaulting to the local `/24` unless `--force` is specified.

### Phase 2: Multi-Protocol Discovery
Runs Nmap's ARP/ping sweep concurrently with UDP multicast probes (SSDP on `239.255.255.250:1900` and mDNS on `224.0.0.251:5353`) and reads the kernel ARP neighbor cache (`ip neigh`) to find live hosts that block ICMP.

### Phase 3: Parallel Port Scanning & Device Categorization
Discovered targets are scanned simultaneously using Nmap's batch scanning engine. Concurrently, a Python thread pool resolves device hostnames (mDNS, NetBIOS, reverse DNS, and fast HTTP title grabs) and looks up manufacturers across IEEE OUI, Nmap prefixes, and an embedded top-vendor database.

### Phase 4: Targeted Vulnerability Scripting
For hosts with open ports, Nmap Scripting Engine (NSE) vulnerability checks (`--script "vuln and not (dos or brute)"`) execute specifically against those ports.

### Phase 5: Multi-Format Reporting & Rogue Device Diffing
Calculates network changes since the previous scan, prints a terminal summary table with color-coded badges, and writes the Markdown report, interactive HTML dashboard, and JSON snapshot.

---

## 📋 Requirements & Installation

### Dependencies
- **iproute2** (`ip`) & **ping** (pre-installed on Linux)
- **python3** (standard library only; no pip dependencies needed)
- **nmap** *(Recommended for deep OS detection and vulnerability scripts)*

On Arch Linux / CachyOS:
```bash
sudo pacman -S --needed nmap iproute2 python
```

On Debian / Ubuntu:
```bash
sudo apt update && sudo apt install -y nmap iproute2 python3
```

---

## 📖 Usage & Examples

### Basic Usage (Auto-Detect Subnet)
```bash
sudo ./network_audit.sh
```

### Quick Scan Mode
Scans top 100 ports and skips heavy vulnerability scripts:
```bash
sudo ./network_audit.sh -q
```

### Full 65,535-Port Deep Audit
```bash
sudo ./network_audit.sh -f
```

### Audit a Specific Network Range
```bash
sudo ./network_audit.sh -r 192.168.1.0/24
```

### Custom Report Output Paths
```bash
sudo ./network_audit.sh -o ./audit.md --html ./dashboard.html --json ./data.json
```

### Exclude Specific Hosts (e.g. Gateways or Sensitive Servers)
```bash
sudo ./network_audit.sh --exclude 192.168.1.1,192.168.1.10
```

### Control Thread Concurrency
```bash
sudo ./network_audit.sh -t 32
```

---

## 📊 Output Formats

1. **Terminal Output**: Color-coded ANSI table with category icons, device names, open ports, and risk badges, plus diff alerts for new devices.
2. **HTML Dashboard (`.html`)**: Modern dark obsidian UI, real-time search box, category tabs, and collapsible finding drawers with remediation instructions.
3. **Markdown Report (`.md`)**: Comprehensive report formatted for GitHub/GitLab and documentation wikis.
4. **JSON Snapshot (`.json`)**: Machine-readable data structure for automated tracking.
