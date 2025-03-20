# D�finir les informations du serveur distant et le disque de sauvegarde
$remoteServer = "SRV-DC01"  # Remplace par le nom ou l'adresse IP de ton serveur Active Directory
$backupDrive = "S:"

# D�marrage de la sauvegarde de l'Active Directory
Write-Host "D�marrage de la sauvegarde de l'Active Directory depuis le serveur $remoteServer..." -ForegroundColor Yellow

# Ex�cuter la commande de sauvegarde de l'�tat du syst�me (incluant l'Active Directory) sur le serveur distant
Invoke-Command -ComputerName $remoteServer -ScriptBlock {
    param ($backupDrive)
    wbadmin start systemstatebackup -backupTarget:$backupDrive -quiet
} -ArgumentList $backupDrive

# V�rifier si la sauvegarde a �t� cr��e avec succ�s
if ($?) {
    # Renommer la sauvegarde pour l'appeler "sauvegarde_activedirectory"
    $backupPath = "$backupDrive\sauvegarde_activedirectory"
    Rename-Item -Path "$backupDrive\WindowsImageBackup" -NewName "sauvegarde_activedirectory"
    Write-Host "La sauvegarde de l'Active Directory a �t� lanc�e et renomm�e avec succ�s." -ForegroundColor Green
} else {
    Write-Host "Erreur lors de la cr�ation de la sauvegarde de l'Active Directory." -ForegroundColor Red
}