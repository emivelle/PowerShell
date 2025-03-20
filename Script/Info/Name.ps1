# D�finir le nouveau nom du serveur
$newServerName = "SRV-SAUV01"

# R�cup�rer le nom actuel de l'ordinateur
$computerName = $env:COMPUTERNAME

# V�rifier si le nom actuel de l'ordinateur est diff�rent du nouveau nom
if ($computerName -ne $newServerName) {
    # Si le nom est diff�rent, afficher un message et renommer l'ordinateur
    Write-Host "Renommage du serveur en $newServerName..." -ForegroundColor Yellow
    
    # Renommer l'ordinateur et forcer le red�marrage
    Rename-Computer -NewName $newServerName -Force -Restart
    
    # Afficher un message indiquant que le serveur a �t� renomm� et red�marr�
    Write-Host "Le serveur a �t� renomm� en $newServerName. Red�marrage..." -ForegroundColor Green
    
    # Quitter le script pour permettre le red�marrage
    exit
} else {
    # Si le nom est d�j� correct, afficher un message et passer � l'�tape suivante
    Write-Host "Le serveur est d�j� nomm� $newServerName. Passons � l'�tape suivante." -ForegroundColor Green
}