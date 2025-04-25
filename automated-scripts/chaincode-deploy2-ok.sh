#!/bin/bash
#kubectl exec -i -t -n fabric ubuntu-cli -c ubuntu-container -- sh -c "(bash || ash || sh)"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=3.0.0
export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=3.0.0
export CA_IMAGE=hyperledger/fabric-ca
export CA_VERSION=1.5.13
export SC_NAME=local-path

# Zmienne konfiguracyjne
NAMESPACE="fabric"
ORDERER_BASE_NAME="ord-bft-node"
ORDERER_IP="10.87.23.33"
NUM_ORDERERS=10
ORG_NUMS=($(seq 1 $NUM_ORDERERS))            # Tablica z numerami organizacji
NUM_ORGS=${#ORG_NUMS[@]}      # Automatyczne obliczenie liczby organizacji
CHAINCODE_NAME="graph5o10"
CHAINCODE_LABEL="graph5o10"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE=1
CHANNEL_NAME="demobft${NUM_ORDERERS}"
CHAINCODE_IMAGE="adabd/chaincode_graph:5.0"
TLS_REQUIRED="false"
REPLICAS=1
REQUIRED_SIGNATURES=$(( (NUM_ORGS / 2) + 1 ))

# Generuj listę MSP organizacji
ORGS=()
for org in "${ORG_NUMS[@]}"; do
    ORGS+=("Org${org}MSP")
done

# Generuj politykę Endorsement w formacie Hyperledger Fabric
generate_endorsement_policy() {
    local REQUIRED=$1
    shift
    local ORGS=("$@")
    
    POLICY="OR("
    local first=true
    for org in "${ORGS[@]}"; do
        if [ "$first" = false ]; then
            POLICY+=", "
        fi
        POLICY+="'$org.member'"
        first=false
    done
    POLICY+=")"
    
    echo "$POLICY"
}
# Wygeneruj finalną politykę
ENDORSEMENT_POLICY=$(generate_endorsement_policy $REQUIRED_SIGNATURES "${ORGS[@]}")
echo "Wygenerowana polityka endorsmentu: $ENDORSEMENT_POLICY"


change_default_channel_name() {
    local config_file=$1
    local new_channel_name=$2
    
    # Sprawdź czy plik istnieje
    if [ ! -f "$config_file" ]; then
        echo "Błąd: Plik $config_file nie istnieje"
        return 1
    fi
    
    # Zmień nazwę kanału _default na nową nazwę
    sed -i "s/^\( *\)_default:/\1$new_channel_name:/" "$config_file"
    sed -i "s/\( *\)name: _default/\1name: $new_channel_name/" "$config_file"
    
    echo "Zmieniono nazwę kanału _default na $new_channel_name w pliku $config_file"
}
# Inspekcja konfiguracji dla każdej organizacji
# for org in "${ORG_NUMS[@]}"; do
#   ORG_MSP="Org${org}MSP"
#   echo "Inspekcja konfiguracji dla $ORG_MSP..."
#   kubectl hlf inspect --output org${org}.yaml -o $ORG_MSP -o OrdererMSP
# done

fix_channels() {
  local ORG=$1
  local CONFIG_FILE="org${ORG}.yaml"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Plik $CONFIG_FILE nie istnieje. Pomijanie..."
    return
  fi

  echo "Korygowanie sekcji channels w pliku $CONFIG_FILE..."

  # 1. Usuń CAŁĄ starą sekcję channels (w tym peers: {})
  sed -i '/^ *channels:/,/^ *[^ ]/d' "$CONFIG_FILE"

  # 2. Dodaj nową sekcję channels z prawidłową strukturą
  {
    echo "channels:"
    echo "  $CHANNEL_NAME:"
    echo "    orderers:"
    for ORDERER_NUM in $(seq 1 $NUM_ORDERERS); do
      echo "      - ord-bft-node${ORDERER_NUM}.fabric"
    done
    echo "    peers:"
    # Użyj wcześniej zdefiniowanej tablicy ORG_NUMS
    for org in "${ORG_NUMS[@]}"; do
      echo "      org${org}-peer0.fabric:"
      echo "        discover: true"
      echo "        endorsingPeer: true"
      echo "        chaincodeQuery: true"
      echo "        ledgerQuery: true"
      echo "        eventSource: true"
    done
  } >> "$CONFIG_FILE"

  echo "Sekcja channels w pliku $CONFIG_FILE została naprawiona."
}

# Rejestracja użytkownika w urzędzie certyfikacji
for org in "${ORG_NUMS[@]}"; do
  ORG_MSP="Org${org}MSP"
  CA_NAME="org${org}-ca"

  kubectl hlf inspect --output org${org}.yaml -o $ORG_MSP -o OrdererMSP

  kubectl hlf ca register --name=$CA_NAME --user=admin --secret=adminpw --type=admin \
 --enroll-id enroll --enroll-secret=enrollpw --mspid $ORG_MSP -n $NAMESPACE

  kubectl hlf ca enroll --name=$CA_NAME  --user=admin --secret=adminpw --mspid $ORG_MSP \
        --ca-name ca  --output peer-org${org}.yaml  -n $NAMESPACE

  kubectl hlf utils adduser --userPath=peer-org${org}.yaml --config=org${org}.yaml --username=admin --mspid=$ORG_MSP

  change_default_channel_name "org${org}.yaml" "$CHANNEL_NAME"
done

# Przygotowanie plików metadanych i połączenia dla chaincode
echo "Przygotowanie plików metadanych i połączenia dla chaincode..."
rm -f code.tar.gz chaincode.tgz
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
  "tls_required": ${TLS_REQUIRED}
}
CONN_EOF

