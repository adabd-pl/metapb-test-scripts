# dedykowane orderer nodey dla demobft

export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=3.0.0

export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=3.0.0

export CA_IMAGE=hyperledger/fabric-ca
export CA_VERSION=1.5.7
export STORAGE_CLASS=local-path

kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=orderer --mspid=OrdererMSP \
    --enroll-pw=ordererpw --capacity=2Gi --name=ord-bft-node1 --ca-name=ord-ca.fabric \
   -n fabric

kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=orderer --mspid=OrdererMSP \
    --enroll-pw=ordererpw --capacity=2Gi --name=ord-bft-node2 --ca-name=ord-ca.fabric \
   -n fabric
kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=orderer --mspid=OrdererMSP \
    --enroll-pw=ordererpw --capacity=2Gi --name=ord-bft-node3 --ca-name=ord-ca.fabric \
   -n fabric

kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=orderer --mspid=OrdererMSP \
    --enroll-pw=ordererpw --capacity=2Gi --name=ord-bft-node4 --ca-name=ord-ca.fabric \
   -n fabric
# 3/4

kubectl wait --timeout=180s --for=condition=Running fabricorderernodes.hlf.kungfusoftware.es --all


# register
kubectl hlf ca register --name=ord-ca --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=OrdererMSP


kubectl hlf identity create --name orderer-admin-sign --namespace fabric \
    --ca-name ord-ca --ca-namespace fabric \
    --ca ca --mspid OrdererMSP --enroll-id admin --enroll-secret adminpw # sign identity

kubectl hlf identity create --name orderer-admin-tls --namespace fabric \
    --ca-name ord-ca --ca-namespace fabric \
    --ca tlsca --mspid OrdererMSP --enroll-id admin --enroll-secret adminpw # tls identity


# register
kubectl hlf ca register --name=org1-ca --namespace=fabric --user=admin --secret=adminpw \
    --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org1MSP

# enroll
kubectl hlf identity create --name org1-admin --namespace fabric \
    --ca-name org1-ca --ca-namespace fabric \
    --ca ca --mspid Org1MSP --enroll-id admin --enroll-secret adminpw


export IDENT_12=$(printf "%16s" "")
# tls CA certificate
export ORDERER_TLS_CERT=$(kubectl get fabriccas ord-ca -o=jsonpath='{.status.tlsca_cert}' | sed -e "s/^/${IDENT_12}/" )

export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER1_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node2 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER2_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node3 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER3_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node4 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )

export ORDERER0_SIGN_CERT=$(kubectl get fabricorderernodes ord-bft-node1 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER1_SIGN_CERT=$(kubectl get fabricorderernodes ord-bft-node2 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER2_SIGN_CERT=$(kubectl get fabricorderernodes ord-bft-node3 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER3_SIGN_CERT=$(kubectl get fabricorderernodes ord-bft-node4 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )

kubectl apply -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricMainChannel
metadata:
  name: demobft
spec:
  name: demobft
  adminOrdererOrganizations:
    - mspID: OrdererMSP
  adminPeerOrganizations:
    - mspID: Org1MSP
  channelConfig:
    application:
      acls: null
      capabilities:
        - V2_5
      policies: null
    capabilities:
      - V3_0
    orderer:
      batchSize:
        absoluteMaxBytes: 1048576
        maxMessageCount: 100
        preferredMaxBytes: 524288
      batchTimeout: 2s
      capabilities:
        - V2_0
      smartBFT:
        request_batch_max_count: 100
        request_batch_max_bytes: 10485760
        request_batch_max_interval: "50ms"
        incoming_message_buffer_size: 200
        request_pool_size: 100000
        request_forward_timeout: "2s"
        request_complain_timeout: "20s"
        request_auto_remove_timeout: "3m"
        view_change_resend_interval: "5s"
        view_change_timeout: "20s"
        leader_heartbeat_timeout: "1m0s"
        leader_heartbeat_count: 10
        collect_timeout: "1s"
        sync_on_start: true
        speed_up_view_change: false
        leader_rotation: null
        decisions_per_leader: 3
        request_max_bytes: 0
      consenterMapping:
      - host: 10.87.23.33
        port: 31200
        id: 1
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER0_TLS_CERT}
        server_tls_cert: |
${ORDERER0_TLS_CERT}
        identity: |
${ORDERER0_SIGN_CERT}
      - host: 10.87.23.33
        port: 31248
        id: 2
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER1_TLS_CERT}
        server_tls_cert: |
${ORDERER1_TLS_CERT}
        identity: |
${ORDERER1_SIGN_CERT}
      - host: 10.87.23.33
        port: 31861
        id: 3
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER2_TLS_CERT}
        server_tls_cert: |
