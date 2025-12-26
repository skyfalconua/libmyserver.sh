add_cron_script() {
  local cronscript="$1"
  local cronjob="$2"
  (crontab -l | grep -v -F "$cronscript" || true ; set -f ; echo "$cronjob" ) | crontab -
}

_lego_echo_renew_certificate() {
  check_variables EMAIL
  local host="$1"

  local token_prefix=""
  local logfile="/opt/cron/logs/update_${host}_host.log"
  local params1="-m ${EMAIL} -d ${host} --path=/opt/lego --accept-tos"

  local params2=""
  if [ -n "$USE_CF_DNS_API_TOKEN" ]; then
    token_prefix="CF_DNS_API_TOKEN=\"${USE_CF_DNS_API_TOKEN}\" "
    params2="--dns cloudflare"
  else
    params2="--http --http.port=:81"
  fi

  local E="_inline_echo"
  $E ""
  $E "runlego() {"
  $E "  echo && \\"
  $E "  ${token_prefix}$(which lego) \\"
  $E "    ${params1} \\"
  $E "    ${params2} renew 2>&1"
  $E "}"
  $E "runlego >> ${logfile}"
  $E "nginx -s reload"
  $E "systemctl restart dumbproxy.service 2>/dev/null"
}

lego_cron_certificate() {
  check_variables CRONMIN HOST

  local cronscript="/opt/cron/scripts/update_${HOST}_host.sh"

  # -- ensure dir exists -- -- --
  mkdir -p /opt/lego/scripts /opt/lego/logs

  # -- create script -- -- --
  _lego_echo_renew_certificate "${HOST}" > "$cronscript" && \
  chmod 755 "$cronscript"

  # -- create cron job -- -- --
  echo_action "> cat $cronscript" && cat "$cronscript"
  cronjob=$CRONMIN' 04 * * * '$cronscript # at 04:XX each day
  add_cron_script "$cronscript" "$cronjob"

  # -- log cronjob -- -- --
  echo && echo_action "> crontab -l" && crontab -l
}

lego_update_certificate_manually() {
  check_variables HOST EMAIL USE_CLOUDFLARE

  if is_enabled "$USE_CLOUDFLARE"; then
    echo_warn "Cloudflare certificate is used, skipping"
    exit
  fi

  lego -d "$HOST" -m "$EMAIL" --path=/opt/lego -a --http --http.port=:81 run && \
  nginx -s reload
}
