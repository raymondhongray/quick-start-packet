#!/bin/bash

source .env.default

# $POA_SIGNER_PRI_KEY is from docker-compose at container running time ,not iamge building time 
# $POA_SIGNER_ADDRESS is from docker-compose at container running time ,not iamge building time 
# $POA_SIGNER_PWD is from docker-compose at container running time ,not iamge building time 
# $GETH_DATA_DIR is from Dockerfile
# $WORK_DIR is from Dockerfile
[[ "$POA_SIGNER_PRI_KEY" == "" ]] && POA_SIGNER_PRI_KEY=$DEFAULT_POA_SIGNER_PRI_KEY
[[ "$POA_SIGNER_ADDRESS" == "" ]] && POA_SIGNER_ADDRESS=$DEFAULT_POA_SIGNER_ADDRESS
[[ "$POA_SIGNER_PWD" == "" ]] && POA_SIGNER_PWD=$DEFAULT_POA_SIGNER_PWD
[[ "$BLOCK_GENERATING_TIME" == "" ]] && BLOCK_GENERATING_TIME=$DEFAULT_BLOCK_GENERATING_TIME

POA_SIGNER_PRIKEY_FILE=$GETH_DATA_DIR/poa_signer.raw_prikey
POA_SIGNER_PWD_FILE=$GETH_DATA_DIR/poa_signer.pwd


# $1 is gethpoa.genesis.json
# $2 is $POA_SIGNER_ADDRESS
# $3 is $BLOCK_GENERATING_TIME
function _modGenesis {
    sed -i "s%<POA_SIGNER_ADDRESS>%$2%g" $1
    sed -i "s%<BLOCK_GENERATING_TIME>%$3%g" $1

    # check if begins with 0x
    POA_SIGNER_ADDRESS_no0x=$2
    [[ "$POA_SIGNER_ADDRESS_no0x" == "0x"* ]] && \
    POA_SIGNER_ADDRESS_no0x=$(echo $POA_SIGNER_ADDRESS_no0x | sed "s%0x%%g")
    sed -i "s%<POA_SIGNER_ADDRESS_NO0x>%$POA_SIGNER_ADDRESS_no0x%g" $1
}


# echo 0 if not modified
# echo 1 if modified
function _isSignerModified {
    [ ! -f "$POA_SIGNER_PRIKEY_FILE" -o ! -f "$POA_SIGNER_PWD_FILE" ] && \
    echo 1 && return

    STORED_POA_SIGNER_PRIKEY=$(cat $POA_SIGNER_PRIKEY_FILE) && \
    STORED_POA_SIGNER_PWD=$(cat $POA_SIGNER_PWD_FILE)

    [ "$STORED_POA_SIGNER_PRIKEY" == "" -o "$STORED_POA_SIGNER_PWD" == "" ] && \
    echo 1 && return

    [ "$STORED_POA_SIGNER_PRIKEY" != "$POA_SIGNER_PRI_KEY" ] && \
    echo 1 && return
    
    [ "$STORED_POA_SIGNER_PWD" != "$POA_SIGNER_PWD" ] && \
    echo 1 && return

    echo 0
}

function _initGeth {
    rm -rfv $GETH_DATA_DIR/*

    # Modify genesis file
    cp gethpoa.genesis.json.tpl gethpoa.genesis.json
    _modGenesis gethpoa.genesis.json $POA_SIGNER_ADDRESS $BLOCK_GENERATING_TIME
    mv gethpoa.genesis.json $GETH_DATA_DIR/gethpoa.genesis.json

    # Run geth init
    geth \
    --datadir $GETH_DATA_DIR \
    init $GETH_DATA_DIR/gethpoa.genesis.json

    echo $POA_SIGNER_PRI_KEY > $POA_SIGNER_PRIKEY_FILE
    echo $POA_SIGNER_PWD > $POA_SIGNER_PWD_FILE

    # Run geth import private key
    geth \
    --datadir $GETH_DATA_DIR \
    --password $POA_SIGNER_PWD_FILE \
    account import $POA_SIGNER_PRIKEY_FILE #/dev/null 2>&1
}

isModified=$(_isSignerModified);
if [[ "$isModified" == "1" ]]; then 
    _initGeth
else
    echo "geth init with the same address, pass init process."
fi

# Start geth
geth \
--maxpeers 25 --cache=2048 \
--rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 \
--rpcapi "db,eth,net,web3,personal" \
--port 30303 --rpcport 8545 \
--datadir $GETH_DATA_DIR \
--unlock "$POA_SIGNER_ADDRESS" \
--etherbase "$POA_SIGNER_ADDRESS" \
--password $POA_SIGNER_PWD_FILE \
--mine