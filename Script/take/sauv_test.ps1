# D�finir les chemins de sauvegarde
$backupSource = "C:\Data"
$backupDrive = "S:"
$backupFolder = "sauvegarde_de_test"

# V�rifier si le dossier source existe
if (Test-Path $backupSource) {
    Write-Host "D�marrage de la sauvegarde du dossier $backupSource..." -ForegroundColor Yellow
    
    # Cr�er le chemin de sauvegarde complet
    $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
    
    # Ex�cuter la commande de sauvegarde
    wbadmin start backup -backupTarget:$backupPath -include:$backupSource -quiet
    
    # V�rifier si la sauvegarde a �t� cr��e avec succ�s
    if ($?) {
        Write-Host "La sauvegarde du dossier $backupSource a �t� lanc�e et stock�e dans $backupPath avec succ�s." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors de la cr�ation de la sauvegarde du dossier $backupSource." -ForegroundColor Red
    }
} else {
    Write-Host "Le chemin d'acc�s $backupSource n'existe pas." -ForegroundColor Red
    exit
}