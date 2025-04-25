#!/bin/bash

# Parametry
ORG_COUNT=10
CHANNEL_NAME="demobft${ORG_COUNT}"  # Nazwa kanału (np. demobft)
NAMESPACE="fabric"
ORDERER_BASE_NAME="ord-bft-node"
ORDERER_IP="10.87.23.33"
IDENT_12=$(printf "%16s" "")

# Definicja organizacji
ORGS=($(seq 1 $ORG_COUNT))
# Pobierz certyfikat TLS orderera
export ORDERER0_TLS_CERT="$(kubectl get fabricorderernodes "${ORDERER_BASE_NAME}1" -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/")"

# Funkcja do tworzenia FabricFollowerChannel dla organizacji
create_follower_channel() {
  local org_number=$1
  local org_name="org${org_number}"
  local msp_id="Org${org_number}MSP"
  local peer_name="${org_name}-peer0"

  kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricFollowerChannel
metadata:
  name: ${CHANNEL_NAME}-${org_name}msp
spec:
  anchorPeers:
    - host: ${peer_name}.fabric
      port: 7051
  hlfIdentity:
    secretKey: user.yaml
    secretName: ${org_name}-admin
    secretNamespace: ${NAMESPACE}
  mspId: ${msp_id}
  name: ${CHANNEL_NAME}
  externalPeersToJoin: []
  orderers:
    - certificate: |
${ORDERER0_TLS_CERT}
      url: grpcs://${ORDERER_BASE_NAME}1.fabric:7050
  peersToJoin:
    - name: ${peer_name}
      namespace: ${NAMESPACE}
EOF
}

# Dodaj organizacje do kanału
for org in "${ORGS[@]}"; do
  echo "Dodawanie organizacji org${org} do kanału ${CHANNEL_NAME}..."
  create_follower_channel $org
done

echo "Wszystkie organizacje zostały dodane do kanału."
