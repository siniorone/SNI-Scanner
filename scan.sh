#!/usr/bin/env bash
# ============================================================
#  SNI SCANNER — MATRIX EDITION
#  Scans common ports for SNI/TLS availability
# ============================================================

# ── Ports to scan ──────────────────────────────────────────
PORTS=(443 80 8080 8443 2053 2083 2087 2096)

# ── Colors ─────────────────────────────────────────────────
G='\033[0;32m'   # green
DG='\033[2;32m'  # dim green
BG='\033[1;32m'  # bold green
R='\033[0;31m'   # red
Y='\033[0;33m'   # yellow
C='\033[0;36m'   # cyan
W='\033[1;37m'   # white
N='\033[0m'      # reset

# ── Log directory ──────────────────────────────────────────
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sni_logs"
mkdir -p "$LOG_DIR" || { echo "ERROR: Cannot create log dir: $LOG_DIR"; exit 1; }

# ── Embedded default target list ───────────────────────────
read -r -d '' DEFAULT_TARGETS << 'EOF'
cloudflare.com
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
rfc-editor.org
EOF

# ══════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════
print_banner() {
    clear
    echo -e "${BG}"
    echo "  ╔════════════════════════════════════════════╗"
    echo "  ║     SNI SCANNER — MATRIX EDITION           ║"
    echo "  ║  \"Follow the white rabbit\" — Neo           ║"
    echo "  ║     SNI SCANNER — MATRIX EDITION           ║"
    echo "  ╚════════════════════════════════════════════╝"
    echo -e "${N}\n"
}

# ══════════════════════════════════════════════════════════════
#  MENU
# ══════════════════════════════════════════════════════════════
print_menu() {
    echo -e "${BG}  ┌──────────────────────────────────────┐${N}"
    echo -e "${BG}  │           SELECT INPUT SOURCE        │${N}"
    echo -e "${BG}  ├──────────────────────────────────────┤${N}"
    echo -e "${BG}  │${G}  1 ${W}» Use embedded default list       ${BG}│${N}"
    echo -e "${BG}  │${G}  2 ${W}» Load from local file            ${BG}│${N}"
    echo -e "${BG}  │${G}  3 ${W}» Download from remote URL        ${BG}│${N}"
    echo -e "${BG}  │${G}  4 ${W}» Scan a single domain / IP       ${BG}│${N}"
    echo -e "${BG}  │${G}  0 ${W}» Exit                            ${BG}│${N}"
    echo -e "${BG}  └──────────────────────────────────────┘${N}"
    echo -ne "${G}  ❯ Choose [0-4]: ${N}"
}

# ══════════════════════════════════════════════════════════════
#  PROGRESS BAR
# ══════════════════════════════════════════════════════════════
progress_bar() {
    local current=$1
    local total=$2
    local target=$3

    local bar_width=30
    local pct=$(( total > 0 ? current * 100 / total : 0 ))
    local filled=$(( pct * bar_width / 100 ))
    local empty=$(( bar_width - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty;  i++)); do bar+="░"; done

    local display_target="${target:0:35}"
    printf "\r${DG}  [${BG}%s${DG}] ${G}%3d%% ${DG}» ${C}%-35s${N}" \
        "$bar" "$pct" "$display_target"
}

