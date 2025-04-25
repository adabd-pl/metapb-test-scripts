<#
.SYNOPSIS
    Aktualizuje nazwę ConfigMap w Jobie Caliper i zapisuje z nową wersją
.DESCRIPTION
    Skrypt:
    1. Aktualizuje nazwę ConfigMap w sekcji volumes
    2. Zapisuje plik z numerem wersji
    3. Nie modyfikuje mountPath
#>

param(
    [string]$InputYamlFile = "..\..\deploy-caliper-bft.yaml",
    [string]$NewConfigMapName = "caliper-benchmarks-raft-1",
    [int]$VersionNumber = 4
)

function Get-VersionedFileName {
    param(
        [string]$fileName,
        [int]$version
    )
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $ext = [System.IO.Path]::GetExtension($fileName)
    return "${baseName}-v${version}${ext}"
}

try {
    # Sprawdzenie istnienia pliku wejściowego
    if (-not (Test-Path $InputYamlFile)) {
        Write-Host "BŁĄD: Plik wejściowy nie istnieje: $InputYamlFile" -ForegroundColor Red
        exit 1
    }

    $fullPath = (Get-Item $InputYamlFile).FullName
    Write-Host "Przetwarzanie pliku: $fullPath" -ForegroundColor Cyan
    
    $content = [System.IO.File]::ReadAllText($fullPath)
    
    $pattern = '(?s)(volumes:\s*- name: shared-data\s*emptyDir: \{\}.*?- name: caliper-benchmarks-bft\s*configMap:\s*name: )caliper-benchmarks-bft'

    if ($content -match $pattern) {
        $updatedContent = $content -replace $pattern, "`$1$NewConfigMapName"
        
        $outputFile = Get-VersionedFileName $InputYamlFile $VersionNumber
        $outputPath = Join-Path (Get-Item $InputYamlFile).DirectoryName $outputFile
        
        Write-Host "Próba zapisu do: $outputPath" -ForegroundColor Yellow
        [System.IO.File]::WriteAllText($outputPath, $updatedContent)
        
        # Weryfikacja zapisu
        if (Test-Path $outputPath) {
            Write-Host "SUKCES: Plik został zapisany jako: $outputPath" -ForegroundColor Green
            Write-Host "Rozmiar pliku: $((Get-Item $outputPath).Length) bajtów" -ForegroundColor Gray
        } else {
            Write-Host "BŁĄD: Plik nie został zapisany!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Zaktualizowano: ConfigMap name: $NewConfigMapName" -ForegroundColor Cyan
    }
    else {
        Write-Host "BŁĄD: Nie znaleziono sekcji ConfigMap do aktualizacji!" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "BŁĄD KRYTYCZNY: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
    exit 1
}