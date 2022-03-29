<#PSScriptInfo
.VERSION 22.3.25.2
.GUID 68790315-3c3f-4a9a-b191-84928e5d6a83
.AUTHOR David Segura @SeguraOSD
.COMPANYNAME osdcloud.com
.COPYRIGHT (c) 2022 David Segura osdcloud.com. All rights reserved.
.TAGS OSDeploy OSDCloud WinPE OOBE Windows AutoPilot
.LICENSEURI 
.PROJECTURI https://github.com/OSDeploy/OSD
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
    Script should be executed in a Command Prompt using either of the following commands:
    powershell Invoke-Expression -Command (Invoke-RestMethod -Uri re.osdcloud.com)
    powershell iex (irm re.osdcloud.com)
#>
<#
.SYNOPSIS
    PSCloudScript at re.osdcloud.com
.DESCRIPTION
    PSCloudScript at re.osdcloud.com
.NOTES
    Version 22.3.25.2
.LINK
    https://raw.githubusercontent.com/OSDeploy/OSD/master/cloudscript/re.ps1
.EXAMPLE
    powershell iex (irm re.osdcloud.com)
#>
[CmdletBinding()]
param()
#https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcd-boot-options-reference
#https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/bcd-settings-and-bitlocker
#http://www.mistyprojects.co.uk/documents/BCDEdit/files/examples1.htm
#============================================
#   Initialize
#============================================
$OSDCloudREVersion = '22.3.25.2'
Write-Host -ForegroundColor DarkGray "re.osdcloud.com $OSDCloudREVersion"
#============================================
#   Test Admin Rights
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test Admin Rights"
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (! $IsAdmin) {
    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) re.osdcloud.com requires elevated Admin Rights"
    Break
}
#============================================
#   Test PowerShell Execution Policy
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test PowerShell Execution Policy"
if ((Get-ExecutionPolicy) -ne 'RemoteSigned') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}
#============================================
#	Test OSD Module
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test OSD Module"
$TestOSDModule = Import-Module OSD -PassThru -ErrorAction Ignore
if (! $TestOSDModule) {
    Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Install Module OSD"
    Install-Module OSD -Force
}
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test OSD Commands"
$TestOSDCommand = Get-Command Get-OSDCloudREPSDrive -ErrorAction Ignore
if (-not $TestOSDCommand) {
    Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Install Module OSD"
    Install-Module OSD -Force
}
#============================================
#   Warning
#============================================
Write-Warning "OSDCloudRE will be created in 10 seconds"
Write-Warning "Press CTRL + C to cancel"
Start-Sleep -Seconds 10
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#============================================
#	Download ISO
#============================================
$fromIsoUrl = 'https://winpe.blob.core.windows.net/public/public_22.3.25.2.iso'

$ResolveUrl = Invoke-WebRequest -Uri $fromIsoUrl -Method Head -MaximumRedirection 0 -UseBasicParsing -ErrorAction SilentlyContinue
if ($ResolveUrl.StatusCode -eq 302) {
    $fromIsoUrl = $ResolveUrl.Headers.Location
}

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Downloading $fromIsoUrl"
$fromIsoFileGetItem = Save-WebFile -SourceUrl $fromIsoUrl -DestinationDirectory (Join-Path $HOME 'Downloads')
$fromIsoFileFullName = $fromIsoFileGetItem.FullName

if ($fromIsoFileGetItem -and $fromIsoFileGetItem.Extension -eq '.iso') {
    Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloudISO downloaded to $fromIsoFileFullName"
}
else {
    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to download OSDCloudISO"
    Break
}
#============================================
#	Download ISO
#============================================
$Volumes = (Get-Volume).Where({$_.DriveLetter}).DriveLetter

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Mounting OSDCloudISO"
$MountDiskImage = Mount-DiskImage -ImagePath $fromIsoFileFullName
Start-Sleep -Seconds 3
$MountDiskImageDriveLetter = (Compare-Object -ReferenceObject $Volumes -DifferenceObject (Get-Volume).Where({$_.DriveLetter}).DriveLetter).InputObject

