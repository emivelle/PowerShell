function PasswordPolicy {
    param (
        [parameter(Mandatory=$true)]
        [string]$DomainNETBIOS
    )


    # Politique pour les utilisateurs normaux
    Write-Host "Application de la politique de mot de passe pour les utilisateurs normaux..."
    Set-ADDefaultDomainPasswordPolicy -Identity "$DomainNETBIOS.LOCAL" `
        -MinPasswordLength 10 `
        -ComplexityEnabled $true `
        -PasswordHistoryCount 24 `
        -ReversibleEncryptionEnabled $false `
        -LockoutThreshold 5 `
        -LockoutDuration "00:30:00" `
        -LockoutObservationWindow "00:30:00" `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "45.00:00:00"

    # Activation du mode d'approbation administrateur dans l'UAC pour renforcer la sécurité
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 1 /f

    # Création d'une politique de mot de passe fine pour les administrateurs
    Write-Host "Application de la politique de mot de passe pour les administrateurs..."
    New-ADFineGrainedPasswordPolicy -Name "AdminPasswordPolicy" `
        -Precedence 1 `
        -MinPasswordLength 16 `
        -ComplexityEnabled $true `
        -PasswordHistoryCount 24 `
        -ReversibleEncryptionEnabled $false `
        -LockoutThreshold 5 `
        -LockoutDuration "00:30:00" `
        -LockoutObservationWindow "00:30:00" `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "30.00:00:00"

    # Application de la politique fine aux administrateurs
    Add-ADFineGrainedPasswordPolicySubject -Identity "AdminPasswordPolicy" -Subjects "Admins du domaine"
    
    Write-Host "Configuration des politiques de mot de passe terminée."
}
