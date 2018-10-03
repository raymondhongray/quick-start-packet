#!/bin/bash

# Output colors
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"

CUR_DIR=$(pwd)

function finally {
    echo "switch to original workspace"
    echo -e -n "$NORMAL"
    cd $CUR_DIR
    exit 1
}

trap finally ERR SIGINT SIGTERM SIGKILL SIGQUIT


cd $APP_ROOT
source .env.default
# [[ "$WEB3_HOST" == "" ]] && WEB3_HOST=$DEFAULT_WEB3_HOST
# [[ "$WEB3_PORT" == "" ]] && WEB3_PORT=$DEFAULT_WEB3_PORT
[[ "$POA_SIGNER_PRI_KEY" == "" ]] && POA_SIGNER_PRI_KEY=$DEFAULT_POA_SIGNER_PRI_KEY
[[ "$POA_SIGNER_ADDRESS" == "" ]] && POA_SIGNER_ADDRESS=$DEFAULT_POA_SIGNER_ADDRESS
[[ "$POA_SIGNER_PWD" == "" ]] && POA_SIGNER_PWD=$DEFAULT_POA_SIGNER_PWD

POA_SIGNER_ADDRESS_FILE=$MOUNT_DATA_DIR/poa_signer.address
POA_SIGNER_PWD_FILE=$MOUNT_DATA_DIR/poa_signer.pwd
BOOSTER_ADDRESS_FILE=$MOUNT_DATA_DIR/booster.address
TWX_ADDRESS_FILE=$MOUNT_DATA_DIR/twx.address

# echo 0 if not modified
# echo 1 if modified
function _isSignerModified {
    [ ! -f "$POA_SIGNER_ADDRESS_FILE" -o ! -f "$POA_SIGNER_PWD_FILE" ] && \
    echo 1 && return

    STORED_POA_SIGNER_ADDRESS=$(cat $POA_SIGNER_ADDRESS_FILE) && \
    STORED_POA_SIGNER_PWD=$(cat $POA_SIGNER_PWD_FILE)

    [ "$STORED_POA_SIGNER_ADDRESS" == "" -o "$STORED_POA_SIGNER_PWD" == "" ] && \
    echo 1 && return

    [ "$STORED_POA_SIGNER_ADDRESS" != "$POA_SIGNER_ADDRESS" ] && \
    echo 1 && return
    
    [ "$STORED_POA_SIGNER_PWD" != "$POA_SIGNER_PWD" ] && \
    echo 1 && return

    echo 0
}

function _isBoosterModified {
    [ ! -f "$BOOSTER_ADDRESS_FILE" ] && \
    echo 1 && return

    STORED_BOOSTER_ADDRESS=$(cat $BOOSTER_ADDRESS_FILE) && \
    [[ "$STORED_BOOSTER_ADDRESS" == "" ]] && \
    echo 1 && return

    echo 0
}

# $1 is string to check
function _cleanBadPattern {
    echo $(echo $1 | tr -d '\r')
}

# $1 is contract.env.js
function _modContractEnvJS {
    sed -i "s%<POA_SIGNER_PRI_KEY>%$POA_SIGNER_PRI_KEY%g" $1
}

# $1 is contract.env.js
# $2 is $boosterAddress
function _modGringottsEnvJS {
    # sed -i "s%<WEB3_HOST>%$WEB3_HOST%g" $1
    # sed -i "s%<WEB3_PORT>%$WEB3_PORT%g" $1
    sed -i "s%<POA_SIGNER_ADDRESS>%$POA_SIGNER_ADDRESS%g" $1
    sed -i "s%<BOOSTER_ADDRESS>%$2%g" $1
}

# Modify env.js of contract
function _produceContractsEnvJS {
    cp contract.env.js.tpl contract.env.js
    _modContractEnvJS contract.env.js
    mv contract.env.js $CONTRACTS_SPACE/env.js
}

# Modify env.js of gringotts
# $1 is $boosterAddress
function _produceGringottsEnvJS {
    cp gringotts.env.js.tpl gringotts.env.js
    _modGringottsEnvJS gringotts.env.js $1
    mv gringotts.env.js $GRINGOTTS_SPACE/env.js
}

