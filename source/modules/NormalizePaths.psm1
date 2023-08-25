# Description: This module contains functions for normalizing paths.

# Get-LongestCommonSubstring returns the longest common substring of a list of strings.
function Get-LongestCommonSubstring {
    param (
        [string[]]$strings
    )

    if ($strings.Count -eq 0) {
        Write-Host "No strings provided."
        return
    }

    $shortestString = $strings | ForEach-Object { $_.Length } | Measure-Object -Minimum
    $maxLength = $shortestString.Minimum
    $longestCommonSubstring = ""

    for ($i = 0; $i -lt $maxLength; $i++) {
        $char = $strings[0][$i]

        $common = $true
        foreach ($str in $strings) {
            if ($str[$i] -ne $char) {
                $common = $false
                break
            }
        }

        if ($common) {
            $longestCommonSubstring += $char
        }
        else {
            break
        }
    }

    return $longestCommonSubstring
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

    $longestCommonSubstring = Get-LongestCommonSubstring -strings $paths
    if ($longestCommonSubstring.Length -eq 0) {
        Write-Host "No common substring found."
        return
    }

    $normalizedPaths = @()
    foreach ($path in $paths) {
        $normalizedPaths += $path.Substring($longestCommonSubstring.Length)
    }

    return @{'normalizedPaths' = $normalizedPaths
        'commonParentPath'     = $longestCommonSubstring
    }
}