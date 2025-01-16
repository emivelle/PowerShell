﻿# Définir le chemin racine pour l'OU Robert Debre
$RootOU = "OU=Robert Debre,DC=GRESIVAUDAN,DC=LOCAL"

# Création de l'OU Robert Debre
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Robert Debre'" -SearchBase "DC=GRESIVAUDAN,DC=LOCAL" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Robert Debre" -Path "DC=GRESIVAUDAN,DC=LOCAL"
    Write-Host "OU 'Robert Debre' créée."
} else {
    Write-Host "OU 'Robert Debre' existe déjà."
}

# Boucle pour créer les OUs des classes et leurs sous-OUs
for ($i = 1; $i -le 15; $i++) {
    $ClassOUName = "Classe$i"
    $ClassOUPath = "OU=$ClassOUName,$RootOU"

    # Création de l'OU ClasseX
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ClassOUName'" -SearchBase $RootOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ClassOUName -Path $RootOU
        Write-Host "OU '$ClassOUName' créée dans 'Robert Debre'."
    } else {
        Write-Host "OU '$ClassOUName' existe déjà."
    }

    # Création de l'OU Users dans ClasseX
    $UsersOUPath = "OU=Users,$ClassOUPath"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Users'" -SearchBase $ClassOUPath -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name "Users" -Path $ClassOUPath
        Write-Host "OU 'Users' créée dans '$ClassOUName'."
    }

    # Création de l'OU Computers dans ClasseX
    $ComputersOUPath = "OU=Computers,$ClassOUPath"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Computers'" -SearchBase $ClassOUPath -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name "Computers" -Path $ClassOUPath
        Write-Host "OU 'Computers' créée dans '$ClassOUName'."
    }

    # Création des sous-OUs Eleve et Enseignant dans Users
    foreach ($SubOU in "Eleve", "Enseignant") {
        $SubOUPath = "OU=$SubOU,$UsersOUPath"
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$SubOU'" -SearchBase $UsersOUPath -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $SubOU -Path $UsersOUPath
            Write-Host "OU '$SubOU' créée dans 'Users' de '$ClassOUName'."
        }
    }
}
