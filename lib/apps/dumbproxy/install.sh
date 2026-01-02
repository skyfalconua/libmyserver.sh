_dumbproxyfetch() {
  local arch=""
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *)       echo "error: unknown architecture"; return ;;
  esac

  local rel="https://api.github.com/repos/SenseUnit/dumbproxy/releases/latest"
  local ver=`curl -s "${rel}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | tr -d 'v'`
  local pkgurl="https://github.com/SenseUnit/dumbproxy/releases/download/v${ver}/dumbproxy.linux-${arch}"

  curl -sL "${pkgurl}" > /usr/bin/dumbproxy && \
  chmod 755 /usr/bin/dumbproxy && \
  echo "created /usr/bin/dumbproxy (v${ver})"
}

_rundumbproxy() {
  check_variables HOST PROXY_PORT

  local E="_inline_echo"
  $E '#!/bin/sh'
  $E
  $E "auth=\"basicfile://?path=/opt/dumbproxy/htpasswd\""
  $E "cert=\"/opt/certificates/lego/${HOST}.crt\""
  $E "key=\"/opt/certificates/lego/${HOST}.key\""
  $E
  $E dumbproxy -bind-address ":${PROXY_PORT}" -auth '"$auth"' -cert '"$cert"' -key '"$key"'
  $E
}

dumbproxy_install() {
  mkdir -p /opt/dumbproxy && cd /opt/dumbproxy

  local rundp="/opt/dumbproxy/run-dumbproxy"
  if [ ! -f "$rundp" ]; then
    _rundumbproxy > "$rundp" && \
    chmod 755 "$rundp"
    echo_action "Created $rundp"
  fi

  echo
  echo_action "to edit params run:"
  echo_action "  micro /opt/dumbproxy/run-dumbproxy"

  local systemd="/etc/systemd/system/dumbproxy.service"
  if [ ! -f "$systemd" ]; then
    echo
    echo "created $systemd"
    echo

    template__systemd_service | \
      DESCRIPTION="Dumbest HTTP proxy ever" \
      WORKINGDIR="/opt/dumbproxy" \
      EXECSTART="/opt/dumbproxy/run-dumbproxy" \
      render_variables DESCRIPTION WORKINGDIR EXECSTART | \
      save_to "$systemd";
  fi

  echo
  systemctl daemon-reload
  systemctl status --no-pager --lines=0 dumbproxy.service

  echo
  echo_action "to enable service run:"
  echo_action "  dumbproxy -passwd /opt/dumbproxy/htpasswd __username__ __password__"
  echo_action "  systemctl enable --now dumbproxy.service"
}
