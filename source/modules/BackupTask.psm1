Import-Module Posh-SSH
Import-Module '$PSScriptRoot\NormalizePaths.psm1'

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
            $creds = New-Object System.Management.Automation.PSCredential($Settings['username'], (ConvertTo-SecureString -String $Settings['password'] -AsPlainText -Force))
            $session = New-SSHSession -ComputerName $Settings['host'] -Credential $creds -AcceptKey
        }
        'privatekey' {
            $session = New-SSHSession -ComputerName $Settings['host'] -KeyFile $Settings['privatekey'] -AcceptKey
        }
    }
    $NormalizedPaths = NormalizePaths -paths $Settings['remote']
    $Paths = $NormalizedPaths['normalizedPaths']
    $WorkingDirectory = $NormalizedPaths['commonParentPath']
    $BackupName = $Name + '_' + $Timestamp.ToString('yyyy-MM-dd_HH-mm-ss') + '.tar.gz'
    $BackupDirectory = Join-Path -Path $Settings['local'] -ChildPath $Name
    Invoke-SSHCommand -SessionId $session.SessionId -Command "cd $WorkingDirectory"
    Invoke-SSHCommand -SessionId $session.SessionId -Command "tar czvf /tmp/$BackupName --transform 's,^,./,' $($Paths -join ' ')"
    switch ($Settings['auth']) {
        'password' {
            Get-SCPItem -Path "/tmp/$BackupName" -Destination $BackupDirectory -ComputerName $Settings['host'] -Credential $creds -AcceptKey
        }
        'privatekey' {
            Get-SCPItem -Path "/tmp/$BackupName" -Destination $BackupDirectory -ComputerName $Settings['host'] -KeyFile $Settings['privatekey'] -AcceptKey
        }
    }
    Invoke-SSHCommand -SessionId $session.SessionId -Command "rm /tmp/$BackupName" 
}