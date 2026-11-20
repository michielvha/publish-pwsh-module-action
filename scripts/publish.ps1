<#
.SYNOPSIS
    Writes the module manifest for an exact release tag and publishes the module once.
.DESCRIPTION
    Reads its inputs from PUBLISH_* environment variables. Checks the tag before writing
    anything, writes and tests the manifest, then publishes with PSResourceGet unless the
    repository already holds that version, which ends the step as already published.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'ReleaseTag.ps1')

function Get-PublishInput {
    param([string]$Name, [switch]$Optional, [string]$Default = '')

    $value = [Environment]::GetEnvironmentVariable("PUBLISH_$Name")
    if ([string]::IsNullOrWhiteSpace($value)) {
        if ($Optional) { return $Default }
        throw "input '$($Name.ToLowerInvariant().Replace('_', '-'))' is empty"
    }
    $value
}

$version = ConvertFrom-ReleaseTag -Tag ([Environment]::GetEnvironmentVariable('PUBLISH_TAG'))
$modulePath = Get-PublishInput -Name 'MODULE_PATH'
$rootModule = Get-PublishInput -Name 'ROOT_MODULE'
$apiKey = Get-PublishInput -Name 'API_KEY'
$description = Get-PublishInput -Name 'DESCRIPTION'
$companyName = Get-PublishInput -Name 'COMPANY_NAME'
$author = Get-PublishInput -Name 'AUTHOR'
$releaseNotes = Get-PublishInput -Name 'RELEASE_NOTES' -Optional
$repository = Get-PublishInput -Name 'REPOSITORY' -Optional -Default 'PSGallery'

$moduleFile = Join-Path $modulePath "$rootModule.psm1"
if (-not (Test-Path -LiteralPath $moduleFile)) {
    throw "module file not found: $moduleFile"
}

$manifestPath = Join-Path $modulePath "$rootModule.psd1"
$manifest = @{
    Path              = $manifestPath
    RootModule        = "$rootModule.psm1"
    ModuleVersion     = $version
    FunctionsToExport = '*'
    Author            = $author
    CompanyName       = $companyName
    Description       = $description
}
if ($releaseNotes) { $manifest.ReleaseNotes = $releaseNotes }
New-ModuleManifest @manifest
Test-ModuleManifest -Path $manifestPath | Out-Null

# A published version cannot change, so an existing one means a retried release.
$existing = Find-PSResource -Name $rootModule -Version $version -Repository $repository -ErrorAction SilentlyContinue
if ($existing) {
    Write-Output "$rootModule $version is already published in $repository; nothing to publish."
    exit 0
}

# PSResourceGet publishes from a folder named after the module.
$staging = Join-Path ([IO.Path]::GetTempPath()) "publish-pwsh-module-$PID" $rootModule
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-Item -Path (Join-Path $modulePath '*') -Destination $staging -Recurse
Publish-PSResource -Path $staging -Repository $repository -ApiKey $apiKey
Remove-Item -LiteralPath (Split-Path -Parent $staging) -Recurse -Force
Write-Output "Published $rootModule $version to $repository"
