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

**Automated Subnet Detection • Host Discovery Sweep • OS Fingerprinting • Vulnerability Audit • Markdown Summary Report**

**Author:** ShadowHarvy  
**Version:** 1.0.0  
**License:** MIT

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [How It Works](#-how-it-works)
  - [Phase 1: Subnet Auto-Detection](#phase-1-subnet-auto-detection)
  - [Phase 2: Ping & Host Discovery Sweep](#phase-2-ping--host-discovery-sweep)
  - [Phase 3: OS & Device Identification](#phase-3-os--device-identification)
  - [Phase 4: Vulnerability & Security Risk Assessment](#phase-4-vulnerability--security-risk-assessment)
  - [Phase 5: Markdown Summary Report](#phase-5-markdown-summary-report)
- [Requirements & Installation](#-requirements--installation)
- [Usage & Examples](#-usage--examples)
- [Sample Report Output](#-sample-report-output)

---

## 🌟 Overview

`network_audit.sh` is an automated security audit and inventory tool designed specifically for home and private office local networks. It automatically detects your active network interface and CIDR subnet (e.g. `192.168.1.0/24`), sweeps the network to find every active connected device, determines the operating system and manufacturer of each, tests for exposed security risks and common CVE vulnerabilities, and outputs both a color-coded terminal table and an executive Markdown report.

---

## 🚀 Key Features

- 🔍 **Zero-Configuration Auto-Detection**: Detects active network adapter (`wlan0`, `eth0`), default gateway, local IP, and subnet CIDR automatically.
- 🏓 **Host Discovery Sweep**: Pings and ARP-sweeps all addresses to build a live device list.
- 💻 **OS & Hardware Fingerprinting**: Uses Nmap OS fingerprinting (`-O`) with MAC vendor lookup and TTL analysis fallback.
- 🛡️ **Vulnerability Assessment**:
  - Scans for dangerous plaintext protocols (Telnet on port 23, FTP on port 21).
  - Checks for exposed remote access (RDP 3389, VNC 5900, SMB 445).
  - Checks for exposed databases (MySQL, PostgreSQL, Redis, MongoDB).
  - Runs automated CVE vulnerability scripts (`nmap --script vuln`) against open services.
- 📄 **Executive Markdown Reports**: Automatically generates timestamped reports in `./reports/network_audit_<date>.md` with an executive summary, device inventory table, risk details, and defensive hardening advice.

---

## ⚙️ How It Works

### Phase 1: Subnet Auto-Detection
The script inspects your system's default route via `ip route show to default` and resolves your active IPv4 interface and subnet mask (e.g. `192.168.1.164/24` $\to$ `192.168.1.0/24`). You can also override the subnet manually with `-r <CIDR>`.

### Phase 2: Ping & Host Discovery Sweep
Performs a fast discovery sweep combining ICMP echo, ARP ping, and common TCP SYN probes to find all online phones, laptops, smart TVs, routers, and IoT devices.

### Phase 3: OS & Device Identification
Probes responsive hosts with Nmap's TCP/IP stack fingerprinting engine (`-O --osscan-guess`) and service version inspection (`-sV`). If Nmap is not installed, it falls back to ICMP TTL heuristics (TTL $\le 64$ for Linux/Android/Apple, TTL $\le 128$ for Windows, TTL $\ge 255$ for Cisco/network appliances) and service banner inspection.

### Phase 4: Vulnerability & Security Risk Assessment
Performs a security audit of open ports to detect unencrypted credentials, exposed administrative portals, and known CVEs using automated Nmap Scripting Engine (NSE) vulnerability checks.

### Phase 5: Markdown Summary Report
Compiles all data into a structured report with:
1. **Executive Summary**: Total devices, clean hosts, hosts with warnings/vulnerabilities.
2. **Device Inventory Table**: IP, Hostname, MAC Address, Vendor, Detected OS, Open Ports, Risk Status.
3. **Risk & CVE Breakdown**: Specific findings and CVE descriptions per device.
4. **Hardening Recommendations**: Actionable guidance to secure your home network.

---

## 📋 Requirements & Installation

### Dependencies
- **iproute2** (`ip`) & **ping** (pre-installed on Linux)
- **python3** (pre-installed on Linux)
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

### Audit a Specific Network Range
```bash
sudo ./network_audit.sh -r 192.168.1.0/24
```

### Save Report to a Custom File
```bash
sudo ./network_audit.sh -o ~/Desktop/home_lan_audit.md
```

### Discovery & OS Identification Only
```bash
sudo ./network_audit.sh --skip-vuln
```

---

## 📊 Sample Report Output

```markdown
# Network Security Audit Report

**Audit Date:** 2026-09-18 21:30:00  
**Target Subnet:** `192.168.1.0/24`  
**Interface:** `wlan0` | **Gateway:** `192.168.1.1`  

## 📊 Executive Summary
| Metric | Value |
| :--- | :--- |
| **Total Devices Detected** | **6** |
| **Devices With Open Ports / Risks** | **2** |
| **Clean / No Exposed Risks** | **4** |

## 🖥️ Device Inventory
| IP Address | Device Name | Manufacturer | MAC Address | Detected OS | Open Ports | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `192.168.1.1` | **eero-09es** | eero inc. | `28:ec:22:bb:8c:92` | Linux 4.4 (Router) | `80/tcp,443/tcp` | 🟢 Clean |
| `192.168.1.164`| **cachyos-x8664-27**| ASUSTeK COMPUTER INC. | `a4:b1:c2:...` | Arch Linux / CachyOS | `22/tcp` | 🟢 Clean |
| `192.168.1.210`| **homeassistant** | Private / Randomized MAC | `02:48:59:b6:38:62` | Linux (Home Assistant OS) | `8123/tcp` | 🟢 Clean |
```
