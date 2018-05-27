docker run -d --name seafile \
  -e SEAFILE_SERVER_HOSTNAME=127.0.0.1 \
  -e SEAFILE_ADMIN_EMAIL=644077730@qq.com \
  -e SEAFILE_ADMIN_PASSWORD=liukang951006 \
  -v /seafile-data:/shared \
  -p 80:80 \
  -p 443:443 \
  seafileltd/seafile:latest
