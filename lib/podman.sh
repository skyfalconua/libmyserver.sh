podman_build_web_app() {
  local appdir="$1"
  check_variables ENV PROJECTNAME
  echo_step "Build $PROJECTNAME-$ENV/web image"
  podman build --format docker --tag "$PROJECTNAME-$ENV/web" "./$appdir"
}

make_config_map_variables() {
  check_variables PROJECTROOT
  if [ -f "$PROJECTROOT/var/configs/ConfigMap.yaml" ]; then return; fi

  local SECRET_KEY=$(</dev/urandom base64 | tr -d '/+' | head -c 50) || true

  echo_step "Create ./var/configs/ConfigMap.yaml"
  template__podman_ConfigMap_yaml | \
    render_variables "${@}" |
    save_to "$PROJECTROOT/var/configs/ConfigMap.yaml"
}

make_config_nginx_container() {
  check_variables PROJECTROOT
  if [ -f "$PROJECTROOT/nginx/nginx-container.conf" ]; then return; fi

  echo_step "Create ./nginx/nginx-container.conf"
  template__nginx_container_nginx | \
    render_variables "${@}" | \
    save_to "$PROJECTROOT/nginx/nginx-container.conf"
}

make_config_podman() {
  check_variables PROJECTROOT OUTPORT
  if [ ! -f "$PROJECTROOT/var/configs/Podman.yaml" ]; then return; fi

  echo_step "Create ./var/configs/Podman.yaml"
  template__podman_Podman_yaml | \
    render_variables PROJECTNAME ENV OUTPORT | \
    save_to "$PROJECTROOT/var/configs/Podman.yaml"
}

make_config_robots_txt() {
  check_variables PROJECTROOT ENV
  if [ -f "$PROJECTROOT/nginx/html/robots.txt" ]; then return; fi

  local outfile="$PROJECTROOT/nginx/html/robots.txt"

  echo_step "Create ./nginx/html/robots.txt"
  if [ "$ENV" = "prod" ]; then
    template__nginx_robots_prod_txt | \
      render_variables HOST | \
      save_to "$outfile"
  else
    template__nginx_robots_dev_txt | \
      render_variables HOST | \
      save_to "$outfile"
  fi
}

podman_build_nginx() {
  check_variables PROJECTNAME ENV
  echo_step "Build $PROJECTNAME-$ENV/nginx image"
  podman build --format docker --tag "$PROJECTNAME-$ENV/nginx" nginx
}

make_config_systemd() {
  check_variables PROJECTROOT PROJECTNAME ENV
  if [ -f "$sddir/$PROJECTNAME-$ENV.kube" ]; then return; fi

  local sddir="$HOME/.config/containers/systemd"
  mkdir -p "$sddir"

  echo_step "Create $sddir/$PROJECTNAME-$ENV.kube"

  template__podman_systemd_conf | \
    render_variables PROJECTROOT PROJECTNAME ENV | \
    save_to "$sddir/$PROJECTNAME-$ENV.kube"
}

start_containers_systemd() {
  check_variables PROJECTNAME ENV
  echo_step "Start containers via systemd"
  systemctl --user daemon-reload && \
  systemctl --user restart "$PROJECTNAME-$ENV.service" && \
  systemctl --user status "$PROJECTNAME-$ENV.service" --lines=0 --no-pager
}

start_containers_podman_kube_play() {
  check_variables PROJECTROOT
  echo_step "Start containers"
  podman kube play --replace --configmap "$PROJECTROOT/var/configs/ConfigMap.yaml" \
    "$PROJECTROOT/var/configs/Podman.yaml"
}
