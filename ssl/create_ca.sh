#!/bin/bash -e

# 创建CA根证书
# 非交互式方式创建以下内容:
# 国家名(2个字母的代号)
C=CN
# 省
ST="Beijing"
# 市
L="Beijing"
# 公司名
O="kiosk007 Technology Co., Ltd"
# 组织或部门名
OU=SRE
# 服务器FQDN或颁发者名
CN=kiosk.io
# 邮箱地址
emailAddress=weijiaxiang007@foxmail.com

mkdir -p ./demoCA/{private,newcerts}
touch ./demoCA/index.txt
[ ! -f ./demoCA/seria ] && echo 01 > ./demoCA/serial
[ ! -f ./demoCA/crlnumber ] && echo 01 > ./demoCA/crlnumber
[ ! -f ./demoCA/cacert.pem ] && openssl req -utf8 -new -x509 -days 36500 -newkey rsa:2048 -nodes -keyout ./demoCA/private/cakey.pem -out ./demoCA/cacert.pem -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}/emailAddress=${emailAddress}"
[ ! -f ./demoCA/private/ca.crl ] && openssl ca -crldays 36500 -gencrl -out "./demoCA/private/ca.crl"
