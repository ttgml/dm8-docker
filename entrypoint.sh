#!/bin/bash
set -e

DB_PATH=${DB_PATH:-"/home/dmdba/data"}
INSTANCE_NAME=${INSTANCE_NAME:-"DMSERVER"}
DB_NAME=${DB_NAME:-"DAMENG"}
DMDB_INSTALL_PATH=${DMDB_INSTALL_PATH:-"/home/dmdba/dmdb"}
INIT_PARAMS=""
PORT_NUM=${PORT_NUM:-"5236"}
TIME_ZONE=${TIME_ZONE:-"+08:00"}
BUFFER=${BUFFER:-"8000"}
PAGE_CHECK=${PAGE_CHECK:-"3"}
PAGE_SIZE=${PAGE_SIZE:-"8"}
LOG_SIZE=${LOG_SIZE:-"4096"}
EXTENT_SIZE=${EXTENT_SIZE:-"16"}
CHARSET=${CHARSET:-"0"}
USE_DB_NAME=${USE_DB_NAME:-"1"}
AUTO_OVERWRITE=${AUTO_OVERWRITE:-"0"}
BLANK_PAD_MODE=${BLANK_PAD_MODE:-"0"}
DPC_MODE=${DPC_MODE:-"0"}
OTHER_PARAMS=${OTHER_PARAMS:-""}

SYSDBA_PWD=${SYSDBA_PWD:-""}
SYSAUDITOR_PWD=${SYSAUDITOR_PWD:-""}

function init_db() {
    if [ -z "$SYSDBA_PWD" ]; then
        echo "SYSDBA_PWD is empty, please set it in environment variables"
        exit 1
    fi
    if [ -z "$SYSAUDITOR_PWD" ]; then
        echo "SYSAUDITOR_PWD is empty, please set it in environment variables"
        exit 1
    fi
    # 判断DB_PATH文件夹内是否存在文件
    if [ -d "$DB_PATH" ]; then
        if [ "$(ls -A $DB_PATH)" ]; then
            echo "DB_PATH is not empty, please check it"
            exit 1
        fi
    else
        echo "DB_PATH is not exist, create it"
        mkdir -p $DB_PATH
        chown -R dmdba $DB_PATH
    fi
    INIT_PARAMS="$INIT_PARAMS PATH=$DB_PATH SYSDBA_PWD=$SYSDBA_PWD SYSAUDITOR_PWD=$SYSAUDITOR_PWD INSTANCE_NAME=$INSTANCE_NAME"
    INIT_PARAMS="$INIT_PARAMS PORT_NUM=$PORT_NUM DB_NAME=$DB_NAME TIME_ZONE=$TIME_ZONE BUFFER=$BUFFER PAGE_CHECK=$PAGE_CHECK PAGE_SIZE=$PAGE_SIZE"
    INIT_PARAMS="$INIT_PARAMS LOG_SIZE=$LOG_SIZE EXTENT_SIZE=$EXTENT_SIZE CHARSET=$CHARSET USE_DB_NAME=$USE_DB_NAME"
    INIT_PARAMS="$INIT_PARAMS AUTO_OVERWRITE=$AUTO_OVERWRITE BLANK_PAD_MODE=$BLANK_PAD_MODE DPC_MODE=$DPC_MODE"
    INIT_PARAMS="$INIT_PARAMS $OTHER_PARAMS"
    echo "Initializing database..."
    echo "Initializing database with parameters:"
    echo $INIT_PARAMS
    sudo -u dmdba ${DMDB_INSTALL_PATH}/bin/dminit $INIT_PARAMS
    echo "Database initialized"
}
function start_dmap() {
    echo "Starting DmAPService..."
    sudo -u dmdba ${DMDB_INSTALL_PATH}/bin/dmap dmap_ini=${DMDB_INSTALL_PATH}/bin/dmap.ini &
    echo "DmAPService started"
}

# 创建一个函数，用来修改文件的权限
function modify_db_permissions() {
    echo "Modifying $DB_PATH permissions..."
    chown -R dmdba $DB_PATH
    echo "$DB_PATH permissions modified"
}

function check_initialized() {
    # 判断 $DB_PATH/$DB_NAME/dm.ini 是否存在
    if [ -f "$DB_PATH/$DB_NAME/dm.ini" ]; then
        echo "Database already initialized"
        modify_db_permissions
    else
        echo "Database not initialized"
        init_db
    fi

}

cd $DMDB_INSTALL_PATH/bin
# 检查DB是否初始化，如果没有初始化则执行初始化
check_initialized

# 启动 DmAPServer
start_dmap

#启动数据库实例
echo "Starting DmServer..."
exec sudo -u dmdba ${DMDB_INSTALL_PATH}/bin/dmserver path=$DB_PATH/$DB_NAME/dm.ini