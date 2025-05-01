#!/bin/bash

# BlackLantern: Network scanner & analyzer
# Author: Daniel Axelson

# Configuration
network_prefix="192.168.0"
subnet="/24"
output_dir="attack_results/scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$output_dir"

json_output="$output_dir/scan_report.json"
echo "[]" > "$json_output"

echo "[+] Scanning network for alive hosts on $network_prefix$subnet..."

# Get alive IPs
alive_ips=$(nmap -sn "$network_prefix$subnet" | grep "Nmap scan report" | awk '{print $NF}')
echo "[+] Alive IPs found:"
echo "$alive_ips"

# Loop through each alive IP and scan
echo "[+] Scanning alive hosts for open ports and doing analysis..."

for ip in $alive_ips; do
    echo "[*] Processing $ip..."

    # Get open ports
    open_ports=$(nmap -p- --min-rate=1000 -T4 "$ip" | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$open_ports" ]]; then
        echo "[*] $ip open ports: none"
    else
        echo "[*] $ip open ports: $open_ports"
    fi

    # Dummy hostname & severity logic (placeholder)
    hostname=$(nslookup "$ip" | grep 'name =' | awk '{print $4}' | sed 's/\.$//')
    risk_severity="low"
    [[ "$open_ports" == *"22"* ]] && risk_severity="medium"
    [[ "$open_ports" == *"23"* || "$open_ports" == *"445"* ]] && risk_severity="high"

    # Dummy SSH brute force placeholder
    ssh_login=""
    [[ "$open_ports" == *"22"* ]] && ssh_login="root:toor"  # For demonstration

    # Create JSON object with jq safely
    json_entry=$(jq -n \
        --arg ip "$ip" \
        --arg hostname "$hostname" \
        --arg ports "$open_ports" \
        --arg severity "$risk_severity" \
        --arg sshlogin "$ssh_login" '
        {
            ip: $ip,
            hostname: $hostname,
            open_ports: ($ports | split(",") | map(select(length > 0))),
            risk: $severity,
            ssh_bruteforce: ($sshlogin | length > 0 ? $sshlogin : null)
        }')

    # Append to JSON file
    tmpfile=$(mktemp)
    jq ". += [$json_entry]" "$json_output" > "$tmpfile" && mv "$tmpfile" "$json_output"
done

echo "[+] Full scan and analysis complete!"
echo "[*] JSON report saved to: $json_output"
