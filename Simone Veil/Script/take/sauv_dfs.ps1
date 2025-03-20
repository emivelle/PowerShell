# D�finir le nom du serveur source et du serveur de destination
$sourceServer = "SRV-sauv01"  # Serveur source
$sourceShare = "\\$sourceServer\PartageFichier"  # Partage SMB source

$destinationServer = "SRV-Sauv01"  # Serveur de destination
$destinationShare = "\\$destinationServer\sauvegarde"  # Partage SMB de destination

# V�rification de l'existence du partage source
Write-Host "Test d'acc�s au partage source $sourceShare..."
if (Test-Path $sourceShare) {
    Write-Host "Le partage source '$sourceShare' est accessible."
} else {
    Write-Host "Le partage source '$sourceShare' n'est pas accessible. V�rifiez la connectivit� et les droits d'acc�s."
    exit
}

# V�rification de l'existence du partage de destination
Write-Host "Test d'acc�s au partage de destination $destinationShare..."
if (Test-Path $destinationShare) {
    Write-Host "Le partage de destination '$destinationShare' est accessible."
} else {
    Write-Host "Le partage de destination '$destinationShare' n'est pas accessible. V�rifiez la connectivit� et les droits d'acc�s."
    exit
}

# V�rification de l'existence du dossier de sauvegarde sur le serveur de destination
$backupFolder = "$destinationShare\Backup"
if (-Not (Test-Path -Path $backupFolder)) {
    Write-Host "Le dossier de sauvegarde n'existe pas, cr�ation du dossier : $backupFolder"
    New-Item -Path $backupFolder -ItemType Directory
}

# Effectuer la sauvegarde des fichiers depuis le partage source vers le partage de destination
Write-Host "D�but de la sauvegarde des fichiers de '$sourceShare' vers '$backupFolder'..."
$copyResult = Copy-Item -Path "$sourceShare\*" -Destination $backupFolder -Recurse -Force

if ($copyResult) {
    Write-Host "Sauvegarde termin�e avec succ�s."
} else {
    Write-Host "Une erreur est survenue lors de la sauvegarde."
}

Write-Host "Processus de sauvegarde termin�."
