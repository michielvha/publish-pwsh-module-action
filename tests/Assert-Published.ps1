# Fails unless the local test repository holds exactly one package of the given version.
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$found = @(Find-PSResource -Name Example -Version $Version -Repository $Repository)
if ($found.Count -ne 1) {
    throw "expected Example $Version once in $Repository, found $($found.Count)"
}
Write-Output "Example $Version is published once in $Repository"
