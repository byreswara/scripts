# Deletes application schemas no longer in use
# Execute in release pipeline after all dependent processes have stopped
# See ReadMe.md for more information
 
param (
    [Parameter(Mandatory = $true)]
    # TC service user ID that is executing updates.
    # This is used to set 'updated by' database column.
    [string]$DeploymentAccountUsername,
 
    [Parameter(Mandatory = $true)]
    # Connection string to update application's database schema objects
    [string]$DbConnectionString,
    
    [Parameter(Mandatory = $true)]
    # Database Name
    [string]$DatabaseName,
 
    [Parameter(Mandatory = $true)]
    # Path to artifact files (appsettings.json, this powershell script, etc)
    [string]$ArtifactPath
)
 
Install-Module -Name SqlServer -Force
Import-Module -Name SqlServer -Force
Import-Module -Name "$ArtifactPath\SchemaManagementLibrary.psm1" -Force
 
# Execute
$ScriptName = 'CleanupOldSchemas.ps1'
 
Write-Host "$ScriptName Starting..." -ForegroundColor Green
 
$appsettingsJson = Get-AppSettingsFile -AppSettingsLocation $ArtifactPath
 
if ($DeploymentAccountUsername.Contains('\')) {
    $DeploymentAccountUsername = $DeploymentAccountUsername.Split('\')[1]
}
 
Write-Host 'Get TC User Profile ID to use in update statement Updated By field' -ForegroundColor Green
$getTcUserProfileIdQuery = Get-QueryTextToGetTcUserProfileId -UserName $DeploymentAccountUsername
$getTcUserProfileIdResults = Invoke-Sqlcmd -ConnectionString $DbConnectionString -Query $getTcUserProfileIdQuery -OutputAs dataset
if ($getTcUserProfileIdResults.Tables.Count -eq 0) {
    Write-Host "No profile ID found for deployment account user name '$($DeploymentAccountUsername)', using default ID '10001'" -ForegroundColor Yellow
    $tcUserProfileId = 10001
}
else {
    $tcUserProfileId = $getTcUserProfileIdResults.Tables[0].USER_PROFILE_ID
    Write-Host "Found profile ID '$tcUserProfileId' for user name '$($DeploymentAccountUsername)'" -ForegroundColor Green
}
 
Write-Host 'Get existing builds deployed' -ForegroundColor Green
$buildsDeployedQry = "SELECT * FROM [$($DatabaseName)].[dbo].[BuildsDeployed]"
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
 
Write-Host 'Get query to clean up unused schemas and related objects' -ForegroundColor Green
$dbContextName = $appsettingsJson.Repository.DbContextName
$cleanUpUnusedSchemasAndRelatedObjects = Get-QueryTextCleanUpUnusedSchemasAndRelatedObjects -BuildId $BuildId -DbContextName $dbContextName -DatabaseName $DatabaseName 
Write-Host 'executing query...' -ForegroundColor Blue
Write-Host $cleanUpUnusedSchemasAndRelatedObjects -ForegroundColor Magenta
$getSchemasAndSchemaObjectsToDeleteResults = Invoke-Sqlcmd -ConnectionString $DbConnectionString -Query $cleanUpUnusedSchemasAndRelatedObjects -OutputAs dataset
if ($getSchemasAndSchemaObjectsToDeleteResults.Tables.Count -eq 0) {
    Write-Host 'No schemas or schema owned objects to delete' -ForegroundColor Yellow
}
else {
    $schemasToDelete = $getSchemasAndSchemaObjectsToDeleteResults.Tables[0]
    $schemaObjectsToDelete = $getSchemasAndSchemaObjectsToDeleteResults.Tables[1]
    $sqlCleanupStatement = ''
    $schemaObjectsToDelete.foreach{ $sqlCleanupStatement += "DROP $($_.objectType) [$($_.schemaName)].[$($_.objectName)]`n"; }
    $schemasToDelete.foreach{ $sqlCleanupStatement += "DROP SCHEMA [$($_.schemaName)]`n"; }
    Write-Host 'executing sql statement(s)...' -ForegroundColor Blue
    Write-Host $sqlCleanupStatement -ForegroundColor Magenta
    Invoke-Sqlcmd -ConnectionString $DbConnectionString -Query $sqlCleanupStatement
}
 
Write-Host "$ScriptName Complete" -ForegroundColor Green
