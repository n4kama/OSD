function Get-HpDriverPack {
    [CmdletBinding()]
    param (
        [System.String]$DownloadPath
    )
    #=================================================
    #   Get Catalog
    #=================================================
    $Results = Get-HPDriverPackCatalogMaster | Select-Object CatalogVersion, @{Name='ReleaseDate';Expression={($_.DateReleased)}}, @{Name='Name';Expression={($_.Model)}}, @{Name='Product';Expression={($_.SystemId)}}, @{Name='DriverPackUrl';Expression={($_.Url)}}, FileName
    #=================================================
    #   DownloadPath
    #=================================================
    if ($PSBoundParameters.ContainsKey('DownloadPath')) {
        $Results = $Results | Out-GridView -Title 'Select one or more files to Download' -PassThru -ErrorAction Stop
        foreach ($Item in $Results) {
            $OutFile = Save-WebFile -SourceUrl $Item.DriverPackUrl -DestinationDirectory $DownloadPath -DestinationName $Item.FileName -Verbose
            $Item | ConvertTo-Json | Out-File "$($OutFile.FullName).json" -Encoding ascii -Width 2000 -Force
        }
    }
    else {
        $Results
    }
}