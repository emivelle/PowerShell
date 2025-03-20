# D�finir les variables pour le serveur et le partage SMB
$linuxServer = "srv-linux"
$linuxShare = "\\$linuxServer\sauvegarde-linux"
$linuxBackupFolder = "/mnt/sauvegarde-linux"

# V�rifier la connectivit� au serveur Linux
Write-Host "Test d'acc�s � $linuxServer via SMB..."
if (Test-Path $linuxShare) {
    Write-Host "Le partage SMB '$linuxShare' est accessible."
} else {
    Write-Host "Le partage SMB n'est pas accessible. V�rifiez la connectivit�."
    exit
}

# V�rifier si le dossier de sauvegarde existe sur SRV-LINUX
Write-Host "V�rification du dossier de sauvegarde sur $linuxServer..."
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    $backupFolder = "/mnt/sauvegarde-linux"
    if (Test-Path $backupFolder) {
        Write-Host "Le dossier de sauvegarde existe d�j� : $backupFolder"
    } else {
        New-Item -Path $backupFolder -ItemType Directory
        Write-Host "Dossier de sauvegarde cr�� sur $linuxServer : $backupFolder"
    }
}

# V�rification de l'installation de Samba (pour la cr�ation de partage SMB sur SRV-LINUX)
Write-Host "V�rification de l'installation de Samba sur $linuxServer..."
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    $sambaStatus = Get-Service -Name samba
    if ($sambaStatus.Status -eq 'Running') {
        Write-Host "Samba est d�j� install� et en cours d'ex�cution."
    } else {
        Write-Host "Installation de Samba sur $linuxServer..."
        sudo apt-get update
        sudo apt-get install -y samba
        sudo systemctl start smbd
        sudo systemctl enable smbd
        Write-Host "Samba install� et d�marr�."
    }
}

# Cr�ation du partage SMB sur SRV-LINUX
Write-Host "Cr�ation du partage SMB sur $linuxServer..."
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    $shareName = "sauvegarde-linux"
    $configFile = "/etc/samba/smb.conf"
    
    # Ajout du partage dans la configuration Samba
    $shareConfig = @"
[$shareName]
   path = /mnt/sauvegarde-linux
   read only = no
   browsable = yes
   guest ok = yes
"@
    
    # Sauvegarder et appliquer les changements
    $shareConfig | Out-File -Append -FilePath $configFile
    sudo systemctl restart smbd
    Write-Host "Partage SMB '$shareName' cr�� et configur�."
}

# Test de la connectivit� apr�s la configuration du partage SMB
Write-Host "Test d'acc�s au partage SMB..."
if (Test-Path $linuxShare) {
    Write-Host "Le partage SMB '$linuxShare' est maintenant accessible."
} else {
    Write-Host "Le partage SMB n'est toujours pas accessible. V�rifiez la configuration Samba sur $linuxServer."
    exit
}

# Lancer une sauvegarde via rsync depuis SRV-DC01 vers SRV-LINUX
Write-Host "D�but de la sauvegarde via rsync sur $linuxServer..."
$backupFolderDC01 = "C:\sauvegarde" # Dossier local de sauvegarde sur SRV-DC01
$backupCommand = "rsync -avz --delete $backupFolderDC01/ $linuxServer:/mnt/sauvegarde-linux/"

Invoke-Command -ComputerName "SRV-DC01" -ScriptBlock {
    # Lancer la commande rsync pour la sauvegarde
    Write-Host "Ex�cution de la sauvegarde avec rsync..."
    $backupCommand = "rsync -avz --delete $using:backupFolderDC01/ $using:linuxServer:/mnt/sauvegarde-linux/"
    Invoke-Expression $backupCommand
    Write-Host "Sauvegarde termin�e."
} -Credential (Get-Credential)

Write-Host "La sauvegarde syst�me a �t� lanc�e sur SRV-DC01 vers $linuxServer:/mnt/sauvegarde-linux"
