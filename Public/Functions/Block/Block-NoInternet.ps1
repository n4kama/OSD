function Block-NoInternet {
    [CmdletBinding()]
    param (
        [System.Management.Automation.SwitchParameter]$Warn,
        [System.Management.Automation.SwitchParameter]$Pause
    )
    $CallingFunction = (Get-PSCallStack)[1].InvocationInfo.Line
    $Message = "[$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))] $CallingFunction requires Internet access"
        
    if (-NOT (Test-WebConnection -Uri 'google.com')) { #Changed from microsoft.com as it stopped reporting a connection.
        Write-Warning $Message
        if ($PSBoundParameters.ContainsKey('Pause')) {
            [void]('Press Enter to Continue')
        }
        if (-NOT ($PSBoundParameters.ContainsKey('Warn'))) {
            Break
        }
    }
}
