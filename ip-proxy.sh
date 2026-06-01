#!/bin/bash
# ip-proxy — single script, auto-setup + rotate IPs every 5s
# Install: ./ip-proxy.sh install  →  service ip-proxy start

TOR_PASS="${TOR_PASS:-pr0xy@r0t4t3}"  # override: export TOR_PASS=yourpass
TOR_CTRL=9051
TOR_SOCKS=9050
INTERVAL=5
COUNTRIES="{us},{gb},{de},{nl},{fr},{se},{ch},{ca},{jp},{au},{br},{sg},{za},{mx}"

_setup_tor() {
    if ! command -v tor &>/dev/null; then
        echo "[*] Installing Tor..."
        apt-get install -y tor netcat-openbsd -qq
    fi

    HASHED=$(tor --hash-password "$TOR_PASS" 2>/dev/null | tail -1)

    # remove old ip-proxy config block if exists
    sed -i '/# ip-proxy-start/,/# ip-proxy-end/d' /etc/tor/torrc

    cat >> /etc/tor/torrc << EOF
# ip-proxy-start
ControlPort $TOR_CTRL
HashedControlPassword $HASHED
MaxCircuitDirtiness $INTERVAL
NewCircuitPeriod $INTERVAL
CircuitBuildTimeout 10
StrictNodes 1
ExitNodes $COUNTRIES
SocksPort $TOR_SOCKS
# ip-proxy-end
EOF
    systemctl restart tor
    sleep 4
}

_new_circuit() {
    printf 'AUTHENTICATE "%s"\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$TOR_PASS" \
        | nc -q1 127.0.0.1 $TOR_CTRL &>/dev/null
}

_current_ip() {
    curl -s --socks5-hostname 127.0.0.1:$TOR_SOCKS \
        --max-time 8 "https://api64.ipify.org?format=json" 2>/dev/null \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
}

_rotate_loop() {
    echo "[ip-proxy] started — rotating every ${INTERVAL}s"
    while true; do
        _new_circuit
        sleep 2
        IP=$(_current_ip)
        echo "[$(date '+%H:%M:%S')] IP → ${IP:-unavailable}"
        sleep $((INTERVAL - 2))
    done
}

case "$1" in
    install)
        _setup_tor
        # write service file
        cat > /etc/systemd/system/ip-proxy.service << EOF
[Unit]
Description=IP Proxy Rotator (Tor)
After=network.target tor.service

[Service]
Type=simple
ExecStart=/usr/local/bin/ip-proxy run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        cp "$0" /usr/local/bin/ip-proxy
        chmod +x /usr/local/bin/ip-proxy
        systemctl daemon-reload
        systemctl enable ip-proxy
        echo "[+] Installed. Use: service ip-proxy start"
        ;;
    run)
        _setup_tor
        _rotate_loop
        ;;
    ip)
        _current_ip
        ;;
    *)
        echo "Usage:"
        echo "  ./ip-proxy.sh install   # install as system service"
        echo "  service ip-proxy start  # start rotation"
        echo "  service ip-proxy stop   # stop"
        echo "  ip-proxy ip             # show current tor IP"
        ;;
esac
