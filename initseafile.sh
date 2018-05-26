docker run -d --name seafile \
  -e SEAFILE_SERVER_LETSENCRYPT=true \
  -e SEAFILE_SERVER_HOSTNAME=proxy.ddvudo.cf \
  -e SEAFILE_ADMIN_EMAIL=644077730@qq.com \
  -e SEAFILE_ADMIN_PASSWORD=liukang951006 \
  -v /seafile-data:/shared \
  -p 80:80 \
  -p 443:443 \
  seafileltd/seafile:latest
