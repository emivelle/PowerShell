# D�finir la lettre de lecteur pour le disque de sauvegarde
$backupDrive = "S:"

# V�rifier si le disque de sauvegarde existe d�j�
if (!(Test-Path $backupDrive)) {
    # Si le disque n'existe pas, afficher un message et commencer la cr�ation
    Write-Host "Le disque de sauvegarde $backupDrive n'existe pas. Cr�ation en cours..." -ForegroundColor Yellow
    
    # R�cup�rer le disque en ligne avec le style de partition GPT et le num�ro de disque 1
    $disk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" -and $_.PartitionStyle -eq "GPT" -and $_.Number -eq 1 }
    
    # Cr�er une nouvelle partition sur le disque sp�cifi� en utilisant toute la taille disponible
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $backupDrive.TrimEnd(':')
    
    # Formater la partition en NTFS sans demander de confirmation
    Format-Volume -Partition $partition -FileSystem NTFS -Confirm:$false
    
    # Afficher un message indiquant que le disque a �t� cr�� et format� avec succ�s
    Write-Host "Le disque de sauvegarde $backupDrive a �t� cr�� et format� en NTFS." -ForegroundColor Green
} else {
    # Si le disque existe d�j�, afficher un message indiquant qu'il est d�j� pr�sent
    Write-Host "Le disque de sauvegarde $backupDrive existe d�j�." -ForegroundColor Green
}