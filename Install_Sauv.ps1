# --- 1. Variables et Pré-requis ---
# Définir les variables pour les chemins, les identifiants et le nom du serveur
$fileSharePath = "\\AutreServeur\PartageDossier"  # Chemin UNC du partage de fichiers
$backupTarget = "S:"  # Dossier de destination pour les sauvegardes
$domain = "SimoneVeil.LOCAL"  # Nom du domaine
$adminUser = "Administrateur"  # Nom de l'utilisateur avec les droits d'ajout
$adminPassword = "hn54weHG"  # Mot de passe de l'utilisateur (à sécuriser)
$newServerName = "SRV-SAUV01"  # Nouveau nom du serveur

# Vérification de l'existence du disque S:
if (!(Test-Path $backupTarget)) {
    Write-Host "Le disque de sauvegarde $backupTarget n'existe pas." -ForegroundColor Red
    exit
}

# --- 2. Renommage du serveur ---
Write-Host "Vérification du nom actuel du serveur..."

$computerName = $env:COMPUTERNAME

# Vérifier si le serveur a déjà le bon nom
if ($computerName -eq $newServerName) {
    Write-Host "Le serveur est déjà nommé $newServerName. Passons à l'étape suivante." -ForegroundColor Yellow
} else {
    Write-Host "Renommage du serveur en $newServerName..."

    Try {
        Rename-Computer -NewName $newServerName -Force -Restart
        Write-Host "Le serveur a été renommé en $newServerName. Redémarrage..." -ForegroundColor Green
        exit  # Sortir du script après redémarrage pour laisser le temps au redémarrage de se produire
    } Catch {
        Write-Host "Échec du renommage du serveur : $_" -ForegroundColor Red
        exit
    }
}

# --- 3. Ajouter le serveur au domaine (après redémarrage) ---
# Attendre quelques secondes pour permettre au serveur de redémarrer complètement
Start-Sleep -Seconds 30  # 30 secondes d'attente avant de continuer après redémarrage

$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
if ($ComputerInfo.PartOfDomain) {
    Write-Host "Cette machine est déjà membre du domaine $($ComputerInfo.Domain)" -ForegroundColor Yellow
} else {
    Try {
        $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential("$domain\$adminUser", $securePassword)
        
        # Ajouter au domaine
        Add-Computer -DomainName $domain -Credential $credential -Restart -Force
        Write-Host "Ajout au domaine $domain en cours..." -ForegroundColor Green
    } Catch {
        Write-Host "Échec de l'ajout au domaine : $_" -ForegroundColor Red
        exit
    }
}

# --- 4. Installation des fonctionnalités nécessaires ---
Write-Host "Installation des fonctionnalités nécessaires..."
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools

# --- 5. Vérification et démarrage du service Windows Server Backup ---
Write-Host "Vérification du service Windows Server Backup (wbengine)..."

# Vérifier si la fonctionnalité est bien installée
$wbFeature = Get-WindowsFeature -Name Windows-Server-Backup
if (-not $wbFeature.Installed) {
    Write-Host "La fonctionnalité Windows Server Backup n'est pas installée correctement." -ForegroundColor Red
    exit
}

# Vérifier si le service wbengine existe
$wbengineService = Get-Service -Name "wbengine" -ErrorAction SilentlyContinue
if ($null -eq $wbengineService) {
    Write-Host "Le service wbengine n'existe pas sur ce serveur." -ForegroundColor Red
    exit
}

# Démarrer le service si nécessaire
if ($wbengineService.Status -ne "Running") {
    Try {
        Start-Service -Name "wbengine" -ErrorAction Stop
        Write-Host "Le service wbengine a été démarré avec succès." -ForegroundColor Green
    } Catch {
        Write-Host "Échec du démarrage du service wbengine : $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "Le service wbengine est déjà en cours d'exécution." -ForegroundColor Yellow
}

# --- 6. Sauvegarde des données critiques ---
Write-Host "Démarrage de la sauvegarde du serveur..."

# Définition des chemins à sauvegarder (modifiable selon besoin)
$backupSource = "C:\Data", "C:\ImportantFiles"  # Remplace par les chemins pertinents
$backupTarget = "S:\Sauvegarde"  # Destination de sauvegarde

# Vérifier si le dossier de sauvegarde existe
if (!(Test-Path $backupTarget)) {
    Write-Host "Le dossier cible $backupTarget n'existe pas. Vérifiez le disque de sauvegarde." -ForegroundColor Red
    exit
}

# Lancer la sauvegarde avec Wbadmin
Try {
    # Assurez-vous que les chemins de source sont correctement formatés
    $backupSourceFormatted = $backupSource -join ","
    wbadmin start backup -backupTarget:$backupTarget -include:$backupSourceFormatted -allCritical -quiet
    Write-Host "La sauvegarde a été lancée avec succès." -ForegroundColor Green
} Catch {
    Write-Host "Échec du lancement de la sauvegarde : $_" -ForegroundColor Red
    exit
}

# --- 7. Vérification de la sauvegarde ---
Start-Sleep -Seconds 10  # Attendre quelques secondes pour éviter une vérification instantanée
$backupStatus = wbadmin get versions

if ($backupStatus -match "Version identifier") {
    Write-Host "Sauvegarde terminée avec succès." -ForegroundColor Green
} else {
    Write-Host "Échec de la sauvegarde, veuillez vérifier les logs." -ForegroundColor Red
}
