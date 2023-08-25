function NormalizeSettings {
    param (
        [Parameter(Mandatory = $true)]
        $Settings
    )
    $ExpectedParameters = Get-Content -Path "$PSScriptRoot\SettingsSchema.txt"
    $NormalizedSettings = @{}
    foreach ($Setting in $Settings) {
        $NormalizedSettings[$Setting.Name] = @{}
        foreach ($expectedParameter in $ExpectedParameters) {
            if ($expectedParameter -match '.*\*$') {
                $NormalizedExpectedParameter = $expectedParameter.Substring(0, $expectedParameter.Length - 1)
                $mandatory = $true
            }
            else {
                $NormalizedExpectedParameter = $expectedParameter
                $mandatory = $false
            }
            $CurrentParameter = $Setting.Parameters | Where-Object { $_.Name -eq $NormalizedExpectedParameter }
            if (-not ($CurrentParameter -or ($CurrentParameter.Value -in @('null', ""))) -and $mandatory) {
                throw "Missing mandatory parameter $NormalizedExpectedParameter in settings block $($Setting.Name)"
            }
            elseif (-not $CurrentParameter -or ($CurrentParameter.Value -in @('null', ""))) {
                $NormalizedSettings[$Setting.Name][$CurrentParameter.Name] = $null
            }
            else {
                $NormalizedSettings[$Setting.Name][$CurrentParameter.Name] = $CurrentParameter.Value
            }
        }
    }
    VerifySettings -Settings $NormalizedSettings
    return TypeSettings -Settings $NormalizedSettings
}

function TypeSettings {
    param (
        [Parameter(Mandatory = $true)]
        $Settings
    )
    if ($null -ne $Settings[$SettingKey]['start']) {
        $Settings[$SettingKey]['start'] = [datetime]::ParseExact($Settings[$SettingKey]['start'], 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    else {
        $Settings[$SettingKey]['start'] = [datetime]::MinValue
    }
    if ($null -ne $Settings[$SettingKey]['end']) {
        $Settings[$SettingKey]['end'] = [datetime]::ParseExact($Settings[$SettingKey]['end'], 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    else {
        $Settings[$SettingKey]['end'] = [datetime]::MaxValue
    }
    if (-not $Settings[$SettingKey]['port']) {
        $Settings[$SettingKey]['port'] = '22'
    }
    if (-not $Settings[$SettingKey]['keep']) {
        $Settings[$SettingKey]['keep'] = [int]::MaxValue
    }
    else {
        $Settings[$SettingKey]['keep'] = [int]$Settings[$SettingKey]['keep']
    }
    $Settings[$SettingKey]['interval'] = [timespan]::Parse($Settings[$SettingKey]['interval'])
    return $Settings
}

function VerifySettings {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    foreach ($SettingKey in $Settings.Keys) {
        $Setting = $Settings[$SettingKey]
        if (($Setting['auth'] -eq 'privatekey') -and -not $Setting['privatekey']) {
            throw "Missing privatekey parameter in settings block $SettingKey"
        }
        if (($Setting['auth'] -eq 'password') -and -not $Setting['password']) {
            throw "Missing password parameter in settings block $SettingKey"
        }
        if (-not $Setting['auth'] -in @('password', 'privatekey')) {
            throw "Invalid auth parameter in settings block $SettingKey. Expected values: password, privatekey"
        }
        $timestamp = [datetime]::MinValue
        $timestampFormat = 'yyyy-MM-dd HH:mm:ss'
        foreach ($timestampParameter in @('start', 'end')) {
            if (!($null -eq $Setting[$timestampParameter]) -and !([DateTime]::TryParseExact($Setting[$timestampParameter], $timestampFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$timestamp))) {
                throw "Invalid timestamp format in parameter $timestampParameter in settings block $SettingKey. Expected format: $timestampFormat"
            }
        }
    }
    if ($Setting['port']) {
        if (-not ($null -eq $Setting['port']) -and ($Setting['port'] -match '^\d+$')) {
            $port = [int]$Setting['port']
            if ($port -lt 1 -or $port -gt 65535) {
                throw "Invalid port number in settings block $SettingKey. Expected values: 1-65535"
            }
        }
        elseif (-not ($Setting['port'] -match '^\d+$')) {
            throw "Invalid port number in settings block $SettingKey. Expected values: 1-65535"
        }
    }
    if (!($Setting['keep'] -match '^\d+$' -and [int]$Setting['keep'] -gt 0)) {
        throw "Invalid keep value in settings block $SettingKey. It must be a positive integer"
    }
}
