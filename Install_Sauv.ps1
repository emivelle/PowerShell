# --- 1. Variables et Pré-requis ---
# Définir les variables pour les chemins, les identifiants et le nom du serveur
$domain = "SimoneVeil.LOCAL"  # Nom du domaine
$adminUser = "Administrateur"  # Nom de l'utilisateur avec les droits d'ajout
$adminPassword = "hn54weHG"  # Mot de passe de l'utilisateur (à sécuriser)
$newServerName = "SRV-SAUV01"  # Nouveau nom du serveur
$backupDrive = "S:"  # Disque de destination pour les sauvegardes

# --- 2. Vérification du nom de la machine ---
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

# --- 3. Vérification de l'appartenance au domaine ---
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

# --- 4. Vérification du disque de sauvegarde ---
Write-Host "Vérification de l'existence du disque de sauvegarde..."

if (!(Test-Path $backupDrive)) {
    Write-Host "Le disque de sauvegarde $backupDrive n'existe pas." -ForegroundColor Red
    exit
}

# Vérification du format du disque de sauvegarde
$volume = Get-Volume -DriveLetter $backupDrive.TrimEnd(':')
if ($volume.FileSystem -ne "NTFS") {
    Write-Host "Le disque de sauvegarde $backupDrive n'est pas formaté en NTFS." -ForegroundColor Red
    exit
}

# Vérification de l'espace disque sur le disque de sauvegarde
$psDrive = Get-PSDrive -Name $backupDrive.TrimEnd(':')
$requiredSpaceGB = 50  # Espace requis en Go (modifiable selon besoin)
$requiredSpaceBytes = $requiredSpaceGB * 1GB

if ($psDrive.Free -lt $requiredSpaceBytes) {
    Write-Host "Le disque de sauvegarde $backupDrive n'a pas suffisamment d'espace. Espace requis : $requiredSpaceGB Go." -ForegroundColor Red
    exit
}

# --- 5. Vérification et installation du service Windows Server Backup ---
Write-Host "Vérification du service Windows Server Backup (wbengine)..."

# Vérifier si la fonctionnalité est bien installée
$wbFeature = Get-WindowsFeature -Name Windows-Server-Backup
if (-not $wbFeature.Installed) {
    Write-Host "La fonctionnalité Windows-Server-Backup n'est pas installée. Installation en cours..." -ForegroundColor Yellow
    Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
}

# Vérifier si le service wbengine existe
$wbengineService = Get-Service -Name "wbengine" -ErrorAction SilentlyContinue
if ($null -eq $wbengineService) {
    Write-Host "Le service wbengine n'existe pas sur ce serveur." -ForegroundColor Red
    exit
}

# Vérifier si le service wbengine est en cours d'exécution
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
$backupSource = "C:\Data"  # Remplace par les chemins pertinents

# Vérifier si les chemins de source existent
foreach ($path in $backupSource) {
    if (!(Test-Path $path)) {
        Write-Host "Le chemin d'accès $path n'existe pas." -ForegroundColor Red
        exit
    }
}

# Lancer la sauvegarde avec Wbadmin
Try {
    # Assurez-vous que les chemins de source sont correctement formatés
    $backupSourceFormatted = $backupSource -join ","
    wbadmin start backup -backupTarget:$backupDrive -include:$backupSourceFormatted -allCritical -quiet
    Write-Host "La sauvegarde a été lancée avec succès." -ForegroundColor Green
} Catch {
    Write-Host "Échec du lancement de la sauvegarde : $_" -ForegroundColor Red
    exit
}

# --- 7. Sauvegarde de l'Active Directory ---
Write-Host "Démarrage de la sauvegarde de l'Active Directory..."

# Lancer la sauvegarde de l'Active Directory avec Wbadmin
Try {
    wbadmin start systemstatebackup -backupTarget:$backupDrive -quiet
    Write-Host "La sauvegarde de l'Active Directory a été lancée avec succès." -ForegroundColor Green
} Catch {
    Write-Host "Échec du lancement de la sauvegarde de l'Active Directory : $_" -ForegroundColor Red
    exit
}

# --- 8. Vérification des logs de wbadmin ---
Write-Host "Vérification des logs de wbadmin..."

# Filtrer les événements pour wbadmin
$wbadminLogs = Get-WinEvent -LogName Application | Where-Object { $_.ProviderName -eq "wbadmin" }

if ($wbadminLogs.Count -gt 0) {
    Write-Host "Logs de wbadmin trouvés :"
    foreach ($log in $wbadminLogs) {
        Write-Host "Log Date: $($log.TimeCreated) - Message: $($log.Message)"
    }
} else {
    Write-Host "Aucun log de wbadmin trouvé." -ForegroundColor Yellow
}

# --- 9. Planification de la sauvegarde ---
Write-Host "Planification de la sauvegarde dans 2 minutes..."

# Créer une tâche planifiée pour exécuter la sauvegarde
$action = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start backup -backupTarget:$backupDrive -include:$backupSourceFormatted -allCritical -quiet"
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(2))
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "ScheduledBackup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings

Write-Host "La sauvegarde planifiée a été créée et s'exécutera dans 2 minutes." -ForegroundColor Green

# --- 10. Vérification de la sauvegarde ---
Start-Sleep -Seconds 10  # Attendre quelques secondes pour éviter une vérification instantanée
$backupStatus = wbadmin get versions

if ($backupStatus -match "Version identifier") {
    Write-Host "Sauvegarde terminée avec succès." -ForegroundColor Green
} else {
    Write-Host "Échec de la sauvegarde, veuillez vérifier les logs." -ForegroundColor Red
}
