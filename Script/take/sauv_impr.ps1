# Définir les informations du serveur distant et le disque de sauvegarde
$printServer = "NomDuServeurDImpression"  # Remplace par le nom ou l'adresse IP de ton serveur d'impression
$backupDrive = "S:"
$backupFolder = "sauv-impr"

# Vérifier la connectivité avec le serveur d'impression
if (Test-Connection -ComputerName $printServer -Quiet) {
    Write-Host "Démarrage de la sauvegarde du serveur d'impression $printServer..." -ForegroundColor Yellow
    
    # Exécuter la commande de sauvegarde sur le serveur distant
    Invoke-Command -ComputerName $printServer -ScriptBlock {
        param ($backupDrive, $backupFolder)
        $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
        wbadmin start backup -backupTarget:$backupPath -include:"C:\CheminDuServeurDImpression" -quiet
    } -ArgumentList $backupDrive, $backupFolder

    # Vérifier si la sauvegarde a été créée avec succès
    if ($?) {
        Write-Host "La sauvegarde du serveur d'impression $printServer a été lancée et stockée dans $backupDrive\$backupFolder avec succès." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors de la création de la sauvegarde du serveur d'impression." -ForegroundColor Red
    }
} else {
    Write-Host "Le serveur d'impression $printServer n'est pas joignable." -ForegroundColor Red
    exit
}