# D�finir les chemins de sauvegarde
$backupSource = "C:\Data"
$backupDrive = "\\Srv-sauv01\s$"
$backupFolder = "sauvegarde_de_test_"

# Cr�er le chemin de sauvegarde complet
$backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder

# V�rifier si le dossier de sauvegarde existe, sinon le cr�er
if (-Not (Test-Path $backupPath)) {
    Write-Host "Le chemin de sauvegarde $backupPath n'existe pas. Cr�ation du dossier..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory
}

# V�rifier si le dossier source existe
if (Test-Path $backupSource) {
    Write-Host "D�marrage de la sauvegarde du dossier $backupSource..." -ForegroundColor Yellow
    
    # V�rifier les permissions d'acc�s au dossier de sauvegarde
    try {
        $acl = Get-Acl $backupPath
        Write-Host "Permissions v�rifi�es pour $backupPath." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la v�rification des permissions pour $backupPath." -ForegroundColor Red
        exit
    }
    
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