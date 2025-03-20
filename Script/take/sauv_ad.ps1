# Définir les informations du serveur distant et le disque de sauvegarde
$remoteServer = "SRV-DC01"  # Remplace par le nom ou l'adresse IP de ton serveur Active Directory
$backupDrive = "S:"

# Démarrage de la sauvegarde de l'Active Directory
Write-Host "Démarrage de la sauvegarde de l'Active Directory depuis le serveur $remoteServer..." -ForegroundColor Yellow

# Exécuter la commande de sauvegarde de l'état du système (incluant l'Active Directory) sur le serveur distant
Invoke-Command -ComputerName $remoteServer -ScriptBlock {
    param ($backupDrive)
    wbadmin start systemstatebackup -backupTarget:$backupDrive -quiet
} -ArgumentList $backupDrive

# Vérifier si la sauvegarde a été créée avec succès
if ($?) {
    # Renommer la sauvegarde pour l'appeler "sauvegarde_activedirectory"
    $backupPath = "$backupDrive\sauvegarde_activedirectory"
    Rename-Item -Path "$backupDrive\WindowsImageBackup" -NewName "sauvegarde_activedirectory"
    Write-Host "La sauvegarde de l'Active Directory a été lancée et renommée avec succès." -ForegroundColor Green
} else {
    Write-Host "Erreur lors de la création de la sauvegarde de l'Active Directory." -ForegroundColor Red
}