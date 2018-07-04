#!/bin/bash

[ ! -f .env ] && cp .env.example .env
source .env

# https://github.com/ethereum/go-ethereum/wiki/Managing-your-accounts
# docker run -it to import key to create address
# For ethereum/client-go images with "alltools" tag ,the "geth" need to call
# ---------------------------------------------------------------------------
# Do not use --dev when under POA mode
# ---------------------------------------------------------------------------
# Do not quote the $NETWORKID_FLAG ,
# it results in unknown error(generate some strange behavior)

# 
[ ! -f "$GETH_HOST_DATA_VOL"/poa_signer.raw_prikey ] && touch "$GETH_HOST_DATA_VOL"/poa_signer.raw_prikey
echo $POA_SIGNER_PRI_KEY > "$GETH_HOST_DATA_VOL"/poa_signer.raw_prikey
[ ! -f "$GETH_HOST_DATA_VOL"/poa_signer.pwd ] && touch "$GETH_HOST_DATA_VOL"/poa_signer.pwd
echo $POA_SIGNER_PWD > "$GETH_HOST_DATA_VOL"/poa_signer.pwd

# Run tmp geth container to import private key
docker run --name geth_tmp \
-v "$GETH_HOST_DATA_VOL":/gethdata \
$GETH_IMAGE:$GETH_IMAGE_TAG \
geth \
--datadir /gethdata \
--password /gethdata/poa_signer.pwd \
account import /gethdata/poa_signer.raw_prikey > /dev/null 2>&1

# stop/rm container only after the status=exited
while :
do
    ids=$(docker ps -f "name=geth_tmp" -f "status=exited" -aq)
    if [ "$ids" != "" ]; then
        docker stop $(docker ps -f "name=geth_tmp" -aq) > /dev/null 2>&1
        docker rm $(docker ps -f "name=geth_tmp" -aq) > /dev/null 2>&1
        break
    fi
done