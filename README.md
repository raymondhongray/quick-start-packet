## Quick-Start-Packet ##
This packet introduce a simple way to provide essential services for the BOLT SDK developing/testing.  
Support Mac OS X and ubuntu 16.04.

### Essential Services ###
The services include ```gringotts``` , ```postgres``` and ```gethpoa```.  
Each service run as an individual docker container.

#### gringotts ####
[gringotts](https://github.com/BOLT-Protocol/gringotts) provide transaction processing and data storage.  
Furthermore, it is designed to build Indexed Merkle Trees and distribute receipts for security purposes of BOLT protocol. 

Once the gringotts service is up ,
a built-in asset (```TWX```) will be deployed.  
User may get the address of ```TWX``` by checking ```twx.address``` under gringotts volume (the ```GRINGOTTS_HOST_DATA_VOL``` inside ```.env```)

This service expose port ```3000```. 

#### postgres ####
A postgresql database which ```gringot``` as db name ,```harry``` as user name and ```potter``` as password.  
This service provide the data storage for gringotts service.   

This service expose port ```5432```.

#### gethpoa ####
A ethereum geth node which using POA consensus to provide rapid block generation rate.   
This node has it's own genesis so it run as a ```private chain``` for developing and testing purpose.

This service expose port ```8545```.

## How To Use ##
This packet is dessigend to be as easy as posibble to use.  
Once you install the docker and docker-compose ,  
only two more step is required to build whole services.

### Step 1 ###
Install docker and docker-compose on your machine.

[Docker ToolBox for Mac OS](https://docs.docker.com/toolbox/toolbox_install_mac/)

[Docker for Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04)
and
[Docker Compose for Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04)

### Step 2 ###
Clone this project.  
Copy .env.example into .env ,then modify the variable which is ```required``` type in .env
```
git clone git@github.com:BOLT-Protocol/quick-start-packet.git 
cd quick-start-packet
cp .env.example .env
vim .env
```

### Step 3 ###
Start all services.
```
docker-compose up -d
```

### NOTE ###
There are two type of variable in .env

For the ```required``` variable, you ```must``` provide the proper value.

For the ```optional``` variable, you could leave it as blank and system will import the default setting automatically.

No matter which type of variable ,variable name ```DO NOT``` followd by space and the equal symbol(```=```).   
also ```NOT``` followed by variable value.

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
POA_SIGNER_PRI_KEY=22b8af6522a7cf410b54eb8be2969c2ee20d30e89a1a2dc5476a8cccc1be8592

# The address of geth poa signer
POA_SIGNER_ADDRESS=0x9644fb7d0108a6B7e52cab5171298969a427CaCD

# The password of geth poa signer
POA_SIGNER_PWD=123qwe456RTY
```