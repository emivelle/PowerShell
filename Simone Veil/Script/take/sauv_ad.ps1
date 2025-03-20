# Définir le nom du serveur de sauvegarde et du partage
$backupServer = "Srv-sauv01"
$backupShare = "\\$backupServer\S$\sauvegarde-ad"

# Vérification de l'existence du dossier de sauvegarde local sur SRV-DC01
$backupFolder = "S:\sauvegarde-ad"
if (Test-Path -Path $backupFolder) {
    Write-Host "Le dossier de sauvegarde existe déjà : $backupFolder"
} else {
    New-Item -Path $backupFolder -ItemType Directory
    Write-Host "Dossier de sauvegarde créé : $backupFolder"
}

# Vérification du partage SMB sur SRV-DC01
$shareName = "sauvegarde-ad"
$shareExists = Get-SmbShare | Where-Object {$_.Name -eq $shareName}

if ($shareExists) {
    Write-Host "Le partage SMB '$shareName' existe déjà sur $backupServer."
} else {
    Write-Host "Création du partage SMB '$shareName' sur $backupServer..."
    New-SmbShare -Name $shareName -Path $backupFolder -FullAccess "Administrators"
    Write-Host "Partage SMB '$shareName' créé et configuré avec accès complet pour les Administrateurs."
}

# Test de connectivité au partage réseau
Write-Host "Test d'accès au partage réseau..."
Test-Path $backupShare

# Ouverture d'une session distante sur SRV-DC01 et installation du service Windows Server Backup
$credential = Get-Credential

Invoke-Command -ComputerName "SRV-DC01" -Credential $credential -ScriptBlock {
    # Vérifier si Windows Server Backup est installé
    $backupFeature = Get-WindowsFeature -Name Windows-Server-Backup
    if ($backupFeature.Installed -eq $false) {
        Write-Host "Installation de Windows Server Backup..."
        Install-WindowsFeature Windows-Server-Backup
    } else {
        Write-Host "Windows Server Backup est déjà installé."
    }

    # Démarrer le service VSS (Volume Shadow Copy Service)
    Write-Host "Démarrage du service VSS..."
    Start-Service -Name vss

    # Démarrer le service wbengine (Windows Backup Engine)
    Write-Host "Démarrage du service wbengine..."
    Start-Service -Name wbengine

    # Lancer la sauvegarde du système
    Write-Host "Démarrage de la sauvegarde système..."
    wbadmin start systemstatebackup -backupTarget:$using:backupShare -quiet
} -ErrorAction Stop

Write-Host "La sauvegarde système a été lancée sur SRV-DC01 vers $backupShare"
