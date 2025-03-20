# D�finir les informations du serveur distant et le disque de sauvegarde
$printServer = "NomDuServeurDImpression"  # Remplace par le nom ou l'adresse IP de ton serveur d'impression
$backupDrive = "S:"
$backupFolder = "sauv-impr"

# V�rifier la connectivit� avec le serveur d'impression
if (Test-Connection -ComputerName $printServer -Quiet) {
    Write-Host "D�marrage de la sauvegarde du serveur d'impression $printServer..." -ForegroundColor Yellow
    
    # Ex�cuter la commande de sauvegarde sur le serveur distant
    Invoke-Command -ComputerName $printServer -ScriptBlock {
        param ($backupDrive, $backupFolder)
        $backupPath = Join-Path -Path $backupDrive -ChildPath $backupFolder
        wbadmin start backup -backupTarget:$backupPath -include:"C:\CheminDuServeurDImpression" -quiet
    } -ArgumentList $backupDrive, $backupFolder

    # V�rifier si la sauvegarde a �t� cr��e avec succ�s
    if ($?) {
        Write-Host "La sauvegarde du serveur d'impression $printServer a �t� lanc�e et stock�e dans $backupDrive\$backupFolder avec succ�s." -ForegroundColor Green
    } else {
        Write-Host "Erreur lors de la cr�ation de la sauvegarde du serveur d'impression." -ForegroundColor Red
    }
} else {
    Write-Host "Le serveur d'impression $printServer n'est pas joignable." -ForegroundColor Red
    exit
}