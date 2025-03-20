# Définir les chemins de sauvegarde
$backupSource = "C:\Data"
$backupDrive = "S:"
$backupFolder = "sauvegarde_de_test"

# Vérifier si le dossier source existe
if (Test-Path $backupSource) {
    Write-Host "Démarrage de la sauvegarde du dossier $backupSource..." -ForegroundColor Yellow
    
    # Créer le chemin de sauvegarde complet
    $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
    
    # Exécuter la commande de sauvegarde
    wbadmin start backup -backupTarget:$backupPath -include:$backupSource -quiet
    
    # Vérifier si la sauvegarde a été créée avec succès
    if ($?) {
        Write-Host "La sauvegarde du dossier $backupSource a été lancée et stockée dans $backupPath avec succès." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors de la création de la sauvegarde du dossier $backupSource." -ForegroundColor Red
    }
} else {
    Write-Host "Le chemin d'accès $backupSource n'existe pas." -ForegroundColor Red
    exit
}