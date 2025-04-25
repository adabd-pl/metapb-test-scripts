#!/bin/bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=3.0.0
export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=3.0.0
export CA_IMAGE=hyperledger/fabric-ca
export CA_VERSION=1.5.13
export SC_NAME=local-path

# Konfiguracja
ORDERER_COUNT=20    # Liczba ordererów
ORG_COUNT=20         # Liczba organizacji
ORDERER_NUMS=($(seq 1 $ORDERER_COUNT))
ORG_NUMS=($(seq 1 $ORG_COUNT))
CHANNEL_NAME="demoraftorg${ORG_COUNT}ord${ORDERER_COUNT}"
NAMESPACE="fabric"
ORDERER_BASE_NAME="ord-bft-node"
ORDERER_IP="10.87.23.33"
IDENT_8=$(printf "%8s" "")
# Generate identities section
generate_identities_section() {
  # Static Orderer section
  cat <<EOS
    OrdererMSP:
      secretKey: user.yaml
      secretName: orderer-admin-tls
      secretNamespace: fabric
    OrdererMSP-sign:
      secretKey: user.yaml
      secretName: orderer-admin-sign
      secretNamespace: fabric
EOS
  
  # Dynamic Organizations section
  for org_num in "${ORG_NUMS[@]}"; do
    cat <<EOS
    Org${org_num}MSP:
      secretKey: user.yaml
      secretName: org${org_num}-admin
      secretNamespace: fabric
EOS
  done
}

# Get orderer ports and certificates
declare -A ORDERER_PORTS ORDERER_TLS_CERTS
for num in "${ORDERER_NUMS[@]}"; do
  svc_name="${ORDERER_BASE_NAME}${num}"
  ORDERER_PORTS[$num]=$(kubectl get svc "$svc_name" -n $NAMESPACE -o jsonpath='{.spec.ports[?(@.name=="grpc")].nodePort}')
  ORDERER_TLS_CERTS[$num]=$(kubectl get fabricorderernodes "${ORDERER_BASE_NAME}${num}" -n $NAMESPACE -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_8}/")
done

# Generate orderers section
ORDERERS_SECTION=$(
for num in "${ORDERER_NUMS[@]}"; do
  cat <<EOS
    - host: $ORDERER_IP
      port: ${ORDERER_PORTS[$num]}
      tlsCert: |-
${ORDERER_TLS_CERTS[$num]}
EOS
done
)

# Generate externalOrderersToJoin section
EXTERNAL_ORDERERS=$(
for num in "${ORDERER_NUMS[@]}"; do
  cat <<EOS
        - host: ${ORDERER_BASE_NAME}${num}.fabric
          port: 7053
EOS
done
)

# Generate ordererEndpoints section
ORDERER_ENDPOINTS=$(
for num in "${ORDERER_NUMS[@]}"; do
  echo "        - \"$ORDERER_IP:${ORDERER_PORTS[$num]}\""
done
)

# Generate peerOrganizations section
PEER_ORGS=$(
for org_num in "${ORG_NUMS[@]}"; do
  cat <<EOS
    - mspID: Org${org_num}MSP
      caName: "org${org_num}-ca"
      caNamespace: "fabric"
EOS
done
)

# Apply the channel configuration
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricMainChannel
metadata:
  name: $CHANNEL_NAME
spec:
  name: $CHANNEL_NAME
  adminOrdererOrganizations:
    - mspID: OrdererMSP
  adminPeerOrganizations:
    - mspID: Org1MSP
  channelConfig:
    application:
      capabilities:
        - V2_5
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
      etcdRaft:
        options:
          electionTick: 400  
          heartbeatTick: 60
          maxInflightBlocks: 100000
          snapshotIntervalSize: 16777216
          tickInterval: "50ms"
      ordererType: etcdraft
  peerOrganizations:
$PEER_ORGS
  identities:
$(generate_identities_section)
  externalOrdererOrganizations: []
  externalPeerOrganizations: []
  ordererOrganizations:
    - caName: "ord-ca"
      caNamespace: "fabric"
      mspID: OrdererMSP
      externalOrderersToJoin:
$EXTERNAL_ORDERERS
      orderersToJoin: []
      ordererEndpoints:
$ORDERER_ENDPOINTS
      signCACert: ""
      tlsCACert: ""
  orderers:
$ORDERERS_SECTION
EOF