${ORDERER2_TLS_CERT}
        identity: |
${ORDERER2_SIGN_CERT}
      - host: 10.87.23.33
        port: 31580
        id: 4
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER3_TLS_CERT}
        server_tls_cert: |
${ORDERER3_TLS_CERT}
        identity: |
${ORDERER3_SIGN_CERT}
      ordererType: BFT
      policies: null
      state: STATE_NORMAL
    policies: null
  externalOrdererOrganizations: []
  peerOrganizations:
    - mspID: Org1MSP
      caName: "org1-ca"
      caNamespace: "fabric"
  identities:
    OrdererMSP:
      secretKey: user.yaml
      secretName: orderer-admin-tls
      secretNamespace: fabric
    OrdererMSP-sign:
      secretKey: user.yaml
      secretName: orderer-admin-sign
      secretNamespace: fabric
    Org1MSP:
      secretKey: user.yaml
      secretName: org1-admin
      secretNamespace: fabric
  externalPeerOrganizations: []
  ordererOrganizations:
    - caName: "ord-ca"
      caNamespace: "fabric"
      externalOrderersToJoin:
        - host: ord-bft-node1.fabric
          port: 7053
        - host: ord-bft-node2.fabric
          port: 7053
        - host: ord-bft-node3.fabric
          port: 7053
        - host: ord-bft-node4.fabric
          port: 7053
      mspID: OrdererMSP
      ordererEndpoints:
        - 10.87.23.33:31200
        - 10.87.23.33:31248
        - 10.87.23.33:31861
        - 10.87.23.33:31580
      orderersToJoin: []
  orderers:
    - host: 10.87.23.33
      port: 31200
      tlsCert: |-
${ORDERER0_TLS_CERT}
    - host: 10.87.23.33
      port: 31248
      tlsCert: |-
${ORDERER1_TLS_CERT}
    - host: 10.87.23.33
      port: 31861
      tlsCert: |-
${ORDERER2_TLS_CERT}
    - host: 10.87.23.33
      port: 31580
      tlsCert: |-
${ORDERER3_TLS_CERT}

EOF




export IDENT_8=$(printf "%8s" "")
export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_8}/" )

kubectl apply -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricFollowerChannel
metadata:
  name: demo-bft-org1msp
spec:
  anchorPeers:
    - host: org1-peer0.fabric
      port: 7051
  hlfIdentity:
    secretKey: user.yaml
    secretName: org1-admin
    secretNamespace: fabric
  mspId: Org1MSP
  name: demobft
  externalPeersToJoin: []
  orderers:
    - certificate: |
${ORDERER0_TLS_CERT}
      url: grpcs://ord-bft-node1.fabric:7050
  peersToJoin:
    - name: org1-peer0
      namespace: fabric
EOF

kubectl hlf networkconfig create --name=org1-cp-bft \
  -o Org1MSP -o OrdererMSP -c demobft \
  --identities=org1-admin.fabric --secret=org1-cp-bft

kubectl get secret org1-cp-bft -o jsonpath="{.data.config\.yaml}" | base64 --decode > org1-bft.yaml

# remove the code.tar.gz chaincode.tgz if they exist
rm code.tar.gz chaincode.tgz
export CHAINCODE_NAME=graph4bft
export CHAINCODE_LABEL=graph4bft
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
    --config=org1-bft.yaml --language=golang --label=$CHAINCODE_LABEL --user=org1-admin-fabric --peer=org1-peer0.fabric

kubectl hlf chaincode queryinstalled --config=org1-bft.yaml --user=org1-admin-fabric --peer=org1-peer0.fabric


kubectl hlf externalchaincode sync --image=adabd/chaincode_graph:3.0 \
    --name=$CHAINCODE_NAME \
    --namespace=fabric \
    --package-id=$PACKAGE_ID \
    --tls-required=false \
    --replicas=1

export SEQUENCE=1
export VERSION="1.0"
kubectl hlf chaincode approveformyorg --config=org1-bft.yaml --user=org1-admin-fabric --peer=org1-peer0.fabric \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=graph4bft \
    --policy="OR('Org1MSP.member')" --channel=demobft



kubectl hlf chaincode commit --config=org1-bft.yaml --user=org1-admin-fabric --mspid=Org1MSP \
    --version "$VERSION" --sequence "$SEQUENCE" --name=graph4bft \
    --policy="OR('Org1MSP.member')" --channel=demobft