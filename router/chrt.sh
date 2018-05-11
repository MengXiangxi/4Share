#!/bin/sh

if [ $# -ne 1 ]; then
    echo $0 add/del/upd
    exit
fi

if [ "$1" == "add" ]; then
    chmod a+rx /tmp/mnt/router/configs/*

    /tmp/mnt/router/configs/route.sh add && echo -e "\n  Add route success!\n"
elif [ "$1" == "del" ]; then
    chmod a+rx /tmp/mnt/router/configs/*

    /tmp/mnt/router/configs/route.sh delete && echo -e "\n  Delete route success!\n"
elif [ "$1" != "upd" ]; then
    curl -o /tmp/mnt/router/configs/route.sh.new https://raw.githubusercontent.com/IceCodeNew/4Share/master/router/route.sh \
    && mv /tmp/mnt/router/configs/route.sh.new /tmp/mnt/router/configs/route.sh -f && echo -e "\n  Update route.sh success!\n"

    curl -o /tmp/mnt/router/configs/accelerated-domains.china.conf.new \
    https://raw.githubusercontent.com/IceCodeNew/4Share/master/router/accelerated-domains.china.conf && \
    mv /tmp/mnt/router/configs/accelerated-domains.china.conf.new /tmp/mnt/router/configs/accelerated-domains.china.conf -f \
    && echo -e "\n  Update accelerated-domains.china.conf success!\n"
else
    echo $0 add/del/upd
    exit
fi

service restart_dnsmasq && echo -e "\n  Restart dnsmasq success!\n"