# Description: This module contains functions for normalizing paths.

function Get-CommonParentPath {
    param (
        [string[]]$paths
    )

    if ($paths.Count -eq 0) {
        Throw "No paths provided."
    }

    $SplitPaths = $strings | ForEach-Object { , ($_.Split('/') ) }

    $shortestPath = $SplitPaths | ForEach-Object { $_.Count } | Measure-Object -Minimum
    $maxLength = $shortestPath.Minimum
    $CommonParentPath = @()

    for ($i = 0; $i -lt $maxLength; $i++) {
        $directory = $SplitPaths[0][$i]

        $common = $true
        foreach ($path in $SplitPaths) {
            if ($path[$i] -ne $directory) {
                $common = $false
                break
            }
        }

        if ($common) {
            $CommonParentPath += $directory
        }
        else {
            break
        }
    }
    return ($CommonParentPath -join '/')
}

# NormalizePaths removes the longest common substring from all paths.
function NormalizePaths {
    param (
        [string[]]$paths
    )

    if ($paths.Count -eq 0) {
        Write-Host "No paths provided."
        return
    }

    $CommonParentPath = Get-CommonParentPath -paths $paths
    if ($CommonParentPath.Length -eq 0) {
        Write-Host "No common substring found."
        return
    }

    $normalizedPaths = @()
    foreach ($path in $paths) {
        $normalizedPaths += $path.Substring($CommonParentPath.Length)
    }

    return @{'normalizedPaths' = $normalizedPaths
        'commonParentPath'     = $CommonParentPath
    }
}