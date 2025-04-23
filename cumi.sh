#!/bin/bash
# === CONFIGURASI ===
INTERFACE="eth0"                      # Ganti sesuai interface kamu (cek dengan `ip a`)
IP_PREFIX="#!/bin/bash
# === CONFIGURASI ===
INTERFACE="eth0"                      # Ganti sesuai interface kamu (cek dengan `ip a`)
IP_PREFIX="#!/bin/bash
# === CONFIGURASI ===
INTERFACE="eth0"                      # Ganti sesuai interface kamu (cek dengan `ip a`)
IP_PREFIX="5.231.238"                 # Prefix dari subnet kamu
START=165                               # Awal range IP
END=252                               # Akhir range IP
EXCLUDE=(1)                       # IP akhir yang ingin dikecualikan, misal: 5.230.48.72, .80, .88
PORT_START=3128                       # Port pertama untuk Squid (akan naik terus)
USERNAME="vodkaace"                   # Username Squid
PASSWORD="indonesia"                  # Password squid
PASSWD_FILE="/etc/squid/passwd"
SQUID_CONF="/etc/squid/squid.conf"
HASIL_FILE="hasil.txt"                # Letak penyimpanan hasil file 
NETMASKS="24"                         # Sesuaikan subnet
# === FUNGSI UNTUK CEK APAKAH ANGKA ADA DI EXCLUDE ===
is_excluded() {
    local num=$1
    for ex in "${EXCLUDE[@]}"; do
        if [[ "$num" -eq "$ex" ]]; then
            return 0
        fi
    done
    return 1
}

# === CEK INTERFACE ===
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "[!] Interface $INTERFACE tidak ditemukan. Periksa kembali." >&2
    exit 1
fi

# === TAMBAHKAN IP KE INTERFACE ===
echo "[+] Menambahkan IP ke interface $INTERFACE"
for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    IP="$IP_PREFIX.$i"
    if ! ip addr show dev $INTERFACE | grep -q "$IP"; then
        sudo ip addr add "$IP/$NETMASKS" dev $INTERFACE
    fi
done

# === INSTALL PAKET YANG DIBUTUHKAN ===
echo "[+] Menginstall Squid dan Apache utils"
sudo apt update
sudo apt install squid apache2-utils -y

# === SETUP AUTH USER ===
echo "[+] Menambahkan user proxy $USERNAME"
if [ ! -f "$PASSWD_FILE" ]; then
    sudo htpasswd -cb "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
else
    sudo htpasswd -b "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
fi

# === BACKUP CONFIG LAMA ===
echo "[+] Membackup konfigurasi Squid lama"
sudo cp "$SQUID_CONF" "$SQUID_CONF.bak.$(date +%s)"

# === BUAT KONFIGURASI BARU ===
echo "[+] Menulis konfigurasi baru ke $SQUID_CONF"
sudo tee "$SQUID_CONF" > /dev/null <<EOF
# === AUTHENTIKASI ===
auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWD_FILE
auth_param basic realm Private Proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated

# === LOGGING ===
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
cache_store_log none
logfile_rotate 0
buffered_logs on
dns_v4_first on

# === PENGATURAN PORT & IP KELUAR ===
EOF

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati konfigurasi untuk IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "http_port $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "acl to$i myport $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "tcp_outgoing_address $IP to$i" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "" | sudo tee -a "$SQUID_CONF" > /dev/null
done

# === BUKA FIREWALL (JIKA UFW AKTIF) ===
if command -v ufw > /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "[+] Membuka port di firewall (UFW)"
    for i in $(seq $START $END); do
        if is_excluded "$i"; then
            continue
        fi
        PORT=$((PORT_START + i - START))
        sudo ufw allow "$PORT/tcp" comment "Allow Squid proxy port $PORT"
    done
fi

# === SIMPAN HASIL KE FILE ===
echo "[+] Menyimpan hasil konfigurasi ke $HASIL_FILE"
: > "$HASIL_FILE"  # Kosongkan isi file hasil.txt jika sudah ada sebelumnya

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "$USERNAME:$PASSWORD:$IP:$PORT" >> "$HASIL_FILE"
done
# Buat direktori override systemd untuk Squid
sudo mkdir -p /etc/systemd/system/squid.service.d

# Buat file override limit
cat <<EOF | sudo tee /etc/systemd/system/squid.service.d/override.conf
[Service]
LimitNOFILE=65535
EOF

echo "[+] Restarting Squid"
echo -n "Loading"
loading_animation() {
    local pid=$1
    local delay=0.1
    local spin='|/-\'

    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\rLoading ${spin:$i:1}"
            sleep $delay
        done
    done
    echo -ne "\r[+] Restart Squid Done     \n"
}

(
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart squid
) &
loading_animation $!

