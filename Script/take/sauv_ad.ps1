# Demander les informations d'identification de l'administrateur
$adminCreds = Get-Credential -Message "Entrez les informations d'identification de l'administrateur"

# Nom du serveur à sauvegarder
$serverName = "SRV-DC01"

# Chemin de sauvegarde
$backupPath = "\\Srv-sauv01\s$\sauvegarde-ad"

# Activer PowerShell Remoting sur le serveur distant
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    Enable-PSRemoting -Force
}

# Ajouter le serveur distant aux hôtes de confiance
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $serverName

# Vérifier que le service WinRM est en cours d'exécution et le démarrer si nécessaire
Invoke-Command -ComputerName $serverName -Credential $adminCreds -ScriptBlock {
    if ((Get-Service WinRM).Status -ne 'Running') {
        Start-Service WinRM
    }
}

# Créer une session PowerShell avec les informations d'identification administratives
$session = New-PSSession -ComputerName $serverName -Credential $adminCreds

# Exécuter la commande de sauvegarde dans cette session
Invoke-Command -Session $session -ScriptBlock {
    param ($backupPath)
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory
    }
    wbadmin start systemstatebackup -backupTarget:$backupPath -quiet
} -ArgumentList $backupPath