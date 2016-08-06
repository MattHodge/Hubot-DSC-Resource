#################
#  TEST HEADER  #
#################

$dscModule = 'Hubot'

$originalLocation = Get-Location

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here


describe "HubotInstallService" {

    ######################################
    #  USED FOR TESTING CLASS BASED DSC  #
    ######################################

    # To support $root\Tests folder structure
    If (Test-Path "..\$dscModule.psm1") {Copy-Item "..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # To support $root\Tests\Unit folder structure
    ElseIf (Test-Path "..\..\$dscModule.psm1") {Copy-Item "..\..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # Or simply throw...
    Else {Throw 'Unable to find source .psm1 file to test against.'}
    
    # Dot source the file to brint classes into current session
    . 'TestDrive:\script.ps1'

    ################
    #  TEST START  #
    ################

    
    context "Get" {
        BeforeEach {
            $TestClass = [HubotInstallService]::new()
            
            # Generate credentials to use
            $password = ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force
            $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'vagrant', $password      
        }

        it "does not throw" {
            { 
                $TestClass.BotPath = 'C:\myhubot'
                $TestClass.ServiceName = 'hubot_service'
                $TestClass.BotAdapter = 'slack'
                $TestClass.Ensure = 'Present'
                $TestClass.Get() 
            } | Should Not Throw
        }

        it "nssm cmds are propegated" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun | Should Not BeNullOrEmpty
        }

        it "hubot generates the correct logging path under the botpath" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().BotLoggingPath | Should BeExactly 'C:\myhubot\Logs'
        }

        it "nssm uses the correct log path when creating service" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun -contains "set hubot_service AppStdout `"c:\myhubot\Logs\hubot_service_log.txt`"" | Should Be $true
        }

        it "nssm uses the correct errorlog path when creating service" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun -contains "set hubot_service AppStderr `"c:\myhubot\Logs\hubot_service_error.txt`"" | Should Be $true
        }

        it "nssm uses localsystem to create service when no credential passed" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun -contains "set hubot_service ObjectName LocalSystem" | Should Be $true
        }

        it "nssm uses credentials to create service when a is credential passed" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Credential = $cred
            $TestClass.Get().NSSMCmdsToRun -contains "set hubot_service ObjectName .\$($cred.UserName) $($cred.GetNetworkCredential().Password)" | Should Be $true
        }

        it "nsssm uses the user provided hubot adapater" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMAppParameters | Should Be '/c .\bin\hubot.cmd -a slack'
        }
    }
}

Set-Location $originalLocation