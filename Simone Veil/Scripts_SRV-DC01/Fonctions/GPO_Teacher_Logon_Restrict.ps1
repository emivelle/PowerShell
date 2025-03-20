Function GPO_Teacher_Logon_Restrict {
    param (
        [parameter(Mandatory=$true)]
        [string]$DomainNETBIOS
    )

    Copy-Item -Path ".\Scripts\Teacher_Logon_Restrict.ps1" -Destination "\\srv-dc01\SYSVOL\$DomainNETBIOS.LOCAL\scripts\Teacher_Logon_Restrict.ps1"


    # Définition des variables
    $GPOName = "Teacher_Logon_Restrict"
    $GroupeEnseignants = "grp_enseignants"
    $Script = "\\srv-dc01\sysvol\$DomainNETBIOS.local\scripts\Teacher_Logon_Restrict.ps1"

    # Creation de la GPO
    New-GPO -Name $GPOName | New-GPLink -Target "DC=$DomainNETBIOS,DC=LOCAL" | Set-GPPermissions -PermissionLevel GpoApply -TargetName "grp_enseignants" -TargetType Group
    Set-GPPermission -Name $GPOName -PermissionLevel None -TargetName "Utilisateurs authentifiés" -TargetType Group
    Set-GPPermission -Name $GPOName -PermissionLevel GpoRead -TargetName "Utilisateurs authentifiés" -TargetType Group

    # Configuration de la GPO
    Set-GPRegistryValue -Name $GPOName `
        -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "LogonScript" `
        -Type String `
        -Value $Script

}