#!/bin/bash


CA_NAME="ord-ca"       # Nazwa CA dla orderera
NAMESPACE="fabric"     # Namespace
NEW_IP="10.87.23.33"  # Nowy adres IP
ENROLL_ID="enroll"     # ID użytkownika do rejestracji
ENROLL_SECRET="enrollpw" # Hasło użytkownika do rejestracji
ORDERER_USER="orderer" # Nazwa użytkownika orderera
ORDERER_SECRET="ordererpw" # Hasło użytkownika orderera
MSPID="OrdererMSP"     # MSP ID dla orderera

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

echo "Tworzenie CA dla orderera..."
kubectl hlf ca create \
  --image=$CA_IMAGE \
  --version=$CA_VERSION \
  --storage-class=$SC_NAME \
  --capacity=1Gi \
  --name=$CA_NAME \
  --enroll-id=$ENROLL_ID \
  --enroll-pw=$ENROLL_SECRET \
  -n $NAMESPACE

sleep 100

echo "Aktualizacja konfiguracji dla $CA_NAME..."

# Aktualizacja spec.ca.csr.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "replace", "path": "/spec/ca/csr/hosts/0", "value": "'$NEW_IP'"}]'

# Aktualizacja spec.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "replace", "path": "/spec/hosts/0", "value": "'$NEW_IP'"}]'

# Aktualizacja spec.tlsCA.csr.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "replace", "path": "/spec/tlsCA/csr/hosts/0", "value": "'$NEW_IP'"}]'

wait_for_pod_restart $CA_NAME
sleep 120

echo "Rejestracja użytkownika orderera..."
kubectl hlf ca register \
  --name=$CA_NAME \
  --user=$ORDERER_USER \
  --secret=$ORDERER_SECRET \
  --type=orderer \
  --enroll-id $ENROLL_ID \
  --enroll-secret=$ENROLL_SECRET \
  --mspid $MSPID \
  -n $NAMESPACE

echo "Przywracanie localhost w konfiguracji..."

# Dodaj localhost do spec.ca.csr.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "add", "path": "/spec/ca/csr/hosts/-", "value": "localhost"}]'

# Dodaj localhost do spec.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "add", "path": "/spec/hosts/-", "value": "localhost"}]'

# Dodaj localhost do spec.tlsCA.csr.hosts
kubectl patch fabriccas.hlf.kungfusoftware.es $CA_NAME -n $NAMESPACE \
  --type=json \
  -p='[{"op": "add", "path": "/spec/tlsCA/csr/hosts/-", "value": "localhost"}]'

# Finalna aktualizacja
sleep 120
kubectl hlf ca register \
  --name=$CA_NAME \
  --user=$ORDERER_USER \
  --secret=$ORDERER_SECRET \
  --type=orderer \
  --enroll-id $ENROLL_ID \
  --enroll-secret=$ENROLL_SECRET \
  --mspid $MSPID \
  -n $NAMESPACE

echo "Proces zakończony pomyślnie dla $CA_NAME!"