docker run -d \
--name aria2-with-webui \
-p 6800:6800 \
-p 6880:80 \
-p 6888:8080 \
-v /root/aria2/aria2-download:/data \
-v /root/aria2/:/conf \
-e SECRET=liukang \
xujinkai/aria2-with-webui
