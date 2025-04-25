# Zmienne konfiguracyjne
ORDERER_IMAGE="hyperledger/fabric-orderer"
CA_NAME="ord-ca.fabric"
NAMESPACE="fabric"
ENROLL_ID="orderer"
ENROLL_PW="ordererpw"
MSPID="OrdererMSP"
CAPACITY="2Gi"

# Pobranie numeru początkowego i końcowego
START=11
END=20

for ((i = START; i <= END; i++)); do
  NODE_NAME="ord-bft-node$i"
  echo "Tworzenie węzła orderera: $NODE_NAME"

  kubectl hlf ordnode create \
    --image=$ORDERER_IMAGE \
    --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS \
    --enroll-id=$ENROLL_ID \
    --mspid=$MSPID \
    --enroll-pw=$ENROLL_PW \
    --capacity=$CAPACITY \
    --name=$NODE_NAME \
    --ca-name=$CA_NAME \
    -n $NAMESPACE

  if [ $? -eq 0 ]; then
    echo "Węzeł $NODE_NAME został pomyślnie utworzony."
  else
    echo "Błąd podczas tworzenia węzła $NODE_NAME."
    exit 1
  fi
done
