Import-Module Posh-SSH
Import-Module "$PSScriptRoot\NormalizePaths.psm1"

function BackupTask {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,
        [Parameter(Mandatory = $true)]
        [datetime]$Timestamp,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    switch ($Settings['auth']) {
        'password' {
            $creds = New-Object System.Management.Automation.PSCredential($Settings['user'], (ConvertTo-SecureString -String $Settings['password'] -AsPlainText -Force))
            $session = New-SSHSession -ComputerName $Settings['host'] -Credential $creds -AcceptKey -Port $Settings['port'] -Force
        }
        'privatekey' {
            $creds = New-Object System.Management.Automation.PSCredential($Settings['user'], (ConvertTo-SecureString -String '0' -AsPlainText -Force))
            $session = New-SSHSession -ComputerName $Settings['host'] -KeyFile $Settings['privatekey']  $creds -AcceptKey -Port $Settings['port']
        }
    }
    if ($Settings['remote'].Count -gt 1) {
        $NormalizedPaths = NormalizePaths -paths $Settings['remote']
        $Paths = $NormalizedPaths['normalizedPaths']
        $WorkingDirectory = $NormalizedPaths['commonParentPath']
    }
    else {
        $splitPath = $Settings['remote'].Split('/')
        $WorkingDirectory = $splitPath[0..($splitPath.Count - 2)] -join '/'
        $Paths = @($splitPath[-1])
    }
    $BackupName = $Name + '_' + $Timestamp.ToString('yyyy-MM-dd_HH-mm-ss') + '.tar.gz'
    Invoke-SSHCommand -SessionId $session.SessionId -Command "cd $WorkingDirectory && tar czvf /tmp/$BackupName --transform 's,^,./,' $($Paths -join ' ')" -TimeOut ([int]::MaxValue)
    switch ($Settings['auth']) {
        'password' {
            Get-SCPItem -Path "/tmp/$BackupName" -Destination $Settings['local'] -ComputerName $Settings['host'] -Credential $creds -AcceptKey -Port $Settings['port'] -PathType 'File' -Force
        }
        'privatekey' {
            Get-SCPItem -Path "/tmp/$BackupName" -Destination $Settings['local'] -ComputerName $Settings['host'] -KeyFile $Settings['privatekey'] -Credential $creds -AcceptKey -Port $Settings['port'] -PathType 'File'
        }
    }
    Invoke-SSHCommand -SessionId $session.SessionId -Command "rm /tmp/$BackupName" 
}