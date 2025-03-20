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

    # Création de la GPO
    $GPO = New-GPO -Name $GPOName
    New-GPLink -Name $GPOName -Target "DC=$DomainNETBIOS,DC=LOCAL" 
    Set-GPPermission -Name $GPOName -PermissionLevel GpoApply -TargetName "grp_eleves" -TargetType Group
    Set-GPPermissions -Name $GPOName -PermissionLevel None -TargetName "Utilisateurs authentifiés" -TargetType Group
    Set-GPPermissions -Name $GPOName -PermissionLevel GpoRead -TargetName "Utilisateurs authentifiés" -TargetType Group

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
    $GPOPath = "\\$ServeurDC\SYSVOL\$DomainNETBIOS.LOCAL\Policies\{$($GPO.ID)}\Machine\Microsoft\Windows NT\SecEdit"

    if (!(Test-Path $GPOPath)) {
        New-Item -ItemType Directory -Path $GPOPath -Force
    }

    $GPOFile = "$GPOPath\GptTmpl.inf"
    Set-Content -Path $GPOFile -Value $SecTemplate -Force

}
