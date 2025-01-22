if ((Get-ComputerInfo).CsName -ne "SRV-DC01") {
    #Si le nom est différent, configurer le nom et redémarrer
    Rename-Computer -NewName "SRV-DC01" -Restart
} else {
    #Si non passer à la suite
    Write-Host "Le nom de la machine est déjà SRV-DC01. Aucune action requise."
}

#Appel du fichier Install-AD
& ".\Install-AD.ps1"

# Déclaration de la table de hachage pour les écoles et leurs nombres de classes
$Schools = @{
    "Simone Veil" = 17
    "Robert Badinter" = 13
    "Robert Debre" = 15
    "Louis Pasteur" = 15
    "Emile Zola" = 16
    "Louise Michel" = 15
    "Jules Ferry" = 20
}

# Parcours de la table de hachage pour créer les OUs
foreach ($School in $Schools.Keys) {
    $NumberOfClasses = $Schools[$School]
    Create-SchoolOrganizationalUnits -SchoolName $School -NumberOfClasses $NumberOfClasses
}

# Définir le chemin du dossier contenant les fichiers CSV
$CSVFolderPath = "Utilisateurs\Eleves\"

# Vérifier si le dossier existe
if (-not (Test-Path -Path $CSVFolderPath)) {
    Write-Warning "Le dossier $CSVFolderPath n'existe pas."
    return
}

# Récupérer tous les fichiers CSV dans le dossier
$CSVFiles = Get-ChildItem -Path $CSVFolderPath -Filter "*.csv"

# Vérifier s'il y a des fichiers à traiter
if ($CSVFiles.Count -eq 0) {
    Write-Warning "Aucun fichier CSV trouvé dans $CSVFolderPath."
    return
}

# Traiter chaque fichier CSV
foreach ($File in $CSVFiles) {
    Write-Host "Traitement du fichier : $($File.FullName)"

    try {
        # Extraire le nom de l'école à partir du nom du fichier (sans l'extension)
        # Exemple : Si le fichier s'appelle "Emile-Zola.csv", on obtient "Emile-Zola"
        $SchoolName = $File.BaseName -replace "-", " "

        if (-not $SchoolName) {
            Write-Warning "Impossible de déterminer le nom de l'école pour le fichier $($File.FullName)."
            continue
        }

        # Appeler la fonction pour traiter les utilisateurs dans le fichier CSV
        Create-Students -CSVPath $File.FullName -SchoolName $SchoolName
    } catch {
        Write-Warning "Erreur lors du traitement du fichier $($File.FullName) : $_"
    }
}

#Creation des enseignants
Create-Teachers -CSVPath "Utilisateurs\Enseignants\Enseignants.csv" 
