# Définir la lettre de lecteur pour le disque de sauvegarde
$backupDrive = "S:"

# Vérifier si le disque de sauvegarde existe déjà
if (!(Test-Path $backupDrive)) {
    # Si le disque n'existe pas, afficher un message et commencer la création
    Write-Host "Le disque de sauvegarde $backupDrive n'existe pas. Création en cours..." -ForegroundColor Yellow
    
    # Récupérer le disque en ligne avec le style de partition GPT et le numéro de disque 1
    $disk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" -and $_.PartitionStyle -eq "GPT" -and $_.Number -eq 1 }
    
    # Créer une nouvelle partition sur le disque spécifié en utilisant toute la taille disponible
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $backupDrive.TrimEnd(':')
    
    # Formater la partition en NTFS sans demander de confirmation
    Format-Volume -Partition $partition -FileSystem NTFS -Confirm:$false
    
    # Afficher un message indiquant que le disque a été créé et formaté avec succès
    Write-Host "Le disque de sauvegarde $backupDrive a été créé et formaté en NTFS." -ForegroundColor Green
} else {
    # Si le disque existe déjà, afficher un message indiquant qu'il est déjà présent
    Write-Host "Le disque de sauvegarde $backupDrive existe déjà." -ForegroundColor Green
}

# Configurer les permissions NTFS
$acl = Get-Acl $backupPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrateurs", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Tout le monde", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $backupPath $acl

Write-Host "Le disque de sauvegarde $backupDrive a été partagé avec les permissions configurées." -ForegroundColor Green

# Vérifier les permissions NTFS
Write-Host "Permissions NTFS pour $backupPath :" -ForegroundColor Yellow
$acl.Access | ForEach-Object {
    Write-Host "Utilisateur : $($_.IdentityReference)"
    Write-Host "Permissions : $($_.FileSystemRights)"
    Write-Host "Type d'accès : $($_.AccessControlType)"
    Write-Host "Héritage : $($_.InheritanceFlags)"
    Write-Host "Propagation : $($_.PropagationFlags)"
    Write-Host "----------------------------------------"
}

# Vérifier l'espace libre du disque
Write-Host "Espace libre sur le disque $backupDrive :" -ForegroundColor Yellow
$diskInfo = Get-PSDrive -Name $backupDrive.TrimEnd(':')
Write-Host "Espace total : $($diskInfo.Used + $diskInfo.Free) octets"
Write-Host "Espace utilisé : $($diskInfo.Used) octets"
Write-Host "Espace libre : $($diskInfo.Free) octets"

Write-Host "Vérification des droits et de l'espace libre terminée." -ForegroundColor Green