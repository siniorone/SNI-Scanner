#!/usr/bin/env python3
"""
SNI SCANNER — MATRIX EDITION (GUI)
Cross-platform GUI version with embedded terminal
"""

import tkinter as tk
from tkinter import ttk, filedialog, scrolledtext
import threading
import socket
import subprocess
import tempfile
import os
from datetime import datetime
from pathlib import Path
import urllib.request
import queue

# ══════════════════════════════════════════════════════════════
#  CONFIGURATION
# ══════════════════════════════════════════════════════════════
PORTS = [443, 80, 8080, 8443, 2053, 2083, 2087, 2096]
LOG_DIR = Path(__file__).parent / "sni_logs"
LOG_DIR.mkdir(exist_ok=True)

DEFAULT_TARGETS = """cloudflare.com
cdn.cloudflare.net
1dot1dot1dot1.cloudflare-dns.com
fastly.com
cdn.fastly.net
akamai.com
akamaized.net
edgecastcdn.net
cloudfront.net
azureedge.net
storage.googleapis.com
cdn.jsdelivr.net
unpkg.com
cdnjs.cloudflare.com
letsencrypt.org
acme-v02.api.letsencrypt.org
r3.o.lencr.org
pki.goog
ocsp.digicert.com
digicert.com
sectigo.com
certum.eu
usertrust.com
comodoca.com
ssl.com
globalsign.com
entrust.net
trustwave.com
github.com
raw.githubusercontent.com
gitlab.com
bitbucket.org
npmjs.com
pypi.org
crates.io
pkg.go.dev
golang.org
nodejs.org
python.org
rust-lang.org
ruby-lang.org
php.net
openjdk.org
kotlinlang.org
swift.org
llvm.org
cmake.org
gnu.org
ubuntu.com
debian.org
archlinux.org
alpinelinux.org
fedoraproject.org
centos.org
opensuse.org
kernel.org
launchpad.net
packages.debian.org
arxiv.org
scholar.google.com
sciencedirect.com
scopus.com
link.springer.com
pubmed.ncbi.nlm.nih.gov
researchgate.net
academia.edu
ieee.org
tandfonline.com
jstor.org
nature.com
science.org
cell.com
plos.org
openssl.org
wireguard.com
openvpn.net
curl.se
libsodium.org
gnupg.org
openssh.com
torproject.org
eff.org
certbot.eff.org
hcaptcha.com
recaptcha.net
react.dev
nextjs.org
vuejs.org
angular.io
svelte.dev
vercel.com
vercel.app
netlify.com
heroku.com
railway.app
stackoverflow.com
askubuntu.com
superuser.com
serverfault.com
sourceforge.net
speedtest.net
fast.com
ipinfo.io
ifconfig.me
mozilla.org
firefox.com
thunderbird.net
w3.org
ietf.org
rfc-editor.org"""


# ══════════════════════════════════════════════════════════════
#  SCANNER CORE
# ══════════════════════════════════════════════════════════════
def resolve_dns(domain):
    """Resolve domain to IP"""
    try:
        return socket.gethostbyname(domain)
    except:
        return None


