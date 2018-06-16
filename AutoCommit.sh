#!/usr/bin/env bash
#
# 输出提示
echo '    Be careful! Make sure all the parameters (dir path) you input are empty,' && \
echo '    or the dir and all the files under it will be deleted and cannot be recovered back.'

# 定义临时目录名（可根据自己需要修改，注意 $tmp_path 最好不要与已有的目录重名，更不要设为根目录！）
export tmp_path='/temp666/'
export tmp_name='icn/'

# 定义函数，用于安全地创建一个空目录
makedir(){
    if [ "$#" != 1 ]; then
        echo 'Please input just one parameter(dir path) !'
    else
        mkdir $1
        if [ "$?" != 0 ]; then
            echo 'Make dir failed!'
            echo 'Do you want to remove the exist folder? Y/N'
            read && echo $REPLY
            if [ "$REPLY" == "Y" ] || [ "$REPLY" == "y" ] || [ "$REPLY" == "yes" ]; then
                rm $1 -rf
            else
                echo 'Your input is not "Y", script will not remove any folder.'
            fi
            mkdir $1
            if [ "$?" != 0 ]; then
                echo 'Make dir failed! Script will end here.'
                exit
            else
                echo 'Make dir success!'
            fi
        fi
    fi
}

# 创建临时目录
makedir $tmp_path
makedir $tmp_path$tmp_name
cd $tmp_path$tmp_name

# 下载最新文件
wget https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf

# 通过 sed 命令处理之
sed -i 's/114.114.114.114/119.29.29.29/g' accelerated-domains.china.conf
sed -i -e 's/^/route\ \${OPS}\ -net\ &/g' -e 's/$/&\ \${ROUTE_GW}/g' china_ip_list.txt
# 针对北京大学校园网划分网段进行特殊处理
sed -i '/.*115\.27\.0\.0.*/'d china_ip_list.txt
sed -i '/.*162\.105\.0\.0.*/'d china_ip_list.txt
sed -i '/.*202\.112\.7\.0.*/'d china_ip_list.txt
sed -i '/.*202\.112\.8\.0.*/'d china_ip_list.txt
sed -i '/.*222\.29\.0\.0.*/'d china_ip_list.txt
sed -i '/.*222\.29\.128\.0.*/'d china_ip_list.txt

# 建立 route.sh 文件
cat > route.sh << 'END_TEXT'
#/bin/bash
#export PATH="/bin:/sbin:/usr/sbin:/usr/bin"

ROUTE_GW="gw `nvram get wan0_gateway`"

if [ $# -ne 1 ]; then
    echo $0 add/delete
    exit
fi

if [ "$1" != "add" ]  && [ "$1" != "delete" ]; then
    echo $0 add/delete
    exit
fi

if [ "$1" == "delete" ]; then
    ROUTE_GW=""
fi

OPS=$1

# route $OPS -net ${IP_SEGMENT} ${ROUTE_GW}
# Generate:
# wget https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
# sed -i -e 's/^/route\ \${OPS}\ -net\ &/g' -e 's/$/&\ \${ROUTE_GW}/g' china_ip_list.txt

# 另一边要用到的命令：
# wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
# sed -i 's/114.114.114.114/119.29.29.29/g' accelerated-domains.china.conf

END_TEXT

cat china_ip_list.txt >> route.sh << 'END_TEXT'
END_TEXT

cat >> route.sh << 'END_TEXT'


# https://its.pku.edu.cn/faq_2.jsp  --获得北大IP网段
# 162.105.0.0/16
# 202.112.7.0/24
# 202.112.8.0/24
# 222.29.0.0/17
# 222.29.128.0/19
# 115.27.0.0/16
# 2001:da8:201::/48
route ${OPS} -net 115.27.0.0/16 ${ROUTE_GW}
route ${OPS} -net 162.105.0.0/16 ${ROUTE_GW}
route ${OPS} -net 202.112.7.0/24 ${ROUTE_GW}
route ${OPS} -net 202.112.8.0/24 ${ROUTE_GW}
route ${OPS} -net 222.29.0.0/17 ${ROUTE_GW}
route ${OPS} -net 222.29.128.0/19 ${ROUTE_GW}
route ${OPS} -A inet6 2001:da8:201::/48 ${ROUTE_GW}
END_TEXT

# 更新 4Share 库 router 目录
rm /github/4Share/router/*.conf
rm /github/4Share/router/*.txt
rm /github/4Share/router/*.sh
cp accelerated-domains.china.conf /github/4Share/router/ -f
cp china_ip_list.txt /github/4Share/router/ -f
cp route.sh /github/4Share/router/ -f
rm *.txt
rm *.sh

# 在已有 accelerated-domains.china.conf 文件的基础上做二次修改，使符合 DNSCrypt 配置格式
sed -i -e 's/server=\///g' -e 's/\//    /g' accelerated-domains.china.conf

# 建立 forwarding-rules.txt 文件
cat > forwarding-rules.txt << 'END_TEXT'
##################################
#        Forwarding rules        #
##################################

## This is used to route specific domain names to specific servers.
## The general format is:
## <domain> <server address>[:port] [, <server address>[:port]...]
## IPv6 addresses can be specified by enclosing the address in square brackets.

## In order to enable this feature, the "forwarding_rules" property needs to
## be set to this file name inside the main configuration file.

## Forward queries for example.com and *.example.com to 9.9.9.9 and 8.8.8.8
# example.com     9.9.9.9,8.8.8.8

# To generate:
# sed -i -e 's/server=\///g' -e 's/\//    /g' accelerated-domains.china.conf

END_TEXT

cat accelerated-domains.china.conf >> route.sh << 'END_TEXT'
END_TEXT

# 更新 4Share 库 DNSCrypt 目录
rm /github/4Share/DNSCrypt/*.conf
rm /github/4Share/DNSCrypt/*.txt
rm /github/4Share/DNSCrypt/*.sh
cp accelerated-domains.china.conf /github/4Share/DNSCrypt/ -f
cp forwarding-rules.txt /github/4Share/DNSCrypt/ -f

# 切换到 4Share 库所在目录，推送更新到 GitHub
cd /github/4Share/
git add *
git commit -a -m "Auto Commit"
git push

# 一点清洁工作
rm -rf $tmp_path