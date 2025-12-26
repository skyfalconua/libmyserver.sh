_inline_echo() {
  printf "%s\n" "$1"
}

is_enabled() {
  local param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  [ "$param" = "true" ] || [ "$param" = "yes" ] || [ "$param" = "on" ] || [ "$param" = "1" ]
}

user_exists(){
  id "$1" &>/dev/null
}

color() {
  case "$1" in
    red) printf '\033[0;31m' ;;
    green) printf '\033[0;32m' ;;
    yellow) printf '\033[0;33m' ;;
    blue) printf '\033[0;34m' ;;
    magenta) printf '\033[0;35m' ;;
    cyan) printf '\033[0;36m' ;;
    *) printf '\033[0m' ;;
  esac
}

echo_step() {
  printf "$(color green)* $1 *$(color)\n\n"
}

echo_warn() {
  printf "$(color yellow)$1$(color)\n\n"
}

echo_action() {
  printf "$(color cyan)$1$(color)\n"
}

read_envfile() {
  # example:
  #   read_envfile \
  #     'ENV=' \
  #     '#USE_PARAM=yes'

  check_variables LIBMYSERVER_ENVFILE
  if [ -z "${LIBMYSERVER_ENVFILE}" ] ; then
    echo "Error: LIBMYSERVER_ENVFILE variable is not set"
    exit
  fi

  # Create envfile with commented placeholders if it doesn't exist
  if [ ! -f "$LIBMYSERVER_ENVFILE" ] ; then
    for keyval in "$@"; do
      echo "$keyval" >> "$LIBMYSERVER_ENVFILE"
    done
  fi

  # Reset all specified variables to empty strings
  local resetvars=""
  for key in "$@"; do
    key="${key#\#}"   # Strip leading '#' (comments)
    key="${key%%=*}"  # Strip everything from '=' to the end
    resetvars="$resetvars $key="
  done
  export $(echo "$resetvars __placeholder")

  # Load non-comment lines from envfile and export as environment variables
  local newvars="$(grep -v '^\s*#' "$LIBMYSERVER_ENVFILE" | tr '\n' ' ')"
  export $(echo "$newvars __placeholder")
}

check_variables() {
  local key=""
  local val=""
  local missing=""

  for key in "$@"; do
    key=$(echo "$key" | tr -cd '[:alnum:]_')
    val=$(eval "echo \$$key")

    if [ -z "$val" ]; then
      missing="$missing $key"
    fi
  done

  if [ -n "$missing" ]; then
    echo "parameters are missing:$missing"
    echo
    if [ -n "${LIBMYSERVER_ENVFILE}" ]; then
      echo " add them ${LIBMYSERVER_ENVFILE}"
    fi
    exit
  fi
}

render_variables() {
  local content=$(cat)
  local varname=""
  local varvalue=""

  for varname in "$@"; do
    local key=$(printf '%s' "$varname" | tr -cd '[:alnum:]_')
    eval "varvalue=\"\${$key}\""

    content=$(printf '%s' "$content" | sed "s#__${key}__#${varvalue}#g")
  done

  printf '%s' "$content"
}

save_to() {
  local filename="$1"
  cat | tee "$filename" > /dev/null
}
