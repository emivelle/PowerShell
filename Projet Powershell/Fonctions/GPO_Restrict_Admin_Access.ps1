Function GPO_Restrict_Admin_Access {
    param (
        [parameter(Mandatory=$true)]
        [string]$DomainNETBIOS
    )

    # Définition des variables
    $GPOName = "Restriction_Acces_Administrateurs"
    $GroupeEleves = "grp_eleves"
    $GroupeAdminsAutorises = "Admins du domaine"
    $ServeurDC = "SRV-DC01"


    # Creation de la GPO
    New-GPO -Name $GPOName | New-GPLink -Target "DC=$DomainNETBIOS,DC=LOCAL" | Set-GPPermissions -PermissionLevel GpoApply -TargetName "grp_eleves" -TargetType Group
    Set-GPPermission -Name $GPOName -PermissionLevel None -TargetName "Utilisateurs authentifiés" -TargetType Group
    Set-GPPermission -Name $GPOName -PermissionLevel GpoRead -TargetName "Utilisateurs authentifiés" -TargetType Group


    # Restreindre les membres du groupe Administrateurs locaux via une règle de stratégie
    Write-Host "Modification des membres du groupe Administrateurs locaux..."
$SecTemplate = @"
[Unicode]
Unicode=yes
[Version]
signature="\$CHICAGO\$"
Revision=1
[Group Membership]
Administrateurs = $GroupeAdminsAutorises
"@

    # Définition du chemin de la stratégie de groupe sur le serveur DC
    $GPOPath = "\\$ServeurDC\SYSVOL\$DomainNETBIOS.local\Policies\{$($GPO.Id)}\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

    # Appliquer le modèle de sécurité
    Write-Host "Application des modifications de la stratégie..."
    Set-Content -Path $GPOPath -Value $SecTemplate

}

