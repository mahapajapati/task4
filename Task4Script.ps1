<#
.SYNOPSIS
Configure a Terminal Server.

.DESCRIPTION
The script can perform the following steps:
- Network configuration
    Set static IP, Gateway and DNS Server
- Domain Configuration
    Joing the node to the specified domain taskfourtest.com
- Computer Configuration
    * Disable UAC
    * Enable remote connections
    * Add AD groups "Group1Task4, Group2Task4" to the local group "Remote Desktop Users"
    * Ensure .Net 3.5 is installed
    * Ensure .Net 4.5 is installed
    * Ensure "Spooler" service is running
- Script Resource Configuration
    * Ensure "script.txt" exists if not create it
    * Ensure "script.txt" has the properties "startup_type='Automatic' and state='running'"
    * Ensure DSCTest exists and it is a shared folder
- LCM Configuration
    * Configure LCM with these options: Reboot if needed = true, Refresh Mode = Push

.PARAMETER NodeName
Name of the machine to configure

.PARAMETER MachineName
Name of the machine to configure, should be the same as NodeName.

.PARAMETER Domain
Name of the Domain where DSC configuration will take place.

.PARAMETER InstallModules
Switch parameter to whether or not install the PS modules.

.PARAMETER NetworkConfig
Switch parameter to whether or not run the network configurations.

.PARAMETER DomainConfig
Switch parameter to whether or not run the join to the domain.

.PARAMETER ComputerConfig
Switch parameter to whether or not run the computer configurations.
i.e.
    * Disable UAC
    * Enable remote connections
    * Add AD groups "Group1Task4, Group2Task4" to the Remote Desktop Users

.PARAMETER LCMConfig
Switch parameter to whether or not run the LCM configuration.

.PARAMETER All
Switch parameter to enable all the configurations.

.EXAMPLE
.\Task4Script.ps1 -InstallModules -All
#>

param
(    
	[string]$NodeName = $ENV:computername,
	[string]$MachineName = $ENV:computername,
    [switch]$InstallModules,
    [switch]$NetworkConfig,
    [switch]$DomainConfig,
    [switch]$ComputerConfig,
    [switch]$ScriptResourceConfig,
    [switch]$LCMConfig,
    [switch]$All
)

############################
## Default Values ##
############################

$InterfaceAlias = "Ethernet"
$IPAddress = "192.168.100.70"
$DefaultGateway = "192.168.100.1"
$DnsServerAddress = "192.168.100.67"
$Domain= "taskfourtest.com"
$domainUser = "TASKFOURTEST\Administrador"
$domainUserPwdPlainText = "Admin123."

#########################
## Start Configuration ##
#########################

if ($All) {
    # $NetworkConfig = $true
    # $DomainConfig = $true
    # $ComputerConfig = $true
    # $ScriptResourceConfig = $true
    $LCMConfig = $true
}

if ($InstallModules) {
    ## Install PowerShell Modules ##
    $ModulesNamesList = @('PackageManagement',
                    'PowerShellGet',
                    'xComputerManagement',
                    'xNetworking',
                    'xPSDesiredStateConfiguration',
                    'xRemoteDesktopAdmin',
                    'xSystemSecurity',
                    'PolicyFileEditor')

    # Install-NuGetProvider
    Install-PackageProvider -Name Nuget

    $ModulesNamesList | ForEach-Object {
        Write-Host "Installing Package $_" -f Cyan
        Install-Module -Name $_ -Force
    }
}

