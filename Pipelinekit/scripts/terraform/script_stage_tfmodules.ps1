param(
    [string]$tf_templates,
    [string]$build_sources_directory,
    [string]$artifact_staging_directory,
    [string]$artifact_name = "modules"
)

write-host "Module List: $tf_templates"
write-host "Terraform Template Library:"
get-childitem -Path "$build_sources_directory/TerraformTemplates/Templates/custom_modules" -Recurse

$templates = $tf_templates -split ' '

foreach ($module in $templates) {
    write-host "Staging Module: $module"
    $module_path = "$build_sources_directory/TerraformTemplates/Templates/custom_modules/$module"
    try {
        if (!(Test-Path -Path $module_path)) {
            throw "Module $module not found"
        }
    }
    catch {
        write-error $_
        exit 1
    }
    copy-item -Path "$module_path" -Destination "$artifact_staging_directory/$artifact_name/$module" -Recurse -Force
}