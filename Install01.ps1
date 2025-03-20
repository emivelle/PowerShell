# Vérifier si l'ISO des Guest Additions est montée (disons sous D:\)
$isoPath = "D:\VBoxWindowsAdditions.exe"

# Vérifiez si le fichier existe avant d'essayer de l'exécuter
if (Test-Path $isoPath) {
    Write-Host "Installation des Guest Additions en cours..."

    # Exécution de l'installateur
    Start-Process -FilePath $isoPath -ArgumentList "/S" -Wait

    Write-Host "Installation terminée."
    
    # Redémarrer la machine virtuelle si nécessaire
    Restart-Computer -Force
} else {
    Write-Host "Impossible de trouver l'ISO des Guest Additions. Assurez-vous que l'ISO est monté sur le lecteur D:."
}

# --- Activer les connexions RDP ---
Write-Host "Activation des connexions RDP..."
$rdpRegKey = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
$rdpValue = "fDenyTSConnections"

# Autoriser les connexions RDP
Set-ItemProperty -Path $rdpRegKey -Name $rdpValue -Value 0

# Activer le service de bureau à distance (RDP)
Enable-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)"
Enable-NetFirewallRule -DisplayName "Remote Desktop - User Mode (UDP-In)"

Write-Host "RDP activé avec succès."

# --- Activer WINRM ---
Write-Host "Activation de WINRM..."
# Activer WINRM
Enable-PSRemoting -Force

# Configurer WINRM pour accepter les connexions depuis n'importe quelle machine
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Activer le pare-feu pour WINRM
Enable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"

Write-Host "WINRM activé avec succès."

# --- Activer les mises à jour automatiques ---
Write-Host "Activation des mises à jour automatiques..."

# Activer les services de mises à jour automatiques
Set-Service -Name wuauserv -StartupType Automatic
Start-Service -Name wuauserv

Write-Host "Mises à jour automatiques activées."

# --- Autres configurations de base ---

# Activer la fonctionnalité de partage de fichiers
Write-Host "Activation du partage de fichiers..."
Set-NetFirewallRule -DisplayName "File and Printer Sharing" -Enabled True

# Activer la protection du pare-feu pour les réseaux privés et publics
Write-Host "Activation de la protection du pare-feu..."
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True

Write-Host "Configuration terminée avec succès."
