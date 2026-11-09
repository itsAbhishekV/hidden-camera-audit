#!/bin/zsh
# Hidden-camera network audit. Only run on networks you are authorized to use.
# Non-destructive: host discovery, port/service checks, vendor lookup. No exploitation, no logins.
set -u
OUT=${1:-$HOME/airbnb_audit}
mkdir -p "$OUT" && cd "$OUT" || exit 1

command -v nmap >/dev/null || HOMEBREW_NO_AUTO_UPDATE=1 brew install nmap

IF=$(route -n get default | awk '/interface:/{print $2}')
IP=$(ipconfig getifaddr "$IF")
GW=$(route -n get default | awk '/gateway:/{print $2}')
NET="${IP%.*}.0/24"
echo "iface=$IF ip=$IP gw=$GW net=$NET" | tee summary.txt

echo "[1] Host discovery"
nmap -sn -n "$NET" -oG discovery.gnmap >/dev/null 2>&1
for i in $(seq 1 254); do ping -c1 -t1 "${IP%.*}.$i" >/dev/null 2>&1 & done; wait
arp -an | grep -v incomplete | grep -v 'ff:ff:ff' | grep -v '224\.' > arp.txt
cat arp.txt

echo "[2] Vendor lookup (+ randomized-MAC flag)"
: > devices.tsv
while read -r _ ip _ mac _; do
  ip=${ip//[()]/}
  norm=$(echo "$mac" | awk -F: '{for(i=1;i<=NF;i++) printf "%s%02s", (i>1?":":""), $i}' | tr ' ' 0 | tr a-f A-F)
  first=$((16#${norm:0:2}))
  if (( first & 2 )); then vendor="RANDOMIZED (phone/laptop likely)"
  else vendor=$(curl -s -m 8 "https://api.macvendors.com/$norm"); sleep 1.1; fi
  printf "%s\t%s\t%s\n" "$ip" "$norm" "$vendor" | tee -a devices.tsv
done < arp.txt

echo "[3] Camera-port scan"
PORTS=21,22,23,80,81,443,554,1935,3702,5000,7000,7001,8000,8080,8081,8443,8554,8899,9000,34567,37777,49152,55443
HOSTS=$(awk '{gsub(/[()]/,"",$2); print $2}' arp.txt | grep -v "^$IP$" | tr '\n' ' ')
nmap -Pn -n -sT -sV --version-light -T4 --open -p $PORTS ${=HOSTS} -oN ports.txt >/dev/null 2>&1
grep -E 'report for|open' ports.txt

echo "[4] mDNS / SSDP"
for t in _rtsp._tcp _onvif._tcp _hap._tcp _googlecast._tcp _airplay._tcp _http._tcp; do
  echo "-- $t"; timeout 4 dns-sd -B $t local. 2>&1 | grep Add
done
python3 -I - <<'E'
import socket,time
m=b'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 3\r\nST: ssdp:all\r\n\r\n'
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(1);s.sendto(m,("239.255.255.250",1900))
t=time.time();seen={}
while time.time()-t<6:
    try:d,a=s.recvfrom(4096)
    except Exception:continue
    seen.setdefault(a[0],d.decode(errors='ignore').splitlines()[:6])
for k,v in seen.items():print(k,v)
E

echo "[5] Nearby camera-style Wi-Fi APs"
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s 2>/dev/null \
  | grep -iE 'ipc|cam|yi-|tuya|smartlife|hikvision|wyze|ezviz|v380' || echo "none visible (airport tool may be unavailable; check Wi-Fi list manually)"

echo "Done. Files in $OUT"
