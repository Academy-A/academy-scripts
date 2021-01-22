#!/bin/bash
cd "/home/$USER"
tar -zcf backups/db/database-$(date +%Y-%m-%d-%H-%M).tar.gz academiaa/migrations academiaa/app.db
