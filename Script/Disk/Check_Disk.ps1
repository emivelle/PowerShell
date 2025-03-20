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