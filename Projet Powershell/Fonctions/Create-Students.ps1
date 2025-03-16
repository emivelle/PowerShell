function Create-Students {
    param (
        [parameter(Mandatory=$true)]
        [string]$CSVPath, # Chemin vers le fichier CSV
        [parameter(Mandatory=$true)]
        [string]$SchoolName, # Nom de l'école pour l'OU racine
        [parameter(Mandatory=$true)]
        [string]$Domain
    )

    # Creation du groupe de sécurité
    New-ADGroup -Name "grp_eleves" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=Users,$Domain" `
                -Description "Groupe de sécurité pour les eleves"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $CSVPath)) {
        Write-Warning "Le fichier $CSVPath n'existe pas."
        return
    }

    # Importer le fichier CSV avec détection du délimiteur et normalisation des colonnes
    $Students = try {
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
    if (-not $Students) {
        Write-Warning "Aucune donnée trouvée dans le fichier CSV $CSVPath."
        return
    }

    $NameCounter = @{}

    foreach ($Student in $Students) {
        # Formatage du prénom et du nom
        $LastName = $Student.nom.ToUpper()
        $FirstName = $Student.prenom.Substring(0, 1).ToUpper() + $Student.prenom.Substring(1).ToLower()
        $Class = $Student.classe.Replace(" ","")

        # Construire l'OU cible
        $TargetOU = "OU=Eleve,OU=Users,OU=$Class,OU=$SchoolName,$Domain"

        # Vérifier si l'OU existe
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$TargetOU'" -ErrorAction SilentlyContinue)) {
            Write-Warning "L'OU cible '$TargetOU' n'existe pas. L'utilisateur $FirstName $LastName ne sera pas créé."
            continue
        }

        $UserCount = 0
        do { 
            #Construction du SamAccountName
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
        $FormattedSchoolName = $SchoolName.Substring(0,1).ToUpper() + $SchoolName.Substring(1).Replace(" ", "")
        $Password = "$FormattedSchoolName$($Class.Substring(6))!" # Extrait le numéro de classe

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


            Add-ADGroupMember -Identity "grp_eleves" -Members $UserSamAccountName

            Write-Host "Utilisateur $FirstName $LastName créé avec succès dans '$TargetOU'. Mot de passe : $Password. L'utilisateur a été ajouté dans le groupe grp_eleves"

        } catch {
            Write-Warning "Erreur lors de la création de l'utilisateur $FirstName $LastName : $_"
        }
    }
}

