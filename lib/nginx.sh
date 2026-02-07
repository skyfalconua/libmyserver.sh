_copy_cloudflare_certificate() {
  check_variables PROJECTROOT HOST

  local certdir="$1"
  sudo mkdir -p "$certdir"

  # Cloudflare origin CA certificate
  local crtfile="$PROJECTROOT/var/certificates/cloudflare.crt"
  local keyfile="$PROJECTROOT/var/certificates/cloudflare.key"

  if [ ! -f "$crtfile" ] || [ ! -f "$keyfile" ]; then
    echo_warn "Cloudflare origin CA certificate was not found. Obtain it here:"
    echo_warn "  https://dash.cloudflare.com/?to=/:account/:zone/ssl-tls/origin"
    echo_warn "Then put them to:"
    echo_warn "  - ./var/certificates/cloudflare.crt"
    echo_warn "  - ./var/certificates/cloudflare.key"
    exit
  fi

  curl -sL https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem \
    > "$certdir/cloudflare_aop_ca.crt"
  chmod 644 "$certdir/cloudflare_aop_ca.crt"

  cat "$crtfile" | save_to "$certdir/$HOST.crt"
  chmod 644 "$certdir/$HOST.crt"

  cat "$keyfile" | save_to "$certdir/$HOST.key"
  chmod 640 "$certdir/$HOST.key"
}

_copy_lego_placeholders() {
  check_variables PROJECTROOT HOST

  local certdir="$1"
  sudo mkdir -p "$certdir"

  local crtfile="${certdir}/$HOST.crt"
  local keyfile="${certdir}/$HOST.key"

  if [ ! -f "$crtfile" ]; then
    template__nginx_placeholder_crt | save_to "$crtfile";
  fi

  if [ ! -f "$keyfile" ]; then
    template__nginx_placeholder_key | save_to "$keyfile";
  fi
}

init_nginx_config() {
  check_variables PROJECTROOT HOST PORT

  echo | save_to /usr/share/nginx/html/index.html;

  local conffile="/etc/nginx/conf.d/$HOST.conf"
  local certdir="" # for cloudflare or lego only
  local ssl_configured=""

  local SSL_OPTIONS=""  # Placeholder for unused legacy variable
  local CERTFILE=""
  local KEYFILE=""

  # -- use cloudflare proxy -- -- --

  if is_enabled "$USE_CLOUDFLARE"; then
    certdir="/opt/certificates/cloudflare"

    SSL_OPTIONS="ssl_client_certificate /opt/certificates/cloudflare_aop_ca.crt;"
    SSL_OPTIONS="$SSL_OPTIONS\n  ssl_verify_client on;"
    CERTFILE="$certdir/$HOST.crt"
    KEYFILE="$certdir/$HOST.key"

    ssl_configured="yes"
    _copy_cloudflare_certificate "$certdir"
  fi

  # -- use go-acme/lego cli -- -- --

  if is_enabled "$USE_LEGO"; then
    certdir="/opt/certificates/lego"

    SSL_OPTIONS=""
    CERTFILE="$certdir/$HOST.crt"
    KEYFILE="$certdir/$HOST.key"

    ssl_configured="yes"
    _copy_lego_placeholders "$certdir"
  fi

  # -- use nginx/nginx-acme module -- -- --

  if is_enabled "$USE_NGXACME"; then
    SSL_OPTIONS="acme_certificate letsencrypt;"
    SSL_OPTIONS="$SSL_OPTIONS\n  ssl_certificate_cache max=2;"

    CERTFILE="\$acme_certificate"
    KEYFILE="\$acme_certificate_key"

    ssl_configured="yes"
    _copy_lego_placeholders "$certdir"
  fi

  # -- ensure ssl configured -- -- --

  if ! is_enabled "$ssl_configured"; then
    echo_warn "One of these parameters is required - USE_CLOUDFLARE, USE_LEGO, USE_NGXACME"
    exit
  fi

  # -- create config -- -- --

  echo_step "Create $conffile"
  template__nginx_system_nginx | \
    render_variables HOST PORT SSL_OPTIONS CERTFILE KEYFILE | \
    save_to "$conffile"
  echo

  # -- reload nginx -- -- --

  echo_step "Reload nginx config"
  sudo nginx -s reload
}
