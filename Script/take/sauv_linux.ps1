# D�finir les informations de la machine Linux et le disque de sauvegarde
$linuxServer = "NomDuServeurLinux"  # Remplace par le nom ou l'adresse IP de ta machine Linux
$backupDrive = "S:"
$backupFolder = "sauv-linux"
$linuxBackupFile = "/tmp/backup_linux.tar.gz"  # Chemin temporaire de l'archive sur la machine Linux

# D�marrage de la sauvegarde de la machine Linux
Write-Host "D�marrage de la sauvegarde de la machine Linux depuis le serveur $linuxServer..." -ForegroundColor Yellow

# Ex�cuter la commande de sauvegarde sur la machine Linux
Invoke-Command -ComputerName $linuxServer -ScriptBlock {
    param ($linuxBackupFile)
    tar -cvzf $linuxBackupFile --exclude=/proc --exclude=/lost+found --exclude=/mnt --exclude=/sys --exclude=/boot /
} -ArgumentList $linuxBackupFile

# V�rifier si la sauvegarde a �t� cr��e avec succ�s
if ($?) {
    Write-Host "La sauvegarde de la machine Linux a �t� cr��e avec succ�s sur $linuxServer." -ForegroundColor Green
    
    # Transf�rer l'archive vers le serveur Windows Server Backup
    $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
    $destinationPath = "$backupPath\backup_linux.tar.gz"
    Copy-Item -Path "\\$linuxServer\$linuxBackupFile" -Destination $destinationPath
    
    # V�rifier si le transfert a �t� effectu� avec succ�s
    if (Test-Path $destinationPath) {
        Write-Host "La sauvegarde de la machine Linux a �t� transf�r�e et stock�e dans $backupPath avec succ�s." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors du transfert de la sauvegarde de la machine Linux." -ForegroundColor Red
    }
} else {
    Write-Host "Erreur lors de la cr�ation de la sauvegarde de la machine Linux." -ForegroundColor Red
}