# Tampilkan limit file descriptor Squid sekarang
echo "Cek limit file descriptor Squid:"
cat /proc/$(pidof squid)/limits | grep "Max open files"
echo "✅ Setup selesai! Proxy siap digunakan."
echo "📄 Hasil disimpan di: $HASIL_FILE""                 # Prefix dari subnet kamu
START=65                               # Awal range IP
END=112                               # Akhir range IP
EXCLUDE=(113)                       # IP akhir yang ingin dikecualikan, misal: 5.230.48.72, .80, .88
PORT_START=3128                       # Port pertama untuk Squid (akan naik terus)
USERNAME="vodkaace"                   # Username Squid
PASSWORD="indonesia"                  # Password squid
PASSWD_FILE="/etc/squid/passwd"
SQUID_CONF="/etc/squid/squid.conf"
HASIL_FILE="hasil.txt"                # Letak penyimpanan hasil file 
NETMASKS="24"                         # Sesuaikan subnet
# === FUNGSI UNTUK CEK APAKAH ANGKA ADA DI EXCLUDE ===
is_excluded() {
    local num=$1
    for ex in "${EXCLUDE[@]}"; do
        if [[ "$num" -eq "$ex" ]]; then
            return 0
        fi
    done
    return 1
}

# === CEK INTERFACE ===
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "[!] Interface $INTERFACE tidak ditemukan. Periksa kembali." >&2
    exit 1
fi

# === TAMBAHKAN IP KE INTERFACE ===
echo "[+] Menambahkan IP ke interface $INTERFACE"
for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    IP="$IP_PREFIX.$i"
    if ! ip addr show dev $INTERFACE | grep -q "$IP"; then
        sudo ip addr add "$IP/$NETMASKS" dev $INTERFACE
    fi
done

# === INSTALL PAKET YANG DIBUTUHKAN ===
echo "[+] Menginstall Squid dan Apache utils"
sudo apt update
sudo apt install squid apache2-utils -y

# === SETUP AUTH USER ===
echo "[+] Menambahkan user proxy $USERNAME"
if [ ! -f "$PASSWD_FILE" ]; then
    sudo htpasswd -cb "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
else
    sudo htpasswd -b "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
fi

# === BACKUP CONFIG LAMA ===
echo "[+] Membackup konfigurasi Squid lama"
sudo cp "$SQUID_CONF" "$SQUID_CONF.bak.$(date +%s)"

# === BUAT KONFIGURASI BARU ===
echo "[+] Menulis konfigurasi baru ke $SQUID_CONF"
sudo tee "$SQUID_CONF" > /dev/null <<EOF
# === AUTHENTIKASI ===
auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWD_FILE
auth_param basic realm Private Proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated

# === LOGGING ===
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
cache_store_log none
logfile_rotate 0
buffered_logs on
dns_v4_first on

# === PENGATURAN PORT & IP KELUAR ===
EOF

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati konfigurasi untuk IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "http_port $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "acl to$i myport $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "tcp_outgoing_address $IP to$i" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "" | sudo tee -a "$SQUID_CONF" > /dev/null
done

# === BUKA FIREWALL (JIKA UFW AKTIF) ===
if command -v ufw > /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "[+] Membuka port di firewall (UFW)"
    for i in $(seq $START $END); do
        if is_excluded "$i"; then
            continue
        fi
        PORT=$((PORT_START + i - START))
        sudo ufw allow "$PORT/tcp" comment "Allow Squid proxy port $PORT"
    done
fi

# === SIMPAN HASIL KE FILE ===
echo "[+] Menyimpan hasil konfigurasi ke $HASIL_FILE"
: > "$HASIL_FILE"  # Kosongkan isi file hasil.txt jika sudah ada sebelumnya

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "$USERNAME:$PASSWORD:$IP:$PORT" >> "$HASIL_FILE"
done
# Buat direktori override systemd untuk Squid
sudo mkdir -p /etc/systemd/system/squid.service.d

# Buat file override limit
cat <<EOF | sudo tee /etc/systemd/system/squid.service.d/override.conf
[Service]
LimitNOFILE=65535
EOF

echo "[+] Restarting Squid"
echo -n "Loading"
loading_animation() {
    local pid=$1
    local delay=0.1
    local spin='|/-\'

    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\rLoading ${spin:$i:1}"
            sleep $delay
        done
    done
    echo -ne "\r[+] Restart Squid Done     \n"
}

(
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart squid
) &
loading_animation $!

