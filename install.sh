#!/bin/bash
 
# set -x
# set -e

source /etc/profile 

SYSTEM=`awk -F= '/^NAME/{print $2}' /etc/os-release` 
USER=`whoami`

if [ $USER != "root" ] ; then
    echo "must be root"
    exit 1
fi

if [[ $SYSTEM = "\"CentOS Linux\"" ]] ; then
    echo -e "\033[32m CentOS Linux : \033[0m"
    echo "1. install devel"
    yum -y install wget git gcc-c++ gcc zlib-devel make gperftools.x86_64 gperftools-libs.x86_64 gperftools-devel.x86_64
elif [[ $SYSTEM = "\"Ubuntu\"" ]] ; then
    echo -e "\033[32m Ubuntu : \033[0m"
    echo "1. install devel"
    apt install -y git gcc g++ zlib1g-dev make  google-perftools libgoogle-perftools-dev libgoogle-perftools4
else
    echo "What?"
    echo $SYSTEM
    echo "Not Support !!"
    exit 0
fi


luajit="LuaJIT-2.0.5"
openssl="openssl-1.1.1f"
pcre="pcre-8.44"
tengine="tengine-2.3.2"
jemalloc="jemalloc-5.2.1"

BUILD_DIR='/tmp/nginx_install'
BASH_PWD=`pwd`

rm -rf ${BUILD_DIR} && mkdir -p ${BUILD_DIR}
cd ${BASH_PWD}/src

echo -e "\033[32m ============================================= \033[0m"
echo "2. decompression source code"
echo -e "\033[32m ============================================= \033[0m"

tar -xf ${luajit}.tar.gz -C ${BUILD_DIR}
tar -xf ${openssl}.tar.gz -C ${BUILD_DIR}
tar -xf ${pcre}.tar.gz -C ${BUILD_DIR}
tar -xf ${tengine}.tar.gz -C ${BUILD_DIR}
tar -xf ${jemalloc}.tar.bz2 -C ${BUILD_DIR}
mkdir ${BASH_PWD}/modules
cd ${BASH_PWD}/modules
git clone https://github.com/openresty/lua-resty-core.git
cp ${BASH_PWD}/modules/lua-resty-core -rf ${BUILD_DIR}

#### install luajit
echo -e "\033[32m ============================================= \033[0m"
echo "3. build lua"
echo -e "\033[32m ============================================= \033[0m"
cd ${BUILD_DIR}
cd ${BUILD_DIR}/lua-resty-core/
make install
cd ${BUILD_DIR}/${luajit}
make && make install
rm  -f /etc/profile.d/lua.sh
sed -i '/export LUAJIT_LIB*/d' /etc/profile
sed -i '/export LUAJIT_INC*/d' /etc/profile
sed -i '/export LD_LIBRARY_PATH*/d' /etc/profile
sed -i '/libluajit-5.1.so.2/d' /etc/profile

echo "export LUAJIT_LIB=/usr/local/lib" >> /etc/profile.d/lua.sh 
echo "export LUAJIT_INC=/usr/local/include/luajit-2.0" >> /etc/profile.d/lua.sh
echo "export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH" >> /etc/profile.d/lua.sh
echo "[ -e /lib64/libluajit-5.1.so.2 ] || ln -sf /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2" >> /etc/profile.d/lua.sh
. /etc/profile

if [[ $? = 0 ]] ; then
    echo -e "\033[32m luajit build successfully !!! \033[0m"
else
    echo -e "\\033[31m luajit build failed !!! \033[0m"
    exit 8
fi


##### install pcre
echo -e "\033[32m ============================================= \033[0m"
echo "4. build pcre"
echo -e "\033[32m ============================================= \033[0m"

cd ${BUILD_DIR}/${pcre}
./configure --enable-jit
make -j32 && make install

if [[ $? = 0 ]] ; then
    echo -e "\033[32m pcre build successfully !!! \033[0m"
else
    echo -e "\\033[31m pcre build failed !!! \033[0m"
    exit 8
fi

##### install tengine
echo -e "\033[32m ============================================= \033[0m"
echo "5. build tengine"
echo -e "\033[32m ============================================= \033[0m"
cd ${BUILD_DIR}/${tengine}/modules/

