FROM ubuntu

ENV SSR_URL https://github.com/shadowsocksr-backup/shadowsocksr.git
ENV SS_PORT 6666
ENV SS_PASSWD liukang951006
ENV SS_METH aes-256-cfb #encryption method
ENV SS_OBFS http_simple #obfsplugin

RUN set -ex \
    && apt update \
    && apt install -y  python-pip python-dev build-essential git \
    && pip install --upgrade pip \
    && git clone ${SSR_URL} \
    && cd ./shadowsocksr/shadowsocks \

CMD python server.py -p $SS_PORT -k $SS_PASSWD -m $SS_METH -o $SS_OBFS --fast-open
