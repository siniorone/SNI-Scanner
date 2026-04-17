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
LOG_DIR="./sni_logs"
mkdir -p "$LOG_DIR"

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
    echo "  ║    github.com/siniorone/SNI-Scanner        ║"
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
        line="${line//$'\r'/}"   # حذف carriage return (فایل‌های ویندوزی)
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue   # نادیده گرفتن خطوط کامنت
        targets+=("$line")
    done < "$filepath"

    local total=${#targets[@]}
    if [[ $total -eq 0 ]]; then
        echo -e "\n${R}  [!] No targets found in list.${N}"
        return
    fi

    echo -e "\n${DG}  Scanning ${BG}$total${DG} targets ...${N}\n"

    local idx=0
    for target in "${targets[@]}"; do
        ((idx++))
        progress_bar "$idx" "$total" "$target"
        results+=( "$(scan_target "$target")" )
    done

    printf "\r%-80s\r\n" " "
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

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local logfile="$LOG_DIR/scan_$timestamp.log"

    # ── ذخیره لاگ ─────────────────────────────────────────
    {
        echo "════════════════════════════════════════════════════════════"
        echo "SNI SCAN RESULTS — $(date '+%Y-%m-%d %H:%M:%S')"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        if [[ ${#closed_list[@]} -gt 0 ]]; then
            echo "▸ CLOSED (${#closed_list[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${closed_list[@]}"; do
                IFS='|' read -r status target _ ip <<< "$line"
                printf "✖  %-35s CLOSED   ip=%s\n" "$target" "$ip"
            done
            echo ""
        fi

        if [[ ${#open_list[@]} -gt 0 ]]; then
            echo "▸ OPEN (${#open_list[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${open_list[@]}"; do
                IFS='|' read -r status target count ip ports <<< "$line"
                printf "✔  %-35s OPEN(%-2s) ip=%-15s ports=%s\n" \
                    "$target" "$count" "$ip" "$ports"
            done
            echo ""
        fi

        if [[ ${#dns_fail_list[@]} -gt 0 ]]; then
            echo "▸ DNS RESOLVE FAILED (${#dns_fail_list[@]})"
            echo "────────────────────────────────────────────────────────────"
            for line in "${dns_fail_list[@]}"; do
                IFS='|' read -r status target _ <<< "$line"
                printf "?  %-35s DNS RESOLVE FAILED\n" "$target"
            done
            echo ""
        fi

        echo "════════════════════════════════════════════════════════════"
        echo "SUMMARY  OPEN=${#open_list[@]}  CLOSED=${#closed_list[@]}  DNS_FAIL=${#dns_fail_list[@]}"
        echo "════════════════════════════════════════════════════════════"
    } > "$logfile"

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
    echo -e "${DG}  └────────────────────────────────────────────────────┘${N}"
    echo -e "  ${DG}Log → ${C}$logfile${N}\n"
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
                if [[ ! -f "$filepath" ]]; then
                    echo -e "${R}  [!] File not found: $filepath${N}"
                else
                    scan_from_file "$filepath"
                fi
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
