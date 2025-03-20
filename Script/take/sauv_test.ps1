# Définir les chemins de sauvegarde
$backupSource = "C:\Data"
$backupDrive = "\\Srv-sauv01\s$"
$backupFolder = "sauvegarde_de_test_"

# Créer le chemin de sauvegarde complet
$backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder

# Vérifier si le dossier de sauvegarde existe, sinon le créer
if (-Not (Test-Path $backupPath)) {
    Write-Host "Le chemin de sauvegarde $backupPath n'existe pas. Création du dossier..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory
}

# Vérifier si le dossier source existe
if (Test-Path $backupSource) {
    Write-Host "Démarrage de la sauvegarde du dossier $backupSource..." -ForegroundColor Yellow
    
    # Vérifier les permissions d'accès au dossier de sauvegarde
    try {
        $acl = Get-Acl $backupPath
        Write-Host "Permissions vérifiées pour $backupPath." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la vérification des permissions pour $backupPath." -ForegroundColor Red
        exit
    }
    
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