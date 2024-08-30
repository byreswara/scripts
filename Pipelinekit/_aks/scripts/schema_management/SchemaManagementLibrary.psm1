# Library functions used by Schema Management scripts
# See ReadMe.md for more information

function Get-AppSettingsFile {
    param (
        [Parameter(Mandatory = $true)]
        # Path to file containing appsettings.json or path to zip containing appsettings.json
        [string]$AppSettingsLocation
    )
 
    $appSettingFileName = 'appsettings.json'
    Write-Host "Retrieving $appSettingFileName from $AppSettingsLocation" -ForegroundColor Green
    $appSettings = ''
    $appSettingsFile = Join-Path $AppSettingsLocation -ChildPath $appSettingFileName
 
    if (Test-Path $appSettingsFile -PathType Leaf) {
        Write-Host "Found file: $appSettingsFile"
        $jsonStreamReader = New-Object System.IO.StreamReader($appSettingsFile)
        $appSettings = $jsonStreamReader.ReadToEnd() | ConvertFrom-Json -Depth 100
        $jsonStreamReader.Close()
    }
    else {
        $artifactZip = Get-ChildItem -Path $AppSettingsLocation -Filter '*.zip'
        Write-Host "Found artifact zip file: $($artifactZip.FullName)"
        Write-Host "Checking for $appSettingFileName in zip file: "
        $artifactStream = [System.IO.Compression.ZipFile]::OpenRead($($artifactZip.FullName))
        $jsonEntry = $artifactStream.Entries | Where-Object { $_.Name -eq $appSettingFileName }
 
        if ($jsonEntry) {
            Write-Host "Reading $appSettingFileName from zip file location: $jsonEntry"
            $jsonStream = $jsonEntry.Open()
            $jsonStreamReader = New-Object System.IO.StreamReader($jsonStream)
            $appSettings = $jsonStreamReader.ReadToEnd() | ConvertFrom-Json -Depth 100
            $jsonStreamReader.Close()
            $jsonStream.Close()
        }
 
        $artifactStream.Dispose()
    }
 
    if ($appSettings -eq '') {
        Write-Host "'$appSettingFileName' was not found in artifact folder. Exiting Script." -ForegroundColor Red
        exit 1
    }
 
    Write-Host "Retrieved $appSettingFileName" -ForegroundColor Green
    return $appSettings
}
 
function Get-QueryTextToGetTcUserProfileId {
    param (
        [Parameter(Mandatory = $true)]
        # TC service user ID that is executing updates
        [string]$UserName
    )
    return @"   
    DECLARE @userName VARCHAR(256) = '$($UserName)';  --provided by devops as parameter   
    SELECT TOP 1 up.USER_PROFILE_ID FROM [TCAuthorization].[dbo].[USER_PROFILE] up
    WHERE up.AD_FIRST_NAME = @userName OR up.AD_LAST_NAME = @userName
    AND up.IS_DELETED != 1   
"@
}
 
function Get-UpdateQueryTextToUpdateBuildsDeployed {
    param (
        [Parameter(Mandatory = $true)]
        # Name of the servers the service is running on
        [string]$ServerNames,
 
        [Parameter(Mandatory = $true)]
        # Application version
        [string]$ApplicationVersion,
 
        [Parameter(Mandatory = $true)]
        # Azure build ID
        [string]$BuildId,

        [Parameter(Mandatory = $true)]
        # Database name
        [string]$DatabaseName,
 
        [Parameter(Mandatory = $true)]
        # Schema Prefix
        [string]$SchemaPrefix,
		
        [Parameter(Mandatory = $true)]
        # TC service user ID that is executing updates
        [long]$UpdatedByUserId
    )
    return @"
    DECLARE @charDelimitedServerNames AS NVARCHAR(256) = '$($ServerNames)';
    DECLARE @applicationVersion AS NVARCHAR(16) = '$($ApplicationVersion)';
    DECLARE @buildId AS NVARCHAR(32) = '$($BuildId)';
	DECLARE @schemaPrefix As NVARCHAR(256) ='$($SchemaPrefix)';
    DECLARE @updateById as BIGINT = $($UpdatedByUserId);
    DECLARE @now DATETIME = GETUTCDATE();
     
    DECLARE @serverNames TABLE (ServerName NVARCHAR(256))
    INSERT INTO @serverNames (ServerName)   SELECT TRIM(value) AS ServerName
											FROM STRING_SPLIT(@charDelimitedServerNames, ',') s1
											WHERE TRIM(s1.value) != ''
 
    MERGE [$($DatabaseName)].[dbo].[BUILDS_DEPLOYED] target
    USING (
        SELECT ServerName from @serverNames)
        SOURCE (ServerName)
    ON
        (target.APPLICATION_SERVER_NAME = source.ServerName AND target.SCHEMA_PREFIX = @schemaPrefix)
    WHEN MATCHED THEN
        UPDATE
        SET [APPLICATION_SERVER_NAME] = serverName,
			[SCHEMA_PREFIX] = @schemaPrefix,
			[APPLICATION_VERSION] = @applicationVersion,
            [BUILD_ID] = @buildId,
            [UPDT_BY] = @updateById,
            [UPDT_TS] = @now
    WHEN NOT MATCHED THEN
        INSERT (Application_Server_Name, SCHEMA_PREFIX, Application_Version, Build_Id, CREATE_BY, CREATE_TS)
        VALUES (ServerName, @schemaPrefix, @applicationVersion, @buildId, @updateById, @now);
"@
}
 
