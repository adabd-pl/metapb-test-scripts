
# Parametry
START_ORG=11  # Początkowy numer organizacji (np. org6-ca)
END_ORG=15  # Końcowy numer organizacji (np. org10-ca)
NAMESPACE="fabric"  # Namespace
ENROLL_ID="enroll"  # ID użytkownika do rejestracji
ENROLL_SECRET="enrollpw"  # Hasło użytkownika do rejestracji
PEER_USER="peer"  # Nazwa użytkownika peera
PEER_SECRET="peerpw"  # Hasło użytkownika peera

# Pętla przez organizacje od org6-ca do org10-ca
for org in $(seq $START_ORG $END_ORG); do
  CA_NAME="org${org}-ca"  # Nazwa zasobu FabricCAS
  MSPID="Org${org}MSP"  # MSP ID organizacji
  PEER_NAME="org${org}-peer0"  # Nazwa peera

  echo "Przetwarzanie organizacji: $CA_NAME"

  # Krok 1: Zarejestruj użytkownika peera
  echo "Rejestracja użytkownika peera dla organizacji $CA_NAME..."
  kubectl hlf ca register --name=$CA_NAME --user=$PEER_USER --secret=$PEER_SECRET --type=peer \
    --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid $MSPID -n $NAMESPACE

  # Krok 2: Utwórz peera
  echo "Tworzenie peera $PEER_NAME dla organizacji $CA_NAME..."
  kubectl hlf peer create --statedb=leveldb --image=$PEER_IMAGE --version=$PEER_VERSION \
    --storage-class=$SC_NAME --enroll-id=$PEER_USER --mspid=$MSPID --enroll-pw=$PEER_SECRET \
    --capacity=5Gi --name=$PEER_NAME --ca-name=$CA_NAME.$NAMESPACE -n $NAMESPACE

  echo "Proces zakończony pomyślnie dla organizacji $CA_NAME!"
done

echo "Wszystkie organizacje od org${START_ORG}-ca do org${END_ORG}-ca zostały przetworzone."