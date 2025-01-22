#Installer la fonctionnalité AD DS
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

#Importer le module de déploiement
Import-Module ADDSDeployment

#Créer une nouvelle forêt
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "GRESIVAUDAN.LOCAL" `
    -DomainNetbiosName "GRESIVAUDAN" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

#Voir les rédirecteurs du serveur DNS
Get-DnsServerForwarder

#Ajouter un redirecteur au serveur DNS, Exemple avec le DNS de CloudFare
Add-DnsServerForwarder -IPAddress 8.8.8.8