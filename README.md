# 🕶️ SNI Scanner --- Matrix Edition

> "Follow the white rabbit." --- Neo\
> There is no spoon. Only open ports.
<img width="890" height="734" alt="image" src="https://github.com/user-attachments/assets/5d6acf69-451f-4fc9-b9ac-e6db3b9c95f7" />

<img width="890" height="473" alt="image" src="https://github.com/user-attachments/assets/020ac981-3392-45ff-90c7-22d44a7978a2" />

A stylish, interactive **Bash-based SNI/TLS port scanner** that checks
common web ports for connectivity --- wrapped in a Matrix-themed
terminal interface.

------------------------------------------------------------------------

## 🚀 Why SNI Scanner?

Lightweight. Clean. No heavy dependencies.\
Built entirely in Bash using native TCP sockets.

Perfect for:

-   🔐 Security researchers\
-   🖥 Infrastructure audits\
-   🌐 Quick connectivity diagnostics\
-   🎓 Educational purposes

------------------------------------------------------------------------

## ✨ Features

-   🔎 Scans common web & TLS ports:

    80, 443, 8080, 8443, 2053, 2083, 2087, 2096

-   🌐 DNS resolution before scanning

-   📂 Multiple input sources

-   📊 Live animated progress bar

-   🎨 Matrix-style terminal UI

-   🗂️ Automatic timestamped logging

-   📑 Sorted results (OPEN targets ranked by port count)

-   🧼 Ignores blank lines & comments

-   🧠 Pure Bash --- no external scanners required

------------------------------------------------------------------------

## 📦 Requirements

-   bash (v4+ recommended)
-   dig
-   timeout
-   wget
-   Standard GNU utilities

### Debian / Ubuntu

    sudo apt install dnsutils wget coreutils

------------------------------------------------------------------------

## ⚡ Quick Run (No Clone Required)

    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/siniorone/SNI-Scanner/main/scan.sh || exit 1)"

⚠️ Security Note:\
Always review remote scripts before executing curl \| bash in production
environments.

------------------------------------------------------------------------

## 🛠️ Offline Installation

    git clone https://github.com/siniorone/SNI-Scanner.git
    cd SNI-Scanner
    chmod +x scan.sh
    ./scan.sh

------------------------------------------------------------------------

## 🪟 Windows GUI Version

Download:
https://github.com/siniorone/SNI-Scanner/releases/download/sni/SNI_Scanner.exe

SHA256: 39c498ea468071368b935ebc671f19b7caccce8ea8e48183289521f1ff66ffc9

------------------------------------------------------------------------

## 🧠 How It Works

1.  Resolves domain using dig +short\

2.  Extracts first IPv4 address\

3.  Attempts TCP connection via /dev/tcp\

4.  Classifies results (OPEN / CLOSED / DNS_FAIL)\

5.  Sorts OPEN targets by number of open ports\

6.  Saves results into:

    sni_logs/scan_YYYYMMDD_HHMMSS.log

------------------------------------------------------------------------

## 📊 Sample Output

    ✔ example.com          93.184.216.34   [2]  ports: 80,443
    ✖ closed-domain.com    192.0.2.10
    ? invalid-domain.test  no resolve

Summary:

    ✔ OPEN     12
    ✖ CLOSED   34
    ? DNS FAIL 3

------------------------------------------------------------------------

## ⚡ Performance

-   Uses timeout 2 per port
-   Sequential scanning (predictable & stable)
-   Reliability prioritized over aggressive speed
-   No external scanning tools required

------------------------------------------------------------------------

## 🔐 Disclaimer

For educational and authorized security research use only.\
Do NOT scan networks without permission.

------------------------------------------------------------------------

## 📜 License

MIT License

------------------------------------------------------------------------

Green text. Black background.\
**Welcome to the real world.**
