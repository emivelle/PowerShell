function Create-Teachers {
    param (
        [parameter(Mandatory=$true)]
        [string]$CSVPath, # Chemin vers le fichier CSV
        [parameter(Mandatory=$true)]
        [string]$Domain,        
        [parameter(Mandatory=$true)]
        [string]$TargetSchool # École ciblée
    )

    # Creation du groupe de sécurité
    New-ADGroup -Name "grp_directeurs" `
                -GroupScope Global `
                -GroupCategory Security `
                -Description "Groupe de sécurité pour les directeurs"

    # Creation du groupe de sécurité
    New-ADGroup -Name "grp_enseignants" `
                -GroupScope Global `
                -GroupCategory Security `
                -Description "Groupe de sécurité pour les enseignants"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $CSVPath)) {
        Write-Warning "Le fichier $CSVPath n'existe pas."
        return
    }

    # Importer le fichier CSV avec normalisation des colonnes
    $Teachers = try {
        Import-Csv -Path $CSVPath -Delimiter ';' | ForEach-Object {
            $NormalizedObject = @{}
            foreach ($Property in $_.PSObject.Properties) {
                $NormalizedObject[$Property.Name.ToLower()] = $Property.Value
            }
            [PSCustomObject]$NormalizedObject
        }
    } catch {
        Write-Warning "Impossible d'importer le fichier CSV $CSVPath : $_"
        return
    }

    # Vérifier si des données ont été importées
    if (-not $Teachers) {
        Write-Warning "Aucune donnée trouvée dans le fichier CSV $CSVPath."
        return
    }
    
    $NameCounter = @{}

    foreach ($Teacher in $Teachers) {
        # Vérifier si l'enseignant appartient bien à l'école ciblée
        $TeacherSchool = $Teacher.ecole -replace "[éèêë]", "e" -replace "[àâä]", "a" -replace "[ôö]", "o" -replace "[ùûü]", "u" -replace "[îï]", "i"
        if ($TeacherSchool -ne $TargetSchool) {
            Write-Host "L'enseignant $($Teacher.prenom) $($Teacher.nom) n'appartient pas à l'école $TargetSchool. Ignoré."
            continue
        }

        # Formatage du prénom et du nom
        $LastName = $Teacher.nom.ToUpper()
        $FirstName = $Teacher.prenom.Substring(0, 1).ToUpper() + $Teacher.prenom.Substring(1).ToLower()
        $Class = $Teacher.classe.Replace(" ", "")

        # Construire l'OU cible
        $TargetOU = "OU=Enseignant,OU=Users,OU=$Class,OU=$TargetSchool,$Domain"

        # Vérifier si l'OU existe
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$TargetOU'" -ErrorAction SilentlyContinue)) {
            Write-Warning "L'OU cible '$TargetOU' n'existe pas. L'utilisateur $FirstName $LastName ne sera pas créé."
            continue
        }

        $UserCount = 0
        do { 
            # Construction du SamAccountName
            $UserSamAccountName = if ($UserCount -eq 0) {
                "$($FirstName.Replace(' ','').ToLower())$($LastName.Substring(0,1).ToLower())"
            } else {
                "$($FirstName.Replace(' ','').ToLower())$($LastName.Substring(0,1).ToLower())$UserCount"
            }
                
            # Vérifier si l'utilisateur existe déjà
            $ExistingUser = Get-ADUser -Filter {SamAccountName -eq $UserSamAccountName} -ErrorAction SilentlyContinue

            if($ExistingUser) {
                $UserCount++
            } else {
                Write-Warning "L'utilisateur $FirstName $LastName existe, son SamAccountName sera $UserSamAccountName. Le compteur est à $UserCount"
            }
        } while ($ExistingUser)

        # Générer le mot de passe
        $FormattedSchoolName = $TargetSchool.Substring(0,1).ToUpper() + $TargetSchool.Substring(1).Replace(" ", "")
        $Password = "Teacher$FormattedSchoolName$($Class.Substring(6))!" # Extrait le numéro de classe

        # Créer l'utilisateur
        try {
            New-ADUser -Name "$FirstName $LastName" `
                       -GivenName $FirstName `
                       -Surname $LastName `
                       -SamAccountName $UserSamAccountName `
                       -UserPrincipalName "$UserSamAccountName@$Domain" `
                       -Path $TargetOU `
                       -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                       -ChangePasswordAtLogon $true `
                       -Enabled $true

            Add-ADGroupMember -Identity "grp_enseignants" -Members $UserSamAccountName

            Write-Host "Utilisateur $FirstName $LastName créé avec succès dans '$TargetOU'. Mot de passe : $Password. L'utilisateur a été ajouté dans le groupe grp_enseignants"
        } catch {
            Write-Warning "Erreur lors de la création de l'utilisateur $FirstName $LastName : $_"
        }
    }
}
