docker run -d --name nextcloud\
       	-v /nextcloud-data:/var/www/html\
       	-e POSTGRES_HOST="ddvudo.tk"\
       	-e POSTGRES_DB="nextcloud"\
       	-e POSTGRES_USER="postgres"\
       	-e POSTGRES_PASSWORD="liukang951006"\
      	-p 80:80\
       	--link postgres:postgres\
       	nextcloud
