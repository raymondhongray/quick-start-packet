## Quick-Start-Packet ##
This packet introduce a simple way to provide services for the BOLT SDK developing/testing.

### Services ###
The Services including ```gringotts``` , ```postgres``` and ```gethpoa```.

#### gringotts ####
[gringotts](https://github.com/BOLT-Protocol/gringotts) provide transaction processing and data storage. Furthermore, it is designed to build Indexed Merkle Trees and distribute receipts for security purposes of BOLT protocol. 

This service expose port ```3000```. 

#### postgres ####
A postgresql database which db name as ```gringot``` ,user name as ```harry``` and password as ```potter```.  
This database is the storage for gringotts service.   

This service expose port ```5432```.

#### gethpoa ####
A ethereum geth node which using POA consensus to provide rapid generation rate of block.   
This node is under ```private chain``` for developing and testing purpose.

This service expose port ```8545```.

## How To Use ##

### Step 1 ###
Copy .env.example into .env ,then modify the variable which is ```required``` type in .env

### Step 2 ###
Start all services.
```
docker-compose up -d
```

### NOTE ###
There are two type of variable in .env

For the ```required``` variable, you ```must``` provide the proper value.

For the ```optional``` variable, you could leave it as blank and system will use the default value automatically.

No matter which type of variable , ```DO NOT``` use space between variable name and the equal symbol(```=```).   
Also ```NOT``` use space between variable value and the equal symbol(```=```).

```
# Correct
POA_SIGNER_PRI_KEY=1234

# Incorrect
POA_SIGNER_PRI_KEY =1234

# Incorrect
POA_SIGNER_PRI_KEY= 1234
```

The default value of ```optional``` variable:
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