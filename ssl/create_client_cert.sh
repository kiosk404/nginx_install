#!/bin/bash -e

show_help() {
    echo "$0 [-h|-?|--help] [--ou ou] [--cn cn] [--email email]"
    echo "-h|-?|--help    显示帮助"
    echo "--ou            设置组织或部门名，如: SRE"
    echo "--cn            设置FQDN或所有者名，如: kiosk"
    echo "--email         设置FQDN或所有者邮件，如: weijiaxiang007@foxmail.com"
}

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|-\?|--help)
            show_help
            exit 0
            ;;
        --ou)
            OU="${2}"
            shift
            ;;        
        --cn)
            CN="${2}"            
            shift
            ;;
        --email)
            emailAddress="${2}"            
            shift
            ;;
        --ext)
	    DNS="${2}"
	    shift
	    ;;
	--)
            shift
            break
        ;;
        *)
            echo -e "Error: $0 invalid option '$1'\nTry '$0 --help' for more information.\n" >&2
            exit 1
        ;;
    esac
shift
done

# 创建客户端证书
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
OU=${OU:-SRE}
# 服务器FQDN或授予者名
CN=${CN:-demo}
# 邮箱地址
emailAddress=${emailAddress:-demo@example.com}

cp demo.ext http.ext
sed -i "s/demo.com/${CN}/g" ./http.ext


#mkdir -p "${CN}"

#[ ! -f "${CN}/${CN}.key" ] && openssl req -utf8 -nodes -newkey rsa:2048 -keyout "${CN}/${CN}.key" -new -days 36500 -out "${CN}/${CN}.csr" -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}/emailAddress=${emailAddress}"
#[ ! -f "${CN}/${CN}.crt" ] && openssl ca -utf8 -batch -days 36500 -in "${CN}/${CN}.csr" -out "${CN}/${CN}.crt" -extfile http.ext
#[ ! -f "${CN}/${CN}.p12" ] && openssl pkcs12 -export -clcerts -CApath ./demoCA/ -inkey "${CN}/${CN}.key" -in "${CN}/${CN}.crt" -certfile "./demoCA/cacert.pem" -passout pass: -out "${CN}/${CN}.p12"
