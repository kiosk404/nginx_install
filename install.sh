#!/bin/bash

# 检查是否为 root 用户
if [ "$(whoami)" != "root" ]; then
    echo "must be root"
    exit 1
fi

# 读取系统信息
SYSTEM=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
echo "Current SYSTEM: ==> ", ${SYSTEM}

# 创建构建目录
BUILD_DIR='/tmp/nginx_install'
mkdir -p "${BUILD_DIR}"

luajit="LuaJIT-2.0.5"
openssl="openssl-1.1.1f"
pcre="pcre-8.45"
tengine="tengine-3.1.0"
jemalloc="jemalloc-5.2.1"
nginx="nginx-1.26.2"

BASH_PWD=`pwd`

# 安装依赖
install_deps() {
    echo -e "\033[32m ============================================= \033[0m"
    echo "1. Install system dependency libraries"
    echo -e "\033[32m ============================================= \033[0m"

    if [[ $SYSTEM = "\"CentOS Linux\"" ]]; then
        echo -e "\033[32m CentOS Linux : \033[0m"
        yum -y install git gcc gcc-c++ autoconf zlib-devel make gperftools gperftools-devel gperftools-libs pcre-devel openssl-devel geoip-devel libxml2-devel libxslt-devel gd-devel libatomic libncurses-devel readline-devel
    elif [[ $SYSTEM = "\"Ubuntu\"" ]]; then
        echo -e "\033[32m Ubuntu : \033[0m"
        apt install -y git gcc g++ autoconf zlib1g-dev make google-perftools libgoogle-perftools-dev libgoogle-perftools4 libpcre3-dev libssl-dev libgeoip-dev libxml2-dev libxslt1-dev libgd-dev libatomic1 libncurses5-dev libreadline-dev
    else
        echo "What?"
        echo $SYSTEM
        echo "Not Support !!"
        exit 0
    fi
}

install_modules() {
    echo -e "\033[32m ============================================= \033[0m"
    echo "2. decompression source code"
    echo -e "\033[32m ============================================= \033[0m"
    cd ${BASH_PWD}/src
    tar -xf ${luajit}.tar.gz -C ${BUILD_DIR}
    tar -xf ${openssl}.tar.gz -C ${BUILD_DIR}
    tar -xf ${pcre}.tar.bz2 -C ${BUILD_DIR}
    tar -xf ${tengine}.tar.gz -C ${BUILD_DIR}
    tar -xf ${jemalloc}.tar.bz2 -C ${BUILD_DIR}
    tar -xf ${nginx}.tar.gz -C ${BUILD_DIR}

    cp ${BASH_PWD}/modules/lua-resty-core -rf ${BUILD_DIR}
}

# 安装 LuaJIT
install_luajit() {
    echo -e "\033[32m ============================================= \033[0m"
    echo "3. build lua"
    echo -e "\033[32m ============================================= \033[0m"
    cd ${BUILD_DIR}/lua-resty-core/
    make install
    cd ${BUILD_DIR}/${luajit}
    make && make install
    setup_luajit_env

    if [[ $? = 0 ]] ; then
        echo -e "\033[32m luajit build successfully !!! \033[0m"
    else
        echo -e "\\033[31m luajit build failed !!! \033[0m"
        exit 8
    fi
}

# 设置 LuaJIT 环境变量
setup_luajit_env() {
    rm -f /etc/profile.d/lua.sh
    echo "export LUAJIT_LIB=/usr/local/lib" >> /etc/profile.d/lua.sh
    echo "export LUAJIT_INC=/usr/local/include/luajit-2.0" >> /etc/profile.d/lua.sh
    echo "export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH" >> /etc/profile.d/lua.sh
    echo "[ -e /lib64/libluajit-5.1.so.2 ] || ln -sf /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2" >> /etc/profile.d/lua.sh
    . /etc/profile
}

# 安装 PCRE
install_pcre() {
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
}

install_nginx_moudle() {
    cd ${BUILD_DIR}/${nginx}
    mkdir -p ${BUILD_DIR}/${nginx}/modules/

    install_tengine_module
    install_other_module
}

# 下载 Tengine Moudle
install_tengine_module() {
    echo -e "\033[32m ============================================= \033[0m"
    echo "5. install tengine module"
    echo -e "\033[32m ============================================= \033[0m"
    cd ${BUILD_DIR}/${tengine}/modules/

    
    cp -rf ngx_http_upstream_dyups_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_concat_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_upstream_session_sticky_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_upstream_check_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_upstream_dynamic_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_lua_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_backtrace_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_reqstat_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_user_agent_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_multi_upstream_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_slab_stat ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_sysguard_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_upstream_consistent_hash_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_proxy_connect_module ${BUILD_DIR}/${tengine}/modules/
    cp -rf ngx_http_upstream_keepalive_module ${BUILD_DIR}/${tengine}/modules/    
}

# 下载其他 Nignx Module
install_other_module() {
    cd ${BUILD_DIR}/${nginx}/modules/

    git clone https://github.com/arut/nginx-rtmp-module.git
    git clone https://github.com/vision5/ngx_devel_kit.git
    git clone https://github.com/openresty/echo-nginx-module.git
    git clone https://github.com/FRiCKLE/ngx_cache_purge.git

    git clone https://github.com/bagder/libbrotli
    cd libbrotli
    ./autogen.sh
    ./configure && make && make install

    cd ${BUILD_DIR}/${tengine}/modules/
    git clone https://github.com/google/ngx_brotli
    cd ngx_brotli && git submodule update --init
    cd -
}

# 安装
compile_tengine() {
    cd ${BUILD_DIR}/${nginx}
    #### 修改 nginx server tag
    sed -i 's/nginx/kiosk007/g' ./src/core/nginx.h
    sed -i 's/nginx/kiosk007/g' ./src/core/nginx.c
    sed -i 's/nginx/kiosk007/g' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/nginx/kiosk007/g' ./src/http/ngx_http_special_response.c

    sed -i 's/NGINX/KIOSK007/g' ./src/core/nginx.h
    sed -i 's/NGINX/KIOSK007/g' ./src/core/nginx.c
    sed -i 's/NGINX/KIOSK007/g' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/NGINX/KIOSK007/g' ./src/http/ngx_http_special_response.c

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
}

build_nginx() {
    # 编译 Nginx
    compile_tengine

    cp ${BASH_PWD}/nginx.service /etc/systemd/system
    systemctl daemon-reload


    #### set default nginx conf
    echo -e "\033[32m ============================================= \033[0m"
    echo "6. set default tengine conf"
    echo -e "\033[32m ============================================= \033[0m"

    mkdir /home/work/nginx/conf.d
    cp ${BASH_PWD}/nginx.conf /home/work/nginx/conf/nginx.conf

    /home/work/nginx/sbin/nginx -t
}


main() {
    # 安装依赖和Nginx源代码
    install_deps
    install_modules

    install_luajit
    install_pcre
    install_nginx_moudle

    build_nginx
}

main