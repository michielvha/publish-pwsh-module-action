function Get-Example {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    'example'
}

Export-ModuleMember -Function Get-Example
