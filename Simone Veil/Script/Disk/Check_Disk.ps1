# Définir la lettre de lecteur pour le disque de sauvegarde
$backupDrive = "S:"

# Vérifier si le disque de sauvegarde existe déjà
if (!(Test-Path $backupDrive)) {
    Write-Host "Le disque de sauvegarde $backupDrive n'existe pas. Création en cours..." -ForegroundColor Yellow

    # Récupérer le disque disponible (modifier si besoin pour cibler un disque précis)
    $disk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" -and $_.PartitionStyle -eq "GPT" } | Select-Object -First 1

    if ($null -eq $disk) {
        Write-Host "Aucun disque GPT en ligne trouvé. Abandon de l'opération." -ForegroundColor Red
        exit
    }

    # Créer une partition utilisant toute la taille disponible
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

    # Récupérer la lettre attribuée et formater en NTFS
    $driveLetter = $partition.DriveLetter + ":"
    Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -Force

    Write-Host "Le disque de sauvegarde $driveLetter a été créé et formaté en NTFS." -ForegroundColor Green
} else {
    Write-Host "Le disque de sauvegarde $backupDrive existe déjà." -ForegroundColor Green
}

# Définir le chemin du lecteur (racine du disque)
$backupPath = $backupDrive + "\"

# Configurer les permissions NTFS
$acl = Get-Acl $backupPath
$accessRuleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrateurs", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$accessRuleEveryone = New-Object System.Security.AccessControl.FileSystemAccessRule("Tout le monde", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")

$acl.SetAccessRule($accessRuleAdmin)
$acl.SetAccessRule($accessRuleEveryone)
Set-Acl -Path $backupPath -AclObject $acl

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
if (Test-Path $backupDrive) {
    Write-Host "Espace libre sur le disque $backupDrive :" -ForegroundColor Yellow
    $diskInfo = Get-PSDrive -Name $backupDrive.TrimEnd(':')
    Write-Host "Espace total : $($diskInfo.Used + $diskInfo.Free) octets"
    Write-Host "Espace utilisé : $($diskInfo.Used) octets"
    Write-Host "Espace libre : $($diskInfo.Free) octets"
} else {
    Write-Host "Le disque $backupDrive n'est pas accessible." -ForegroundColor Red
}

Write-Host "Vérification des droits et de l'espace libre terminée." -ForegroundColor Green
