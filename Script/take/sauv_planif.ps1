# Définir les chemins des scripts de sauvegarde
$scriptPaths = @(
    "C:\Script\take\sauv_test.ps1",
    "C:\Script\take\sauv_ad.ps1",
    "C:\Script\take\sauv_impr.ps1",
    "C:\Script\take\sauv_linux.ps1",
    "C:\Script\take\sauv_dfs.ps1"
)

# Créer un script principal qui appelle tous les scripts de sauvegarde
$mainScriptPath = "C:\Script\DailyBackup.ps1"
$mainScriptContent = @"
foreach (\$script in $scriptPaths) {
    & \$script
}
"@
Set-Content -Path $mainScriptPath -Value $mainScriptContent

# Planification de la sauvegarde quotidienne à 2h du matin
Write-Host "Planification de la sauvegarde quotidienne à 2h du matin..." -ForegroundColor Yellow
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$mainScriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "DailyBackup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Write-Host "La tâche planifiée pour la sauvegarde quotidienne a été créée." -ForegroundColor Green