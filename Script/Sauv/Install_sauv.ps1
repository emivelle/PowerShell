# Installation du service Windows Server Backup et configuration de VSS

# V�rification et installation de la fonctionnalit� Windows Server Backup
Write-Host "V�rification du service Windows Server Backup..." -ForegroundColor Yellow
$wbFeature = Get-WindowsFeature -Name Windows-Server-Backup
if (-not $wbFeature.Installed) {
    Write-Host "La fonctionnalit� Windows-Server-Backup n'est pas install�e. Installation en cours..." -ForegroundColor Yellow
    Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
    Write-Host "La fonctionnalit� Windows-Server-Backup a �t� install�e." -ForegroundColor Green
} else {
    Write-Host "La fonctionnalit� Windows-Server-Backup est d�j� install�e." -ForegroundColor Green
}

# V�rification et d�marrage du service wbengine
$wbengineService = Get-Service -Name "wbengine" -ErrorAction SilentlyContinue
if ($null -eq $wbengineService) {
    Write-Host "Le service wbengine n'existe pas sur ce serveur." -ForegroundColor Red
    exit
} elseif ($wbengineService.Status -ne "Running") {
    Start-Service -Name "wbengine"
    Write-Host "Le service wbengine a �t� d�marr� avec succ�s." -ForegroundColor Green
} else {
    Write-Host "Le service wbengine est d�j� en cours d'ex�cution." -ForegroundColor Green
}

# Configuration du service Volume Shadow Copy (VSS) pour les versions pr�c�dentes
Write-Host "Configuration du service Volume Shadow Copy (VSS)..." -ForegroundColor Yellow
$backupDrive = "S:"
$sourceVolume = "C:"
Enable-VolumeShadowCopy -Volume $sourceVolume
Write-Host "Le service VSS a �t� activ� pour le volume $sourceVolume:" -ForegroundColor Green

# Configuration des param�tres de VSS pour utiliser le disque de sauvegarde S:\
$shadowStorage = Get-WmiObject -Namespace "root\cimv2" -Class "Win32_ShadowStorage" -Filter "Volume='\\?\Volume{$($sourceVolume.Guid)}\'"
if ($shadowStorage) {
    $shadowStorage.DiffVolume = "\\?\Volume{$($backupDrive.TrimEnd(':'))}\"
    $shadowStorage.MaxSpace = 10GB  # D�finir la limite d'espace pour les copies instantan�es
    $shadowStorage.Put()
    Write-Host "Les param�tres de VSS ont �t� configur�s pour le volume $sourceVolume avec le stockage sur $backupDrive:" -ForegroundColor Green
} else {
    # Cr�er une nouvelle configuration de stockage VSS si elle n'existe pas
    $shadowStorage = ([wmiclass]"\\.\root\cimv2:Win32_ShadowStorage").CreateInstance()
    $shadowStorage.Volume = "\\?\Volume{$($sourceVolume.Guid)}\"
    $shadowStorage.DiffVolume = "\\?\Volume{$($backupDrive.TrimEnd(':'))}\"
    $shadowStorage.MaxSpace = 10GB  # D�finir la limite d'espace pour les copies instantan�es
    $shadowStorage.Put()
    Write-Host "Les param�tres de VSS ont �t� cr��s et configur�s pour le volume $sourceVolume avec le stockage sur $backupDrive:" -ForegroundColor Green
}

Write-Host "La configuration de Windows Server Backup et VSS est termin�e." -ForegroundColor Green