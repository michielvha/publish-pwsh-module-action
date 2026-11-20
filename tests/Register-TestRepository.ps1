# Registers a local folder as a PSResourceGet repository for the end-to-end run.
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $Path -Force | Out-Null
Register-PSResourceRepository -Name $Name -Uri (Resolve-Path -LiteralPath $Path).Path -Trusted
Write-Output "Registered $Name at $Path"
