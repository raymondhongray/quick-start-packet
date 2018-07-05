#!/bin/bash

cd $APP_ROOT
source .env.default
# [[ "$WEB3_HOST" == "" ]] && WEB3_HOST=$DEFAULT_WEB3_HOST
# [[ "$WEB3_PORT" == "" ]] && WEB3_PORT=$DEFAULT_WEB3_PORT
[[ "$POA_SIGNER_ADDRESS" == "" ]] && POA_SIGNER_ADDRESS=$DEFAULT_POA_SIGNER_ADDRESS
[[ "$POA_SIGNER_PWD" == "" ]] && POA_SIGNER_PWD=$DEFAULT_POA_SIGNER_PWD

POA_SIGNER_ADDRESS_FILE=$MOUNT_DATA_DIR/poa_signer.address
POA_SIGNER_PWD_FILE=$MOUNT_DATA_DIR/poa_signer.pwd

# echo 0 if not modified
# echo 1 if modified
function _isSignerModified {
    [ ! -f "$POA_SIGNER_ADDRESS_FILE" -o ! -f "$POA_SIGNER_PWD_FILE" ] && \
    echo 1 && return

    STORED_POA_SIGNER_ADDRESS=$(cat $POA_SIGNER_ADDRESS_FILE) && \
    [[ "$STORED_POA_SIGNER_ADDRESS" != "" ]] && [[ "$STORED_POA_SIGNER_ADDRESS" != "$POA_SIGNER_ADDRESS" ]] && \
    echo 1 && return
    
    STORED_POA_SIGNER_PWD=$(cat $POA_SIGNER_PWD_FILE) && \
    [[ "$STORED_POA_SIGNER_PWD" != "" ]] && [[ "$STORED_POA_SIGNER_PWD" != "$POA_SIGNER_PWD" ]] && \
    echo 1 && return

    echo 0
}

# $1 is string to check
function _cleanBadPattern {
    echo $(echo $1 | tr -d '\r')
}

# $1 is contract.env.js
function _modContractEnvJS {
    # sed -i "s%<WEB3_HOST>%$WEB3_HOST%g" $1
    # sed -i "s%<WEB3_PORT>%$WEB3_PORT%g" $1
    sed -i "s%<POA_SIGNER_ADDRESS>%$POA_SIGNER_ADDRESS%g" $1
    sed -i "s%<POA_SIGNER_PWD>%$POA_SIGNER_PWD%g" $1
}

# $1 is contract.env.js
# $2 is $sideChainAddress
function _modGringottsEnvJS {
    # sed -i "s%<WEB3_HOST>%$WEB3_HOST%g" $1
    # sed -i "s%<WEB3_PORT>%$WEB3_PORT%g" $1
    sed -i "s%<POA_SIGNER_ADDRESS>%$POA_SIGNER_ADDRESS$%g" $1
    sed -i "s%<SIDECHAIN_ADDRESS>%$2%g" $1
}

# Modify env.js of contract
function _updateContractsEnvJS {
    cp contract.env.js.tpl contract.env.js
    _modContractEnvJS contract.env.js
    mv contract.env.js $GRIN_CONTRACTS_SPACE/env.js
}

# Modify env.js of gringotts
# $1 is $sideChainAddress
function _updateGringottsEnvJS {
    cp gringotts.env.js.tpl gringotts.env.js
    _modGringottsEnvJS gringotts.env.js $1
    mv gringotts.env.js $GRINGOTTS_SPACE/env.js
}

# Deploy InfinitechainManager then SideChain
# $1 is the file to store SideChainAddress
function _deploy {
    # Deploy InfinitechainManager
    cd $GRIN_CONTRACTS_SPACE
    truffle compile > /dev/null 2>&1
    tmpDeployFile=truffle-deploy.tmp
    truffle deploy --reset 2>/dev/stdout | tee $tmpDeployFile
    local ifcManagerAddress=$(cat $tmpDeployFile | grep InfinitechainManager: | sed "s%InfinitechainManager:%%g" | sed "s% %%g")
    local ifcManagerAddress=$(_cleanBadPattern $ifcManagerAddress)
    rm $tmpDeployFile

    # Deploy SideChain
    cd $GRIN_CONTRACTS_SPACE
    local sideChainAddress=$(npm install > /dev/null 2>&1 && node testDeploySidechain.js --managerAddress $ifcManagerAddress --sidechainOwner $POA_SIGNER_ADDRESS) 
    echo $sideChainAddress > $1
}

function _provision {
    cd $GRIN_CONTRACTS_SPACE
    _updateContractsEnvJS
    _deploy sideChainAddressFile
    sideChainAddress=$(cat sideChainAddressFile)
    [[ "$sideChainAddress" == "0x0000000000000000000000000000000000000000" ]] && \
    echo "Sidechain deployment failed" && exit 256

    cd $GRINGOTTS_SPACE
    _updateGringottsEnvJS $sideChainAddress

    echo $POA_SIGNER_ADDRESS > $POA_SIGNER_ADDRESS_FILE
    echo $POA_SIGNER_PWD > $POA_SIGNER_PWD_FILE
}

isModified=$(_isSignerModified);
if [[ "$isModified" == "1" ]]; then 
    _provision
else
    echo "signer address is unchanged, pass provision process."
fi

cd $GRINGOTTS_SPACE
npm run pgmigrate
pm2 start --log-date-format 'DD-MM HH:mm:ss.SSS' --no-daemon server.js