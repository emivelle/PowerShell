# D�finir les informations du domaine et les identifiants administratifs
$domain = "SimoneVeil.LOCAL"
$adminUser = "Administrateur"
$adminPassword = "Alpha00"

# Attendre quelques secondes pour permettre au serveur de red�marrer compl�tement
Start-Sleep -Seconds 30

# R�cup�rer les informations du syst�me de l'ordinateur
$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem

# V�rifier si l'ordinateur n'est pas d�j� membre du domaine
if (-not $ComputerInfo.PartOfDomain) {
    # Si l'ordinateur n'est pas membre du domaine, afficher un message et commencer l'ajout au domaine
    Write-Host "Ajout au domaine $domain en cours..." -ForegroundColor Yellow
    
    # Convertir le mot de passe en une cha�ne s�curis�e
    $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
    
    # Cr�er les informations d'identification pour l'ajout au domaine
    $credential = New-Object System.Management.Automation.PSCredential("$domain\$adminUser", $securePassword)
    
    # Ajouter l'ordinateur au domaine avec les informations d'identification fournies et forcer le red�marrage
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force
    
    # Afficher un message indiquant que l'ajout au domaine a r�ussi
    Write-Host "Ajout au domaine $domain r�ussi." -ForegroundColor Green
} else {
    # Si l'ordinateur est d�j� membre du domaine, afficher un message indiquant le domaine actuel
    Write-Host "Cette machine est d�j� membre du domaine $($ComputerInfo.Domain)." -ForegroundColor Green
}