<#
.SYNOPSIS
Returns a Intel Wireless Driver Object

.DESCRIPTION
Returns a Intel Wireless Driver Object
#>
function Get-CloudDriverIntelEthernet {
    [CmdletBinding()]
    param (
        [System.Management.Automation.SwitchParameter]
        $Force
    )
    #=================================================
    #   Online
    #=================================================
    $IsOnline = $false
    $DriverUrl = 'https://www.intel.com/content/www/us/en/download/15084/intel-ethernet-adapter-complete-driver-pack.html'

    if ($Force) {
        $IsOnline = Test-WebConnection $DriverUrl
    }
    #=================================================
    #   OfflineCloudDriver
    #=================================================
    $OfflineCloudDriverPath = "$($MyInvocation.MyCommand.Module.ModuleBase)\clouddriver\CloudDriverIntelEthernet.json"
    $OfflineCloudDriver = Get-Content -Path $OfflineCloudDriverPath -Raw | ConvertFrom-Json
    #=================================================
    #   IsOnline
    #=================================================
    if ($IsOnline) {
        Write-Verbose "CloudDriver Online"
        #All Drivers are from the same URL
        $OfflineCloudDriver = $OfflineCloudDriver | Select-Object -First 1
        #=================================================
        #   ForEach
        #=================================================
        $ZipFileResults = @()
        $CloudDriver = @()
        $CloudDriver = foreach ($OfflineCloudDriverItem in $OfflineCloudDriver) {
            #=================================================
            #   WebRequest
            #=================================================
            $DriverInfoWebRequest = Invoke-WebRequest -Uri $OfflineCloudDriverItem.DriverInfo -Method Get
            $DriverInfoWebRequestContent = $DriverInfoWebRequest.Content

            $DriverInfoHTML = $DriverInfoWebRequest.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
            $DriverInfoHEAD = $DriverInfoHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
            $DriverInfoMETA = $DriverInfoHEAD.childNodes | Where-Object {$_.nodename -like "meta*"} | Select-Object -Property Name, Content
            $OSCompatibility = $DriverInfoMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
            Write-Verbose "OSCompatibility: $OSCompatibility"
            #=================================================
            #   Driver Filter
            #=================================================
            $ZipFileResults = @($DriverInfoWebRequestContent -split " " -split '"' -match 'http' -match "downloadmirror" -match ".zip")
            $ZipFileResults = $ZipFileResults | Select-Object -Unique
            #=================================================
            #   Driver Details
            #=================================================
            foreach ($DriverZipFile in $ZipFileResults) {
                Write-Verbose "Latest DriverPack: $DriverZipFile"
                #=================================================
                #   Defaults
                #=================================================
                $OSDVersion = $(Get-Module -Name OSD | Sort-Object Version | Select-Object Version -Last 1).Version
                $LastUpdate = [datetime] $(Get-Date)
                $OSDStatus = $null
                $OSDGroup = 'IntelEthernet'
                $OSDType = 'Driver'

                $DriverName = $null
                $DriverVersion = $null
                $DriverReleaseId = $null
                $DriverGrouping = $null

                $OsVersion = '10.0'
                $OsArch = 'x64'
                $OsBuildMax = @()
                $OsBuildMin = @()
        
                $Make = @()
                $MakeNe = @()
                $MakeLike = @()
                $MakeNotLike = @()
                $MakeMatch = @()
                $MakeNotMatch = @()
        
                $Generation = $null
                $SystemFamily = $null
        
                $Model = @()
                $ModelNe = @()
                $ModelLike = @()
                $ModelNotLike = @()
                $ModelMatch = @()
                $ModelNotMatch = @()
        
                $SystemSku = @()
                $SystemSkuNe = @()
        
                $DriverBundle = $null
                $DriverWeight = 100
        
                $DownloadFile = $null
                $SizeMB = $null
                $DriverUrl = $null
                $DriverInfo = $OfflineCloudDriverItem.DriverInfo
                $DriverDescription = $null
                $Hash = $null
                $OSDGuid = $(New-Guid)
                #=================================================
                #   LastUpdate
                #=================================================
                #$LastUpdateMeta = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                #$LastUpdate = [datetime]::ParseExact($LastUpdateMeta, "MM/dd/yyyy HH:mm:ss", $null)

                $LastUpdateMeta = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                Write-Verbose "LastUpdateMeta: $LastUpdateMeta"

                if ($LastUpdateMeta) {
                    $LastUpdateSplit = ($LastUpdateMeta -split (' '))[0]
                    #Write-Verbose "LastUpdateSplit: $LastUpdateSplit"
    
                    $LastUpdate = [datetime]::Parse($LastUpdateSplit)
                    #Write-Verbose "LastUpdate: $LastUpdate"
                }
                #=================================================
                #   DriverUrl
                #=================================================
                $DriverUrl = $DriverZipFile
                $DownloadFile = Split-Path $DriverUrl -Leaf
                #=================================================
                #   DriverVersion
                #=================================================
                $DriverVersion = ($DownloadFile -split '.zip')[0]
                $DriverVersion = $DriverVersion -replace '_', '.'
                #=================================================
                #   Values
                #=================================================
                $DriverGrouping = $OfflineCloudDriverItem.DriverGrouping
                $DriverName = "$DriverGrouping $OsArch $DriverVersion $OsVersion"
                $DriverDescription = $DriverInfoMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
                $OSDPnpClass = 'Net'
                $OSDPnpClassGuid = '{4D36E972-E325-11CE-BFC1-08002BE10318}'
                #=================================================
                #   Create Object
                #=================================================
                $ObjectProperties = @{
                    OSDVersion              = [string] $OSDVersion
                    LastUpdate              = [datetime] $LastUpdate
                    OSDStatus               = [string] $OSDStatus
                    OSDType                 = [string] $OSDType
                    OSDGroup                = [string] $OSDGroup
        
                    DriverName              = [string] $DriverName
                    DriverVersion           = [string] $DriverVersion
                    DriverReleaseId         = [string] $DriverReleaseID
        
                    OperatingSystem         = [string[]] $OperatingSystem
                    OsVersion               = [string[]] $OsVersion
                    OsArch                  = [string[]] $OsArch
                    OsBuildMax              = [string] $OsBuildMax
                    OsBuildMin              = [string] $OsBuildMin
        
                    Make                    = [string[]] $Make
                    MakeNe                  = [string[]] $MakeNe
                    MakeLike                = [string[]] $MakeLike
                    MakeNotLike             = [string[]] $MakeNotLike
                    MakeMatch               = [string[]] $MakeMatch
                    MakeNotMatch            = [string[]] $MakeNotMatch
        
                    Generation              = [string] $Generation
                    SystemFamily            = [string] $SystemFamily
        
                    Model                   = [string[]] $Model
                    ModelNe                 = [string[]] $ModelNe
                    ModelLike               = [string[]] $ModelLike
                    ModelNotLike            = [string[]] $ModelNotLike
                    ModelMatch              = [string[]] $ModelMatch
                    ModelNotMatch           = [string[]] $ModelNotMatch
        
                    SystemSku               = [string[]] $SystemSku
                    SystemSkuNe             = [string[]] $SystemSkuNe
        
                    SystemFamilyMatch       = [string[]] $SystemFamilyMatch
                    SystemFamilyNotMatch    = [string[]] $SystemFamilyNotMatch
        
                    SystemSkuMatch          = [string[]] $SystemSkuMatch
                    SystemSkuNotMatch       = [string[]] $SystemSkuNotMatch
        
                    DriverGrouping          = [string] $DriverGrouping
                    DriverBundle            = [string] $DriverBundle
                    DriverWeight            = [int] $DriverWeight
        
                    DownloadFile            = [string] $DownloadFile
                    SizeMB                  = [int] $SizeMB
                    DriverUrl               = [string] $DriverUrl
                    DriverInfo              = [string] $DriverInfo
                    DriverDescription       = [string] $DriverDescription
                    Hash                    = [string] $Hash
                    OSDGuid                 = [string] $OSDGuid
        
                    OSDPnpClass             = [string] $OSDPnpClass
                    OSDPnpClassGuid         = [string] $OSDPnpClassGuid
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
        }
    }
    #=================================================
    #   Offline
    #=================================================
    else {
        Write-Verbose "CloudDriver Offline"
        $CloudDriver = $OfflineCloudDriver
    }
    #=================================================
    #   Remove Duplicates
    #=================================================
    $CloudDriver = $CloudDriver | Sort-Object DriverUrl -Unique
    #=================================================
    #   Select-Object
    #=================================================
    $CloudDriver = $CloudDriver | Select-Object OSDVersion, LastUpdate, OSDStatus, OSDType, OSDGroup,`
    DriverName, DriverVersion,`
    OsVersion, OsArch,`
    DriverGrouping,`
    DownloadFile, DriverUrl, DriverInfo, DriverDescription,`
    OSDGuid,`
    OSDPnpClass, OSDPnpClassGuid
    #=================================================
    #   Sort-Object
    #=================================================
    $CloudDriver = $CloudDriver | Sort-Object -Property LastUpdate -Descending
    $CloudDriver | ConvertTo-Json | Out-File "$env:TEMP\CloudDriverIntelEthernet.json" -Encoding ascii -Width 2000 -Force
    #=================================================
    #   Filter
    #=================================================
    switch ($CompatArch) {
        'x64'   {$CloudDriver = $CloudDriver | Where-Object {$_.OSArch -match 'x64'}}
        'x86'   {$CloudDriver = $CloudDriver | Where-Object {$_.OSArch -match 'x86'}}
    }
    switch ($CompatOS) {
        'Win7'   {$CloudDriver = $CloudDriver | Where-Object {$_.OsVersion -match '6.0'}}
        'Win8'   {$CloudDriver = $CloudDriver | Where-Object {$_.OsVersion -match '6.3'}}
        'Win10'   {$CloudDriver = $CloudDriver | Where-Object {$_.OsVersion -match '10.0'}}
    }
    #=================================================
    #   Return
    #=================================================
    Return $CloudDriver
    #=================================================
}