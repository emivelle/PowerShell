if ((Get-ComputerInfo).CsName -ne "SRV-DC01") {
    # Si le nom est différent, configurer le nom et redémarrer
    Rename-Computer -NewName "SRV-DC01" -Restart -Force
} else {
    # Si non, passer à la suite
    Write-Host "Le nom de la machine est déjà SRV-DC01. Aucune action requise."
}

# Déclaration de l'école unique, du nombre de classes et du domaine
$SchoolName = "Simone Veil"
$NumberOfClasses = 17
$Domain = "DC=$SchoolName,DC=LOCAL"

# Appel du fichier Install-AD
Import-Module .\Fonctions\Install-AD.ps1
Install-AD -DomainNETBIOS $SchoolName

# Importation du module et création des OUs pour l'école unique
Import-Module .\Fonctions\Create-SchoolOrganizationalUnits.ps1
Create-SchoolOrganizationalUnits -SchoolName $SchoolName -Domain $Domain -NumberOfClasses $NumberOfClasses

# Définir le chemin du fichier CSV unique des élèves
$CSVPath = "Utilisateurs\Eleves\Simone-Veil.csv"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $CSVPath)) {
    Write-Warning "Le fichier CSV des élèves n'existe pas : $CSVPath."
    return
}

# Traitement du fichier CSV des élèves
Write-Host "Traitement du fichier : $CSVPath"

try {
    # Importation du module et création des utilisateurs élèves
    Import-Module .\Fonctions\Create-Students.ps1
    Create-Students -CSVPath $CSVPath -Domain $Domain -SchoolName $SchoolName
} catch {
    Write-Warning "Erreur lors du traitement du fichier des élèves : $_"
}

$CSVPath = "Utilisateurs\Enseignants\Enseignants.csv"

# Création des enseignants
Import-Module .\Fonctions\Create-Teachers.ps1
Create-Teachers -CSVPath $CSVPath -Domain $Domain -TargetSchool $SchoolName

# Mise en place de politique de mot de passe
Import-Module .\Fonctions\PasswordPolicy.ps1
PasswordPolicy -DomainNETBIOS $SchoolName




#############################################################################################
#                                    Application des GPO                                    #
#############################################################################################


# Mise en place de la restrictions d'installation de logiciel pour les eleves
Import-Module .\Fonctions\GPO_Restrict_Admin_Access.ps1
GPO_Restrict_Admin_Access -DomainNETBIOS $SchoolName

Import-Module .\Fonctions\GPO_Teacher_Logon_Restrict.ps1
GPO_Teacher_Logon_Restrict -DomainNETBIOS $SchoolName

Import-Module .\Fonctions\GPO_Student_Logon_Restrict.ps1
GPO_Student_Logon_Restrict -DomainNETBIOS $SchoolName


