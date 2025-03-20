# ==============================
# SCRIPT DE CONFIGURATION SERVEUR
# ==============================

$ServerRole = Read-Host "Quel type de serveur configurez-vous ? (DFS / Impression)"
$Numero = Read-Host "Indiquez le numéro du serveur (ex: 01, 02...)"
$DomainName = "SimoneVeil.local"
$DC_IP = "10.26.32.52"
$AdminUser = "SimoneVeil.local\Administrateur"
$AdminPass = "Toto123"

if ($ServerRole -eq "DFS") {
    $ServerName = "SRV-SV-DFS$Numero"
} elseif ($ServerRole -eq "Impression") {
    $ServerName = "SRV-SV-IMPR$Numero"
} else {
    Write-Host "Type de serveur non reconnu."
    exit
}

$RebootNeeded = $false

# Vérification du ping vers le contrôleur de domaine
Write-Host "Vérification du ping vers $DC_IP..."
if (!(Test-Connection -ComputerName $DC_IP -Count 2 -Quiet)) {
    Write-Host "ERREUR : Impossible de pinguer le contrôleur de domaine ($DC_IP)."
    exit 1
}
Write-Host "Ping réussi vers $DC_IP."

# Configuration DNS
Write-Host "Configuration du serveur DNS..."
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $DC_IP

# Renommage et ajout au domaine
if ((Get-WmiObject Win32_ComputerSystem).Name -ne $ServerName) {
    Write-Host "Renommage du serveur en $ServerName..."
    Rename-Computer -NewName $ServerName -Force
    $RebootNeeded = $true
}

if ((Get-WmiObject Win32_ComputerSystem).Domain -ne $DomainName) {
    Write-Host "Ajout du serveur au domaine..."
    $Command = "netdom join $ServerName /domain:$DomainName /userd:$AdminUser /passwordd:$AdminPass"
    Invoke-Expression -Command $Command
    if ($?) {
        Write-Host "Serveur ajouté au domaine avec succès !"
        $RebootNeeded = $true
    } else {
        Write-Host "ERREUR : Impossible d'ajouter l'ordinateur au domaine."
        exit 1
    }
}

if ($RebootNeeded) {
    Write-Host "Redémarrage en cours..."
    Start-Sleep -Seconds 30
    Restart-Computer -Force
    exit 0
}

if ($ServerRole -eq "Impression") {
    Write-Host "Configuration du Serveur d'Impression..."
    Install-WindowsFeature -Name Print-Services -IncludeManagementTools

    # Ajout de l'imprimante réseau
    $PrinterName = "Microsoft Print to PDF"
    Write-Host "Ajout de l'imprimante réseau..."
    Add-Printer -Name $PrinterName -DriverName "Microsoft Print to PDF" -PortName "PORTPROMPT:"

    # Définir l'imprimante par défaut en noir et blanc recto-verso
    Write-Host "Configuration de l'impression par défaut..."
    Set-PrintConfiguration -PrinterName $PrinterName -Color $false -DuplexingMode TwoSidedLongEdge
    Restart-Service Spooler
    Start-Sleep -Seconds 2

    # Vérifier la configuration
    $Config = Get-PrintConfiguration -PrinterName $PrinterName
    if ($Config.Color -eq $false -and $Config.DuplexingMode -eq "TwoSidedLongEdge") {
        Write-Host "Vérification OK : Impression en Noir et Blanc et Recto-Verso activée."
    } else {
        Write-Host "Attention : La configuration couleur/recto-verso n'a pas été prise en compte !"
    }

    # Configuration des permissions d'impression avec les groupes corrects
    Write-Host "Configuration des permissions pour les imprimantes..."
    $SpoolerPath = "C:\\Windows\\System32\\spool\\PRINTERS"

    try {
        icacls $SpoolerPath /grant "grp_directeurs:F" "grp_enseignants:F" "grp_eleves:R"
        Write-Host "Permissions appliquées avec icacls."
    } catch {
        Write-Host "ERREUR : Impossible d'appliquer les permissions avec icacls."
    }
}

if ($ServerRole -eq "DFS") {
    Write-Host "Configuration du DFS..."
    
    # Installation des modules DFS et Active Directory pour éviter les erreurs
    Write-Host "Installation des modules DFS..."
    Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con, RSAT-AD-Tools -IncludeManagementTools

    # Vérifier si DFS Namespace est installé
    if (!(Get-WindowsFeature FS-DFS-Namespace).Installed) {
        Write-Host "ERREUR : DFS Namespace n'a pas pu Ãªtre installé."
        exit 1
    }
	# Création du dossier DFSRoot si absent
	$DfsRootPath = "C:\DFSRoot"
	if (!(Test-Path $DfsRootPath)) {
		Write-Host "Création du dossier DFSRoot..."
		New-Item -Path $DfsRootPath -ItemType Directory -Force
	}

# Création du partage SMB pour DFSRoot
Write-Host "Création du partage DFSRoot..."
New-SmbShare -Name "DFSRoot" -Path $DfsRootPath -FullAccess "Tout le monde"

    # Création du DFS Namespace
    New-DfsnRoot -TargetPath "\\$ServerName\DFSRoot" -Type DomainV2 -Path "\\$DomainName\DFS"
    Write-Host "DFS configuré."

    # Configuration des dossiers DFS
    Write-Host "Création des partages DFS..."
    New-Item -Path "C:\\Partages\\Direction" -ItemType Directory -Force
    New-Item -Path "C:\\Partages\\Enseignants" -ItemType Directory -Force
    New-Item -Path "C:\\Partages\\Classes" -ItemType Directory -Force
    New-Item -Path "C:\\Partages\\Personnels" -ItemType Directory -Force
    
    # Configuration des permissions NTFS avec les bons groupes
    icacls "C:\\Partages\\Direction" /grant "grp_directeurs:F"
    icacls "C:\\Partages\\Enseignants" /grant "grp_directeurs:R" "grp_enseignants:F"
    icacls "C:\\Partages\\Classes" /grant "grp_directeurs:R" "grp_enseignants:R" "grp_eleves:R"
    icacls "C:\\Partages\\Personnels" /grant "Administrateurs:F"

    # Application des quotas
    # Application des quotas
	Write-Host "Application des quotas sur les dossiers..."
	fsutil quota enforce "C:\Partages\Personnels"
	fsutil quota modify "C:\Partages\Personnels" 1073741824 966367641 "Tout le monde" # 1GB avec alerte à 90%
    Write-Host "Permissions et quotas configurés."
}

Write-Host "Configuration du serveur terminée."
