#!/bin/bash

# Parametry
START_ORG=16 # Początkowy numer organizacji (np. org6-ca)
END_ORG=16   # Końcowy numer organizacji (np. org10-ca)
NAMESPACE="fabric"  # Namespace
NEW_IP="10.87.23.33"  # Nowy adres IP
ENROLL_ID="enroll"  # ID użytkownika do rejestracji
ENROLL_SECRET="enrollpw"  # Hasło użytkownika do rejestracji
PEER_USER="peer"  # Nazwa użytkownika peera
PEER_SECRET="peerpw"  # Hasło użytkownika peera

# Funkcja do oczekiwania na restart poda
wait_for_pod_restart() {
  local ca_name=$1
  local pod_name
  local timeout=300  
  local start_time=$(date +%s)

  echo "Oczekiwanie na pod związany z $ca_name..."

  while :; do
    pod_name=$(kubectl get pods -n $NAMESPACE -l app=hlf-ca,release=$ca_name -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -n "$pod_name" ]; then
      echo "Pod $pod_name został znaleziony."
      break
    fi

    local current_time=$(date +%s)
    if (( current_time - start_time > timeout )); then
      echo "Timeout: Nie znaleziono poda związanego z $ca_name w ciągu $timeout sekund."
      return 1
    fi

    sleep 5
  done

  echo "Oczekiwanie na restart poda $pod_name..."
  kubectl wait --for=condition=Ready pod/$pod_name -n $NAMESPACE --timeout=300s
  echo "Pod $pod_name został zrestartowany i jest w stanie Running."
}

for org in $(seq $START_ORG $END_ORG); do
  CA_NAME="org${org}-ca"  # Nazwa zasobu FabricCAS


kubectl hlf ca create  --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$SC_NAME --capacity=1Gi --name=$CA_NAME \
--enroll-id=enroll --enroll-pw=enrollpw   -n fabric
sleep 100
 echo "Przetwarzanie organizacji: $CA_NAME"

  echo "Zmieniam localhost na $NEW_IP w zasobie $CA_NAME..."

  if kubectl get fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE -o jsonpath='{.spec.ca.csr.hosts}' | grep -q "localhost"; then
    # Zmiana w spec.ca.csr.hosts
    kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
      --type=json \
      -p='[{"op": "replace", "path": "/spec/ca/csr/hosts/0", "value": "'$NEW_IP'"}]'
  else
    kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
      --type=json \
      -p='[{"op": "add", "path": "/spec/ca/csr/hosts", "value": ["'$NEW_IP'"]}]'
  fi

  # Zmiana w spec.hosts
  kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
    --type=json \
    -p='[{"op": "replace", "path": "/spec/hosts/0", "value": "'$NEW_IP'"}]'

  # Zmiana w spec.tlsCA.csr.hosts
  kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
    --type=json \
    -p='[{"op": "replace", "path": "/spec/tlsCA/csr/hosts/0", "value": "'$NEW_IP'"}]'

  # Krok 2: Czekaj na restart poda

  sleep 120

  kubectl hlf ca register --name=$CA_NAME --user=$PEER_USER --secret=$PEER_SECRET --type=peer \
    --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid Org${org}MSP -n $NAMESPACE


  # Krok 3: Dodaj localhost z powrotem, nie kasując adresu IP
  echo "Dodaję localhost z powrotem do zasobu $CA_NAME..."

  # Dodanie localhost w spec.ca.csr.hosts
  kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
    --type=json \
    -p='[{"op": "add", "path": "/spec/ca/csr/hosts/-", "value": "localhost"}]'

  # Dodanie localhost w spec.hosts
  kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
    --type=json \
    -p='[{"op": "add", "path": "/spec/hosts/-", "value": "localhost"}]'

  # Dodanie localhost w spec.tlsCA.csr.hosts
  kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
    --type=json \
    -p='[{"op": "add", "path": "/spec/tlsCA/csr/hosts/-", "value": "localhost"}]'

  sleep 120
  kubectl hlf ca register --name=$CA_NAME --user=$PEER_USER --secret=$PEER_SECRET --type=peer \
    --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid Org${org}MSP -n $NAMESPACE

  echo "Proces zakończony pomyślnie dla organizacji $CA_NAME!"
done

for org in $(seq $START_ORG $END_ORG); do
  CA_NAME="org${org}-ca"
  echo "Rejestracja dla: ${CA_NAME}"
 kubectl hlf ca register --name=$CA_NAME --user=$PEER_USER --secret=$PEER_SECRET --type=peer \
    --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid Org${org}MSP -n $NAMESPACE
done
echo "Wszystkie organizacje od org${START_ORG}-ca do org${END_ORG}-ca zostały przetworzone."