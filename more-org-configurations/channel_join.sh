export CHANNEL_NAME="demobft2org"
export ORG_NR="1"


export IDENT_8=$(printf "%8s" "")
export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-bft-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_8}/" )

kubectl apply -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricFollowerChannel
metadata:
  name: ${CHANNEL_NAME}-org${ORG_NR}msp
spec:
  anchorPeers:
    - host: org${ORG_NR}-peer0.fabric
      port: 7051
  hlfIdentity:
    secretKey: user.yaml
    secretName: org${ORG_NR}-admin
    secretNamespace: fabric
  mspId: Org${ORG_NR}MSP
  name: ${CHANNEL_NAME}
  externalPeersToJoin: []
  orderers:
    - certificate: |
${ORDERER0_TLS_CERT}
      url: grpcs://ord-bft-node1.fabric:7050
  peersToJoin:
    - name: org${ORG_NR}-peer0
      namespace: fabric
EOF