if ($MountDiskImageDriveLetter) {
    $OSDCloudREMedia = "$($MountDiskImageDriveLetter):\"
}
else {
    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to mount $MountDiskImage"
    Break
}
#============================================
#	Suspend BitLocker
#   https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/bcd-settings-and-bitlocker
#============================================
$BitLockerVolumes = Get-BitLockerVolume | Where-Object {($_.ProtectionStatus -eq 'On') -and ($_.VolumeType -eq 'OperatingSystem')} -ErrorAction Ignore
if ($BitLockerVolumes) {
    $BitLockerVolumes | Suspend-BitLocker -RebootCount 1 -ErrorAction Ignore

    if (Get-BitLockerVolume -MountPoint $BitLockerVolumes | Where-Object ProtectionStatus -eq "On") {
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to suspend BitLocker for next boot"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) BitLocker is suspended for the next boot"
    }
}
#============================================
#   New-OSDCloudREVolume
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Creating a new OSDCloudRE volume"
$OSDCloudREVolume = New-OSDCloudREVolume
#============================================
#   PSDrive
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test OSDCloudRE PSDrive"
$OSDCloudREPSDrive = Get-OSDCloudREPSDrive

if (! $OSDCloudREPSDrive) {
    Write-Error "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to find OSDCloudRE PSDrive"
    Break
}
#============================================
#	OSDCloudRERoot
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test OSDCloudRE Root"
$OSDCloudRERoot = ($OSDCloudREPSDrive).Root
if (-NOT (Test-Path $OSDCloudRERoot)) {
    Write-Error "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to find OSDCloudRE Root at $OSDCloudRERoot"
    Break
}
#============================================
#	Update WinPE Volume
#============================================
if ((Test-Path -Path "$OSDCloudREMedia") -and (Test-Path -Path "$OSDCloudRERoot")) {
    Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Copying $OSDCloudREMedia to OSDCloud WinPE partition at $OSDCloudRERoot"
    $null = robocopy "$OSDCloudREMedia" "$OSDCloudRERoot" *.* /e /ndl /njh /njs /np /r:0 /w:0 /b /zb
}
else {
    Write-Error "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to copy Media to OSDCloudRE"
    Break
}
#============================================
#	Remove Read-Only Attribute
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Removing Read Only attributes in $OSDCloudRERoot"
Get-ChildItem -Path $OSDCloudRERoot -File -Recurse -Force | foreach {
    Set-ItemProperty -Path $_.FullName -Name IsReadOnly -Value $false -Force -ErrorAction Ignore
}
#============================================
#   Dismount OSDCloudISO
#============================================
if ($MountDiskImage) {
    Start-Sleep -Seconds 3
    Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Dismounting ISO at $($MountDiskImage.ImagePath)"
    $null = Dismount-DiskImage -ImagePath $MountDiskImage.ImagePath
}
#============================================
#   Get-OSDCloudREVolume
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Testing OSDCloudRE Volume"
if (! (Get-OSDCloudREVolume)) {
    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Could not create OSDCloudRE"
    Break
}
#============================================
#   Set-OSDCloudREBCD
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set OSDCloudRE Ramdisk: Set-OSDCloudREBootmgr -SetRamdisk"
Set-OSDCloudREBootmgr -SetRamdisk
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set OSDCloudRE OSLoader: Set-OSDCloudREBootmgr -SetOSloader"
Set-OSDCloudREBootmgr -SetOSloader
#============================================
#   Hide-OSDCloudREDrive
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Hiding OSDCloudRE volume: Hide-OSDCloudREDrive"
Hide-OSDCloudREDrive
#============================================
#   Set-OSDCloudREBootmgr
#============================================
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set OSDCloudRE to restart on next boot: Set-OSDCloudREBootmgr -BootToOSDCloudRE"
Set-OSDCloudREBootmgr -BootToOSDCloudRE
#============================================
#   Complete
#============================================
Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloudRE setup is complete"
#============================================