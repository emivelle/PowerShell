# Définir le nouveau nom du serveur
$newServerName = "SRV-SAUV01"

# Récupérer le nom actuel de l'ordinateur
$computerName = $env:COMPUTERNAME

# Vérifier si le nom actuel de l'ordinateur est différent du nouveau nom
if ($computerName -ne $newServerName) {
    # Si le nom est différent, afficher un message et renommer l'ordinateur
    Write-Host "Renommage du serveur en $newServerName..." -ForegroundColor Yellow
    
    # Renommer l'ordinateur et forcer le redémarrage
    Rename-Computer -NewName $newServerName -Force -Restart
    
    # Afficher un message indiquant que le serveur a été renommé et redémarré
    Write-Host "Le serveur a été renommé en $newServerName. Redémarrage..." -ForegroundColor Green
    
    # Quitter le script pour permettre le redémarrage
    exit
} else {
    # Si le nom est déjà correct, afficher un message et passer à l'étape suivante
    Write-Host "Le serveur est déjà nommé $newServerName. Passons à l'étape suivante." -ForegroundColor Green
}