#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

log() {
    echo "[$(date '+%H:%M:%S %Y-%m-%d')] [$0]" $1
}

make_backup(){
  log "Making full backup..."
  tar -czvf backups/full/academiaa-$(date +%Y-%m-%d-%H-%M).tar.gz academiaa/
  cp -r academiaa/{app.db,migrations} important/db/
  mv academiaa backups/last
}
init_venv(){
  log "Initializing venv..."
  python3 -m venv academiaa/venv
  academiaa/venv/bin/pip install -r academiaa/requirements.txt
  academiaa/venv/bin/pip install wheel
  academiaa/venv/bin/pip install uwsgi -I --no-cache-dir
}
copy_settings(){
  log "Copying settings..."
  cp important/{academiaa.ini,keys/google-keys.json,keys/flask-config.yml} ./academiaa/
}

init_new_db(){
  echo "Initializing new database..."
  rm -rf academiaa/app.db academiaa/migrations
  academiaa/venv/bin/flask db init
  update_db "Initial commit"
}
update_db(){
  log "Updating current version..."
  venv/bin/flask db migrate -m "$1"
  venv/bin/flask db upgrade
}

restore_db(){
  cp -r important/db/{migrations,app.db} academiaa/
  update_db "Update "
}

restart_service(){
  log "Restarting service..."
  sudo systemctl restart academiaa.service
}

main(){
  log "Start update!"
  cd "/home/$USER"
  export FLASK_APP=/home/sergey/academiaa/wsgi
  make_backup
  git clone https://github.com/andy-takker/academiaa.git
  init_venv
  copy_settings
  restore_db
  restart_service
  log "Finish update!"
}

main
