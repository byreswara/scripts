# Maintains schema build definitions defined in appsettings.json and sql files
# executed as part of build pipeline
# see application readme.md for more information
 
param (
    [Parameter(Mandatory = $true)]
    # unique ID assigned to build, e.g. 235932
    [long]$BuildId,
 
    [Parameter(Mandatory = $true)]
    # service or worker version (aka buildNumber) e.g. 1.0.0.
    # will clean off extra characters e.g. 1.1.1-PR1234 will become 1.1.1
    [string]$ApplicationVersion,
 
    [Parameter(Mandatory = $true)]
    # path to service project containing app settings file e.g. ".\TC.Enterprise.Claim.WebService"
    [string]$AppsettingsPath,

	# Data project relative path e.g. ".\Claim.Database.Build"
    [Parameter(Mandatory = $true)]
    [string]$DbBuildProjectPath,
 
    [Parameter(Mandatory = $false)]
    # path to worker project containing app settings file e.g. ".\TC.Enterprise.Claim.Worker.Internal"
	# if no service and worker only do not use this parameter, instead put worker in AppsettingsPath
    [string]$WorkerProjectPath
)
 
function Update-SchemaVersion
{
    param (
        [string] $BuildId,
        [string] $ApplicationVersion,
        [string] $AppSettingsPath,
        [string] $DbBuildProjectPath
    )
 
    # read in appsetting.json
    $appsettingsFile = [IO.Path]::Combine($AppSettingsPath, "appsettings.json");
    Write-Host "##[group] processing $($appsettingsFile)";
    $json = Get-Content -Raw $appsettingsFile | ConvertFrom-Json -Depth 100;
 
    # construct new schema name
    $version = [version]$ApplicationVersion;
    $newSchemaName = "$($json.Repository.DbContextName)V$($version.Major)_BuildId$($BuildId)";
 
    # preserve token schema name to later search and replace
    $schemaNameToReplace = $json.Repository.DbSchemaName;
 
    # update and save json with new schema name
    $json.Repository.DbSchemaName = $newSchemaName;
    $json.BuildInfo.ApplicationVersion = $ApplicationVersion;
    $json.BuildInfo.BuildId = $BuildId;
    $json | ConvertTo-Json -Depth 100 | Set-Content -Path $appsettingsFile;
    Write-Host "Appsettings updated to " -ForegroundColor Cyan;
    $json;
    Write-Host "##[endgroup]";
 
    if ($DbBuildProjectPath)
    {
        Update-SearchAndReplaceValueInFiles -Path $DbBuildProjectPath -Extension 'sql' -SearchText $schemaNameToReplace -ReplaceText $newSchemaName;
    }
}
 
function Update-SearchAndReplaceValueInFiles
{
    param (
        [string] $path,
        [string] $extension,
        [string] $searchText,
        [string] $replaceText
    )
 
    $files = Get-ChildItem $path -Filter *.$extension -Recurse | where-object Directory -notlike "*bin*" | where-object Directory -Notlike "*obj*" | where-object Name -Notlike "*.csproj*";
 
    Write-Host "##[group] Searching Path: $($path) for text: $($searchText)";
 
    $filesWithContent = New-Object System.Collections.ArrayList;
    foreach ($file in $files)
    {
        $matchingLine = Select-String -Pattern $searchText -Path $file;
        if ($matchingLine.Count -gt 0)
        {
            Write-Host "##[section] File: $($file.Name) contains $($matchingLine.Count) matches...";
            Write-Host $matchingLine;
            $filesWithContent.Add($file);
        }
    }
    Write-Host "##[endgroup]";
 
    Write-Host "##[command] Replacing text: $($searchText) with $($replaceText) in $($filesWithContent.Count) files";
 
    foreach ($fileWithContent in $filesWithContent)
    {
        ((Get-Content -Path $fileWithContent) -Replace $searchText, $replaceText | Set-Content -Path $fileWithContent);
    }
    Write-Host "##[section] Replace text operation has completed";
}
 
# Execute
Write-Host "##[section]========== AddVersionToSqlSchema.ps1 Starting ========== ";
 
# remove additional characters from application version such as '-PullRequest12345.12' in string 1.138.1-PullRequest12345.12
$ApplicationVersion = [regex]::Match($ApplicationVersion, '\d+(?:\.\d+)*').Value;
 
Write-Host "Inputs: BuildId '$($BuildId)', ApplicationVersion '$($ApplicationVersion)', AppsettingsPath '$($AppsettingsPath)', DbBuildProjectPath '$($DbBuildProjectPath)', WorkerProjectPath '$($WorkerProjectPath)'";
 
Update-SchemaVersion -BuildId $BuildId -ApplicationVersion $ApplicationVersion -AppSettingsPath $AppsettingsPath -DbBuildProjectPath $DbBuildProjectPath;
if ($WorkerProjectPath.Length -gt 0)
{
	Update-SchemaVersion -BuildId $BuildId -ApplicationVersion $ApplicationVersion -AppSettingsPath $WorkerProjectPath;
}
 
Write-Host "##[section]========== AddVersionToSqlSchema.ps1 Complete ========== ";
