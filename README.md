# 🕶️ SNI Scanner — Matrix Edition

> “Follow the white rabbit.” — Neo
> There is no spoon. Only open ports.

A stylish, interactive Bash-based SNI/TLS port scanner that checks common web ports for connectivity and availability — wrapped in a Matrix-themed terminal interface.
<img width="1105" height="733" alt="image" src="https://github.com/user-attachments/assets/c0c68ca0-4c8b-408e-a087-114fda0c9770" />

---

## 🚀 Features

* 🔎 Scans common web & TLS-related ports:

  ```
  443, 80, 8080, 8443, 2053, 2083, 2087, 2096
  ```
* 🌐 DNS resolution before scanning
* 📂 Multiple input sources:

  * Embedded default target list
  * Local file
  * Remote URL (auto-download via wget)
  * Single domain/IP
* 📊 Live animated progress bar
* 🎨 Matrix-style terminal UI with colorized output
* 🗂️ Automatic timestamped logging
* 📑 Sorted results (OPEN targets prioritized by port count)
* 🧼 Ignores blank lines and comments in lists

---

## 📦 Requirements

Make sure the following tools are installed:

* `bash` (v4+ recommended)
* `dig`
* `timeout`
* `wget`
* Standard GNU utilities

### Debian / Ubuntu

```bash
sudo apt install dnsutils wget coreutils
```

---
---

## ⚡ Quick Run (One-Liner)

Want to run it instantly without cloning the repository?

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/siniorone/SNI-Scanner/refs/heads/main/scan.sh || exit 1)"
```

### 🔍 What This Does

* Downloads the latest `scan.sh` directly from GitHub
* Executes it immediately using `bash`
* Stops execution if download fails (`|| exit 1`)

---

## 🛠️ Offline Run

```bash
git clone https://github.com/siniorone/SNI-Scanner.git
cd SNI-Scanner
chmod +x scan.sh
```

Run it:

```bash
./scan.sh
```

---

## 🧠 How It Works

1. Resolves target using:

   ```bash
   dig +short domain.com
   ```

2. Extracts the first IPv4 address.

3. Attempts TCP connection to each port using Bash's built-in TCP:

   ```bash
   echo > /dev/tcp/IP/PORT
   ```

4. Classifies results as:

   * ✅ `OPEN`
   * ❌ `CLOSED`
   * ❓ `DNS_FAIL`

5. Sorts OPEN targets by number of open ports.

6. Saves structured output into:

   ```
   ./sni_logs/scan_YYYYMMDD_HHMMSS.log
   ```

---

## 📂 Input Modes

### 1️⃣ Embedded Default List

Includes curated infrastructure targets:

* CDNs
* Certificate Authorities
* Developer platforms
* Linux distributions
* Security tools
* Research platforms

Zero configuration needed.

---

### 2️⃣ Local File

File format:

```
example.com
1.2.3.4
sub.domain.net
```

Rules:

* One domain/IP per line
* Blank lines ignored
* Lines starting with `#` are treated as comments
* Windows CRLF handled automatically

---

### 3️⃣ Remote URL

Provide a direct URL to a raw `.txt` file.

Example:

```
https://example.com/targets.txt
```

The file is downloaded temporarily and scanned.

---

### 4️⃣ Single Target

Quick scan for one domain or IP.

Perfect for fast diagnostics.

---

## 📊 Output Example

```
✔ example.com                    93.184.216.34   [2]  ports: 80,443
✖ closed-domain.com              192.0.2.10
? invalid-domain.test            no resolve
```

### Summary Block

```
✔ OPEN     12
✖ CLOSED   34
? DNS FAIL 3
```

---

## 📁 Logs

All scans are automatically saved inside:

```
sni_logs/
 └── scan_20260417_153012.log
```

Each log includes:

* Timestamp
* Categorized results
* Sorted OPEN entries
* Final summary

---

## ⚡ Performance Notes

* Uses `timeout 2` per port
* Sequential scanning (stable & predictable)
* Designed for reliability over aggressive speed
* No external scanning tools required

---

## 🔐 Disclaimer

This tool is intended for:

* Educational purposes
* Security research
* Infrastructure auditing
* Personal server diagnostics

⚠️ Do NOT scan networks you do not own or do not have permission to test.

Unauthorized scanning may violate laws in your jurisdiction.

---

## 🟢 License

MIT License — Free to use, modify, and distribute.

---

## 👨‍💻 Final Words

Clean Bash.
No dependencies beyond the basics.
Green text. Black background.

**Welcome to the real world.**
