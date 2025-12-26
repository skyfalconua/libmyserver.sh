podman_django_collectstatic() {
  check_variables ENV PROJECTNAME

  echo_step "Collect static files"
  podman exec "$PROJECTNAME-$ENV-web" python manage.py collectstatic --no-input
  echo
}

podman_django_migrate_db() {
  check_variables ENV PROJECTNAME
  echo_step "Migrate database"
  podman exec "$PROJECTNAME-$ENV-web" python manage.py migrate --noinput
  echo
}

podman_django_dump_data() {
  check_variables ENV HOST PROJECTNAME PROJECTROOT

  local pod_name="$PROJECTNAME-$ENV-web"
  local pod_prefix="podman exec -it $pod_name "
  local auto_push=""
  local params=""

  # Parse command line options
  for i in "$@"; do
    case $i in
      --local)
        pod_prefix=""
        shift
        ;;
      --auto-push)
        auto_push=YES
        shift
        ;;
      --drop-revisions)
        params="$params --drop-revisions"
        shift
        ;;
      *)
        ;;
    esac
  done

  cd "$PROJECTROOT/var"
  git reset       initial_data/data.json
  git checkout -f initial_data/data.json
  echo

  if [ -z "$pod_prefix" ]; then
    source "$PROJECTROOT/venv/bin/activate"
    echo
  fi

  cd "$PROJECTROOT/src"
  $pod_prefix python manage.py dump_initial_data $params
  echo

  if [ -n "$pod_prefix" ]; then
    cd "$PROJECTROOT"
    echo   Copy "$pod_name:/volumes/initial_data/data.json" to ./var/initial_data/data.json
    podman cp   "$pod_name:/volumes/initial_data/data.json"    ./var/initial_data/data.json
    echo
  fi

  cd "$PROJECTROOT/var"

  local timestamp=$(date +"%m-%d-%Y-%H-%M-%S")
  git add --all
  git commit -m "dump $timestamp" || true

  if [ -n "$auto_push" ]; then
    git push
  else
    echo
    echo "please run the following commands:"
    echo "  cd $PROJECTROOT/var"
    echo "  git push"
  fi
}

podman_django_load_data() {
  check_variables ENV HOST PROJECTNAME PROJECTROOT

  local pod_name="$PROJECTNAME-$ENV-web"
  local pod_prefix="podman exec -it $pod_name "

  # Parse command line options
  for i in "$@"; do
    case $i in
      --local)
        pod_prefix=""
        shift
        ;;
      *)
        ;;
    esac
  done

  if [ -z "$pod_prefix" ]; then
    source "$PROJECTROOT/venv/bin/activate"
    echo
  else
    cd "$PROJECTROOT"
    echo   Copy ./var/initial_data/data.json to "$pod_name:/volumes/initial_data/data.json"
    podman cp   ./var/initial_data/data.json    "$pod_name:/volumes/initial_data/data.json"
    echo
  fi

  cd "$PROJECTROOT/src"
  $pod_prefix python manage.py migrate
  $pod_prefix python manage.py load_initial_data
  echo
  $pod_prefix python manage.py changepassword admin

  echo
  echo_warn "Don't forget to update site domain and port"
  echo "https://$HOST/admin/sites/"
  echo
  echo "Hostname:"
  echo "  $HOST"
  echo "Port:"
  echo "  443"
  echo
}
