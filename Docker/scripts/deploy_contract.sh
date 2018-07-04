#!/bin/bash

# Deploy InfinitechainManager
tmpDeployFile=truffle-deploy.tmp
truffle console deploy --reset 2>/dev/stdout | tee $tmpDeployFile
ifcManagerAddress=$(cat $tmpDeployFile | grep InfinitechainManager: | sed "s%InfinitechainManager:%%g" | sed "s% %%g")
ifcManagerAddress=$(_cleanBadPattern $ifcManagerAddress)
rm $tmpDeployFile

# Deploy SideChain
sideChainAddress=$(./deploySideChain.sh "$ifcManagerAddress") 
[[ "$sideChainAddress" == "0x0000000000000000000000000000000000000000" ]] && echo "Sidechain deployment failed" && exit 256

sed -i "s%^$1=.*%$1=$2%g" gringotts.env.js.tpl
_replaceRuntimeVar SIDECHAIN_ADDRESS "$sideChainAddress"

_update-conf