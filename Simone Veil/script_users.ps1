# ==============================
# SCRIPT D'ACTIVATION RDP + MONTAGE PARTAGES
# ==============================

# Vérifier si l'ordinateur est dans le domaine
$DomainCheck = (Get-WmiObject Win32_ComputerSystem).Domain
if ($DomainCheck -eq "WORKGROUP") {
    Write-Host "L'ordinateur n'est pas dans un domaine, certaines configurations seront ignorées."
}

# Activer le Bureau à distance (RDP)
Write-Host "Activation du Bureau à Distance..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP"
Write-Host "Bureau à Distance activé avec succès."

# Ajouter les groupes autorisés à se connecter en RDP (si dans un domaine)
if ($DomainCheck -ne "WORKGROUP") {
    Write-Host "Ajout des groupes aux autorisations RDP..."
    $Groups = @("grp_directeurs", "grp_enseignants")
    foreach ($Group in $Groups) {
        net localgroup "Utilisateurs du Bureau à distance" "$Group" /add
    }
    Write-Host "Groupes RDP ajoutés."
} else {
    Write-Host "Saut de l'ajout des groupes RDP (ordinateur non joint au domaine)."
}

# Configuration du firewall pour DFS et accès à distance
Write-Host "Configuration du firewall..."
New-NetFirewallRule -DisplayName "Autoriser DFS" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
New-NetFirewallRule -DisplayName "Autoriser accès à distance" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
Write-Host "Firewall configuré."

# Montage automatique des partages réseau au démarrage
Write-Host "Création du script de montage des partages réseau..."
$LogonScriptPath = "C:\Scripts\MapNetworkDrives.ps1"
$ScriptContent = @"
# Script de montage des partages réseau
\$UserGroup = (Get-ADUser \$env:USERNAME -Property MemberOf).MemberOf -match "CN=(.*?),"

If (\$UserGroup -match "grp_directeurs") {
    net use Z: \\SimoneVeil.local\DFS\Direction /persistent:yes
}

If (\$UserGroup -match "grp_enseignants") {
    net use S: \\SimoneVeil.local\DFS\Enseignants /persistent:yes
    net use T: \\SimoneVeil.local\DFS\Classes /persistent:yes
}

If (\$UserGroup -match "grp_eleves") {
    net use T: \\SimoneVeil.local\DFS\Classes /persistent:yes
}
"@

New-Item -Path $LogonScriptPath -ItemType File -Force
Set-Content -Path $LogonScriptPath -Value $ScriptContent

# Ajout du script au démarrage (si l'ordinateur est dans un domaine)
if ($DomainCheck -ne "WORKGROUP") {
    Write-Host "Ajout du script de montage au démarrage..."
    $TaskName = "MountNetworkDrives"
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $LogonScriptPath"
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Description "Monter les partages réseau automatiquement"
    Register-ScheduledTask -TaskName $TaskName -InputObject $Task -Force
} else {
    Write-Host "Saut de l'ajout du script de montage (ordinateur non joint au domaine)."
}

Write-Host "Configuration terminée. Redémarrage recommandé."
