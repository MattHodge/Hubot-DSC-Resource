Configuration HubotPrerequisites
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $ChocolateyInstallPath = 'C:\choco'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module cChoco

    cChocoInstaller installChoco
    {
        InstallDir = $ChocolateyInstallPath
    }

    cChocoPackageInstaller installnssm
    {
        Name = "nssm"
        DependsOn = "[cChocoInstaller]installChoco"
    }

    cChocoPackageInstaller installGit
    {
        Name = "git.install"
        DependsOn = "[cChocoInstaller]installChoco"
    }

    cChocoPackageInstaller installNode
    {
        Name = "nodejs.install"
        Version = "5.10.1"
        DependsOn = "[cChocoInstaller]installChoco"
    }
}