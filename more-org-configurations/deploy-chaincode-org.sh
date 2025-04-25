export ORG_NR="1"
export CHANNEL_NAME="demobft2org"
export CHAINCODE_LABEL="graph4"
export PACKAGE_ID=$(kubectl hlf chaincode calculatepackageid --path=chaincode.tgz --language=node --label=$CHAINCODE_LABEL)
echo "PACKAGE_ID=$PACKAGE_ID"

ORG_LIST=(1 2)
for ORG_NR in "${ORG_LIST[@]}"
do
    
# This identity will register and enroll the user
    kubectl hlf identity create --name org"$ORG_NR"-admin --namespace fabric \
        --ca-name org"$ORG_NR"-ca --ca-namespace fabric \
        --ca ca --mspid Org"$ORG_NR"MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
        --ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin


    kubectl hlf networkconfig create --name=org"$ORG_NR"-cp2-"$CHANNEL_NAME" \
    -o Org"$ORG_NR"MSP -o OrdererMSP -c $CHANNEL_NAME \
    --identities=org"$ORG_NR"-admin.fabric --secret=org"$ORG_NR"-cp2-"$CHANNEL_NAME" -n fabric
        
    kubectl get secret org${ORG_NR}-cp2-${CHANNEL_NAME} -n fabric -o jsonpath="{.data.config\.yaml}" | base64 --decode > org${ORG_NR}.yaml

    kubectl hlf chaincode install --path=./chaincode.tgz \
        --config=org"$ORG_NR".yaml --language=node --label=$CHAINCODE_LABEL --user=org"$ORG_NR"-admin-fabric --peer=org"$ORG_NR"-peer0.fabric

    kubectl hlf chaincode queryinstalled --config=org"$ORG_NR".yaml --user=org"$ORG_NR"-admin-fabric --peer=org"$ORG_NR"-peer0.fabric

    kubectl hlf externalchaincode sync --image=adabd/chaincode_graph:3.0 \
        --name=$CHAINCODE_NAME \
        --namespace=fabric \
        --package-id=$PACKAGE_ID \
        --tls-required=false \
        --replicas=1

    export SEQUENCE=1
    export VERSION="1.0"
    kubectl hlf chaincode approveformyorg --config=org"$ORG_NR".yaml --user=org"$ORG_NR"-admin-fabric --peer=org"$ORG_NR"-peer0.fabric \
        --package-id=$PACKAGE_ID \
        --version "$VERSION" --sequence "$SEQUENCE" --name=graph4bft \
        --policy="OR('Org${ORG_NR}MSP.member')" --channel="$CHANNEL_NAME"

    kubectl hlf chaincode commit --config=org"$ORG_NR".yaml --user=org"$ORG_NR"-admin-fabric --mspid=Org"$ORG_NR"MSP \
        --version "$VERSION" --sequence "$SEQUENCE" --name=graph4bft \
        --policy="OR('Org${ORG_NR}MSP.member')" --channel="$CHANNEL_NAME"
done