# Deploy InfinitechainManager then SideChain
# $1 is the file to store SideChainAddress
function _deploy {
    # Deploy InfinitechainManager
    cd $CONTRACTS_SPACE
    truffle compile > /dev/null 2>&1
    tmpDeployFile=truffle-deploy.tmp
    truffle deploy --reset 2>/dev/stdout | tee $tmpDeployFile
    local ifcManagerAddress=$(cat $tmpDeployFile | grep InfinitechainManager: | sed "s%InfinitechainManager:%%g" | sed "s% %%g")
    local ifcManagerAddress=$(_cleanBadPattern $ifcManagerAddress)
    local twxAddress=$(cat $tmpDeployFile | grep TWX: | sed "s%TWX:%%g" | sed "s% %%g")
    local twxAddress=$(_cleanBadPattern $twxAddress)
    
    rm $tmpDeployFile

    # Deploy SideChain
    cd $CONTRACTS_SPACE
    local boosterAddress=$(npm install > /dev/null 2>&1 && node testDeployBooster.js --managerAddress $ifcManagerAddress --boosterOwner $POA_SIGNER_ADDRESS --assetAddress $twxAddress --maxWithdraw 100) 
    echo $boosterAddress > $1
    echo $twxAddress > $TWX_ADDRESS_FILE
}

function _provision {
    cd $CONTRACTS_SPACE
    _produceContractsEnvJS
    
    _deploy $BOOSTER_ADDRESS_FILE
    boosterAddress=$(cat $BOOSTER_ADDRESS_FILE)
    [[ "$boosterAddress" == "0x0000000000000000000000000000000000000000" ]] && \
    echo "Sidechain deployment failed" && exit 256

    cd $GRINGOTTS_SPACE
    _produceGringottsEnvJS $boosterAddress
    NODE_ENV=production ./node_modules/.bin/sequelize \
    db:migrate:undo:all --config env.js \
    --migrations-path ./storage-manager/migrations \
    --models-path ./storage-manager/models

    # Try to re-create old db after deploy new SideChain
    # https://www.tutorialspoint.com/postgresql/postgresql_drop_database.htm
    # https://dba.stackexchange.com/questions/14740/how-to-use-psql-with-no-password-prompt
    PGPASSWORD=potter dropdb -h postgres -p 5432 -U harry gringot
    PGPASSWORD=potter createdb -h postgres -p 5432 -U harry gringot

    echo $POA_SIGNER_ADDRESS > $POA_SIGNER_ADDRESS_FILE
    echo $POA_SIGNER_PWD > $POA_SIGNER_PWD_FILE
}

isSingerModified=$(_isSignerModified);
isBoosterModified=$(_isBoosterModified);
if [ "$isSingerModified" == "1" ]; then
    echo -e -n "$BLUE"
    echo ""
    echo "Changes detected(signer address), execute provision process."
    echo ""
    echo -e -n "$NORMAL"
    _provision
elif [ "$isBoosterModified" == "1" ]; then
    echo -e -n "$BLUE"
    echo ""
    echo "Changes detected(booster address), execute provision process."
    echo ""
    echo -e -n "$NORMAL"
    _provision    
else
    echo -e -n "$BLUE"
    echo ""
    echo "No changes detected, skip provision process."
    echo ""
    echo -e -n "$NORMAL"
    boosterAddress=$(cat $BOOSTER_ADDRESS_FILE)
    cd $GRINGOTTS_SPACE
    _produceGringottsEnvJS $boosterAddress
fi

echo -e -n "$BLUE"
echo ""
echo "signer private key: "$POA_SIGNER_PRI_KEY
echo "signer address    : "$POA_SIGNER_ADDRESS
echo "signer password   : "$POA_SIGNER_PWD
echo ""
echo -e -n "$NORMAL"

cd $GRINGOTTS_SPACE
npm run pgmigrate
pm2 start --log-date-format 'DD-MM HH:mm:ss.SSS' --no-daemon server.js