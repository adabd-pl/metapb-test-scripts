export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=3.0.0

export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=3.0.0

export CA_IMAGE=hyperledger/fabric-ca
export CA_VERSION=1.5.13

export SC_NAME=local-path


#org 2 
kubectl hlf ca create  --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$SC_NAME --capacity=1Gi --name=org2-ca \
    --enroll-id=enroll --enroll-pw=enrollpw  -n fabric

kubectl hlf ca register --name=org2-ca --user=peer --secret=peerpw --type=peer \
 --enroll-id enroll --enroll-secret=enrollpw --mspid Org2MSP -n fabric

kubectl hlf peer create --statedb=leveldb --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$SC_NAME --enroll-id=peer --mspid=Org2MSP \
        --enroll-pw=peerpw --capacity=5Gi --name=org2-peer0 --ca-name=org2-ca.fabric -n fabric

#org 3 
kubectl hlf ca create  --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$SC_NAME --capacity=1Gi --name=org3-ca \
    --enroll-id=enroll --enroll-pw=enrollpw  -n fabric

kubectl hlf ca register --name=org3-ca --user=peer --secret=peerpw --type=peer \
 --enroll-id enroll --enroll-secret=enrollpw --mspid Org3MSP -n fabric

kubectl hlf peer create --statedb=leveldb --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$SC_NAME --enroll-id=peer --mspid=Org3MSP \
        --enroll-pw=peerpw --capacity=5Gi --name=org3-peer0 --ca-name=org3-ca.fabric -n fabric


#org 4
kubectl hlf ca create  --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$SC_NAME --capacity=1Gi --name=org4-ca \
    --enroll-id=enroll --enroll-pw=enrollpw  -n fabric

kubectl hlf ca register --name=org4-ca --user=peer --secret=peerpw --type=peer \
 --enroll-id enroll --enroll-secret=enrollpw --mspid Org4MSP -n fabric

kubectl hlf peer create --statedb=leveldb --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$SC_NAME --enroll-id=peer --mspid=Org4MSP \
        --enroll-pw=peerpw --capacity=5Gi --name=org4-peer0 --ca-name=org4-ca.fabric -n fabric


#org 4
kubectl hlf ca create  --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$SC_NAME --capacity=1Gi --name=org4-ca \
    --enroll-id=enroll --enroll-pw=enrollpw  -n fabric

kubectl hlf ca register --name=org4-ca --user=peer --secret=peerpw --type=peer \
 --enroll-id enroll --enroll-secret=enrollpw --mspid Org4MSP -n fabric

kubectl hlf peer create --statedb=leveldb --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$SC_NAME --enroll-id=peer --mspid=Org4MSP \
        --enroll-pw=peerpw --capacity=5Gi --name=org4-peer0 --ca-name=org4-ca.fabric -n fabric


## Create Channel

#org 2 rejestracja

kubectl hlf ca register --name=org2-ca --namespace=fabric --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org2MSP

# enroll
kubectl hlf identity create --name org2-admin --namespace fabric \
    --ca-name org2-ca --ca-namespace fabric \
    --ca ca --mspid Org2MSP --enroll-id admin --enroll-secret adminpw


# register
kubectl hlf ca register --name=org1-ca --namespace=default --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org1MSP

# enroll


# enroll
kubectl hlf identity create --name org1-admin --namespace default \
    --ca-name org1-ca --ca-namespace default \
    --ca ca --mspid Org1MSP --enroll-id admin --enroll-secret adminpw



#org 3 rejestracja

kubectl hlf ca register --name=org3-ca --namespace=fabric --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org3MSP

# enroll
kubectl hlf identity create --name org3-admin --namespace fabric \
    --ca-name org3-ca --ca-namespace fabric \
    --ca ca --mspid Org3MSP --enroll-id admin --enroll-secret adminpw


#org 4 rejestracja

kubectl hlf ca register --name=org4-ca --namespace=fabric --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org4MSP

# enroll
kubectl hlf identity create --name org4-admin --namespace fabric \
    --ca-name org4-ca --ca-namespace fabric \
    --ca ca --mspid Org4MSP --enroll-id admin --enroll-secret adminpw


