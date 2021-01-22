#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

make_backup(){
  echo "Making full backup..."
  tar -zxvf backups/full/academiaa-$(date +%Y-%m-%d-%H-%M).tar.gz academiaa/
  cp -r academiaa/{app.db,migrations} important/db/
  mv academiaa backups/last
}
init_venv(){
  echo "Initializing venv..."
  python3 -m venv academiaa/venv
  academiaa/venv/bin/pip install -r academiaa/requirements.txt
  academiaa/venv/bin/pip install wheel
  academiaa/venv/bin/pip install uwsgi -I --no-cache-dir
}
copy_settings(){
  echo "Copying settings..."
  cp important/{academiaa.ini,keys/google-keys.json,keys/flask-config.yml} ./academiaa/
}

init_new_db(){
  echo "Initializing new database..."
  rm -rf academiaa/app.db academiaa/migrations
  academiaa/venv/bin/flask db init
  update_db "Initial commit"
}
update_db(){
  echo "Updating current version..."
  academiaa/venv/bin/flask db migrate -m "$1"
  academiaa/venv/bin/flask db upgrade
}

restore_db(){
  cp -r important/db/{migrations,app.db} academiaa/
  update_db "Update "
}

main(){
  cd /home/sergey
  export FLASK_APP=wsgi
  make_backup
  git clone https://github.com/andy-takker/academiaa.git
  init_venv
  copy_settings
  restore_db
  sudo systemctl restart academiaa.service
}

main
