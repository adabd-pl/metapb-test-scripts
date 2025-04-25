<#
.SYNOPSIS
    Skrypt do aktualizacji parametrów batchSize i batchTimeout w działającym zasobie FabricMainChannel
.DESCRIPTION
    Skrypt modyfikuje konfigurację działającego zasobu Kubernetes poprzez:
    1. Pobranie aktualnej konfiguracji
    2. Modyfikację parametrów batch
    3. Zastosowanie zmian za pomocą kubectl apply
#>

# Nazwa zasobu do modyfikacji
$resourceName = "demobft10"
$namespace = "fabric" # Zmień na właściwą namespace jeśli potrzeba

# Pobierz aktualną konfigurację zasobu
$currentConfig = kubectl get fabricmainchannel.hlf.kungfusoftware.es $resourceName -n $namespace -o yaml

# Sprawdź czy udało się pobrać konfigurację
if (-not $currentConfig) {
    Write-Error "Nie udało się pobrać konfiguracji zasobu $resourceName"
    exit 1
}

# Definicja nowych parametrów
$newParams = @{
    absoluteMaxBytes = 2097152    # 2MB
    maxMessageCount = 200
    preferredMaxBytes = 1048576   # 1MB
    batchTimeout = "100ms"
}

# Modyfikacja konfiguracji
$modifiedConfig = $currentConfig -replace "absoluteMaxBytes: \d+", "absoluteMaxBytes: $($newParams.absoluteMaxBytes)"
$modifiedConfig = $modifiedConfig -replace "maxMessageCount: \d+", "maxMessageCount: $($newParams.maxMessageCount)"
$modifiedConfig = $modifiedConfig -replace "preferredMaxBytes: \d+", "preferredMaxBytes: $($newParams.preferredMaxBytes)"
$modifiedConfig = $modifiedConfig -replace "batchTimeout: \d+ms", "batchTimeout: $($newParams.batchTimeout)"

# Zapisz zmodyfikowaną konfigurację do tymczasowego pliku
$tempFile = [System.IO.Path]::GetTempFileName() + ".yaml"
$modifiedConfig | Out-File -FilePath $tempFile -Encoding utf8

Write-Host "Zastosuję następujące zmiany:"
Write-Host "absoluteMaxBytes: $($newParams.absoluteMaxBytes)"
Write-Host "maxMessageCount: $($newParams.maxMessageCount)"
Write-Host "preferredMaxBytes: $($newParams.preferredMaxBytes)"
Write-Host "batchTimeout: $($newParams.batchTimeout)"

# Potwierdzenie przed zastosowaniem zmian
$confirmation = Read-Host "Czy na pewno chcesz zaktualizować konfigurację? (T/N)"
if ($confirmation -ne 'T') {
    Write-Host "Anulowano aktualizację"
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    exit
}

# Zastosowanie zmian
Write-Host "Stosuję zmiany..."
kubectl apply -f $tempFile

# Sprzątanie - usunięcie tymczasowego pliku
Remove-Item $tempFile -ErrorAction SilentlyContinue

Write-Host "Aktualizacja zakończona. Sprawdź status zasobu komendą:"
Write-Host "kubectl get fabricmainchannel.hlf.kungfusoftware.es $resourceName -n $namespace -o yaml"