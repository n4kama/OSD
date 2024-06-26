function Convert-XmlDellDriverPackCatalog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
		[string]$CatalogXmlPath
    )
    #=================================================
    #   Dell Catalog
    #=================================================
    [xml]$DriverPackCatalogXmlContent = Get-Content "$CatalogXmlPath" -ErrorAction Stop
    $DriverPackCatalog = $DriverPackCatalogXmlContent.DriverPackManifest.DriverPackage
    #=================================================
    #   ForEach
    #=================================================
    $ErrorActionPreference = 'SilentlyContinue'
    $global:GetOSDDriverDellModel = @()
    $global:GetOSDDriverDellModel = foreach ($item in $DriverPackCatalog) {
        #=================================================
        #   Defaults
        #=================================================
        $OSDVersion = $(Get-Module -Name OSD | Sort-Object Version | Select-Object Version -Last 1).Version
        $LastUpdate = [datetime] $(Get-Date)
        $OSDStatus = $null
        $OSDType = 'ModelPack'
        $OSDGroup = 'DellModel'

        $DriverName = $null
        $DriverVersion = $null
        $DriverReleaseId = $null
        $DriverGrouping = $null

        $OperatingSystem = @()
        $OsVersion = @()
        $OsArch = @()
        $OsBuildMax = @()
        $OsBuildMin = @()

        $Make = 'Dell'
        $MakeNe = @()
        $MakeLike = @()
        $MakeNotLike = @()
        $MakeMatch = @()
        $MakeNotMatch = @()

        $Generation = $null
        $SystemFamily = $null

        $Model = $null
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
        $DriverInfo = $null
        $DriverDescription = $null
        $Hash = $null
        $OSDGuid = $(New-Guid)
        #=================================================
        #   Get Values
        #=================================================
        $LastUpdate         = [datetime] $item.dateTime
        $DriverVersion      = $item.dellVersion.Trim()
        $DriverDelta        = $item.delta.Trim()
        $DriverFormat       = $item.format.Trim()
        $Hash               = $item.hashMD5.Trim()
        $DownloadFile       = $item.Name.Display.'#cdata-section'.Trim()
        $DriverReleaseId    = $item.releaseID.Trim()
        $SizeMB             = ($item.size.Trim() | Select-Object -Unique) / 1024
        $DriverType         = $item.type.Trim()
        $VendorVersion      = $item.vendorVersion.Trim()
        $DriverInfo         = $item.ImportantInfo.URL.Trim() | Select-Object -Unique
        $OperatingSystem    = $item.SupportedOperatingSystems.OperatingSystem.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $OsArch             = $item.SupportedOperatingSystems.OperatingSystem.osArch.Trim() | Select-Object -Unique
        $OsCode             = $item.SupportedOperatingSystems.OperatingSystem.osCode.Trim() | Select-Object -Unique
        $OsType             = $item.SupportedOperatingSystems.OperatingSystem.osType.Trim() | Select-Object -Unique
        $OsVendor           = $item.SupportedOperatingSystems.OperatingSystem.osVendor.Trim() | Select-Object -Unique
        $OsMajor            = $item.SupportedOperatingSystems.OperatingSystem.majorVersion.Trim() | Select-Object -Unique
        $OsMinor            = $item.SupportedOperatingSystems.OperatingSystem.minorVersion.Trim() | Select-Object -Unique
        $ModelBrand         = $item.SupportedSystems.Brand.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $ModelBrandKey      = $item.SupportedSystems.Brand.Key.Trim() | Select-Object -Unique
        $ModelId            = $item.SupportedSystems.Brand.Model.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $Generation         = $item.SupportedSystems.Brand.Model.Generation.Trim() | Select-Object -Unique
        $Model              = $item.SupportedSystems.Brand.Model.Name.Trim() | Select-Object -Unique
        $ModelRtsDate       = [datetime] $($item.SupportedSystems.Brand.Model.rtsdate.Trim() | Select-Object -Unique)
        $SystemSku          = $item.SupportedSystems.Brand.Model.systemID.Trim() | Select-Object -Unique
        $ModelPrefix        = $item.SupportedSystems.Brand.Prefix.Trim() | Select-Object -Unique

        if ($null -eq $Model) {Continue}
        #=================================================
        #   DriverFamily
        #=================================================
        if ($ModelPrefix -Contains 'IOT') {
            $SystemFamily = 'IOT'
            $IsDesktop = $true
        }
        if ($ModelPrefix -Contains 'LAT') {
            $SystemFamily = 'Latitude'
            $IsLaptop = $true
        }
        if ($ModelPrefix -Contains 'OP') {
            $SystemFamily = 'Optiplex'
            $IsDesktop = $true
        }
        if ($ModelPrefix -Contains 'PRE') {$SystemFamily = 'Precision'}
        if ($ModelPrefix -Contains 'TABLET') {
            $SystemFamily = 'Tablet'
            $IsLaptop = $true
        }
        if ($ModelPrefix -Contains 'XPSNOTEBOOK') {
            $SystemFamily = 'XPS'
            $IsLaptop = $true
        }
        #=================================================
        #   Corrections
        #=================================================
        if ($Model -eq 'Latitude E6420' -and $SystemSku -eq '04E4') {$Model = 'Latitude E6420 XFR'}
        if ($Model -eq 'Precision M4600') {$Generation = 'X3'}
        if ($Model -eq 'Precision M3800') {$Model = 'Dell Precision M3800'}
        #=================================================
        #   Customizations
        #=================================================
        if ($OsCode -eq 'XP') {Continue}
        if ($OsCode -eq 'Vista') {Continue}
        #if ($OsCode -eq 'Windows8') {Continue}
        #if ($OsCode -eq 'Windows8.1') {Continue}
        if ($OsCode -match 'WinPE') {Continue}
        $DriverUrl = "$UrlDownloads/$($item.path)"
        $OsVersion = "$($OsMajor).$($OsMinor)"
        $DriverName = "$OSDGroup $Generation $Model $OsVersion $DriverVersion"
        $DriverGrouping = "$Generation $Model $OsVersion"
        if (Test-Path "$DownloadPath\$DownloadFile") {
            $OSDStatus = 'Downloaded'
        }
        #=================================================
        #   Create Object 
        #=================================================
        $ObjectProperties = @{
            OSDVersion              = [string]$OSDVersion
            LastUpdate              = $(($LastUpdate).ToString("yyyy-MM-dd"))
            OSDStatus               = $OSDStatus
            OSDType                 = $OSDType
            OSDGroup                = $OSDGroup

            DriverName              = $DriverName
            DriverVersion           = $DriverVersion
            DriverReleaseId         = $DriverReleaseID

            OperatingSystem         = $OperatingSystem
            OsVersion               = $OsVersion
            OsArch                  = $OsArch
            OsBuildMax              = $OsBuildMax
            OsBuildMin              = $OsBuildMin

            Make                    = $Make
            MakeNe                  = $MakeNe
            MakeLike                = $MakeLike
            MakeNotLike             = $MakeNotLike
            MakeMatch               = $MakeMatch
            MakeNotMatch            = $MakeNotMatch

            Generation              = $Generation
            SystemFamily            = $SystemFamily

            Model                   = $Model
            ModelNe                 = $ModelNe
            ModelLike               = $ModelLike
            ModelNotLike            = $ModelNotLike
            ModelMatch              = $ModelMatch
            ModelNotMatch           = $ModelNotMatch

            SystemSku               = $SystemSku
            SystemSkuNe             = $SystemSkuNe

            DriverGrouping          = $DriverGrouping
            DriverBundle            = $DriverBundle
            DriverWeight            = [int] $DriverWeight

            DownloadFile            = $DownloadFile
            SizeMB                  = [int] $SizeMB
            DriverUrl               = $DriverUrl
            DriverInfo              = $DriverInfo
            DriverDescription       = $DriverDescription
            Hash                    = $Hash
            OSDGuid                 = $OSDGuid
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #=================================================
    #   Select-Object
    #=================================================
    $global:GetOSDDriverDellModel = $global:GetOSDDriverDellModel | Select-Object LastUpdate,`
    OSDType, OSDGroup, OSDStatus, `
    DriverGrouping, DriverName, Make, Generation, Model, SystemSku,`
    DriverVersion, DriverReleaseId,`
    OsVersion, OsArch,
    DownloadFile, SizeMB, DriverUrl, DriverInfo,`
    Hash, OSDGuid, OSDVersion
    #=================================================
    #   Sort Object
    #=================================================
    $global:GetOSDDriverDellModel = $global:GetOSDDriverDellModel | Sort-Object LastUpdate -Descending

    Return $global:GetOSDDriverDellModel

}