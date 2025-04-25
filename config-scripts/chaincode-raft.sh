kubectl hlf networkconfig create --name=org1-cp-bft \
  -o Org1MSP -o OrdererMSP -c demo \
  --identities=org1-admin.fabric --secret=org1-cp-bft

kubectl get secret org1-cp-bft -o jsonpath="{.data.config\.yaml}" | base64 --decode > org1-bft.yaml

# remove the code.tar.gz chaincode.tgz if they exist
rm code.tar.gz chaincode.tgz
export CHAINCODE_NAME=graph4
export CHAINCODE_LABEL=graph4
cat << METADATA-EOF > "metadata.json"
{
    "type": "ccaas",
    "label": "${CHAINCODE_LABEL}"
}
METADATA-EOF

cat > "connection.json" <<CONN_EOF
{
  "address": "${CHAINCODE_NAME}:7052",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF

tar cfz code.tar.gz connection.json
tar cfz chaincode.tgz metadata.json code.tar.gz
export PACKAGE_ID=$(kubectl hlf chaincode calculatepackageid --path=chaincode.tgz --language=node --label=$CHAINCODE_LABEL)
echo "PACKAGE_ID=$PACKAGE_ID"

kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=org1-bft.yaml --language=golang --label=$CHAINCODE_LABEL --user=admin --peer=org1-peer0.fabric

kubectl hlf chaincode queryinstalled --config=org1-bft.yaml --user=admin --peer=org1-peer0.fabric


kubectl hlf externalchaincode sync --image=adabd/chaincode_graph:3.0 \
    --name=$CHAINCODE_NAME \
    --namespace=fabric \
    --package-id=$PACKAGE_ID \
    --tls-required=false \
    --replicas=1

export SEQUENCE=1
export VERSION="1.0"
kubectl hlf chaincode approveformyorg --config=org1.yaml --user=admin --peer=org1-peer0.fabric \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=graph4 \
    --policy="OR('Org1MSP.member')" --channel=demoraft



kubectl hlf chaincode commit --config=org1.yaml --user=admin --mspid=Org1MSP \
    --version "$VERSION" --sequence "$SEQUENCE" --name=graph4 \
    --policy="OR('Org1MSP.member')" --channel=demoraft