def scan_port(ip, port, timeout=2):
    """Check if port is open"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False


def scan_target(target):
    """Scan single target"""
    ip = resolve_dns(target)
    
    if not ip:
        return {"status": "DNS_FAIL", "target": target, "count": 0}
    
    open_ports = [port for port in PORTS if scan_port(ip, port)]
    
    if not open_ports:
        return {"status": "CLOSED", "target": target, "count": 0, "ip": ip}
    
    return {
        "status": "OPEN",
        "target": target,
        "count": len(open_ports),
        "ip": ip,
        "ports": open_ports
    }


# ══════════════════════════════════════════════════════════════
#  GUI APPLICATION
# ══════════════════════════════════════════════════════════════
class SNIScannerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("SNI SCANNER — MATRIX EDITION")
        self.root.geometry("900x700")
        self.root.configure(bg="#0d0d0d")
        
        self.scanning = False
        self.log_queue = queue.Queue()
        
        self.setup_ui()
        self.process_log_queue()
    
    def setup_ui(self):
        """Setup UI components"""
        # ── Header ──
        header = tk.Frame(self.root, bg="#0d0d0d")
        header.pack(fill=tk.X, padx=10, pady=10)
        
        title = tk.Label(
            header,
            text="SNI SCANNER — MATRIX EDITION",
            font=("Courier New", 18, "bold"),
            fg="#00ff00",
            bg="#0d0d0d"
        )
        title.pack()
        
        subtitle = tk.Label(
            header,
            text='"Follow the white rabbit" — Neo',
            font=("Courier New", 10),
            fg="#00aa00",
            bg="#0d0d0d"
        )
        subtitle.pack()
        
        # ── Control Panel ──
        control = tk.Frame(self.root, bg="#0d0d0d")
        control.pack(fill=tk.X, padx=10, pady=5)
        
        btn_style = {
            "font": ("Courier New", 10),
            "bg": "#1a1a1a",
            "fg": "#00ff00",
            "activebackground": "#00ff00",
            "activeforeground": "#000000",
            "relief": tk.FLAT,
            "cursor": "hand2",
            "padx": 15,
            "pady": 8
        }
        
        tk.Button(control, text="Default List", command=self.scan_default, **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(control, text="Load File", command=self.scan_file, **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(control, text="From URL", command=self.scan_url, **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(control, text="Single Target", command=self.scan_single, **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(control, text="Clear", command=self.clear_terminal, **btn_style).pack(side=tk.LEFT, padx=2)
        
        # ── Progress Bar ──
        self.progress_frame = tk.Frame(self.root, bg="#0d0d0d")
        self.progress_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.progress = ttk.Progressbar(
            self.progress_frame,
            mode='determinate',
            style="Matrix.Horizontal.TProgressbar"
        )
        self.progress.pack(fill=tk.X, side=tk.LEFT, expand=True)
        
        self.progress_label = tk.Label(
            self.progress_frame,
            text="Ready",
            font=("Courier New", 9),
            fg="#00aa00",
            bg="#0d0d0d",
            width=15
        )
        self.progress_label.pack(side=tk.LEFT, padx=5)
        
        # ── Terminal ──
        terminal_frame = tk.Frame(self.root, bg="#0d0d0d")
        terminal_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.terminal = scrolledtext.ScrolledText(
            terminal_frame,
            font=("Courier New", 9),
            bg="#000000",
            fg="#00ff00",
            insertbackground="#00ff00",
            selectbackground="#00aa00",
            selectforeground="#000000",
            relief=tk.FLAT,
            wrap=tk.WORD
        )
        self.terminal.pack(fill=tk.BOTH, expand=True)
        
        # ── Status Bar ──
        status = tk.Frame(self.root, bg="#1a1a1a", height=25)
        status.pack(fill=tk.X, side=tk.BOTTOM)
        
        self.status_label = tk.Label(
            status,
            text=f"Log Directory: {LOG_DIR}",
            font=("Courier New", 8),
            fg="#00aa00",
            bg="#1a1a1a",
            anchor=tk.W
        )
        self.status_label.pack(fill=tk.X, padx=5)
        
        # ── Style ──
        style = ttk.Style()
        style.theme_use('default')
        style.configure(
            "Matrix.Horizontal.TProgressbar",
            background="#00ff00",
            troughcolor="#1a1a1a",
            bordercolor="#0d0d0d",
            lightcolor="#00ff00",
            darkcolor="#00aa00"
        )
        
        self.log("═" * 80)
        self.log("SNI SCANNER — Ready")
        self.log("═" * 80)
    
    def log(self, message, color=None):
        """Add message to terminal"""
        self.log_queue.put((message, color))
    
    def process_log_queue(self):
        """Process log queue"""
        try:
            while True:
                message, color = self.log_queue.get_nowait()
                
                if color:
                    tag = f"color_{color}"
                    self.terminal.tag_config(tag, foreground=color)
                    self.terminal.insert(tk.END, message + "\n", tag)
                else:
                    self.terminal.insert(tk.END, message + "\n")
                
                self.terminal.see(tk.END)
        except queue.Empty:
            pass
        
        self.root.after(100, self.process_log_queue)
    
    def clear_terminal(self):
        """Clear terminal"""
        self.terminal.delete(1.0, tk.END)
        self.log("Terminal cleared")
    
    def update_progress(self, current, total, target=""):
        """Update progress bar"""
        if total > 0:
            pct = int((current / total) * 100)
            self.progress['value'] = pct
            self.progress_label.config(text=f"{pct}% » {target[:12]}")
        self.root.update_idletasks()
    
    def scan_targets(self, targets, source_name):
        """Scan list of targets"""
        if self.scanning:
            self.log("⚠ Scan already in progress", "#ffaa00")
            return
        
        self.scanning = True
        thread = threading.Thread(
            target=self._scan_worker,
            args=(targets, source_name),
            daemon=True
        )
        thread.start()
    
    def _scan_worker(self, targets, source_name):
        """Worker thread for scanning"""
        targets = [t.strip() for t in targets if t.strip() and not t.startswith('#')]
        total = len(targets)
        
        if total == 0:
            self.log("✖ No valid targets found", "#ff0000")
            self.scanning = False
            return
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = LOG_DIR / f"scan_{timestamp}.log"
        
        self.log("\n" + "═" * 80)
        self.log(f"SCAN STARTED — {source_name}")
        self.log(f"Targets: {total} | Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.log(f"Log: {log_file}")
        self.log("═" * 80 + "\n")
        
        results = {"OPEN": [], "CLOSED": [], "DNS_FAIL": []}
        
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write("═" * 80 + "\n")
            f.write(f"SNI SCAN — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Source: {source_name}\n")
            f.write(f"Total targets: {total}\n")
            f.write("═" * 80 + "\n\n")
            
            for idx, target in enumerate(targets, 1):
                self.update_progress(idx, total, target)
                
                result = scan_target(target)
                results[result["status"]].append(result)
                
                # Log to file
                if result["status"] == "OPEN":
                    ports_str = ",".join(map(str, result["ports"]))
                    line = f"✔ {result['target']:<35} OPEN({result['count']:<2}) ip={result['ip']:<15} ports={ports_str}\n"
                    f.write(line)
                    self.log(f"✔ {result['target']:<35} {result['ip']:<15} [{result['count']}] {ports_str}", "#00ff00")
                elif result["status"] == "CLOSED":
                    line = f"✖ {result['target']:<35} CLOSED   ip={result['ip']}\n"
                    f.write(line)
                    self.log(f"✖ {result['target']:<35} {result['ip']:<15} CLOSED", "#ffaa00")
                else:
                    line = f"? {result['target']:<35} DNS FAIL\n"
                    f.write(line)
                    self.log(f"? {result['target']:<35} DNS FAIL", "#ff0000")
            
            # Summary
            f.write("\n" + "═" * 80 + "\n")
            f.write("SUMMARY\n")
            f.write("═" * 80 + "\n")
            f.write(f"OPEN: {len(results['OPEN'])}\n")
            f.write(f"CLOSED: {len(results['CLOSED'])}\n")
            f.write(f"DNS_FAIL: {len(results['DNS_FAIL'])}\n")
        
        self.log("\n" + "═" * 80)
        self.log("SCAN COMPLETED")
        self.log(f"✔ OPEN: {len(results['OPEN'])}  ✖ CLOSED: {len(results['CLOSED'])}  ? DNS_FAIL: {len(results['DNS_FAIL'])}")
        self.log(f"Log saved: {log_file}")
        self.log("═" * 80 + "\n")
        
        self.progress['value'] = 0
        self.progress_label.config(text="Done")
        self.scanning = False
    
    def scan_default(self):
        """Scan default list"""
        targets = DEFAULT_TARGETS.strip().split('\n')
        self.scan_targets(targets, "Embedded Default List")
    
    def scan_file(self):
        """Scan from file"""
        filepath = filedialog.askopenfilename(
            title="Select Target List",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if not filepath:
            return
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                targets = f.readlines()
            self.scan_targets(targets, f"File: {Path(filepath).name}")
        except Exception as e:
            self.log(f"✖ Error reading file: {e}", "#ff0000")
    
    def scan_url(self):
        """Scan from URL"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Download from URL")
        dialog.geometry("500x150")
        dialog.configure(bg="#0d0d0d")
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(
            dialog,
            text="Enter URL:",
            font=("Courier New", 10),
            fg="#00ff00",
            bg="#0d0d0d"
        ).pack(pady=10)
        
        url_entry = tk.Entry(
            dialog,
            font=("Courier New", 10),
            bg="#1a1a1a",
            fg="#00ff00",
            insertbackground="#00ff00",
            relief=tk.FLAT
        )
        url_entry.pack(fill=tk.X, padx=20, pady=5)
        url_entry.focus()
        
        def download():
            url = url_entry.get().strip()
            if not url:
                return
            
            dialog.destroy()
            self.log(f"Downloading from: {url}")
            
            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    content = response.read().decode('utf-8')
                    targets = content.split('\n')
                    self.scan_targets(targets, f"URL: {url}")
            except Exception as e:
                self.log(f"✖ Download failed: {e}", "#ff0000")
        
        tk.Button(
            dialog,
            text="Download & Scan",
            command=download,
            font=("Courier New", 10),
            bg="#1a1a1a",
            fg="#00ff00",
            activebackground="#00ff00",
            activeforeground="#000000",
            relief=tk.FLAT,
            cursor="hand2"
        ).pack(pady=10)
    
    def scan_single(self):
        """Scan single target"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Scan Single Target")
        dialog.geometry("500x150")
        dialog.configure(bg="#0d0d0d")
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(
            dialog,
            text="Enter domain or IP:",
            font=("Courier New", 10),
            fg="#00ff00",
            bg="#0d0d0d"
        ).pack(pady=10)
        
        target_entry = tk.Entry(
            dialog,
            font=("Courier New", 10),
            bg="#1a1a1a",
            fg="#00ff00",
            insertbackground="#00ff00",
            relief=tk.FLAT
        )
        target_entry.pack(fill=tk.X, padx=20, pady=5)
        target_entry.focus()
        
        def scan():
            target = target_entry.get().strip()
            if not target:
                return
            
            dialog.destroy()
            self.scan_targets([target], f"Single: {target}")
        
        tk.Button(
            dialog,
            text="Scan",
            command=scan,
            font=("Courier New", 10),
            bg="#1a1a1a",
            fg="#00ff00",
            activebackground="#00ff00",
            activeforeground="#000000",
            relief=tk.FLAT,
            cursor="hand2"
        ).pack(pady=10)


# ══════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════
if __name__ == "__main__":
    root = tk.Tk()
    app = SNIScannerGUI(root)
    root.mainloop()
