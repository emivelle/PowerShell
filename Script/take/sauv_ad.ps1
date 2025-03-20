# Demander les informations d'identification de l'administrateur
$adminCreds = Get-Credential -Message "Entrez les informations d'identification de l'administrateur"

# Nom du serveur à sauvegarder
$serverName = "SRV-DC01"

# Chemin de sauvegarde
$backupPath = "C:\sauvegarde-ad"  # Utiliser un chemin local plus simple
$shareName = "sauvegarde-ad"
$shareDescription = "Partage pour la sauvegarde AD"

# Vérifier si le dossier de sauvegarde existe et le créer si nécessaire
if (!(Test-Path -Path $backupPath)) {
    try {
        New-Item -Path $backupPath -ItemType Directory -Force -ErrorAction Stop
        Write-Host "Dossier de sauvegarde créé : $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "Erreur de création du dossier $backupPath : $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "Le dossier de sauvegarde existe déjà : $backupPath" -ForegroundColor Green
}

# Créer un partage SMB
try {
    # Créer un partage SMB sur le répertoire local (sans le `$`)
    New-SmbShare -Path $backupPath -Name $shareName -Description $shareDescription -FullAccess "Administrateurs" -ErrorAction Stop
    Write-Host "Partage SMB créé pour $backupPath avec les droits d'accès en lecture/écriture pour 'Administrateurs'" -ForegroundColor Green
} catch {
    Write-Host "Erreur de création du partage SMB : $_" -ForegroundColor Red
    exit
}

# Vérifier que le répertoire de logs existe
$logPath = "C:\BackupLogs"
if (!(Test-Path -Path $logPath)) {
    try {
        New-Item -Path $logPath -ItemType Directory -Force -ErrorAction Stop
        Write-Host "Dossier de logs créé à : $logPath" -ForegroundColor Green
    } catch {
        Write-Host "Erreur de création du dossier de logs : $_" -ForegroundColor Red
        exit
    }
}

# Tester l'accès réseau en écriture
try {
    $testFile = "$backupPath\test_access.txt"
    "Test d'écriture" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item -Path $testFile -Force
    Write-Host "Test d'accès au partage réseau réussi." -ForegroundColor Green
} catch {
    Write-Host "Erreur d'accès en écriture sur $backupPath. Vérifiez les permissions réseau !" -ForegroundColor Red
    exit
}

# Activer PowerShell Remoting si nécessaire
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    if ((Get-Item WSMan:\localhost\Service\Auth\Basic).Value -eq $false) {
        Enable-PSRemoting -Force
    }
}

# Ajouter le serveur distant aux hôtes de confiance
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrustedHosts -notlike "*$serverName*") {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$currentTrustedHosts, $serverName" -Concatenate
}

# Vérifier que le service WinRM est en cours d'exécution et le démarrer si nécessaire
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    if (Get-Service WinRM -ErrorAction SilentlyContinue) {
        if ((Get-Service WinRM).Status -ne 'Running') {
            Start-Service WinRM
        }
    } else {
        Write-Host "Le service WinRM n'est pas installé sur $using:serverName" -ForegroundColor Red
        exit
    }
}

# Créer une session PowerShell avec les informations d'identification administratives
$session = New-PSSession -ComputerName $serverName -Credential $adminCreds

if ($session) {
    Write-Host "Session PowerShell créée avec succès sur $serverName." -ForegroundColor Green
} else {
    Write-Host "Échec de la création de la session PowerShell sur $serverName." -ForegroundColor Red
    exit
}

# Exécuter la commande de sauvegarde dans cette session avec log détaillé
Invoke-Command -Session $session -ScriptBlock {
    param ($backupPath, $logPath)
    
    # Vérifier et créer le dossier de sauvegarde si nécessaire
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force
        Write-Host "Dossier de sauvegarde créé : $backupPath" -ForegroundColor Yellow
    }

    # Vérifier que wbadmin est bien disponible
    if (-not (Get-Command wbadmin -ErrorAction SilentlyContinue)) {
        Write-Host "Erreur : wbadmin n'est pas disponible sur $env:COMPUTERNAME" -ForegroundColor Red
        exit
    }

    # Lancer la sauvegarde avec logs détaillés
    Write-Host "Début de la sauvegarde système..." -ForegroundColor Cyan
    $logFile = "$logPath\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    wbadmin start systemstatebackup -backupTarget:$backupPath -quiet *>&1 | Tee-Object -FilePath $logFile

    Write-Host "Sauvegarde terminée. Logs disponibles dans $logFile" -ForegroundColor Green

} -ArgumentList $backupPath, $logPath

Write-Host "Processus de sauvegarde terminé !" -ForegroundColor Green
