wireguard_install() {
  mkdir -p /opt/wireguard
  cd /opt/wireguard

  wget https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh
  ln -sfv /etc/wireguard/wg0.conf .
}
