NAMESPACE="fabric"
ORDERER_BASE_NAME="ord-bft-node"
ORDERER_IP="10.87.23.33"
NUM_ORDERERS=10
ORG_NUMS=(1 2 3 4 5 6 7 8 9 10)           # Tablica z numerami organizacji
NUM_ORGS=${#ORG_NUMS[@]}
CHANNEL_NAME="demobftorg10ord10"



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

 
  kubectl hlf ca enroll --name=$CA_NAME  --user=admin --secret=adminpw --mspid $ORG_MSP \
        --ca-name ca  --output peer-org${org}.yaml  -n $NAMESPACE

  kubectl hlf utils adduser --userPath=peer-org${org}.yaml --config=org${org}.yaml --username=admin --mspid=$ORG_MSP

  change_default_channel_name "org${org}.yaml" "$CHANNEL_NAME"
 # fix_channels $org
done