# Tampilkan limit file descriptor Squid sekarang
echo "Cek limit file descriptor Squid:"
cat /proc/$(pidof squid)/limits | grep "Max open files"
echo "✅ Setup selesai! Proxy siap digunakan."
echo "📄 Hasil disimpan di: $HASIL_FILE""                 # Prefix dari subnet kamu
START=165                               # Awal range IP
END=252                               # Akhir range IP
EXCLUDE=(1)                       # IP akhir yang ingin dikecualikan, misal: 5.230.48.72, .80, .88
PORT_START=3128                       # Port pertama untuk Squid (akan naik terus)
USERNAME="vodkaace"                   # Username Squid
PASSWORD="indonesia"                  # Password squid
PASSWD_FILE="/etc/squid/passwd"
SQUID_CONF="/etc/squid/squid.conf"
HASIL_FILE="hasil.txt"                # Letak penyimpanan hasil file 
NETMASKS="24"                         # Sesuaikan subnet
# === FUNGSI UNTUK CEK APAKAH ANGKA ADA DI EXCLUDE ===
is_excluded() {
    local num=$1
    for ex in "${EXCLUDE[@]}"; do
        if [[ "$num" -eq "$ex" ]]; then
            return 0
        fi
    done
    return 1
}

# === CEK INTERFACE ===
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "[!] Interface $INTERFACE tidak ditemukan. Periksa kembali." >&2
    exit 1
fi

# === TAMBAHKAN IP KE INTERFACE ===
echo "[+] Menambahkan IP ke interface $INTERFACE"
for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    IP="$IP_PREFIX.$i"
    if ! ip addr show dev $INTERFACE | grep -q "$IP"; then
        sudo ip addr add "$IP/$NETMASKS" dev $INTERFACE
    fi
done

# === INSTALL PAKET YANG DIBUTUHKAN ===
echo "[+] Menginstall Squid dan Apache utils"
sudo apt update
sudo apt install squid apache2-utils -y

# === SETUP AUTH USER ===
echo "[+] Menambahkan user proxy $USERNAME"
if [ ! -f "$PASSWD_FILE" ]; then
    sudo htpasswd -cb "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
else
    sudo htpasswd -b "$PASSWD_FILE" "$USERNAME" "$PASSWORD"
fi

# === BACKUP CONFIG LAMA ===
echo "[+] Membackup konfigurasi Squid lama"
sudo cp "$SQUID_CONF" "$SQUID_CONF.bak.$(date +%s)"

# === BUAT KONFIGURASI BARU ===
echo "[+] Menulis konfigurasi baru ke $SQUID_CONF"
sudo tee "$SQUID_CONF" > /dev/null <<EOF
# === AUTHENTIKASI ===
auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWD_FILE
auth_param basic realm Private Proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated

# === LOGGING ===
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
cache_store_log none
logfile_rotate 0
buffered_logs on
dns_v4_first on

# === PENGATURAN PORT & IP KELUAR ===
EOF

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        echo "[!] Melewati konfigurasi untuk IP $IP_PREFIX.$i (dikecualikan)"
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "http_port $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "acl to$i myport $PORT" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "tcp_outgoing_address $IP to$i" | sudo tee -a "$SQUID_CONF" > /dev/null
    echo "" | sudo tee -a "$SQUID_CONF" > /dev/null
done

# === BUKA FIREWALL (JIKA UFW AKTIF) ===
if command -v ufw > /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "[+] Membuka port di firewall (UFW)"
    for i in $(seq $START $END); do
        if is_excluded "$i"; then
            continue
        fi
        PORT=$((PORT_START + i - START))
        sudo ufw allow "$PORT/tcp" comment "Allow Squid proxy port $PORT"
    done
fi

# === SIMPAN HASIL KE FILE ===
echo "[+] Menyimpan hasil konfigurasi ke $HASIL_FILE"
: > "$HASIL_FILE"  # Kosongkan isi file hasil.txt jika sudah ada sebelumnya

for i in $(seq $START $END); do
    if is_excluded "$i"; then
        continue
    fi
    PORT=$((PORT_START + i - START))
    IP="$IP_PREFIX.$i"
    echo "$USERNAME:$PASSWORD:$IP:$PORT" >> "$HASIL_FILE"
done
# Buat direktori override systemd untuk Squid
sudo mkdir -p /etc/systemd/system/squid.service.d

# Buat file override limit
cat <<EOF | sudo tee /etc/systemd/system/squid.service.d/override.conf
[Service]
LimitNOFILE=65535
EOF

echo "[+] Restarting Squid"
echo -n "Loading"
loading_animation() {
    local pid=$1
    local delay=0.1
    local spin='|/-\'

    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\rLoading ${spin:$i:1}"
            sleep $delay
        done
    done
    echo -ne "\r[+] Restart Squid Done     \n"
}

(
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart squid
) &
loading_animation $!

# Tampilkan limit file descriptor Squid sekarang
echo "Cek limit file descriptor Squid:"
cat /proc/$(pidof squid)/limits | grep "Max open files"
echo "✅ Setup selesai! Proxy siap digunakan."
echo "📄 Hasil disimpan di: $HASIL_FILE"
