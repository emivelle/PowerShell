# Script Principal d'exécution du plan de sauvegarde

$folderScript = "C:\Script"
$folderData = "C:\Data"
$fileTest = "C:\Data\test.txt"

# Vérifier et créer le dossier Script
if (!(Test-Path -Path $folderScript)) {
    New-Item -ItemType Directory -Path $folderScript | Out-Null
    Write-Output "Le dossier 'Script' a été créé avec succès sous C:\."
} else {
    Write-Output "Le dossier 'Script' existe déjà sous C:\."
}

# Vérifier et créer le dossier Data
if (!(Test-Path -Path $folderData)) {
    New-Item -ItemType Directory -Path $folderData | Out-Null
    Write-Output "Le dossier 'Data' a été créé avec succès sous C:\."
} else {
    Write-Output "Le dossier 'Data' existe déjà sous C:\."
}

# Créer et écrire dans le fichier test.txt
"C'est un test" | Out-File -FilePath $fileTest -Encoding UTF8
Write-Output "Le fichier 'test.txt' a été créé dans C:\Data avec le contenu spécifié."

# Fonction pour exécuter un script et vérifier son succès
function Execute-Script {
    param (
        [string]$scriptPath,
        [string]$stepName
    )
    try {
        & $scriptPath
        Write-Output "L'étape '$stepName' a été exécutée avec succès."
    } catch {
        Write-Output "Erreur lors de l'exécution de l'étape '$stepName'."
        exit 1
    }
}

# Étape 1 : Vérification du disque
Execute-Script -scriptPath "C:\Script\Disk\Check_Disk.ps1" -stepName "Vérification du disque"

# Étape 2 : Modification du nom de la machine et redémarrage
Execute-Script -scriptPath "C:\Script\Info\Name.ps1" -stepName "Modification du nom de la machine et redémarrage"

# Étape 3 : Connexion au domaine Active Directory
Execute-Script -scriptPath "C:\Script\Info\Domaine.ps1" -stepName "Connexion au domaine Active Directory"

# Étape 4 : Installation de Windows Server Backup
Execute-Script -scriptPath "C:\Script\Sauv\Install_sauv.ps1" -stepName "Installation de Windows Server Backup"

# Étape 5 : Première sauvegarde de test
Execute-Script -scriptPath "C:\Script\take\sauv_test.ps1" -stepName "Première sauvegarde de test"

# Étape 6 : Sauvegarde de l'Active Directory
Execute-Script -scriptPath "C:\Script\take\sauv_ad.ps1" -stepName "Sauvegarde de l'Active Directory"

# Étape 7 : Sauvegarde du serveur d'impression
Execute-Script -scriptPath "C:\Script\take\sauv_impr.ps1" -stepName "Sauvegarde du serveur d'impression"

# Étape 8 : Sauvegarde de la machine Linux
Execute-Script -scriptPath "C:\Script\take\sauv_linux.ps1" -stepName "Sauvegarde de la machine Linux"

# Étape 9 : Sauvegarde des partages de fichiers critiques
Execute-Script -scriptPath "C:\Script\take\sauv_dfs.ps1" -stepName "Sauvegarde des partages de fichiers critiques"

# Étape 10 : Création des planifications de sauvegardes
Execute-Script -scriptPath "C:\Script\take\sauv_planif.ps1" -stepName "Création des planifications de sauvegardes"