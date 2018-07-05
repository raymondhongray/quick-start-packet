## How to use ##

### Step 1 ###
Copy .env.example into .env ,provide the value for variable in .env

#### NOTE ####
There are two kind of variable in .env

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

### Step 2 ###
Start all services.
```
docker-compose up -d
```

#### NOTE ####
This command will start 3 service(3 docker container) which including:

#### gethpoa ####
A ```private``` ethereum geth node for developing and testing purpose.

#### postgres ####
A postgresql database which db name as ```gringot``` ,user as ```harry``` and password as ```potter```.
This database is the storage for gringotts service. 

#### gringotts ####
Gringotts provide transaction processing and data storage. Furthermore, it is designed to build Indexed Merkle Trees and distribute receipts for security purposes of BOLT protocol.