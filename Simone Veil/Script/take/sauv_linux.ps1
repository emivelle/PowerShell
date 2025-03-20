# Définir les variables pour le serveur et le partage SMB
$linuxServer = "srv-linux"
$linuxShare = "\\$linuxServer\sauvegarde-linux"
$linuxBackupFolder = "/mnt/sauvegarde-linux"

# Vérifier la connectivité au serveur Linux
Write-Host "Test d'accès à $linuxServer via SMB..."
if (Test-Path $linuxShare) {
    Write-Host "Le partage SMB '$linuxShare' est accessible."
} else {
    Write-Host "Le partage SMB n'est pas accessible. Vérifiez la connectivité."
    exit
}

# Vérifier si le dossier de sauvegarde existe sur SRV-LINUX
Write-Host "Vérification du dossier de sauvegarde sur $linuxServer..."
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    $backupFolder = "/mnt/sauvegarde-linux"
    if (Test-Path $backupFolder) {
        Write-Host "Le dossier de sauvegarde existe déjà : $backupFolder"
    } else {
        New-Item -Path $backupFolder -ItemType Directory
        Write-Host "Dossier de sauvegarde créé sur $linuxServer : $backupFolder"
    }
}

# Vérification de l'installation de Samba (pour la création de partage SMB sur SRV-LINUX)
Write-Host "Vérification de l'installation de Samba sur $linuxServer..."
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    $sambaStatus = Get-Service -Name samba
    if ($sambaStatus.Status -eq 'Running') {
        Write-Host "Samba est déjà installé et en cours d'exécution."
    } else {
        Write-Host "Installation de Samba sur $linuxServer..."
        sudo apt-get update
        sudo apt-get install -y samba
        sudo systemctl start smbd
        sudo systemctl enable smbd
        Write-Host "Samba installé et démarré."
    }
}

# Création du partage SMB sur SRV-LINUX
Write-Host "Création du partage SMB sur $linuxServer..."
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
    Write-Host "Partage SMB '$shareName' créé et configuré."
}

# Test de la connectivité après la configuration du partage SMB
Write-Host "Test d'accès au partage SMB..."
if (Test-Path $linuxShare) {
    Write-Host "Le partage SMB '$linuxShare' est maintenant accessible."
} else {
    Write-Host "Le partage SMB n'est toujours pas accessible. Vérifiez la configuration Samba sur $linuxServer."
    exit
}

# Lancer une sauvegarde via rsync depuis SRV-DC01 vers SRV-LINUX
Write-Host "Début de la sauvegarde via rsync sur $linuxServer..."
$backupFolderDC01 = "C:\sauvegarde" # Dossier local de sauvegarde sur SRV-DC01
$backupCommand = "rsync -avz --delete $backupFolderDC01/ $linuxServer:/mnt/sauvegarde-linux/"

Invoke-Command -ComputerName "SRV-DC01" -ScriptBlock {
    # Lancer la commande rsync pour la sauvegarde
    Write-Host "Exécution de la sauvegarde avec rsync..."
    $backupCommand = "rsync -avz --delete $using:backupFolderDC01/ $using:linuxServer:/mnt/sauvegarde-linux/"
    Invoke-Expression $backupCommand
    Write-Host "Sauvegarde terminée."
} -Credential (Get-Credential)

Write-Host "La sauvegarde système a été lancée sur SRV-DC01 vers $linuxServer:/mnt/sauvegarde-linux"
