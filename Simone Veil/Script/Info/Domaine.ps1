# Définir les informations du domaine et les identifiants administratifs
$domain = "SimoneVeil.LOCAL"
$adminUser = "Administrateur"
$adminPassword = "Alpha00"

# Attendre quelques secondes pour permettre au serveur de redémarrer complètement
Start-Sleep -Seconds 30

# Récupérer les informations du système de l'ordinateur
$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem

# Vérifier si l'ordinateur n'est pas déjà membre du domaine
if (-not $ComputerInfo.PartOfDomain) {
    # Si l'ordinateur n'est pas membre du domaine, afficher un message et commencer l'ajout au domaine
    Write-Host "Ajout au domaine $domain en cours..." -ForegroundColor Yellow
    
    # Convertir le mot de passe en une chaîne sécurisée
    $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
    
    # Créer les informations d'identification pour l'ajout au domaine
    $credential = New-Object System.Management.Automation.PSCredential("$domain\$adminUser", $securePassword)
    
    # Ajouter l'ordinateur au domaine avec les informations d'identification fournies et forcer le redémarrage
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force
    
    # Afficher un message indiquant que l'ajout au domaine a réussi
    Write-Host "Ajout au domaine $domain réussi." -ForegroundColor Green
} else {
    # Si l'ordinateur est déjà membre du domaine, afficher un message indiquant le domaine actuel
    Write-Host "Cette machine est déjà membre du domaine $($ComputerInfo.Domain)." -ForegroundColor Green
}