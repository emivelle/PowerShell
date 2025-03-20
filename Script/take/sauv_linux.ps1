# Définir les informations de la machine Linux et le disque de sauvegarde
$linuxServer = "NomDuServeurLinux"  # Remplace par le nom ou l'adresse IP de ta machine Linux
$backupDrive = "S:"
$backupFolder = "sauv-linux"
$linuxBackupFile = "/tmp/backup_linux.tar.gz"  # Chemin temporaire de l'archive sur la machine Linux

# Démarrage de la sauvegarde de la machine Linux
Write-Host "Démarrage de la sauvegarde de la machine Linux depuis le serveur $linuxServer..." -ForegroundColor Yellow

# Exécuter la commande de sauvegarde sur la machine Linux
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    param ($linuxBackupFile)
    tar -cvzf $linuxBackupFile --exclude=/proc --exclude=/lost+found --exclude=/mnt --exclude=/sys --exclude=/boot /
} -ArgumentList $linuxBackupFile

# Vérifier si la sauvegarde a été créée avec succès
if ($?) {
    Write-Host "La sauvegarde de la machine Linux a été créée avec succès sur $linuxServer." -ForegroundColor Green
    
    # Transférer l'archive vers le serveur Windows Server Backup
    $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
    $destinationPath = "$backupPath\backup_linux.tar.gz"
    Copy-Item -Path "\\$linuxServer\$linuxBackupFile" -Destination $destinationPath
    
    # Vérifier si le transfert a été effectué avec succès
    if (Test-Path $destinationPath) {
        Write-Host "La sauvegarde de la machine Linux a été transférée et stockée dans $backupPath avec succès." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors du transfert de la sauvegarde de la machine Linux." -ForegroundColor Red
    }
} else {
    Write-Host "Erreur lors de la création de la sauvegarde de la machine Linux." -ForegroundColor Red
}