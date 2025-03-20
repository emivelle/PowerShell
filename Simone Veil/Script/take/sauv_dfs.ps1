# Définir le nom du serveur source et du serveur de destination
$sourceServer = "SRV-sauv01"  # Serveur source
$sourceShare = "\\$sourceServer\PartageFichier"  # Partage SMB source

$destinationServer = "SRV-Sauv01"  # Serveur de destination
$destinationShare = "\\$destinationServer\sauvegarde"  # Partage SMB de destination

# Vérification de l'existence du partage source
Write-Host "Test d'accès au partage source $sourceShare..."
if (Test-Path $sourceShare) {
    Write-Host "Le partage source '$sourceShare' est accessible."
} else {
    Write-Host "Le partage source '$sourceShare' n'est pas accessible. Vérifiez la connectivité et les droits d'accès."
    exit
}

# Vérification de l'existence du partage de destination
Write-Host "Test d'accès au partage de destination $destinationShare..."
if (Test-Path $destinationShare) {
    Write-Host "Le partage de destination '$destinationShare' est accessible."
} else {
    Write-Host "Le partage de destination '$destinationShare' n'est pas accessible. Vérifiez la connectivité et les droits d'accès."
    exit
}

# Vérification de l'existence du dossier de sauvegarde sur le serveur de destination
$backupFolder = "$destinationShare\Backup"
if (-Not (Test-Path -Path $backupFolder)) {
    Write-Host "Le dossier de sauvegarde n'existe pas, création du dossier : $backupFolder"
    New-Item -Path $backupFolder -ItemType Directory
}

# Effectuer la sauvegarde des fichiers depuis le partage source vers le partage de destination
Write-Host "Début de la sauvegarde des fichiers de '$sourceShare' vers '$backupFolder'..."
$copyResult = Copy-Item -Path "$sourceShare\*" -Destination $backupFolder -Recurse -Force

if ($copyResult) {
    Write-Host "Sauvegarde terminée avec succès."
} else {
    Write-Host "Une erreur est survenue lors de la sauvegarde."
}

Write-Host "Processus de sauvegarde terminé."
