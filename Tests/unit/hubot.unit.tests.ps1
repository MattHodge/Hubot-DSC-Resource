$dscModule = 'Hubot'

$originalLocation = Get-Location

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here


describe "Hubot DSC Module - Unit Testing" {

    # To support $root\Tests folder structure
    If (Test-Path "..\$dscModule.psm1") {Copy-Item "..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # To support $root\Tests\Unit folder structure
    ElseIf (Test-Path "..\..\$dscModule.psm1") {Copy-Item "..\..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # Or simply throw...
    Else {Throw 'Unable to find source .psm1 file to test against.'}
    
    # Dot source the file to brint classes into current session
    . 'TestDrive:\script.ps1'

    $guid = (New-Guid).Guid

    context "RefreshPathVariable" {
        it "returns something" {
            [HubotHelpers]::new().RefreshPathVariable() | Should Not Be Null
        }

        it "return should contain atleast one semicolon" {
            [HubotHelpers]::new().RefreshPathVariable() | Should BeLike "*;*"
        }

        it "when split into array should have 2 or more items" {
            $array = [HubotHelpers]::new().RefreshPathVariable() -split ';'
            $array.Count | Should BeGreaterThan 1
        }
    }

    context "CheckPathExists" {
        it "returns true when path that exists is passed" {
            [HubotHelpers]::new().CheckPathExists("TestDrive:\") | Should Be $true
        }
        it "returns false when path that does not exist is passed" {          
            [HubotHelpers]::new().CheckPathExists("TestDrive:\$($guid)") | Should Be $false
        }
    }

    context "HubotInstall - Get" {
        it "does not throw" {
            { 
                $x = [HubotInstall]::new()
                $x.BotPath = 'C:\myhubot'
                $x.Ensure = 'Present'
                $x.Get() 
            } | Should Not Throw
        }

        it "returns a [HubotInstall] class" {
            $x = [HubotInstall]::new()
            $x.BotPath = 'TestDrive:\'
            $x.Ensure = 'Present'
            $x.Get().GetType().Name | Should Be 'HubotInstall'
        }

        it "returns ensure present if BotPath exists" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $x = [HubotInstall]::new()
            $x.BotPath = $TestDrive
            $x.Get().Ensure | Should Be 'Present'
        }

        it "node modules path should be valid" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $x = [HubotInstall]::new()
            $x.BotPath = $TestDrive
            $x.Get().NodeModulesPath | Should Be $fakeModuleFolder
        }

        it "returns ensure absent if BotPath does not exist" {
            $x = [HubotInstall]::new()
            $x.BotPath = "TestDrive:\$($guid)"
            $x.Get().Ensure | Should Be 'Absent'
        }
    }

    context "HubotInstall - Set" {
        BeforeEach {
            $TestClass = [HubotInstall]::new()          

            Mock Start-Process { return $true }

$getCmdMockObject = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <Obj RefId="0">
    <TN RefId="0">
      <T>System.Management.Automation.ApplicationInfo</T>
      <T>System.Management.Automation.CommandInfo</T>
      <T>System.Object</T>
    </TN>
    <ToString>npm.cmd</ToString>
    <Props>
      <S N="Path">C:\Program Files\nodejs\npm.cmd</S>
      <S N="Extension">.cmd</S>
      <S N="Definition">C:\Program Files\nodejs\npm.cmd</S>
      <S N="Source">C:\Program Files\nodejs\npm.cmd</S>
      <Version N="Version">0.0.0.0</Version>
      <Obj N="Visibility" RefId="1">
        <TN RefId="1">
          <T>System.Management.Automation.SessionStateEntryVisibility</T>
          <T>System.Enum</T>
          <T>System.ValueType</T>
          <T>System.Object</T>
        </TN>
        <ToString>Public</ToString>
        <I32>0</I32>
      </Obj>
      <Obj N="OutputType" RefId="2">
        <TN RefId="2">
          <T>System.Collections.ObjectModel.ReadOnlyCollection`1[[System.Management.Automation.PSTypeName, System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]]</T>
          <T>System.Object</T>
        </TN>
        <LST>
          <S>System.String</S>
        </LST>
      </Obj>
      <S N="Name">npm.cmd</S>
      <Obj N="CommandType" RefId="3">
        <TN RefId="3">
          <T>System.Management.Automation.CommandTypes</T>
          <T>System.Enum</T>
          <T>System.ValueType</T>
          <T>System.Object</T>
        </TN>
        <ToString>Application</ToString>
        <I32>32</I32>
      </Obj>
      <S N="ModuleName"></S>
      <Nil N="Module" />
      <Obj N="RemotingCapability" RefId="4">
        <TN RefId="4">
          <T>System.Management.Automation.RemotingCapability</T>
          <T>System.Enum</T>
          <T>System.ValueType</T>
          <T>System.Object</T>
        </TN>
        <ToString>PowerShell</ToString>
        <I32>1</I32>
      </Obj>
    </Props>
    <MS>
      <S N="Namespace"></S>
      <S N="HelpUri"></S>
      <Obj N="FileVersionInfo" RefId="5">
        <TN RefId="5">
          <T>System.Diagnostics.FileVersionInfo</T>
          <T>System.Object</T>
        </TN>
        <ToString>File:             C:\Program Files\nodejs\npm.cmd_x000D__x000A_InternalName:     _x000D__x000A_OriginalFilename: _x000D__x000A_FileVersion:      _x000D__x000A_FileDescription:  _x000D__x000A_Product:          _x000D__x000A_ProductVersion:   _x000D__x000A_Debug:            False_x000D__x000A_Patched:          False_x000D__x000A_PreRelease:       False_x000D__x000A_PrivateBuild:     False_x000D__x000A_SpecialBuild:     False_x000D__x000A_Language:         _x000D__x000A_</ToString>
        <Props>
          <Nil N="Comments" />
          <Nil N="CompanyName" />
          <I32 N="FileBuildPart">0</I32>
          <Nil N="FileDescription" />
          <I32 N="FileMajorPart">0</I32>
          <I32 N="FileMinorPart">0</I32>
          <S N="FileName">C:\Program Files\nodejs\npm.cmd</S>
          <I32 N="FilePrivatePart">0</I32>
          <Nil N="FileVersion" />
          <Nil N="InternalName" />
          <B N="IsDebug">false</B>
          <B N="IsPatched">false</B>
          <B N="IsPrivateBuild">false</B>
          <B N="IsPreRelease">false</B>
          <B N="IsSpecialBuild">false</B>
          <Nil N="Language" />
          <Nil N="LegalCopyright" />
          <Nil N="LegalTrademarks" />
          <Nil N="OriginalFilename" />
          <Nil N="PrivateBuild" />
          <I32 N="ProductBuildPart">0</I32>
          <I32 N="ProductMajorPart">0</I32>
          <I32 N="ProductMinorPart">0</I32>
          <Nil N="ProductName" />
          <I32 N="ProductPrivatePart">0</I32>
          <Nil N="ProductVersion" />
          <Nil N="SpecialBuild" />
        </Props>
        <MS>
          <Version N="FileVersionRaw">0.0.0.0</Version>
          <Version N="ProductVersionRaw">0.0.0.0</Version>
        </MS>
      </Obj>
    </MS>
  </Obj>
</Objs>
"@

            $myobj = [System.Management.Automation.PSSerializer]::Deserialize($getCmdMockObject)
            
            Mock Get-Command { return $myobj }

        }

        it "throws when botpath is not found" {
            {
                $TestClass.BotPath = "$TestDrive\$($guid)"
                $result = $TestClass.Get()
                $result.Set()
            } | Should Throw
        }

        it "does not throw when botpath is found and ensure is present" {
            {
                $TestClass.BotPath = "$TestDrive"
                $result = $TestClass.Get()
                $result.Ensure = 'Present'
                $result.Set()
            } | Should Not Throw
        }

        it "throws when npm not found" {
            Mock Get-Command { return $null }

            {
                $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
                New-Item -Path $fakeModuleFolder -ItemType Directory -Force
                $TestClass.BotPath = $TestDrive
                $result = $TestClass.Get()
                $result.Set()
            } | Should Throw
        }

        it "does not throw when npm not found" {
            {
                $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
                New-Item -Path $fakeModuleFolder -ItemType Directory -Force
                $TestClass.BotPath = $TestDrive
                $result = $TestClass.Get()
                $result.Set()
            } | Should Not Throw
        }
                
        it "calls start-process twice to uninstall coffee-script and then npm" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $TestClass.BotPath = $TestDrive
            $result = $TestClass.Get()
            $result.Ensure = 'Absent'
            $result.Set()
            Assert-MockCalled Start-Process 2 -Exactly -ParameterFilter {$FilePath -like "*npm*" -and $ArgumentList -like "*uninstall*"} -Scope It
        }


        it "calls start-process twice to install coffee-script and then npm install" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $TestClass.BotPath = $TestDrive
            $result = $TestClass.Get()
            $result.Set()
            Assert-MockCalled Start-Process 2 -Exactly -ParameterFilter {$FilePath -like "*npm*" -and $ArgumentList -like "*install*"} -Scope It
        }
    }

    
    context "HubotInstallService - Get" {
        BeforeEach {
            $TestClass = [HubotInstallService]::new()
            
            $mockCredentails = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <Obj RefId="0">
    <TN RefId="0">
      <T>System.Management.Automation.PSCredential</T>
      <T>System.Object</T>
    </TN>
    <ToString>System.Management.Automation.PSCredential</ToString>
    <Props>
      <S N="UserName">testcred</S>
      <SS N="Password">01000000d08c9ddf0115d1118c7a00c04fc297eb0100000022024a8d285b3c42bafde6694bbb66d3000000000200000000001066000000010000200000002b8c53179bb32647d53242cccea7d78b19539e734207a0b42eed69dad1bedb2e000000000e8000000002000020000000c220783e1d75689f27513baa1ff11cd7fee988b4b90cb3a1ae43643d3d84fee920000000232161e521b14022a83daf792dc02b060abeac90b97e7abd4a907a8d33e935e14000000051395f3ff0f13f388eb54eb2c83a52ebbbf41715f3af76217b1e5b9f1a738c92f547a2cbc03b481cdd9a94267f06dbc4e0774477531f822b92b3b0503847b7e0</SS>
    </Props>
  </Obj>
</Objs>
"@

            $cred = [System.Management.Automation.PSSerializer]::Deserialize($mockCredentails)          
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

        it "NSSMAppParameters contains the user provided adapater" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMAppParameters | Should Be '/c .\bin\hubot.cmd -a slack'
        }

        it "NSSMCmdsToRun is not null" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun | Should Not BeNullOrEmpty
        }

        it "BotLoggingPath should be 'C:\myhubot\Logs'" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().BotLoggingPath | Should BeExactly 'C:\myhubot\Logs'
        }

        it "nssm cmd 'set hubot_service AppStdout' should be 'c:\myhubot\Logs\hubot_service_log.txt'" {
                
            $TestClass = [HubotInstallService]::new()
            $TestClass.BotPath = 'C:\myhubot'
            $TestClass.ServiceName = 'hubot_service'
            $TestClass.BotAdapter = 'slack'
            $TestClass.Ensure = 'Present'
            $TestClass.Get().NSSMCmdsToRun -contains "set hubot_service AppStdout `"c:\myhubot\Logs\hubot_service_log.txt`"" | Should Be $true
        }

        it "nssm cmd 'set hubot_service AppStderr' should be 'c:\myhubot\Logs\hubot_service_error.txt'" {
                
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
    }

    context "HubotInstallService - Set" {
        BeforeEach {
            $TestClass = [HubotInstallService]::new()          

            Mock Start-Process { return $true }
            
            Mock Get-Command { return $myobj }
        }

        it "does not throw" {
            { 
                $TestClass.BotPath = 'C:\myhubot'
                $TestClass.ServiceName = 'hubot_service'
                $TestClass.BotAdapter = 'slack'
                $TestClass.Ensure = 'Present'
                $TestClass.Set()
            } | Should Throw
        }

        it "NSSMAppParameters contains the user provided adapater" {
                
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