# Deletes application schemas no longer in use
# Executed as part of release pipeline
# See application readme.md for more information

# Mathew Ashley notes:
# update deployment account username to deployed by ado var
# update target web server to AKS cluster


param (
    [Parameter(Mandatory = $true)]
    # TC service user ID that is executing updates.
    # This is used to set 'updated by' database column.
    $Deployedby,
 
    [Parameter(Mandatory = $true)]
    # Server name(s) the service will run on.
    [string]$TargetWebServer,
 
    [Parameter(Mandatory = $true)]
    # Connection string to update application's database schema objects
    [string]$DbConnectionString,

    [Parameter(Mandatory = $true)]
    # Database Name
    [string]$DatabaseName,
 
    [Parameter(Mandatory = $true)]
    # Path to schema scripts (SchemaManagementLibrary.psm1)
    [string]$SchemaScriptsPath,

    [Parameter(Mandatory = $true)]
    # Path to appsettings.json
    [string]$AppsettingsPath
)
 
Install-Module -Name SqlServer -Force
Import-Module -Name SqlServer -Force
Import-Module -Name "$SchemaScriptsPath\SchemaManagementLibrary.psm1" -Force
 
# Execute
$ScriptName = 'UpdateBuildsDeployed.ps1'
 
Write-Host "$ScriptName Starting..." -ForegroundColor Green


$appsettingsJson = Get-AppSettingsFile -AppSettingsLocation $AppsettingsPath

if ($Deployedby.Contains('\')) {
    $Deployedby = $Deployedby.Split('\')[1]
}
elseif ($Deployedby.Contains(' ')){
    Write-Host "deployedby = $($Deployedby)"
}
else {
    continue
}

Write-Host 'Get TC User Profile ID to use in update statement Updated By field' -ForegroundColor Green
$getTcUserProfileIdQuery = Get-QueryTextToGetTcUserProfileId -UserName $Deployedby

$getTcUserProfileIdResults = Invoke-Sqlcmd -ConnectionString $DbConnectionString -Query $getTcUserProfileIdQuery -OutputAs dataset
if ($getTcUserProfileIdResults.Tables.Count -eq 0) {
    Write-Host "No profile ID found for deployment account user name '$($Deployedby)', using default ID '10001'" -ForegroundColor Yellow
    $tcUserProfileId = 10001
}
else {
    $tcUserProfileId = $getTcUserProfileIdResults.Tables[0].USER_PROFILE_ID
    Write-Host "Found profile ID '$tcUserProfileId' for user name '$($Deployedby)'" -ForegroundColor Green
}
 
Write-Host 'Get existing builds deployed' -ForegroundColor Green
$buildsDeployedQry = "SELECT * FROM [$($DatabaseName)].[dbo].[BUILDS_DEPLOYED]"
$buildsDeployed = Invoke-Sqlcmd  -ConnectionString $DbConnectionString -Query $buildsDeployedQry
$buildsDeployed | Format-Table -AutoSize
 
$applicationVersion = $appsettingsJson.BuildInfo.ApplicationVersion
if (([string]::IsNullOrWhitespace($applicationVersion))) {
    Write-Host "'BuildInfo.ApplicationVersion' is not set in appsettings.json" -ForegroundColor Red
    exit 1
}
 
$buildId = $appsettingsJson.BuildInfo.BuildId
if (([string]::IsNullOrWhitespace($buildId))) {
    Write-Host "'BuildInfo.BuildId' is not set in appsettings.json" -ForegroundColor Red
    exit 1
}
 
$dbContextName = $appsettingsJson.Repository.DbContextName
# construct new schema name
$version = [version]$ApplicationVersion
$schemaPrefix = "$($dbContextName)V$($version.Major)" 
write-host "update args: targetwebserver: $($TargetWebServer) Applicationversion: $($applicationVersion) buildid: $($buildid), databasename: $($DatabaseName), schemaprefix: $($schemaPrefix), updatedbyuserid: $($tcUserProfileId)"
$updateAppInstanceWithCurrentSchemaQry = Get-UpdateQueryTextToUpdateBuildsDeployed -ServerNames $TargetWebServer -ApplicationVersion $applicationVersion -BuildId $buildId -DatabaseName $DatabaseName -SchemaPrefix $schemaPrefix -UpdatedByUserId $tcUserProfileId
# BuildId DatabaseName SchemaPrefix UpdatedByUserId
Write-Host 'Get update application instances with build query text' -ForegroundColor Green
Write-Host 'executing query...' -ForegroundColor Blue
Write-Host $updateAppInstanceWithCurrentSchemaQry -ForegroundColor Magenta
$mergeBuildsDeployedResult = Invoke-Sqlcmd -ConnectionString $DbConnectionString -Query $updateAppInstanceWithCurrentSchemaQry
$mergeBuildsDeployedResult | Format-Table -AutoSize
 
Write-Host "$ScriptName Complete" -ForegroundColor Green