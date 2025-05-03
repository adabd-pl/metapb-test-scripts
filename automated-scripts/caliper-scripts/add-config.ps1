<#
.SYNOPSIS
    Generuje konfigurację Calipera dla Hyperledger Fabric
.DESCRIPTION
    Skrypt tworzy plik caliper-config.yaml, pobierając:
    - Certyfikaty i klucze z sekretów Kubernetes (orgX-admin)
    - Pliki konfiguracyjne orgX.yaml z poda ubuntu-cli
#>

# Konfiguracja
$CHANNEL_NAME = "demobft5"  # Nazwa kanału
$ORGS_COUNT = 5                  # Liczba organizacji
$NAMESPACE = "fabric"             # Namespace
$SOURCE_POD = "ubuntu-cli"        # Nazwa poda źródłowego
$SOURCE_PATH = "."  # Ścieżka do plików orgX.yaml w podzie
$OUTPUT_DIR = "..\..\caliper-benchmarks-bft-5"  # Katalog wyjściowy
$CONTRACT = "graph5o5"
# Utwórz katalog wyjściowy
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null

# Nagłówek pliku konfiguracyjnego
@"
name: Caliper Benchmarks
version: "2.0.0"

caliper:
  blockchain: fabric

channels:
  - channelName: $CHANNEL_NAME
    contracts:
    - id: $CONTRACT

organizations:
"@ | Out-File -FilePath "$OUTPUT_DIR\networkConfig.yaml" -Encoding utf8

function Get-CertificatesFromSecret {
    param (
        [string]$secretName,
        [string]$namespace
    )
    
    try {
        # Pobierz sekret w formacie JSON
        $secretJson = kubectl get secret -n $namespace $secretName -o json
        $secret = $secretJson | ConvertFrom-Json

        # Certyfikat i klucz są bezpośrednio w sekrecie
        $cert = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret.data.'cert.pem'))
        $key = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret.data.'key.pem'))

        return @{
            Cert = $cert
            Key = $key
        }
    }
    catch {
        Write-Warning "Błąd przetwarzania sekretu $secretName : $_"
        return $null
    }
}

# Generowanie sekcji dla każdej organizacji
for ($org = 1; $org -le $ORGS_COUNT; $org++) {
    Write-Host "Przetwarzanie organizacji Org${org}MSP..."

    # 1. Pobierz certyfikaty
    $certs = Get-CertificatesFromSecret -secretName "org${org}-admin" -namespace $NAMESPACE
    if (-not $certs) {
        Write-Host "  Pomijanie z powodu błędów" -ForegroundColor Yellow
        continue
    }

    # 2. Skopiuj plik orgX.yaml
    $orgYamlPath = "$OUTPUT_DIR\org${org}.yaml"
    try {
        kubectl cp "${NAMESPACE}/${SOURCE_POD}:org${org}.yaml" $orgYamlPath 2>&1 | Out-Null
        if (-not (Test-Path $orgYamlPath)) {
            throw "Nie udało się skopiować pliku"
        }
    }
    catch {
        Write-Host "  Błąd kopiowania org${org}.yaml: $_" -ForegroundColor Red
        continue
    }

    # 3. Dodaj sekcję organizacji
    try {
        $orgConfig = @"
  - mspid: Org${org}MSP
    identities:
      certificates:
      - name: admin
        clientSignedCert:
          pem: |
            $($certs.Cert -replace "`r`n", "`n            " -replace "`n", "`n            ")
        clientPrivateKey:
          pem: |
            $($certs.Key -replace "`r`n", "`n            " -replace "`n", "`n            ")
    connectionProfile:
      path: ./org${org}.yaml
"@
        Add-Content -Path "$OUTPUT_DIR\networkConfig.yaml" -Value $orgConfig -Encoding utf8
        Write-Host "  Dodano pomyślnie" -ForegroundColor Green
    }
    catch {
        Write-Host "  Błąd zapisu konfiguracji: $_" -ForegroundColor Red
    }
}

# Podsumowanie
Write-Host "`nPodsumowanie:" -ForegroundColor Cyan
Write-Host "- Konfiguracja zapisana w $OUTPUT_DIR\networkConfig.yaml" -ForegroundColor Green
Write-Host "- Pliki connection profile:" -ForegroundColor Cyan
Get-ChildItem -Path "$OUTPUT_DIR\org*.yaml" | Select-Object Name