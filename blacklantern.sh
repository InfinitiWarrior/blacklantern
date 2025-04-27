#!/bin/bash

# ========== Settings ==========
NETWORK_RANGE="192.168.0.0/24"
RESULTS_DIR="attack_results"
ALIVE_IPS="$RESULTS_DIR/alive_ips.txt"
PING_SWEEP="$RESULTS_DIR/ping_sweep.gnmap"
SCAN_RESULTS="$RESULTS_DIR/nmap_detailed_scan.gnmap"
HOSTNAMES="$RESULTS_DIR/hostnames.txt"
COMMON_PORTS="21,22,23,25,80,443,445,139,3306,3389,6379,8080,5900"

# Create results folder
mkdir -p "$RESULTS_DIR"

# ========== 1. Find Alive Hosts ==========
echo "[+] Scanning network for alive hosts on $NETWORK_RANGE..."
nmap -sn "$NETWORK_RANGE" -oG "$PING_SWEEP"

# Extract alive IPs
grep "Up" "$PING_SWEEP" | awk '{print $2}' > "$ALIVE_IPS"

echo "[+] Alive IPs found:"
cat "$ALIVE_IPS"

# ========== 2. Scan Alive Hosts ==========
echo "[+] Scanning alive hosts for open ports..."
nmap -p "$COMMON_PORTS" --open -oG "$SCAN_RESULTS" -iL "$ALIVE_IPS"

# ========== 3. Hostname Lookup ==========
echo "[+] Resolving hostnames..."
> "$HOSTNAMES"  # Clear previous results
while read -r ip; do
    hostname=$(nslookup "$ip" 2>/dev/null | grep 'name =' | awk '{print $4}' | sed 's/\.$//')
    if [[ -n "$hostname" ]]; then
        echo "$ip $hostname" >> "$HOSTNAMES"
    else
        echo "$ip (no hostname)" >> "$HOSTNAMES"
    fi
done < "$ALIVE_IPS"

echo "[+] Hostnames saved to $HOSTNAMES"
echo ""

# ========== 4. Username / Password Guessing Placeholder ==========
echo "[+] Starting username/password guessing phase..."
echo "[!] (Placeholder) Insert brute-forcing logic here."
echo ""

# Example (fake) hydra command
# while read -r ip; do
#     echo "[*] Trying SSH login on $ip..."
#     hydra -L usernames.txt -P passwords.txt ssh://$ip
# done < "$ALIVE_IPS"

# ========== Done ==========
echo "[+] Full scan and setup complete."
echo "[*] Results stored inside: $RESULTS_DIR"
