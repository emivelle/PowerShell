# Demander les informations d'identification de l'administrateur
$adminCreds = Get-Credential -Message "Entrez les informations d'identification de l'administrateur"

# Nom du serveur � sauvegarder
$serverName = "SRV-DC01"

# Chemin de sauvegarde
$backupPath = "C:\sauvegarde-ad"  # Utiliser un chemin local plus simple
$shareName = "sauvegarde-ad"
$shareDescription = "Partage pour la sauvegarde AD"

# V�rifier si le dossier de sauvegarde existe et le cr�er si n�cessaire
if (!(Test-Path -Path $backupPath)) {
    try {
        New-Item -Path $backupPath -ItemType Directory -Force -ErrorAction Stop
        Write-Host "Dossier de sauvegarde cr�� : $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "Erreur de cr�ation du dossier $backupPath : $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "Le dossier de sauvegarde existe d�j� : $backupPath" -ForegroundColor Green
}

# Cr�er un partage SMB
try {
    # Cr�er un partage SMB sur le r�pertoire local (sans le `$`)
    New-SmbShare -Path $backupPath -Name $shareName -Description $shareDescription -FullAccess "Administrateurs" -ErrorAction Stop
    Write-Host "Partage SMB cr�� pour $backupPath avec les droits d'acc�s en lecture/�criture pour 'Administrateurs'" -ForegroundColor Green
} catch {
    Write-Host "Erreur de cr�ation du partage SMB : $_" -ForegroundColor Red
    exit
}

# V�rifier que le r�pertoire de logs existe
$logPath = "C:\BackupLogs"
if (!(Test-Path -Path $logPath)) {
    try {
        New-Item -Path $logPath -ItemType Directory -Force -ErrorAction Stop
        Write-Host "Dossier de logs cr�� � : $logPath" -ForegroundColor Green
    } catch {
        Write-Host "Erreur de cr�ation du dossier de logs : $_" -ForegroundColor Red
        exit
    }
}

# Tester l'acc�s r�seau en �criture
try {
    $testFile = "$backupPath\test_access.txt"
    "Test d'�criture" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item -Path $testFile -Force
    Write-Host "Test d'acc�s au partage r�seau r�ussi." -ForegroundColor Green
} catch {
    Write-Host "Erreur d'acc�s en �criture sur $backupPath. V�rifiez les permissions r�seau !" -ForegroundColor Red
    exit
}

# Activer PowerShell Remoting si n�cessaire
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    if ((Get-Item WSMan:\localhost\Service\Auth\Basic).Value -eq $false) {
        Enable-PSRemoting -Force
    }
}

# Ajouter le serveur distant aux h�tes de confiance
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrustedHosts -notlike "*$serverName*") {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$currentTrustedHosts, $serverName" -Concatenate
}

# V�rifier que le service WinRM est en cours d'ex�cution et le d�marrer si n�cessaire
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    if (Get-Service WinRM -ErrorAction SilentlyContinue) {
        if ((Get-Service WinRM).Status -ne 'Running') {
            Start-Service WinRM
        }
    } else {
        Write-Host "Le service WinRM n'est pas install� sur $using:serverName" -ForegroundColor Red
        exit
    }
}

# Cr�er une session PowerShell avec les informations d'identification administratives
$session = New-PSSession -ComputerName $serverName -Credential $adminCreds

if ($session) {
    Write-Host "Session PowerShell cr��e avec succ�s sur $serverName." -ForegroundColor Green
} else {
    Write-Host "�chec de la cr�ation de la session PowerShell sur $serverName." -ForegroundColor Red
    exit
}

# Ex�cuter la commande de sauvegarde dans cette session avec log d�taill�
Invoke-Command -Session $session -ScriptBlock {
    param ($backupPath, $logPath)
    
    # V�rifier et cr�er le dossier de sauvegarde si n�cessaire
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force
        Write-Host "Dossier de sauvegarde cr�� : $backupPath" -ForegroundColor Yellow
    }

    # V�rifier que wbadmin est bien disponible
    if (-not (Get-Command wbadmin -ErrorAction SilentlyContinue)) {
        Write-Host "Erreur : wbadmin n'est pas disponible sur $env:COMPUTERNAME" -ForegroundColor Red
        exit
    }

    # Lancer la sauvegarde avec logs d�taill�s
    Write-Host "D�but de la sauvegarde syst�me..." -ForegroundColor Cyan
    $logFile = "$logPath\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    wbadmin start systemstatebackup -backupTarget:$backupPath -quiet *>&1 | Tee-Object -FilePath $logFile

    Write-Host "Sauvegarde termin�e. Logs disponibles dans $logFile" -ForegroundColor Green

} -ArgumentList $backupPath, $logPath

Write-Host "Processus de sauvegarde termin� !" -ForegroundColor Green
