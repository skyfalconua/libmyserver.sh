reset_configs() {
  check_variables ENV PROJECTROOT PROJECTNAME

  rm -f "$PROJECTROOT/nginx/nginx-container.conf"
  rm -f "$PROJECTROOT/nginx/html/robots.txt"
  rm -f "$PROJECTROOT/var/configs/Podman.yaml"
  rm -f "$PROJECTROOT/var/configs/ConfigMap.yaml"
  rm -f "$HOME/.config/containers/systemd/$PROJECTNAME-$ENV.kube"
}
