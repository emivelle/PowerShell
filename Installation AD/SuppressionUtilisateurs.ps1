# Spécifiez le chemin de l'OU principale
$BaseOU = "OU=MonOU,DC=GRESIVAUDAN,DC=local"

# Récupère les utilisateurs jusqu'à 4 niveaux de profondeur
$Users = Get-ADUser -Filter * -SearchBase $BaseOU -SearchScope Subtree -Properties DistinguishedName

# Supprime chaque utilisateur trouvé
foreach ($User in $Users) {
    try {
        Remove-ADUser -Identity $User.DistinguishedName -Confirm:$false
        Write-Host "Utilisateur supprimé : $($User.SamAccountName)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la suppression de l'utilisateur $($User.SamAccountName) : $_" -ForegroundColor Red
    }
}