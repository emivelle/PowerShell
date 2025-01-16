if ((Get-ComputerInfo).CsName -ne "SRV-DC01") {
    #Si le nom est différent, configurer le nom est redémarrer
    Rename-Computer -NewName "SRV-DC01" -Restart
} else {
    #Si non passer à la suite
    Write-Host "Le nom de la machine est déjà SRV-DC01. Aucune action requise."
}

#Appel du fichier Install-AD
& ".\Install-AD.ps1"

#Appel des fichiers d'installation des OUs
& ".\OU-Jules-Ferry.ps1"
& ".\OU-Simone-Veil.ps1"
& ".\OU-Robert-Badinter.ps1"
& ".\OU-Robert-Debre.ps1"
& ".\OU-Louis-Pasteur.ps1"
& ".\OU-Emile-Zola.ps1"
& ".\OU-Louise-Michel.ps1"