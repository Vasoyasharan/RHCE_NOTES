#!/bin/bash

# Create backup directory if not exists
mkdir -p /backup

# Create compressed backup
tar -czf /backup/backup_$(date +%F).tar.gz /home

# Transfer to remote server
rsync -avz /backup/backup_$(date +%F).tar.gz root@192.168.0.106:/remote_backup

# Delete backups older than 7 days 
find /backup -type f -mtime +7 -delete

# Log result
echo "Backup done on $(date)" >> /var/log/auto_backup.log