if ($NetworkConfig) {
    
    ## IP Address ##
    Write-Host "Selected IP: $IPAddress" -f Cyan

    # Network Configuration
    $IPAddress = "$IPAddress/24"
    Write-Host "Load Network Configuration Recipe..." -f Cyan
    . $PSScriptRoot\BaseNetworkConfiguration.ps1

    Write-Host "Compile Network Configuration..." -f Cyan

    BaseNetworkConfiguration -NodeName $NodeName `
                            -InterfaceAlias $InterfaceAlias `
                            -IPAddress $ipAddress `
                            -DefaultGateway $DefaultGateway `
                            -DnsServerAddress $DnsServerAddress `
                            -Domain $Domain

    Write-Host "Execute Network Configuration..." -f Cyan
    Start-DscConfiguration -Wait -Verbose -Path .\BaseNetworkConfiguration -Force

    Write-Host "Finished Network Configuration" -f Cyan
    Start-Sleep -s 5
}

if ($DomainConfig -or $ComputerConfig) {

    # Computer Management Configuration
    Write-Host "Configure Domain [$Domain] Credentials..." -f Cyan

    $Password = $domainUserPwdPlainText | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $domainUser, $Password

    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName = $NodeName
                # Allows credential to be saved in plain-text in the the *.mof instance document.
                PSDscAllowPlainTextPassword = $true
            }
        )
    }

    $DomainComponents = $Domain.Split('.')
    $DC = $DomainComponents[0]
    $DC1 = $DomainComponents[1]

    Write-Host "Load ComputerManagement Configuration Recipe..." -f Cyan
    . $PSScriptRoot\BaseComputerMgmtConfig-TerminalServer.ps1

    if ($DomainConfig) {
        Write-Host "Compile ComputerManagement Configuration..." -f Cyan
        BaseComputerManagementConfiguration -NodeName $NodeName `
                                            -ConfigurationData $ConfigData `
                                            -MachineName $MachineName `
                                            -Domain $Domain `
                                            -DC $DC `
                                            -DC1 $DC1 `
                                            -Credential $Credential
        
        Write-Host "Execute ComputerManagement Configuration..." -f Cyan
        Start-DscConfiguration -Wait -Verbose -Path .\BaseComputerManagementConfiguration -Force
        Start-Sleep -s 3
    }

    if ($ComputerConfig) {

        # Computer Configuration
        Write-Host "Compile Computer Configuration..." -f Cyan
        BaseComputerConfiguration -NodeName $NodeName `
                                            -ConfigurationData $ConfigData `
                                            -MachineName $MachineName `
                                            -Domain $Domain `
                                            -Credential $Credential

        Write-Host "Execute Computer Configuration..." -f Cyan
        Start-DscConfiguration -Wait -Verbose -Path .\BaseComputerConfiguration -Force
        Start-Sleep -s 3
    }
}

if ($ScriptResourceConfig) {

    # Script Resource Configuration
    Write-Host "Load ScriptResource Configuration Recipe..." -f Cyan
    . $PSScriptRoot\ScriptResourceConfiguration.ps1

    Write-Host "Compile Script Resource Configuration..." -f Cyan
    ScriptTest -NodeName $NodeName

    Write-Host "Execute ScriptTest Configuration..." -f Cyan
    Start-DscConfiguration -Wait -Verbose -Path .\ScriptTest -Force

    Write-Host "Compile Script Resource Configuration 2..." -f Cyan
    ScriptTest2 -NodeName $NodeName

    Write-Host "Execute ScriptTest2 Configuration..." -f Cyan
    Start-DscConfiguration -Wait -Verbose -Path .\ScriptTest2 -Force

    Write-Host "Compile Script Resource Configuration 3..." -f Cyan
    ScriptTest3 -NodeName $NodeName

    Write-Host "Execute ScriptTest3 Configuration..." -f Cyan
    Start-DscConfiguration -Wait -Verbose -Path .\ScriptTest3 -Force

    Start-Sleep -s 3
}

if ($LCMConfig) {

    # Script Resource Configuration
    Write-Host "Load LCM Configuration Recipe..." -f Cyan
    . $PSScriptRoot\LCMConfig.ps1

    Write-Host "Compile LCM Configuration..." -f Cyan
    LCMConfig -NodeName $NodeName

    Write-Host "Execute LCM Configuration..." -f Cyan
    Set-DscLocalConfigurationManager -Path .\LCMConfig

    Start-Sleep -s 3
}

Write-Host "Configuration Finished!" -BackgroundColor Magenta

# [string]$rebootResponse = $( Read-Host "`nBox needs to be rebooted. ...Do you want to proceed?:[Y] Yes, [N] No" )

# if ($rebootResponse -eq "Y") {
# 	Restart-Computer
# }