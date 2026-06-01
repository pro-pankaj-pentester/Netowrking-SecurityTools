# ip-proxy

Tor-based IP rotator for Linux. Rotates exit IP every 5 seconds across 14 countries. Installs as a systemd service.

## Requirements

- Linux (Debian/Kali/Ubuntu)
- Root access
- `tor`, `netcat-openbsd` (auto-installed on first run)

## Setup

```bash
chmod +x ip-proxy.sh
./ip-proxy.sh install
```

This will:
- Install Tor if not present
- Configure Tor with fast circuit rotation
- Register `ip-proxy` as a systemd service

## Usage

```bash
service ip-proxy start     # start rotation
service ip-proxy stop      # stop
ip-proxy ip                # show current Tor IP
```

Run any command through Tor:
```bash
torsocks curl https://target.com/
torsocks curl -X POST https://target.com/api -d '{"key":"value"}'
```

## Custom Password

```bash
export TOR_PASS="yourpassword"
./ip-proxy.sh install
```

## Exit Countries

US, GB, DE, NL, FR, SE, CH, CA, JP, AU, BR, SG, ZA, MX

## Notes

- Minimum rotation interval is ~5 seconds (Tor circuit build time)
- SOCKS5 proxy runs on `127.0.0.1:9050`
- Control port on `127.0.0.1:9051`
