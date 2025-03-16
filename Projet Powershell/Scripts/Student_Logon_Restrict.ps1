# Définition des horaires autorisés
$heure_min = 9
$heure_max = 16.5
$jours_autorises = @(1, 2, 3, 4, 5)  # Lundi (1) à Vendredi (5)

# Définition du groupe AD concerné
$groupe_ad = "grp_students"

# Obtenir l'utilisateur en cours
$utilisateur = $env:USERNAME
$jour_actuel = (Get-Date).DayOfWeek.value__
$heure_actuelle = (Get-Date).Hour

# Vérifier si l'utilisateur appartient au groupe AD
$est_dans_groupe = (Get-ADUser -Identity $utilisateur -Properties MemberOf).MemberOf -match $groupe_ad

if ($est_dans_groupe) {
    if (($jour_actuel -in $jours_autorises) -and ($heure_actuelle -ge $heure_min -and $heure_actuelle -lt $heure_max)) {
        # L'utilisateur est dans le bon créneau horaire, ne rien faire
        exit
    } else {
        # Hors des horaires autorisés, forcer la déconnexion
        Write-Host "Déconnexion de $utilisateur - Hors des horaires autorisés."
        Stop-Process -Name "explorer" -Force
        Start-Sleep -Seconds 2
        logoff
    }
}
