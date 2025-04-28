#!/bin/bash

# ========== Settings ==========
NETWORK_RANGE="192.168.0.0/24"
RESULTS_DIR="attack_results"
RESULT_JSON="$RESULTS_DIR/scan_report.json"
COMMON_PORTS="21,22,23,25,80,443,445,139,3306,3389,6379,8080,5900"

# Create results folder
mkdir -p "$RESULTS_DIR"

# Empty previous JSON
echo "[]" > "$RESULT_JSON"

# ========== 1. Find Alive Hosts ==========
echo "[+] Scanning network for alive hosts on $NETWORK_RANGE..."
ALIVE_IPS=$(nmap -sn "$NETWORK_RANGE" -oG - | awk '/Up$/{print $2}')

if [[ -z "$ALIVE_IPS" ]]; then
    echo "[!] No alive hosts found. Exiting."
    exit 1
fi

echo "[+] Alive IPs found:"
echo "$ALIVE_IPS"

# ========== 2. Scan Alive Hosts and Analyze ==========
echo "[+] Scanning alive hosts for open ports and doing analysis..."

REPORTS=()

for ip in $ALIVE_IPS; do
    echo "[*] Scanning $ip..."
    
    # Get open ports
    OPEN_PORTS=$(nmap -p "$COMMON_PORTS" --open "$ip" -oG - | awk '/Ports:/{print $0}' | sed 's/.*Ports: //' | awk -F'/' '{print $1}' | paste -sd, -)

    # Lookup hostname
    HOSTNAME=$(getent hosts "$ip" | awk '{print $2}')
    if [[ -z "$HOSTNAME" ]]; then
        HOSTNAME="(no hostname)"
    fi

    # Security Analysis based on open ports
    SEVERITY="low"
    if echo "$OPEN_PORTS" | grep -qE "(23|445|139)"; then
        SEVERITY="high"
    elif echo "$OPEN_PORTS" | grep -qE "(21|3306|6379|5900)"; then
        SEVERITY="medium"
    elif echo "$OPEN_PORTS" | grep -qE "(80|443|8080)"; then
        SEVERITY="low"
    fi

    # If many critical ports are open
    if [[ $(echo "$OPEN_PORTS" | tr ',' '\n' | wc -l) -ge 5 ]]; then
        SEVERITY="critical"
    fi

    # Save individual report
    REPORT=$(jq -n \
        --arg ip "$ip" \
        --arg hostname "$HOSTNAME" \
        --arg ports "$OPEN_PORTS" \
        --arg severity "$SEVERITY" \
        '{ip: $ip, hostname: $hostname, open_ports: ($ports | split(",")), risk: $severity}'
    )
    
    REPORTS+=("$REPORT")
done

# Write final JSON
jq -s '.' <<< "${REPORTS[@]}" > "$RESULT_JSON"

echo "[+] Full scan and analysis complete!"
echo "[*] JSON report saved to: $RESULT_JSON"
