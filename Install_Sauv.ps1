# --- 1. Variables et Pré-requis ---
# Définir les variables pour les chemins et les identifiants
$backupTarget = "D:"  # Dossier de destination pour les sauvegardes (assurez-vous que D: est un disque valide)
$fileSharePath = "\\AutreServeur\PartageDossier"  # Remplacez par le chemin UNC du partage de fichiers
$domainAdminUser = "AdministrateurDomaine"  # Utilisateur du domaine avec privilèges d'administrateur
$domainAdminPassword = ConvertTo-SecureString "votreMotDePasse" -AsPlainText -Force  # Mot de passe en clair
$domain = "votre-domaine.local"  # Nom de domaine

# --- 2. Ajouter le serveur au domaine (si nécessaire) ---
# Vérifie si le serveur est déjà dans le domaine
$computerDomain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
if ($computerDomain -ne $domain) {
    Write-Host "Le serveur n'est pas dans le domaine. Ajout en cours..."
    
    # Ajouter au domaine
    $domainCredential = New-Object System.Management.Automation.PSCredential($domainAdminUser, $domainAdminPassword)
    Add-Computer -DomainName $domain -Credential $domainCredential -Restart
    Write-Host "Le serveur a été ajouté au domaine. Redémarrage en cours..."
} else {
    Write-Host "Le serveur est déjà dans le domaine."
}

# --- 3. Installation des fonctionnalités nécessaires ---
# Installer les fonctionnalités Windows Server Backup et Active Directory Domain Services
Write-Host "Installation des fonctionnalités nécessaires..."

# Installer Windows Server Backup
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools

# Installer Active Directory Domain Services (si non installé)
Install-WindowsFeature -Name AD-Domain-Services

# --- 4. Démarrer le service Windows Server Backup ---
# Vérifie si le service Windows Server Backup est en cours d'exécution
$wbengineService = Get-Service -Name "wbengine"
if ($wbengineService.Status -ne "Running") {
    Write-Host "Le service Windows Server Backup n'est pas en cours d'exécution. Démarrage..."
    Start-Service -Name "wbengine"
} else {
    Write-Host "Le service Windows Server Backup est déjà en cours d'exécution."
}

# --- 5. Sauvegarde de l'Active Directory ---
# Sauvegarde de l'Active Directory et de ses composants critiques (NTDS et SYSVOL)
Write-Host "Démarrage de la sauvegarde de l'Active Directory..."
wbadmin start backup -backupTarget:$backupTarget -include:C:\Windows\NTDS, C:\Windows\SYSVOL -allCritical -quiet
Write-Host "Sauvegarde de l'Active Directory terminée."

# --- 6. Sauvegarde du partage réseau ---
# Sauvegarde du partage de fichiers situé sur un autre serveur via le réseau
Write-Host "Démarrage de la sauvegarde du partage de fichiers..."
wbadmin start backup -backupTarget:$backupTarget -include:$fileSharePath -quiet
Write-Host "Sauvegarde du partage de fichiers terminée."

# --- 7. Création des tâches planifiées ---
# Créer une tâche planifiée pour la sauvegarde du partage de fichiers
$backupTriggerFiles = New-ScheduledTaskTrigger -Daily -At "02:00AM"  # Sauvegarde tous les jours à 2h du matin
$backupActionFiles = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start backup -backupTarget:$backupTarget -include:$fileSharePath -quiet"
Register-ScheduledTask -Action $backupActionFiles -Trigger $backupTriggerFiles -TaskName "BackupPartageFichier" -User "SYSTEM" -RunLevel Highest
Write-Host "Tâche planifiée pour la sauvegarde du partage de fichiers créée."

# Créer une tâche planifiée pour la sauvegarde de l'Active Directory
$backupTriggerAD = New-ScheduledTaskTrigger -Daily -At "03:00AM"  # Sauvegarde tous les jours à 3h du matin
$backupActionAD = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start backup -backupTarget:$backupTarget -include:C:\Windows\NTDS, C:\Windows\SYSVOL -allCritical -quiet"
Register-ScheduledTask -Action $backupActionAD -Trigger $backupTriggerAD -TaskName "BackupAD" -User "SYSTEM" -RunLevel Highest
Write-Host "Tâche planifiée pour la sauvegarde de l'Active Directory créée."

# --- 8. Vérification des tâches planifiées ---
Write-Host "Vérification des tâches planifiées..."
$taskFiles = Get-ScheduledTask -TaskName "BackupPartageFichier"
$taskAD = Get-ScheduledTask -TaskName "BackupAD"

# Afficher l'état des tâches planifiées
Write-Host "État de la tâche de sauvegarde du partage de fichiers : $($taskFiles.State)"
Write-Host "État de la tâche de sauvegarde de l'Active Directory : $($taskAD.State)"

# --- 9. Récapitulatif ---
Write-Host "Script de sauvegarde exécuté avec succès. Les tâches planifiées ont été créées pour les sauvegardes quotidiennes."
Write-Host "Sauvegarde du partage de fichiers à 2h du matin et de l'Active Directory à 3h du matin."
