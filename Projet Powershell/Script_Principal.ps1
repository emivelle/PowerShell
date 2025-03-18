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
$DomainName = $SchoolName.Replace(" ","")
$Domain = "DC=$DomainName,DC=LOCAL"

# Vérifier si Active Directory est déjà installé
if (Get-WindowsFeature -Name AD-Domain-Services | Where-Object { $_.Installed }) {
    Write-Host "Active Directory est déjà installé. Passage à l'étape suivante..." -ForegroundColor Yellow
} else {
    # Importer et exécuter l'installation d'AD
    Import-Module .\Fonctions\Install-AD.ps1
    Install-AD -DomainNETBIOS $DomainName
}


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
PasswordPolicy -DomainNETBIOS $DomainName

# Déclaration de l'école unique, du nombre de classes et du domaine
$SchoolName = "Simone Veil"
$NumberOfClasses = 17
$DomainName = $SchoolName.Replace(" ","")
$Domain = "DC=$DomainName,DC=LOCAL"


#############################################################################################
#                                    Application des GPO                                    #
#############################################################################################


# Mise en place de la restrictions d'installation de logiciel pour les eleves
Import-Module .\Fonctions\GPO_Restrict_Admin_Access.ps1
GPO_Restrict_Admin_Access -DomainNETBIOS $DomainName

Import-Module .\Fonctions\GPO_Teacher_Logon_Restrict.ps1
GPO_Teacher_Logon_Restrict -DomainNETBIOS $DomainName

Import-Module .\Fonctions\GPO_Student_Logon_Restrict.ps1
GPO_Student_Logon_Restrict -DomainNETBIOS $DomainName


