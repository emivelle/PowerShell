# D�finir le nom du serveur de sauvegarde et du partage
$backupServer = "Srv-sauv01"
$backupShare = "\\$backupServer\S$\sauvegarde-impr"

# V�rification de l'existence du dossier de sauvegarde local sur SRV-DC01
$backupFolder = "S:\sauvegarde-impr"
if (Test-Path -Path $backupFolder) {
    Write-Host "Le dossier de sauvegarde existe d�j� : $backupFolder"
} else {
    New-Item -Path $backupFolder -ItemType Directory
    Write-Host "Dossier de sauvegarde cr�� : $backupFolder"
}

# V�rification du partage SMB sur le serveur de sauvegarde (Srv-sauv01)
$shareName = "sauvegarde-impr"
$shareExists = Get-SmbShare -ComputerName $backupServer | Where-Object {$_.Name -eq $shareName}

if ($shareExists) {
    Write-Host "Le partage SMB '$shareName' existe d�j� sur $backupServer."
} else {
    Write-Host "Cr�ation du partage SMB '$shareName' sur $backupServer..."
    New-SmbShare -Name $shareName -Path $backupFolder -FullAccess "Administrators"
    Write-Host "Partage SMB '$shareName' cr�� et configur� avec acc�s complet pour les Administrateurs."
}

# Test de connectivit� au partage r�seau
Write-Host "Test d'acc�s au partage r�seau..."
if (Test-Path $backupShare) {
    Write-Host "Le partage r�seau est accessible."
} else {
    Write-Host "Le partage r�seau n'est pas accessible. V�rifiez la connectivit�."
    exit
}

# Ouverture d'une session distante sur SRV-IMPR01 et installation du service Windows Server Backup
$credential = Get-Credential

Invoke-Command -ComputerName "SRV-IMPR01" -Credential $credential -ScriptBlock {
    # V�rifier si Windows Server Backup est install�
    $backupFeature = Get-WindowsFeature -Name Windows-Server-Backup
    if ($backupFeature.Installed -eq $false) {
        Write-Host "Installation de Windows Server Backup..."
        Install-WindowsFeature Windows-Server-Backup
    } else {
        Write-Host "Windows Server Backup est d�j� install�."
    }

    # D�marrer le service VSS (Volume Shadow Copy Service)
    Write-Host "D�marrage du service VSS..."
    Start-Service -Name vss

    # D�marrer le service wbengine (Windows Backup Engine)
    Write-Host "D�marrage du service wbengine..."
    Start-Service -Name wbengine

    # Lancer la sauvegarde du syst�me
    Write-Host "D�marrage de la sauvegarde syst�me..."
    wbadmin start systemstatebackup -backupTarget:$using:backupShare -quiet
} -ErrorAction Stop

Write-Host "La sauvegarde syst�me a �t� lanc�e sur SRV-IMPR01 vers $backupShare"
