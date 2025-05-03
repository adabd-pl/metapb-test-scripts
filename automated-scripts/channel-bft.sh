#!/bin/bash

# Parametry
ORDERER_COUNT=1    # Liczba ordererów
ORG_COUNT=1         # Liczba organizacji
CHANNEL_NAME="demobft${ORG_COUNT}"
NAMESPACE="fabric"
ORDERER_BASE_NAME="ord-bft-node"
ORDERER_IP="10.87.23.33"
IDENT_12=$(printf "%16s" "")
IDENT_8=$(printf "%8s" "")


ORDERER_NUMS=($(seq 1 $ORDERER_COUNT))
ORG_NUMS=($(seq 1 $ORG_COUNT))

# Funkcja do pobierania portu z serwisu
get_orderer_port() {
  local node_number=$1
  kubectl get svc "${ORDERER_BASE_NAME}${node_number}" -n $NAMESPACE \
    -o jsonpath='{.spec.ports[?(@.name=="grpc")].nodePort}'
}

# Pobierz certyfikaty TLS i Sign dla ordererów
declare -i index=0
for orderer_num in "${ORDERER_NUMS[@]}"; do
  export ORDERER${index}_TLS_CERT="$(kubectl get fabricorderernodes "${ORDERER_BASE_NAME}${orderer_num}" -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/")"
  export ORDERER${index}_SIGN_CERT="$(kubectl get fabricorderernodes "${ORDERER_BASE_NAME}${orderer_num}" -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/")"
  index+=1
done

# Generowanie sekcji consenterMapping
# Generowanie sekcji consenterMapping (POPRAWIONE)
CONSENTER_MAPPING=$(
for orderer_num in "${ORDERER_NUMS[@]}"; do
  PORT=$(get_orderer_port $orderer_num)
  
  # Oblicz index na podstawie numeru orderera (BEZ 'local')
  index=$((orderer_num - 1))  # <--- TUTAJ BYŁ BŁĄD
  
  TLS_CERT_VAR="ORDERER${index}_TLS_CERT"
  SIGN_CERT_VAR="ORDERER${index}_SIGN_CERT"
  
  cat <<EOF
      - host: $ORDERER_IP
        port: $PORT
        id: $orderer_num
        msp_id: OrdererMSP
        client_tls_cert: |
${!TLS_CERT_VAR}
        server_tls_cert: |
${!TLS_CERT_VAR}
        identity: |
${!SIGN_CERT_VAR}
EOF
done
)

# Generowanie sekcji ordererEndpoints
ORDERER_ENDPOINTS=$(
for orderer_num in "${ORDERER_NUMS[@]}"; do
  PORT=$(get_orderer_port $orderer_num)
  echo "        - $ORDERER_IP:$PORT"
done
)

# Generowanie sekcji orderers
ORDERERS=$(
declare -i index=0
for orderer_num in "${ORDERER_NUMS[@]}"; do
  PORT=$(get_orderer_port $orderer_num)
  TLS_CERT_VAR="ORDERER${index}_TLS_CERT"
  cat <<EOF
    - host: $ORDERER_IP
      port: $PORT
      tlsCert: |
${!TLS_CERT_VAR}
EOF
  index+=1
done
)

# Generowanie sekcji peerOrganizations
PEER_ORGS=$(
for org_num in "${ORG_NUMS[@]}"; do
  cat <<EOF
    - mspID: Org${org_num}MSP
      caName: "org${org_num}-ca"
      caNamespace: "fabric"
EOF
done
)

# Generowanie sekcji identities
IDENTITIES=$(
for org_num in "${ORG_NUMS[@]}"; do
  cat <<EOF
    Org${org_num}MSP:
      secretKey: user.yaml
      secretName: org${org_num}-admin
      secretNamespace: fabric
EOF
done
)

# Zastosuj konfigurację FabricMainChannel
kubectl apply --server-side=true --force-conflicts -n fabric -f - <<EOF
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
$CONSENTER_MAPPING
      ordererType: BFT
      policies: null
      state: STATE_NORMAL
    policies: null
  externalOrdererOrganizations: []
  peerOrganizations:
$PEER_ORGS
  identities:
    OrdererMSP:
      secretKey: user.yaml
      secretName: orderer-admin-tls
      secretNamespace: fabric
    OrdererMSP-sign:
      secretKey: user.yaml
      secretName: orderer-admin-sign
      secretNamespace: fabric
$IDENTITIES
  externalPeerOrganizations: []
  ordererOrganizations:
    - caName: "ord-ca"
      caNamespace: "fabric"
      externalOrderersToJoin:
$(for orderer_num in "${ORDERER_NUMS[@]}"; do
  echo "        - host: ${ORDERER_BASE_NAME}${orderer_num}.fabric"
  echo "          port: 7053"
done)
      mspID: OrdererMSP
      ordererEndpoints:
$ORDERER_ENDPOINTS
      orderersToJoin: []
      signCACert: ''
      tlsCACert: ''
  orderers:
$ORDERERS
EOF


