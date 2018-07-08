docker run -d \
    -e "ARGS=server -l :6060 -p liukang" \
    -p 6060:6060/tcp -p 6060:6060/udp \
    chenhw2/brook