function Get-QueryTextCleanUpUnusedSchemasAndRelatedObjects {
    param (
        [Parameter(Mandatory = $true)]
        # Azure build ID
        [string]$BuildId,
 
        [Parameter(Mandatory = $true)]
        # Name of the database context as used in the repository, this is different than the database name
        [string]$DbContextName,

        [Parameter(Mandatory = $true)]
        # Database name
        [string]$DatabaseName
    )
    return @"
    DECLARE @buildId AS NVARCHAR(32) = '$($BuildId)';
    DECLARE @dbContextName NVARCHAR(32) = '$($DbContextName)';
    DECLARE @schemasToDelete TABLE (schemaId BIGINT, schemaName SYSNAME, buildId NVARCHAR(32));
    DECLARE @schemaObjectsToDelete TABLE (schemaName SYSNAME, objectType NVARCHAR(32), objectName SYSNAME);
     
    --schemas to delete
    INSERT INTO @schemasToDelete (schemaId, schemaName)
    SELECT s.[schema_id], s.[name]
    FROM [$($DatabaseName)].[sys].[schemas] s
    LEFT JOIN [$($DatabaseName)].[dbo].[BUILDS_DEPLOYED] b on b.BUILD_ID = SUBSTRING(s.[name], CHARINDEX('_', s.[name]) + LEN('BuildId') + 1, LEN(s.[name]))
    WHERE s.[name] LIKE CONCAT(@dbContextName,'V%', 'BUILDID%') and b.BUILD_ID is null
     
    select schemaName from @schemasToDelete
     
    --procedures to delete
    INSERT INTO @schemaObjectsToDelete (schemaName, objectType, objectName)
    SELECT s2d.schemaName, 'PROCEDURE', p.[name]
    FROM [$($DatabaseName)].[sys].[procedures] p
    JOIN @schemasToDelete s2d ON p.[schema_id] = s2d.schemaId
     
    --functions to delete
    INSERT INTO @schemaObjectsToDelete (schemaName, objectType, objectName)
    SELECT s2d.schemaName, 'FUNCTION', f.[name]
    FROM [$($DatabaseName)].[sys].[objects] f
    JOIN @schemasToDelete s2d ON f.[schema_id] = s2d.schemaId
    WHERE type IN ('FN', 'IF', 'TF')
 
    --views to delete
    INSERT INTO @schemaObjectsToDelete (schemaName, objectType, objectName)
    SELECT s2d.schemaName, 'VIEW', f.[name]
    FROM [$($DatabaseName)].[sys].[objects] f
    JOIN @schemasToDelete s2d ON f.[schema_id] = s2d.schemaId
    WHERE type = 'V'
 
    --user defined types to delete
    INSERT INTO @schemaObjectsToDelete (schemaName, objectType, objectName)
    SELECT s2d.schemaName, 'TYPE', udt.[name]
    FROM [$($DatabaseName)].[sys].[types] udt
    JOIN @schemasToDelete s2d ON udt.[schema_id] = s2d.schemaId
    WHERE udt.is_user_defined = 1;
     
    select * from @schemaObjectsToDelete
"@
}
