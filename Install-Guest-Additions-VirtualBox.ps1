# Vérifier si l'ISO des Guest Additions est montée (disons sous D:\)
$isoPath = "D:\VBoxWindowsAdditions.exe"

# Vérifiez si le fichier existe avant d'essayer de l'exécuter
if (Test-Path $isoPath) {
    Write-Host "Installation des Guest Additions en cours..."

    # Exécution de l'installateur
    Start-Process -FilePath $isoPath -ArgumentList "/S" -Wait

    Write-Host "Installation terminée,"
    
    # Redémarrer la machine virtuelle si nécessaire
    Restart-Computer -Force
} else {
    Write-Host "Impossible de trouver l'ISO des Guest Additions. Assurez-vous que l'ISO est monté sur le lecteur D:."
}