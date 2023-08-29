param (
    [Parameter(Mandatory = $true, HelpMessage = "Path to the settings file.")]
    [ValidateScript({ (Test-Path -Path $_ -PathType Leaf) -and ($_ -match '\.ini$') })]
    [string]$SettingsPath
)

Import-Module "$PSScriptRoot\modules\ParseIni.psm1"
Import-Module "$PSScriptRoot\modules\BackupTask.psm1"
Import-Module "$PSScriptRoot\modules\CreateRegistry.psm1"
Import-Module "$PSScriptRoot\modules\Settings.psm1"

# Load settings
$Settings = NormalizeSettings -Settings (ParseIniFile -Path $SettingsPath)

foreach ($SettingKey in $Settings.Keys) {
    if (-not (Test-Path -Path $Settings[$SettingKey]['local'])) {
        New-Item -Path $Settings[$SettingKey]['local'] -ItemType Directory
    }
    $now = Get-Date -AsUTC
    CreateRegistry -Root HKLM -SubKey "SOFTWARE\WOW6432Node\RemoteBackup\$SettingKey"
    $parentKeyPath = "HKLM:\SOFTWARE\WOW6432Node\RemoteBackup\$SettingKey"
    $LatestBackups = (Get-ItemProperty -Path $parentKeyPath -Name 'LatestBackups' -ErrorAction SilentlyContinue).LatestBackups
    if ($null -ne $LatestBackups) {
        $LatestBackups = $LatestBackups.Split(',') | Where-Object { $_ } | ForEach-Object { [datetime]::ParseExact($_, 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture) }
        if ($LatestBackups.GetType() -eq [datetime]) {
            $LatestBackups = @($LatestBackups)
        }
    }
    if (-not $LatestBackups) {
        if ($now -ge $Settings[$SettingKey]['start']) {
            BackupTask -Setting $Settings[$SettingKey] -Timestamp $now -Name $SettingKey
            CreateRegistry -Root HKLM -SubKey "SOFTWARE\WOW6432Node\RemoteBackup\$SettingKey" -Key 'LatestBackups' -Value "$($now.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
        else {
            continue
        }
    }
    else {
        $lastBackup = $LatestBackups[-1]
        $nextBackup = $Settings[$SettingKey]['start'] + ([math]::Floor(($lastBackup - $Settings[$SettingKey]['start']) / $Settings[$SettingKey]['interval']) + 1) * $Settings[$SettingKey]['interval'] 
        if ($now -ge $nextBackup) {
            BackupTask -Setting $Settings[$SettingKey] -Timestamp $now -Name $SettingKey
            if ($LatestBackups.Count -ge $Settings[$SettingKey]['keep']) {
                $RemoveFile = $SettingKey + '_' + $LatestBackups[0].ToString('yyyy-MM-dd_HH:mm:ss') + '.tar.gz'
                $RemoveFilePath = Join-Path -Path $Settings[$SettingKey]['local'] -ChildPath $RemoveFile
                Remove-Item -Path $RemoveFilePath -Force
                $LatestBackups = ($LatestBackups | Select-Object -Skip 1).ToList()
            }
            $LatestBackups = $LatestBackups | ForEach-Object { $_.ToString('yyyy-MM-dd HH:mm:ss') }
            if ($LatestBackups.GetType() -eq [string]) {
                $LatestBackups = @($LatestBackups)
            }
            $LatestBackups += $now.ToString('yyyy-MM-dd HH:mm:ss')
            $LatestBackupsStr = $LatestBackups -join ',' 
            CreateRegistry -Root HKLM -SubKey "SOFTWARE\WOW6432Node\RemoteBackup\$SettingKey" -Key 'LatestBackups' -Value $LatestBackupsStr
        }
        else {
            continue
        }
    }
}
