function ParseIniFile($path, $BypassDoubleness) {

    # Initialize the parameters that will be used to run the merge
    $blocks = @()
    $currentBlock = $null
    $content = Get-Content $path
    $lastComments = @()

    foreach ($line in $content) {
        if ($line.StartsWith(";")) {
            # Add comments to the list that will be associated with the next parameter/block
            $lastComments += $line.TrimStart(";")
        }
        elseif ($line.StartsWith("[")) {
            # Start of new block
            $currentBlock = @{
                Name       = ""
                Comments   = @()
                Parameters = @()
            }
            $currentBlock.Name = $line.Trim("[", "]", " ")
            $currentBlock.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate block names
            if (-not $null -eq ($blocks | Where-Object { $_.Name -eq $currentBlock.Name })) {
                Write-Host "Inconsistent '$path' file. There is more than one [$($currentBlock.Name)] block in the file."
                if ($BypassDoubleness) {
                    $blocks = $blocks | Where-Object { $_.Name -ne $currentBlock.Name }
                }
                else {
                    Throw "Inconsistent '$path' file. There is more than one [$($currentBlock.Name)] block in the file."
                }
            }
            if ($currentBlock.Count -eq 3) {
                $blocks += $currentBlock
            }
        }
        elseif ($line.Contains("=")) {
            # Parameter line
            $paramParts = $line.Split("=", 2).Trim()
            $param = @{
                Name     = ""
                Value    = ""
                Comments = @()
            }
            $param.Name = $paramParts[0]
            $param.Value = $paramParts[1]
            $param.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate parameter names within a block
            if (-not $null -eq ($currentBlock.Parameters | Where-Object { $_.Name -eq $param.Name })) {
                Write-Host "Inconsistent '$path' file. There is more than one '$($param.Name)' parameter in the block '[$($currentBlock.Name)]'."
                if ($BypassDoubleness) {
                    $currentBlock.Parameters = $currentBlock.Parameters | Where-Object { $_.Name -ne $param.Name }
                }
                else {
                    Throw "Inconsistent '$path' file. There is more than one '$($param.Name)' parameter in the block '[$($currentBlock.Name)]'."
                }
            }
            if ($param.Count -eq 3) {
                $currentBlock.Parameters += $param
            }
        }
    }
    # Return the list of block structs
    return $blocks
}

# Mount the Block object to a list of strings as it will be appended to the output file
function MountBlock($block) {
    $blockContent = @()
    foreach ($comment in $block.Comments) {
        $blockContent += ";$comment"
    }
    $blockContent += "[$($block.Name)]"
    foreach ($parameter in $block.Parameters) {
        foreach ($comment in $parameter.Comments) {
            $blockContent += ";$comment"
        }
        $blockContent += "$($parameter.Name)=$($parameter.Value)"
    }
    $blockContent += ""
    return $blockContent
}