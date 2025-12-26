#!/bin/env bash

export PROJECTROOT="$(cd "$(dirname "$0")" && pwd)"
export PROJECTNAME="myproject"
export USE_DJANGO="yes"
export LIBMYSERVER_ENVFILE="$PROJECTROOT/var/configs/envfile"

# curl https://skyfalconua.github.io/libmyserver.sh > .libmyserver.sh
source "$PROJECTROOT/.libmyserver.sh"

# -- -- --

_tonbsp() {
  sed -E 's/ /\xC2\xA0/g'
}
_fromnbsp() {
  sed -E 's/\xC2\xA0/ /g'
}
_fzf() {
  fzf --height 40% --border --no-separator --layout=reverse
}
_init_envfile() {
  read_envfile \
    'ENV=' \
    'HOST=' \
    'PORT=' \
    'EMAIL=' \
    'CRON_MIN=' \
    '#USE_SYSTEMD=yes' \
    '#USE_NGXACME=no' \
    '#USE_CLOUDFLARE=no' \
    '#USE_CLOUDFLARE=no'
}

# -- -- -- --

restart() { # @TASK:restart - Restart the application containers
  _init_envfile
  check_variables USE_SYSTEMD

  podman_build_web_app "src"
  echo

  make_config_nginx_container
  make_config_robots_txt
  podman_build_nginx
  echo

  export OUTPORT="$PORT" # main container output port

  make_config_map_variables SECRET_KEY
  make_config_podman

  if is_enabled "$USE_SYSTEMD"; then
    make_config_systemd
    start_containers_systemd
  else
    start_containers_podman_kube_play
  fi

  # Post-start actions
  echo
  echo_step "Pod started, waiting 5 sec.."
  sleep 5

  podman_django_collectstatic
  podman_django_migrate_db
}

update_nginx() { # @TASK:update_nginx - Update nginx configuration
  _init_envfile
  init_nginx_config
}

update_certificate() { # @TASK:update_certificate - Update SSL certificate
  _init_envfile
  lego_update_certificate_manually
}

cron_certificate() { # @TASK:cron_certificate - Setup cron job for certificate renewal
  _init_envfile
  lego_cron_certificate
}

dump_data() { # @TASK:dump_data - Dump database data to JSON
  _init_envfile
  podman_django_dump_data
}

load_data() { # @TASK:load_data - Load database data from JSON
  _init_envfile
  podman_django_load_data
}

# -- -- -- --

SELF="$0"

print_all_tasks() { # @TASK:h - Help
  local list=""
  local line=""
  local task=""

  local IFS='';
  for line in `grep -E '#[ ]+@TASK' "$self"`; do
    task=`echo "$line" | sed s/@TASK:/@/ | cut -d@ -f2- | _tonbsp`
    list="$list $task"
  done;

  echo "$list" | xargs | sed -E 's/[ ]+/\n/g' | sort
}

_get_task() {
  print_all_tasks | _fzf | _fromnbsp | cut -d ' ' -f1
}

_run_task() {
  local line=`grep -E "@TASK:([0-9]+\.)?$1([ ]|$)" "$SELF"`
  if [ -z "$line" ]; then
    echo "Usage: $(basename $SELF) <task>"
    exit
  fi

  local funcname=`echo $line | cut -d '(' -f1`
  # parameters after `$SELF $funcname`
  shift; if [ "$#" -ge 1 ]; then shift 1; fi

  echo "=> $funcname $@" && eval $funcname $@
}

# -- -- -- --

topcmd="$1"
if [ -z "$topcmd" ]; then
  topcmd=`_get_task`
fi
_run_task "$topcmd" $@
