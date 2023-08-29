function CreateRegistry {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("HKLM", "HKCU", "HKCR", "HKU", "HKCC")]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$SubKey,

        [Parameter(Mandatory = $false)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$Value
    )

    $fullPath = "${Root}:\" + $SubKey

    # Check if the subkey exists, create it if necessary
    if (!(Test-Path -Path $fullPath)) {
        New-Item -Path $fullPath -Force | Out-Null
    }

    if ($Key -and $Value) {
        # Create or modify the registry value
        Set-ItemProperty -Path $fullPath -Name $Key -Value $Value -Force | Out-Null
    }
    elseif ($Key) {
        $actualValue = $Value
        if (-not $actualValue) {
            $actualValue = ""
        }
        Set-ItemProperty -Path $fullPath -Name $Key -Value $actualValue -Force | Out-Null
    }
    elseif ($Value) {
        # Value is provided but key is missing
        Write-Output "Error: Key is missing for the value '$Value'."
        return
    }
    else {
        return
    }

    Write-Output "Registry key and value successfully created/updated: $fullPath"
}