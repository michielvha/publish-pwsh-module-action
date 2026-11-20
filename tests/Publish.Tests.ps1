# End to end: publishes the fixture module to a local folder repository twice.
BeforeAll {
    $script:publish = Join-Path $PSScriptRoot '..' 'scripts' 'publish.ps1'
    $script:work = Join-Path ([IO.Path]::GetTempPath()) "publish-tests-$PID"
    $script:feed = Join-Path $work 'feed'
    $script:modulePath = Join-Path $work 'module'
    New-Item -ItemType Directory -Path $feed -Force | Out-Null
    Copy-Item -Path (Join-Path $PSScriptRoot 'fixture' 'Example') -Destination $modulePath -Recurse
    $script:repository = "publish-tests-$PID"
    Register-PSResourceRepository -Name $repository -Uri $feed -Trusted

    function Invoke-Publish([string]$Tag) {
        $env:PUBLISH_MODULE_PATH = $modulePath
        $env:PUBLISH_TAG = $Tag
        $env:PUBLISH_API_KEY = 'unused-for-a-local-repository'
        $env:PUBLISH_ROOT_MODULE = 'Example'
        $env:PUBLISH_DESCRIPTION = 'Fixture module'
        $env:PUBLISH_COMPANY_NAME = 'Example Company'
        $env:PUBLISH_AUTHOR = 'Example Author'
        $env:PUBLISH_RELEASE_NOTES = 'https://example.com/releases/tag/' + $Tag
        $env:PUBLISH_REPOSITORY = $repository
        $pwsh = (Get-Process -Id $PID).Path
        $output = & $pwsh -NoProfile -File $publish 2>&1 | Out-String
        [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $output }
    }
}

AfterAll {
    Unregister-PSResourceRepository -Name $repository -ErrorAction SilentlyContinue
    Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'publish.ps1' {
    It 'publishes a new version with the manifest fields' {
        $run = Invoke-Publish -Tag 'v1.2.3'
        $run.Exit | Should -Be 0 -Because $run.Output
        $run.Output | Should -Match 'Published Example 1.2.3'
        $found = Find-PSResource -Name Example -Version 1.2.3 -Repository $repository
        $found.Version.ToString() | Should -Be '1.2.3'
        $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $modulePath 'Example.psd1')
        $manifest.ModuleVersion | Should -Be '1.2.3'
        $manifest.Author | Should -Be 'Example Author'
        $manifest.CompanyName | Should -Be 'Example Company'
        $manifest.PrivateData.PSData.ReleaseNotes | Should -Be 'https://example.com/releases/tag/v1.2.3'
    }

    It 'succeeds without publishing when the version already exists' {
        $before = @(Get-ChildItem -Path $feed -File).Count
        $run = Invoke-Publish -Tag 'v1.2.3'
        $run.Exit | Should -Be 0 -Because $run.Output
        $run.Output | Should -Match 'already published'
        @(Get-ChildItem -Path $feed -File).Count | Should -Be $before
    }

    It 'fails before writing a manifest for a prerelease tag' {
        Remove-Item -LiteralPath (Join-Path $modulePath 'Example.psd1') -ErrorAction SilentlyContinue
        $run = Invoke-Publish -Tag 'v1.3.0-preview.1'
        $run.Exit | Should -Not -Be 0
        $run.Output | Should -Match 'v1.3.0-preview.1'
        Join-Path $modulePath 'Example.psd1' | Should -Not -Exist
    }
}
