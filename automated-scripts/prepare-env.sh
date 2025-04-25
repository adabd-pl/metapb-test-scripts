#kubectl exec -i -t -n fabric ubuntu-cli -c ubuntu-container -- sh -c "(bash || ash || sh)"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=3.0.0
export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=3.0.0
export CA_IMAGE=hyperledger/fabric-ca
export CA_VERSION=1.5.13
export SC_NAME=local-path


