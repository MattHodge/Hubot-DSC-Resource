Configuration HubotPrerequisites
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $ChocolateyInstallPath = 'C:\choco',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $PsDscRunAsCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $GitDownloadUri
    )

    # Import the module that defines custom resources
    Import-DscResource -Module cChoco


    cChocoInstaller installChoco
    {
        InstallDir = $ChocolateyInstallPath
    }
    
    # need to run the git installer under a user account otherwise the install just hangs
    cChocoPackageInstaller installGit
    {
        Name = "git"
        DependsOn = "[cChocoInstaller]installChoco"
        PsDscRunAsCredential = $PsDscRunAsCredential
    }

    cChocoPackageInstaller installnssm
    {
        Name = "nssm"
        DependsOn = "[cChocoInstaller]installChoco"
    }

    cChocoPackageInstaller installNode
    {
        Name = "nodejs.install"
        Version = "5.10.1"
        DependsOn = "[cChocoInstaller]installChoco"
    }   

}