# Installation du service Windows Server Backup et configuration de VSS

# V�rification et installation de la fonctionnalit� Windows Server Backup
Write-Host "V�rification du service Windows Server Backup..." -ForegroundColor Yellow
$wbFeature = Get-WindowsFeature -Name Windows-Server-Backup
if (-not $wbFeature.Installed) {
    Write-Host "La fonctionnalit� Windows-Server-Backup n'est pas install�e. Installation en cours..." -ForegroundColor Yellow
    try {
        Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools -Source "wim:E:\sources\install.wim:1"
        Write-Host "La fonctionnalit� Windows-Server-Backup a �t� install�e." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'installation de Windows Server Backup : $_" -ForegroundColor Red
        exit 1
    }
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
$volumes = Get-Volume
foreach ($volume in $volumes) {
    $driveLetter = $volume.DriveLetter
    if ($driveLetter) {
        Write-Host "Activation du service VSS pour le volume $driveLetter..." -ForegroundColor Yellow
        Start-Process -FilePath "vssadmin" -ArgumentList "Add ShadowStorage /For=${driveLetter}: /On=${backupDrive}: /MaxSize=10GB" -NoNewWindow -Wait
        Write-Host "Le service VSS a �t� activ� pour le volume $driveLetter avec le stockage sur ${backupDrive}." -ForegroundColor Green
    } else {
        Write-Host "Volume sans lettre de lecteur d�tect�. Ignor�." -ForegroundColor Yellow
    }
}

Write-Host "La configuration de Windows Server Backup et VSS est termin�e." -ForegroundColor Green