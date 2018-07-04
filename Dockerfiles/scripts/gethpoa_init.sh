#!/bin/bash

# $POA_SIGNER_ADDRESS is from docker-compose and has default in Dockerfile
# $GETH_DATA_DIR is from Dockerfile
# $WORK_DIR is from Dockerfile


HERE=$(pwd)

# $1 is template/gethpoa_genesis.json
# $2 is $POA_SIGNER_ADDRESS
function _modGenesis {
    sed -i "s%<POA_SIGNER_ADDRESS>%$2%g" $1

    # check if begins with 0x
    poa_signer_address_no0x=$2

    [[ "$poa_signer_address_no0x" == "0x"* ]] && \
    poa_signer_address_no0x=$(echo $poa_signer_address_no0x | sed "s%0x%%g")

    sed -i "s%<poa_signer_address_no0x>%$poa_signer_address_no0x%g" $1
}

# --------------------------------------------------------------------------------------------

# replace genesis file
cp gethpoa_genesis.json.tpl gethpoa_genesis.json
_modGenesis gethpoa_genesis.json $POA_SIGNER_ADDRESS
mv gethpoa_genesis.json $GETH_DATA_DIR/gethpoa_genesis.json
cd $HERE

# Run tmp geth container to geth init
geth \
--datadir $GETH_DATA_DIR \
init $GETH_DATA_DIR/gethpoa_genesis.json