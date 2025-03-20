function Install-AD {
    param (
        [parameter(Mandatory=$true)]
        [string]$DomainNETBIOS
    )

    #Installer la fonctionnalité AD DS
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    #Importer le module de déploiement
    Import-Module ADDSDeployment

    #Créer une nouvelle forêt
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "WinThreshold" `
        -DomainName "$DomainNETBIOS.LOCAL" `
        -DomainNetbiosName $DomainNETBIOS `
        -ForestMode "WinThreshold" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true

    #Voir les rédirecteurs du serveur DNS
    Get-DnsServerForwarder

    #Ajouter des redirecteurs au serveur DNS
    Add-DnsServerForwarder -IPAddress 8.8.8.8

    #Ajouter une zone DNS principale
    Add-DnsServerPrimaryZone -Name "$DomainNETBIOS.LOCAL" -ZoneFile "$DomainNETBIOS.LOCAL.dns" -DynamicUpdate Secure

    #Ajouter une zone de recherche inversée
    Add-DnsServerPrimaryZone -NetworkID "192.168.133.0/24" -ZoneFile "133.168.192.in-addr.arpa.dns"

    Restart-Computer -Force

    Start-Sleep 120
}
