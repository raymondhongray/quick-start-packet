## How to use ##

Copy .env.example into .env ,assign the value for variable in .env

#### NOTE ####
There two kind of variable in .env

For those which are ```required```, you ```must``` set the proper value.

For those which are ```optional```, you could leave it as blank and system will use the default value automatically.

The default value for ```optional``` variable as following:
```
# The private key of geth poa signer
POA_SIGNER_PRI_KEY=18c55c27f047f21ed3f42588c6ec0b2a50c77ceba223439ee9744bb86ed8fa5c

# The address of geth poa signer
POA_SIGNER_ADDRESS=0x50afb1b4c52c64daed49ab8c3aa82b0609b75db0

# The password of geth poa signer
POA_SIGNER_PWD=2wsx4rfv

# The time to generate the block in seconds
BLOCK_GENERATING_TIME=3
```