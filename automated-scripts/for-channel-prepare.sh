NUM_ORGS=20
NUM_ORDERERS=20

# Zmienne konfiguracyjne
NAMESPACE="fabric"
CA_ADMIN_USER="admin"
CA_ADMIN_SECRET="adminpw"
ENROLL_ID="enroll"
ENROLL_SECRET="enrollpw"

    # Rejestracja i tworzenie tożsamości dla OrdererMSP
    ORDERER_NAME="ord-ca"
    echo "Rejestracja i tworzenie tożsamości dla OrdererMSP (${ORDERER_NAME})..."

    # Rejestracja tożsamości orderera
    kubectl hlf ca register --name=$ORDERER_NAME --user=$CA_ADMIN_USER --secret=$CA_ADMIN_SECRET  --namespace $NAMESPACE \
        --type=admin --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid=OrdererMSP

    # Tworzenie tożsamości do podpisywania (sign identity)
    kubectl hlf identity create --name orderer-admin-sign --namespace $NAMESPACE \
        --ca-name $ORDERER_NAME --ca-namespace $NAMESPACE \
        --ca ca --mspid OrdererMSP --enroll-id $CA_ADMIN_USER --enroll-secret $CA_ADMIN_SECRET

    # Tworzenie tożsamości TLS (tls identity)
    kubectl hlf identity create --name orderer-admin-tls --namespace $NAMESPACE \
        --ca-name $ORDERER_NAME --ca-namespace $NAMESPACE \
        --ca tlsca --mspid OrdererMSP --enroll-id $CA_ADMIN_USER --enroll-secret $CA_ADMIN_SECRET

    # Rejestracja i tworzenie tożsamości dla organizacji
    for ORG_NUM in $(seq 1 $NUM_ORGS); do
    ORG_NAME="org${ORG_NUM}"
    ORG_MSP="${ORG_NAME}MSP"
    ORG_CA_NAME="${ORG_NAME}-ca"

    echo "Rejestracja i tworzenie tożsamości dla ${ORG_MSP}..."

    # Rejestracja tożsamości organizacji
    kubectl hlf ca register --name=$ORG_CA_NAME --namespace=$NAMESPACE --user=$CA_ADMIN_USER --secret=$CA_ADMIN_SECRET \
        --type=admin --enroll-id $ENROLL_ID --enroll-secret=$ENROLL_SECRET --mspid=$ORG_MSP

    # Tworzenie tożsamości administratora organizacji
    kubectl hlf identity create --name ${ORG_NAME}-admin --namespace $NAMESPACE \
        --ca-name $ORG_CA_NAME --ca-namespace $NAMESPACE \
        --ca ca --mspid $ORG_MSP --enroll-id $CA_ADMIN_USER --enroll-secret $CA_ADMIN_SECRET
    done

echo "Proces rejestracji i tworzenia tożsamości zakończony."