git clone https://github.com/arut/nginx-rtmp-module.git
git clone https://github.com/vision5/ngx_devel_kit.git
git clone https://github.com/openresty/echo-nginx-module.git
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/FRiCKLE/ngx_cache_purge.git

git clone https://github.com/bagder/libbrotli
cd libbrotli
./autogen.sh
./configure && make && make install

cd ${BUILD_DIR}/${tengine}/modules/
git clone https://github.com/google/ngx_brotli
cd ngx_brotli && git submodule update --init
cd -

cd ${BUILD_DIR}/${tengine}
#### 修改tengine server tag
sed -i 's/tengine/KServer/g' ./src/core/nginx.h
sed -i 's/tengine/KServer/g' ./src/core/nginx.c
sed -i 's/tengine/KServer/g' ./src/http/ngx_http_header_filter_module.c
sed -i 's/tengine/KServer/g' ./src/http/ngx_http_special_response.c

sed -i 's/Tengine/KServer/g' ./src/core/nginx.h
sed -i 's/Tengine/KServer/g' ./src/core/nginx.c
sed -i 's/Tengine/KServer/g' ./src/http/ngx_http_header_filter_module.c
sed -i 's/Tengine/KServer/g' ./src/http/ngx_http_special_response.c

# nginx work dir
useradd work

./configure --prefix=/home/work/nginx --error-log-path=/home/work/log/nginx/nginx.log \
--add-module=./modules/ngx_http_upstream_dyups_module \
--add-module=./modules/ngx_http_concat_module \
--add-module=./modules/ngx_http_upstream_session_sticky_module \
--add-module=./modules/ngx_http_upstream_check_module \
--add-module=./modules/ngx_http_upstream_dynamic_module \
--add-module=./modules/ngx_http_lua_module \
--add-module=./modules/ngx_backtrace_module \
--add-module=./modules/ngx_http_reqstat_module \
--add-module=./modules/ngx_http_user_agent_module \
--add-module=./modules/ngx_multi_upstream_module \
--add-module=./modules/headers-more-nginx-module \
--add-module=./modules/ngx_cache_purge \
--add-module=./modules/ngx_devel_kit \
--add-module=./modules/echo-nginx-module \
--add-module=./modules/ngx_slab_stat \
--add-module=./modules/ngx_http_sysguard_module \
--add-module=./modules/ngx_http_upstream_consistent_hash_module \
--add-module=./modules/ngx_http_proxy_connect_module \
--add-module=./modules/ngx_http_upstream_keepalive_module \
--add-module=./modules/ngx_brotli \
--add-module=./modules/nginx-rtmp-module \
--without-http_upstream_keepalive_module \
--with-file-aio \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_addition_module \
--without-mail_pop3_module \
--without-mail_imap_module \
--without-mail_smtp_module \
--with-http_sub_module \
--with-pcre=${BUILD_DIR}/${pcre} --with-pcre-jit \
--with-openssl=${BUILD_DIR}/${openssl} --with-openssl-opt=enable-shared \
--with-jemalloc=${BUILD_DIR}/${jemalloc} \
--with-luajit-inc=/usr/local/include/luajit-2.0 \
--with-luajit-lib=/usr/local/lib \
--with-http_auth_request_module \
--with-http_stub_status_module \
--with-google_perftools_module --with-ld-opt=-ltcmalloc \
--with-http_secure_link_module \
--with-http_mp4_module 


make -j32
make install

if [[ $? = 0 ]] ; then
    echo -e "\033[32m tengine build successfully !!! \033[0m"
else
    echo -e "\\033[31m tengine build failed !!! \033[0m"
    exit 8
fi

cp ${BASH_PWD}/nginx.service /etc/systemd/system
systemctl daemon-reload


#### set default nginx conf
echo -e "\033[32m ============================================= \033[0m"
echo "6. set default tengine conf"
echo -e "\033[32m ============================================= \033[0m"

mkdir /home/work/nginx/conf.d
cp ${BASH_PWD}/nginx.conf /home/work/nginx/conf/nginx.conf

/home/work/nginx/sbin/nginx -t


if [[ `echo $?` = 0 ]] ; then
    echo -e "\033[32m install nginx successfully \033[0m"
else
    echo -e "\033[31m install nginx failed !!!! \033[0m"
fi

