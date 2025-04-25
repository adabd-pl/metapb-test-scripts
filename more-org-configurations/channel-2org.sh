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

export CHANNEL_NAME="demobft2org"

kubectl apply -n fabric -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricMainChannel
metadata:
  name: demobft2org
spec:
  name: demobft2org
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
    - mspID: Org2MSP
      caName: "org2-ca"
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
    Org2MSP:
      secretKey: user.yaml
      secretName: org2-admin
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
  name: demo-bft2-org1msp
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



kubectl apply -f - <<EOF
apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricFollowerChannel
metadata:
  name: demo-bft2-org2msp
spec:
  anchorPeers:
    - host: org2-peer0.fabric
      port: 7051
  hlfIdentity:
    secretKey: user.yaml
    secretName: org2-admin
    secretNamespace: fabric
  mspId: Org2MSP
  name: demobft
  externalPeersToJoin: []
  orderers:
    - certificate: |
${ORDERER0_TLS_CERT}
      url: grpcs://ord-bft-node1.fabric:7050
  peersToJoin:
    - name: org2-peer0
      namespace: fabric
EOF