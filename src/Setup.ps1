<#
.SYNOPSIS
    Setup.ps1
    Setup pour chaque script (logs, affichage).

.DESCRIPTION
    Setup.ps1
    A faire.

.EXAMPLE
    . $PSScriptRoot\Setup.ps1 -LogName $PSCommandPath
    Usage basique dans un script.

.NOTES
    Auteur : 1337phtm
    Version : 1.0
    Compatibilité : Windows 11
    Nécessite : PowerShell 5.1+

.LINK
    GitHub :
    https://github.com/1337phtm/
#>

param(
    [string]$LogName
)

#======================================================================
# --- Logs ---
#======================================================================

$info = [System.IO.Path]::GetFileNameWithoutExtension($LogName)

#function Start-Log {
# --- Dossiers de logs ---
$Global:MainLog = Join-Path $env:LOCALAPPDATA "Github - 1337phtm"
$Global:ScriptLogDir = Join-Path $Global:MainLog "$($info)_Logs"

foreach ($dir in @($Global:MainLog, $Global:ScriptLogDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# --- Fichiers de log ---

foreach ($ScriptDir in @($Global:ScriptLogDir)) {
    if (-not (Test-Path $ScriptDir)) {
        New-Item -ItemType Directory -Path $ScriptDir | Out-Null
    }
}

$Global:LogFile = Join-Path $Global:ScriptLogDir "$($info).log"
$Global:ErrorLogFile = Join-Path $Global:ScriptLogDir "$($info).error.log"

foreach ($file in @($Global:LogFile, $Global:ErrorLogFile)) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}
#}

Add-Content -Path $Global:LogFile -Value "" -Force
Add-Content -Path $Global:LogFile -Value "" -Force
$LogEntry = "Démarrage du script : $($LogName) - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Add-Content -Path $Global:LogFile -Value $logEntry -Force
Add-Content -Path $Global:LogFile -Value "" -Force
Add-Content -Path $Global:LogFile -Value "" -Force

#======================================================================
# --- Affichage ---
#======================================================================

$Global:StatusCounters = @{
    SUCCESS = 0
    ERROR   = 0
    SKIP    = 0
    INFO    = 0
}

function Show-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║ $Title" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    $logEntry = ""
    Add-Content -Path $Global:LogFile -Value $logEntry -Force
    $logEntry = "╔══════════════════════════════════════════╗"
    Add-Content -Path $Global:LogFile -Value $logEntry -Force
    $logEntry = "║ $Title"
    Add-Content -Path $Global:LogFile -Value $logEntry -Force
    $logEntry = "╚══════════════════════════════════════════╝"
    Add-Content -Path $Global:LogFile -Value $logEntry -Force
    $logEntry = ""
    Add-Content -Path $Global:LogFile -Value $logEntry -Force

}

function Write-Status {
    param(
        [ValidateSet("SUCCESS", "ERROR", "SKIP", "INFO"<#, "TEST"#>)]$Type,
        [string]$Message
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $Global:StatusCounters[$Type]++

    switch ($Type) {
        "SUCCESS" { Write-Host " [$timestamp] ✓  $Message" -ForegroundColor Green }
        "ERROR" { Write-Host " [$timestamp] ✗ $Message" -ForegroundColor Red }
        "SKIP" { Write-Host " [$timestamp] - $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host " [$timestamp] → $Message" -ForegroundColor Cyan }
        #"TEST" { Write-Host " [$timestamp] ✎ [TEST] $Message" -ForegroundColor Magenta }
    }

    # LOG AUTOMATIQUE
    $logEntry = "[$timestamp] [$Type] $Message"
    Add-Content -Path $Global:LogFile -Value $logEntry -Force

    if ($Type -eq "ERROR") {
        Add-Content -Path $Global:ErrorLogFile -Value $logEntry -Force
    }
}

function Show-Counters {
    Show-SectionHeader "Execution Summary"
    Write-Host "  ✓ SUCCESS : $($Global:StatusCounters.SUCCESS)" -ForegroundColor Green
    Write-Host "  ✗ ERROR   : $($Global:StatusCounters.ERROR)" -ForegroundColor Red
    Write-Host "  - SKIP    : $($Global:StatusCounters.SKIP)" -ForegroundColor Yellow
    Write-Host "  → INFO    : $($Global:StatusCounters.INFO)`n" -ForegroundColor Cyan
    Write-Host "  📝 Logs    : $($Global:LogFile)`n" -ForegroundColor Gray
}



#Start-Log
