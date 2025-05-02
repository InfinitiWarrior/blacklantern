#!/bin/bash

# ========== Config ==========
NETWORK_RANGE="192.168.0.0/24"
RESULTS_DIR="attack_results"
COMMON_PORTS="21,22,23,25,80,443,445,139,3306,3389,6379,8080,5900"

# Output files
ALIVE_IPS="$RESULTS_DIR/alive_ips.txt"
PING_SWEEP="$RESULTS_DIR/ping_sweep.gnmap"
SCAN_RESULTS="$RESULTS_DIR/nmap_scan.gnmap"
JSON_OUTPUT="$RESULTS_DIR/security_report.json"

# ========== Setup ==========
mkdir -p "$RESULTS_DIR"
echo "[]" > "$JSON_OUTPUT"

# ========== 1. Ping Sweep ==========
echo "[+] Scanning for alive hosts in $NETWORK_RANGE..."
nmap -sn "$NETWORK_RANGE" -oG "$PING_SWEEP"
grep "Up" "$PING_SWEEP" | awk '{print $2}' > "$ALIVE_IPS"

# ========== 2. Port Scan ==========
echo "[+] Scanning open ports on alive hosts..."
nmap -p "$COMMON_PORTS" --open -oG "$SCAN_RESULTS" -iL "$ALIVE_IPS"

# ========== 3. Analyze and Build JSON ==========
echo "[+] Analyzing scan results and assigning risk levels..."

while read -r ip; do
    OPEN_PORTS=$(grep "$ip" "$SCAN_RESULTS" | grep -oP "Ports: \K.*" | cut -d '/' -f 1 | cut -d ',' -f1 | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$OPEN_PORTS" ]]; then
        continue
    fi

    # Default severity logic
    SEVERITY="low"
    if echo "$OPEN_PORTS" | grep -qE "445|139"; then
        SEVERITY="critical"
    elif echo "$OPEN_PORTS" | grep -qE "23|3389"; then
        SEVERITY="high"
    elif echo "$OPEN_PORTS" | grep -qE "22|21|3306|6379|5900"; then
        SEVERITY="medium"
    fi

    # Get hostname if available
    HOSTNAME=$(nslookup "$ip" 2>/dev/null | awk -F'name = ' '/name =/ {gsub(/\.$/, "", $2); print $2}' | head -n1)
    [[ -z "$HOSTNAME" ]] && HOSTNAME="(no hostname)"

    # Add result to JSON
    jq --arg ip "$ip" \
       --arg hostname "$HOSTNAME" \
       --arg ports "$OPEN_PORTS" \
       --arg severity "$SEVERITY" \
       '. += [{"ip": $ip, "hostname": $hostname, "open_ports": ($ports | split(",")), "severity": $severity}]' \
       "$JSON_OUTPUT" > "$JSON_OUTPUT.tmp" && mv "$JSON_OUTPUT.tmp" "$JSON_OUTPUT"

done < "$ALIVE_IPS"

# ========== 4. Placeholder for Credential Brute-Forcing ==========
echo "[+] Starting username/password guessing phase... (placeholder)"

# Future logic: Update severity in JSON if weak login is found
# Example logic for SSH brute-force:
# while read -r ip; do
#     hydra -L usernames.txt -P passwords.txt ssh://$ip -f -t 4 -o hydra_output.txt
#     if grep -q "login:" hydra_output.txt; then
#         # Update JSON severity to critical for that IP
#         jq --arg ip "$ip" 'map(if .ip == $ip then .severity = "critical" else . end)' \
#         "$JSON_OUTPUT" > "$JSON_OUTPUT.tmp" && mv "$JSON_OUTPUT.tmp" "$JSON_OUTPUT"
#     fi
# done < "$ALIVE_IPS"

# ========== Done ==========
echo "[✓] Scan complete. Results saved to $JSON_OUTPUT"
jq . "$JSON_OUTPUT"
