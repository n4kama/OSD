<#
.SYNOPSIS
Returns the BIOS Component of the Dell System Catalog

.DESCRIPTION
Returns the BIOS Component of the Dell System Catalog

.PARAMETER Compatible
If you have a Dell System, this will filter the results based on your
ComputerSystem SystemSKUNumber

.LINK
https://osd.osdeploy.com

.NOTES
#>
function Get-DellBiosCatalog {
    [CmdletBinding()]
    param (
        [System.Management.Automation.SwitchParameter]$Compatible
    )
	
    if ($PSBoundParameters.ContainsKey('Compatible')) {
	    Get-DellSystemMasterCatalog -Component BIOS -Compatible | Sort-Object -Property ReleaseDate -Descending
    }
    else {
        Get-DellSystemMasterCatalog -Component BIOS | Sort-Object -Property ReleaseDate -Descending
    }
}