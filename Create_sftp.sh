#!/bin/bash

# Funzione per generare una password randomica
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 16
}

# Controllo input
if [ $# -ne 2 ]; then
  echo "Uso: $0 <path> <nomeutente>"
  exit 1
fi

# Parametri
DIRECTORY=$1
USERNAME=$2

# Controllo che la directory esista
if [ ! -d "$DIRECTORY" ]; then
  echo "Errore: La directory $DIRECTORY non esiste!"
  exit 1
fi

# Creazione utente
PASSWORD=$(generate_password)
useradd -m -s /usr/sbin/nologin "$USERNAME"

# Imposta password
echo "$USERNAME:$PASSWORD" | chpasswd

# Creazione struttura per chroot
SFTP_DIR="/home/$USERNAME/sftp"
mkdir -p "$SFTP_DIR"
chown root:root "/home/$USERNAME"
chmod 755 "/home/$USERNAME"
ln -s "$DIRECTORY" "$SFTP_DIR/httpdocs"
chown -R www-data:www-data "$DIRECTORY"

# Configurazione SSH per limitare l'accesso
SSHD_CONFIG="/etc/ssh/sshd_config"
if ! grep -q "^Match User $USERNAME" "$SSHD_CONFIG"; then
  echo -e "\n# Configurazione per utente SFTP: $USERNAME" >> "$SSHD_CONFIG"
  echo "Match User $USERNAME" >> "$SSHD_CONFIG"
  echo "    ChrootDirectory /home/$USERNAME" >> "$SSHD_CONFIG"
  echo "    ForceCommand internal-sftp" >> "$SSHD_CONFIG"
  echo "    AllowTcpForwarding no" >> "$SSHD_CONFIG"
fi

# Riavvia il servizio SSH
systemctl restart sshd

# Output delle credenziali
echo "Utente SFTP creato con successo!"
echo "Nome utente: $USERNAME"
echo "Password: $PASSWORD"
echo "Accesso alla directory: $DIRECTORY"