# ══════════════════════════════════════════════════════════════
#  SCAN ONE TARGET
# ══════════════════════════════════════════════════════════════
scan_target() {
    local target=$1
    local ip
    ip=$(dig +short "$target" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)

    if [[ -z "$ip" ]]; then
        echo "DNS_FAIL|$target|0"
        return
    fi

    local open_ports=()
    for port in "${PORTS[@]}"; do
        if timeout 2 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
            open_ports+=("$port")
        fi
    done

    local count=${#open_ports[@]}
    if [[ $count -eq 0 ]]; then
        echo "CLOSED|$target|0|$ip"
    else
        local joined
        joined=$(IFS=','; echo "${open_ports[*]}")
        echo "OPEN|$target|$count|$ip|$joined"
    fi
}

# ══════════════════════════════════════════════════════════════
#  SCAN FROM FILE / LIST
# ══════════════════════════════════════════════════════════════
scan_from_file() {
    local filepath=$1
    local results=()
    local targets=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line// /}"
        line="${line//$'\r'/}"
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        targets+=("$line")
    done < "$filepath"

    local total=${#targets[@]}
    if [[ $total -eq 0 ]]; then
        echo -e "\n${R}  [!] No targets found in list.${N}"
        return
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local LIVE_LOG="$LOG_DIR/scan_$timestamp.log"

    {
        echo "════════════════════════════════════════════════════════════"
        echo "SNI SCAN — Started at $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Total targets: $total"
        echo "════════════════════════════════════════════════════════════"
        echo ""
    } > "$LIVE_LOG"

    echo -e "\n${DG}  Scanning ${BG}$total${DG} targets ...${N}"
    echo -e "${DG}  Live log: ${C}$LIVE_LOG${N}\n"

    local idx=0
    local last_line=""

    for target in "${targets[@]}"; do
        ((idx++))

        local result
        result="$(scan_target "$target")"

        # ذخیره فوری در لاگ
        echo "$result" >> "$LIVE_LOG"

        results+=("$result")

        # ساخت خط نمایش رنگی زیر progress bar
        case "$result" in
            OPEN*)
                IFS='|' read -r _ t cnt ip ports <<< "$result"
                last_line="$(printf "${G}  ✔  ${BG}%-35s ${C}%-15s ${DG}ports: ${G}%s${N}" "$t" "$ip" "$ports")"
                ;;
            CLOSED*)
                IFS='|' read -r _ t _ ip <<< "$result"
                last_line="$(printf "${R}  ✖  ${DG}%-35s ${Y}%s  CLOSED${N}" "$t" "$ip")"
                ;;
            DNS_FAIL*)
                IFS='|' read -r _ t _ <<< "$result"
                last_line="$(printf "${R}  ?  ${DG}%-35s ${R}DNS FAIL${N}" "$t")"
                ;;
        esac

        # پاک کردن دو خط قبلی و رسم مجدد
        printf "\033[2K"
        progress_bar "$idx" "$total" "$target"
        printf "\n\033[2K%b\n" "$last_line"
        # برگشت دو خط بالا برای overwrite در دور بعدی
        printf "\033[2A"
    done

    # رفتن به پایین دو خط بعد از حلقه
    printf "\n\n"

    # ── append نتیجه نهایی به همان فایل لاگ ──────────────
    {
        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "FINAL RESULTS — $(date '+%Y-%m-%d %H:%M:%S')"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        local open_r=() closed_r=() dns_r=()
        for line in "${results[@]}"; do
            case "$line" in
                OPEN*)     open_r+=("$line")   ;;
                CLOSED*)   closed_r+=("$line") ;;
                DNS_FAIL*) dns_r+=("$line")    ;;
            esac
        done

        if [[ ${#open_r[@]} -gt 0 ]]; then
            echo "▸ OPEN (${#open_r[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${open_r[@]}"; do
                IFS='|' read -r _ t cnt ip ports <<< "$line"
                printf "✔  %-35s OPEN(%-2s) ip=%-15s ports=%s\n" "$t" "$cnt" "$ip" "$ports"
            done
            echo ""
        fi

        if [[ ${#closed_r[@]} -gt 0 ]]; then
            echo "▸ CLOSED (${#closed_r[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${closed_r[@]}"; do
                IFS='|' read -r _ t _ ip <<< "$line"
                printf "✖  %-35s CLOSED   ip=%s\n" "$t" "$ip"
            done
            echo ""
        fi

        if [[ ${#dns_r[@]} -gt 0 ]]; then
            echo "▸ DNS RESOLVE FAILED (${#dns_r[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${dns_r[@]}"; do
                IFS='|' read -r _ t _ <<< "$line"
                printf "?  %-35s DNS RESOLVE FAILED\n" "$t"
            done
            echo ""
        fi

        echo "════════════════════════════════════════════════════════════"
        echo "SUMMARY  OPEN=${#open_r[@]}  CLOSED=${#closed_r[@]}  DNS_FAIL=${#dns_r[@]}"
        echo "════════════════════════════════════════════════════════════"
    } >> "$LIVE_LOG"

    echo -e "${G}  ✓ Log saved: ${C}$LIVE_LOG${N}\n"

    display_results "${results[@]}"
}


# ══════════════════════════════════════════════════════════════
#  DISPLAY RESULTS
# ══════════════════════════════════════════════════════════════
display_results() {
    local -a closed_list dns_fail_list open_list
    local line

    for line in "$@"; do
        case "$line" in
            CLOSED*)    closed_list+=("$line")   ;;
            DNS_FAIL*)  dns_fail_list+=("$line") ;;
            OPEN*)      open_list+=("$line")     ;;
        esac
    done

    # مرتب‌سازی OPEN بر اساس تعداد پورت (کمترین بالاتر)
    IFS=$'\n' open_list=($(
        for l in "${open_list[@]}"; do
            cnt=$(echo "$l" | cut -d'|' -f3)
            echo "$cnt $l"
        done | sort -n | cut -d' ' -f2-
    ))
    unset IFS

    # ── نمایش در ترمینال ───────────────────────────────────
    echo -e "\n${DG}  ┌────────────────────────────────────────────────────┐${N}"
    echo -e "${DG}  │${BG}              SCAN RESULTS                          ${DG}│${N}"
    echo -e "${DG}  └────────────────────────────────────────────────────┘${N}"

    # ── CLOSED ─────────────────────────────────────────────
    if [[ ${#closed_list[@]} -gt 0 ]]; then
        echo -e "\n${Y}  ╔═  CLOSED  (${#closed_list[@]})${N}"
        echo -e "${DG}  ║${N}"
        for line in "${closed_list[@]}"; do
            IFS='|' read -r status target _ ip <<< "$line"
            printf "  ${DG}║  ${R}✖  ${DG}%-35s ${Y}%-15s${N}\n" "$target" "$ip"
        done
        echo -e "${DG}  ║${N}"
    fi

    # ── OPEN ───────────────────────────────────────────────
    if [[ ${#open_list[@]} -gt 0 ]]; then
        echo -e "\n${BG}  ╔═  OPEN  (${#open_list[@]})${N}"
        echo -e "${DG}  ║${N}"
        for line in "${open_list[@]}"; do
            IFS='|' read -r status target count ip ports <<< "$line"
            printf "  ${DG}║  ${G}✔  ${BG}%-35s ${C}%-15s ${DG}[%s]  ports: ${G}%s${N}\n" \
                "$target" "$ip" "$count" "$ports"
        done
        echo -e "${DG}  ║${N}"
    fi

    # ── DNS FAIL ───────────────────────────────────────────
    if [[ ${#dns_fail_list[@]} -gt 0 ]]; then
        echo -e "\n${R}  ╔═  DNS FAILED  (${#dns_fail_list[@]})${N}"
        echo -e "${DG}  ║${N}"
        for line in "${dns_fail_list[@]}"; do
            IFS='|' read -r status target _ <<< "$line"
            printf "  ${DG}║  ${R}?  %-35s ${DG}no resolve${N}\n" "$target"
        done
        echo -e "${DG}  ║${N}"
    fi

    # ── SUMMARY ────────────────────────────────────────────
    echo -e "\n${DG}  ┌────────────────────────────────────────────────────┐${N}"
    printf   "  ${DG}│${N}  ${G}✔ OPEN   ${BG}%-4s${N}  ${R}✖ CLOSED  ${Y}%-4s${N}  ${R}? DNS FAIL  ${R}%-4s${N}  ${DG}│${N}\n" \
        "${#open_list[@]}" "${#closed_list[@]}" "${#dns_fail_list[@]}"
    echo -e "${DG}  └────────────────────────────────────────────────────┘${N}\n"
}


# ══════════════════════════════════════════════════════════════
#  MAIN LOOP
# ══════════════════════════════════════════════════════════════
main() {
    while true; do
        print_banner
        print_menu
        read -r choice

        case "$choice" in
            1)
                local tmp_default
                tmp_default=$(mktemp /tmp/sni_default_XXXXXX.txt)
                echo "$DEFAULT_TARGETS" | grep -v '^[[:space:]]*$' > "$tmp_default"
                scan_from_file "$tmp_default"
                rm -f "$tmp_default"
                echo -ne "${G}  Press ENTER to return to menu ...${N}"
                read -r
                ;;

            2)
                echo -e "\n${BG}  ┌──────────────────────────────────────────────────┐${N}"
                echo -e "${BG}  │  HOW TO USE LOCAL FILE                           │${N}"
                echo -e "${BG}  ├──────────────────────────────────────────────────┤${N}"
                echo -e "${BG}  │${DG}  • Copy your list file into this folder, or      ${BG}│${N}"
                echo -e "${BG}  │${DG}    provide a relative / absolute path            ${BG}│${N}"
                echo -e "${BG}  │${DG}  • File format: one domain or IP per line        ${BG}│${N}"
                echo -e "${BG}  │${DG}  • Example (relative):  targets.txt              ${BG}│${N}"
                echo -e "${BG}  │${DG}  • Example (absolute):  /home/user/list.txt      ${BG}│${N}"
                echo -e "${BG}  │${DG}  • Blank lines and extra spaces are ignored      ${BG}│${N}"
                echo -e "${BG}  └──────────────────────────────────────────────────┘${N}"
                echo -ne "\n${G}  Path to file: ${N}"
                read -r filepath
                
                # ── اگر فایل پیدا نشد، در کنار اسکریپت بگرد ──
                if [[ ! -f "$filepath" ]]; then
                    local script_dir
                    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                    local alt_path="$script_dir/$filepath"
                    
                    if [[ -f "$alt_path" ]]; then
                        filepath="$alt_path"
                        echo -e "${DG}  → Found: $filepath${N}"
                    else
                        echo -e "${R}  [!] File not found: $filepath${N}"
                        echo -e "${DG}      (also checked: $alt_path)${N}"
                        echo -ne "${G}  Press ENTER to return to menu ...${N}"
                        read -r
                        continue
                    fi
                fi
                
                scan_from_file "$filepath"
                echo -ne "${G}  Press ENTER to return to menu ...${N}"
                read -r
                ;;


            3)
                echo -ne "\n${G}  Enter URL: ${N}"
                read -r url
                local tmp_remote
                tmp_remote=$(mktemp /tmp/sni_remote_XXXXXX.txt)
                echo -e "${DG}  Downloading ...${N}"
                if wget -q --timeout=10 -O "$tmp_remote" "$url" 2>/dev/null; then
                    if [[ -s "$tmp_remote" ]]; then
                        scan_from_file "$tmp_remote"
                    else
                        echo -e "${R}  [!] Downloaded file is empty.${N}"
                    fi
                else
                    echo -e "${R}  [!] Download failed. Check URL or connection.${N}"
                fi
                rm -f "$tmp_remote"
                echo -ne "${G}  Press ENTER to return to menu ...${N}"
                read -r
                ;;

            4)
                echo -ne "\n${G}  Enter domain or IP: ${N}"
                read -r single
                single="${single// /}"
                if [[ -z "$single" ]]; then
                    echo -e "${R}  [!] No input given.${N}"
                else
                    echo -e "\n${DG}  Scanning ${BG}$single${DG} ...${N}\n"
                    local result
                    result=$(scan_target "$single")
                    display_results "$result"
                fi
                echo -ne "${G}  Press ENTER to return to menu ...${N}"
                read -r
                ;;

            0)
                echo -e "\n${BG}  \"There is no spoon.\"${N}\n"
                exit 0
                ;;

            *)
                echo -e "${R}  [!] Invalid choice. Try 0-4.${N}"
                sleep 1
                ;;
        esac
    done
}

main
