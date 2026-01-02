#!/bin/sh

OUT="./_dist/libmyserver.sh"
# OUT="../skyfalconua.github.io/libmyserver.sh"

str_match() {
  # expr returns 0 (true) if match, 1 (false) if not
  # prepend a char to avoid issues with lines starting with -
   printf '%s\n' "$1" | grep -q "$2"
}

path_escape() {
  printf '%s' "$1" | tr -c '[:alnum:]' '_'
}

lib() {
  local file="./lib/$1"
  if [ ! -f "$file" ]; then
    printf "Error: File '%s' not found\n" "$file" >&2
    exit
  fi
  local name=$(path_escape "$1")

  printf "\n#- %s\n\n" "$file"  >> "$OUT"
  cat "$file"               >> "$OUT"
}

generate_certificate_placeholder() {
  cd templates/nginx && openssl req -new \
    -newkey rsa:4096 -days 9999 -nodes -x509 \
    -subj "/C=c/ST=st/O=o/CN=placeholder.com" \
    -keyout placeholder.key -out placeholder.crt
}

_template() {
  local file="./templates/$1"
  if [ ! -f "$file" ]; then
    printf "Error: File '%s' not found\n" "$file" >&2
    exit
  fi
  local name=$(path_escape "$1")

  printf "\n#- %s\n\n" "$file"
  printf "template__%s() {\n" "$name"
  printf "  local E=_inline_echo\n"

  while IFS= read -r line || [ -n "$line" ]; do
    if str_match "$line" '^[ ]*#>'; then
      local cleaned_line=$(printf '%s' "$line" | sed 's/^[ ]*\#>//g')
      printf "%s\n" "  $cleaned_line"
    else
      local escaped_line=$(printf '%s' "$line" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/"/\\"/g')
      printf "  \$E \"%s\"\n" "$escaped_line"
    fi
  done < "$file"

  printf "}\n"
}
template() {
  _template "$1" >> "$OUT"
}

VERSION=$(date +"%Y.%-m.%-d")

# reset file
mkdir -p ./_dist
echo "# libmyserver.sh v$VERSION"                      > "$OUT"
echo "# https://skyfalconua.github.io/libmyserver.sh" >> "$OUT"

lib "utils.sh"
template "nginx/container.nginx"
template "nginx/system.nginx"

# ( generate_certificate_placeholder )
template "nginx/placeholder.crt"
template "nginx/placeholder.key"

template "nginx/robots-dev.txt"
template "nginx/robots-prod.txt"
template "podman/ConfigMap.yaml"
template "podman/Podman.yaml"
template "podman/systemd.conf"

lib "nginx.sh"
lib "lego.sh"
lib "podman.sh"
lib "django.sh"

if [ -n "$ENABLE_APPS" ]; then
  template "systemd.service"
  lib "apps/dumbproxy/install.sh"
  lib "apps/wireguard/install.sh"
fi
