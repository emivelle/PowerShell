# Installation du service Windows Server Backup et configuration de VSS

# Vérification et installation de la fonctionnalité Windows Server Backup
Write-Host "Vérification du service Windows Server Backup..." -ForegroundColor Yellow
$wbFeature = Get-WindowsFeature -Name Windows-Server-Backup
if (-not $wbFeature.Installed) {
    Write-Host "La fonctionnalité Windows-Server-Backup n'est pas installée. Installation en cours..." -ForegroundColor Yellow
    Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
    Write-Host "La fonctionnalité Windows-Server-Backup a été installée." -ForegroundColor Green
} else {
    Write-Host "La fonctionnalité Windows-Server-Backup est déjà installée." -ForegroundColor Green
}

# Vérification et démarrage du service wbengine
$wbengineService = Get-Service -Name "wbengine" -ErrorAction SilentlyContinue
if ($null -eq $wbengineService) {
    Write-Host "Le service wbengine n'existe pas sur ce serveur." -ForegroundColor Red
    exit
} elseif ($wbengineService.Status -ne "Running") {
    Start-Service -Name "wbengine"
    Write-Host "Le service wbengine a été démarré avec succès." -ForegroundColor Green
} else {
    Write-Host "Le service wbengine est déjà en cours d'exécution." -ForegroundColor Green
}

# Configuration du service Volume Shadow Copy (VSS) pour les versions précédentes
Write-Host "Configuration du service Volume Shadow Copy (VSS)..." -ForegroundColor Yellow
$backupDrive = "S:"
$sourceVolume = "C:"
Enable-VolumeShadowCopy -Volume $sourceVolume
Write-Host "Le service VSS a été activé pour le volume $sourceVolume:" -ForegroundColor Green

# Configuration des paramètres de VSS pour utiliser le disque de sauvegarde S:\
$shadowStorage = Get-WmiObject -Namespace "root\cimv2" -Class "Win32_ShadowStorage" -Filter "Volume='\\?\Volume{$($sourceVolume.Guid)}\'"
if ($shadowStorage) {
    $shadowStorage.DiffVolume = "\\?\Volume{$($backupDrive.TrimEnd(':'))}\"
    $shadowStorage.MaxSpace = 10GB  # Définir la limite d'espace pour les copies instantanées
    $shadowStorage.Put()
    Write-Host "Les paramètres de VSS ont été configurés pour le volume $sourceVolume avec le stockage sur $backupDrive:" -ForegroundColor Green
} else {
    # Créer une nouvelle configuration de stockage VSS si elle n'existe pas
    $shadowStorage = ([wmiclass]"\\.\root\cimv2:Win32_ShadowStorage").CreateInstance()
    $shadowStorage.Volume = "\\?\Volume{$($sourceVolume.Guid)}\"
    $shadowStorage.DiffVolume = "\\?\Volume{$($backupDrive.TrimEnd(':'))}\"
    $shadowStorage.MaxSpace = 10GB  # Définir la limite d'espace pour les copies instantanées
    $shadowStorage.Put()
    Write-Host "Les paramètres de VSS ont été créés et configurés pour le volume $sourceVolume avec le stockage sur $backupDrive:" -ForegroundColor Green
}

Write-Host "La configuration de Windows Server Backup et VSS est terminée." -ForegroundColor Green