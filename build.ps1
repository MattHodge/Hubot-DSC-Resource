[cmdletbinding()]
param(
    [string[]]$Task = 'default'
)

if (!(Get-Module -Name Pester -ListAvailable)) { Install-Module -Name Pester -Force -Scope CurrentUser }
if (!(Get-Module -Name psake -ListAvailable)) { Install-Module -Name psake -Force -Scope CurrentUser }
if (!(Get-Module -Name PSDeploy -ListAvailable)) { Install-Module -Name PSDeploy -Force -Scope CurrentUser }

if (-not($env:APPVEYOR))
{
    $env:appveyor_build_version = '10.10.10'
}

# Invoke PSake
Invoke-psake -buildFile "$PSScriptRoot\psakeBuild.ps1" -taskList $Task -parameters @{'build_version' = $env:appveyor_build_version} -Verbose:$VerbosePreference