tar cfz code.tar.gz connection.json
tar cfz chaincode.tgz metadata.json code.tar.gz

export PACKAGE_ID=$(kubectl hlf chaincode calculatepackageid --path=chaincode.tgz --language=node --label=$CHAINCODE_LABEL)
echo "PACKAGE_ID=$PACKAGE_ID"

# Instalacja chaincode
for org in "${ORG_NUMS[@]}"; do
  ORG_MSP="Org${org}MSP"
  ADMIN_NAME="admin"
  NETWORK_CONFIG_FILE="org${org}.yaml"

  echo "Instalowanie chaincode na org${org}-peer0..."
  kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=$NETWORK_CONFIG_FILE --language=node --label=$CHAINCODE_LABEL \
    --user=$ADMIN_NAME --peer=org${org}-peer0.$NAMESPACE
done

sleep 30

# Wdrożenie kontenera chaincode
kubectl hlf externalchaincode sync --image=$CHAINCODE_IMAGE \
  --name=$CHAINCODE_NAME \
  --namespace=$NAMESPACE \
  --package-id=$PACKAGE_ID \
  --tls-required=$TLS_REQUIRED \
  --replicas=$REPLICAS

# Zatwierdzanie chaincode
for org in "${ORG_NUMS[@]}"; do
  ORG_MSP="Org${org}MSP"
  ADMIN_NAME="admin"
  NETWORK_CONFIG_FILE="org${org}.yaml"
  
  echo "======================================"
  echo "Przetwarzanie organizacji $ORG_MSP..."
  
  OUTPUT=$(kubectl hlf chaincode approveformyorg --config=$NETWORK_CONFIG_FILE \
    --user=$ADMIN_NAME --peer=org${org}-peer0.$NAMESPACE \
    --package-id=$PACKAGE_ID \
    --version "$CHAINCODE_VERSION" --sequence "$CHAINCODE_SEQUENCE" \
    --name=$CHAINCODE_NAME --policy="$ENDORSEMENT_POLICY" --channel=$CHANNEL_NAME 2>&1)
  
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    echo "SUKCES: Zatwierdzono dla $ORG_MSP"
  else
    if [[ $OUTPUT == *"attempted to redefine uncommitted sequence"* ]]; then
      echo "OSTRZEŻENIE: $ORG_MSP już zatwierdziła tę wersję chaincode - pomijam"
    else
      echo "BŁĄD: Nieudana próba zatwierdzenia dla $ORG_MSP:"
      echo "$OUTPUT"
    fi
  fi

  echo "Przechodzę do następnej organizacji..."
  sleep 2  # Krótka przerwa między organizacjami
done
# Finalne zatwierdzenie
kubectl hlf chaincode commit --config=org1.yaml --user=admin --mspid=Org1MSP \
  --version "$CHAINCODE_VERSION" --sequence "$CHAINCODE_SEQUENCE" --name=$CHAINCODE_NAME \
  --policy="$ENDORSEMENT_POLICY"  --channel=$CHANNEL_NAME

echo "WDRAŻANIE ZAKOŃCZONE POMYŚLNIE!"


