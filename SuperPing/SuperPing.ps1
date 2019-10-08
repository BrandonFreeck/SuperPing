Param (
    [array]$Targets = ("google.com", "192.168.7.1", "172.17.0.50"),
    $Hours = 15
    )

$Code = {
    Param (
    $Duration = .01,
    $TestTarget = "google.com",
    $LogPath = $PSScriptRoot + "\log.csv"
    )

    $Count = $Duration*60*60
    $Ping = @()

    #Test if path exists, if not, create it
    If (-not (Test-Path (Split-Path $LogPath) -PathType Container)) {   
        Write-Host "Folder doesn't exist $(Split-Path $LogPath), creating..."
        New-Item (Split-Path $LogPath) -ItemType Directory | Out-Null
    }

    #Test if log file exists, if not seed it with a header row
    If (-not (Test-Path $LogPath)) {   
        Write-Host "Log file doesn't exist: $($LogPath), creating..."
        Add-Content -Value '"TimeStamp","Source","Destination","Status","ResponseTime"' -Path $LogPath
    }

    #Log collection loop
    Write-Host "Beginning Ping monitoring of $TestTarget for $Count tries:"
    While ($Count -gt 0) {   
        $Ping = Get-WmiObject Win32_PingStatus -Filter "Address = '$TestTarget'" | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.__Server }},@{Label="Destination";Expression={ $_.Address }},@{Label="Status";Expression={ If ($_.StatusCode -ne 0) {"Failed"} Else {""}}},ResponseTime
        $Result = $Ping | Select TimeStamp,Source,Destination,Status,ResponseTime | ConvertTo-Csv -NoTypeInformation
        $Result[1] | Add-Content -Path $LogPath
        Write-Host ($Ping | Select TimeStamp,Source,Destination,Status,ResponseTime | Format-Table -AutoSize | Out-String)
        $Count --
        Start-Sleep -Seconds 1
    }
}

$JobCount = 1
$FullPath = ""
$JobName = ""

ForEach ($Target in $Targets) {
    $FullPath = $PSScriptRoot + "\log" + $JobCount + ".csv"
    $JobName = "PingJob" + $JobCount
    Start-Job -Name $JobName -ScriptBlock $Code -ArgumentList @($Hours, $Target, $FullPath)
    $JobCount ++
}