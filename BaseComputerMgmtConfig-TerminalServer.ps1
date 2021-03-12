Configuration BaseComputerManagementConfiguration
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName,		

		[Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [string]$DC,

        [Parameter(Mandatory)]
        [string]$DC1,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    
	Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    
	Node $NodeName
    {        
        xComputer JoinDomain
        {
            Name          = $MachineName
            DomainName    = $Domain
            JoinOU        = "OU=TS Servers,DC=$DC,DC=$DC1"
            Credential    = $Credential  # Credential to join to domain
        }        
	}
}

Configuration BaseComputerConfiguration
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName,		

		[Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    
	Import-DscResource -ModuleName xComputerManagement
	Import-DSCResource -ModuleName xSystemSecurity
	Import-DscResource -ModuleName xRemoteDesktopAdmin
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    
	Node $NodeName
    {        
        xUAC DisableUAC
        {
            Setting = "NeverNotifyAndDisableAll"
        }

		xRemoteDesktopAdmin EnableRemoteDesktop
        {
           Ensure = 'Present'
           UserAuthentication = 'Secure'
        }
		
		xGroup RDPGroup
        {
            Ensure = 'Present'
            GroupName = 'Remote Desktop Users'
            Members = @("$Domain\Group1Task4", "$Domain\Group2Task4")
            Credential = $Credential
        }
    
		#Ensures .Net-Framework 3.5 is present
		xWindowsFeature Net-Framework-Core
        {
            Ensure = "Present"
            Name = "Net-Framework-Core"
        }

		#Ensures .Net-Framework 4.5 is present
		xWindowsFeature Net-Framework-45-Core
        {
            Ensure = "Present"
            Name = "Net-Framework-45-Core"
        }
        
        # Ensure Spooler Service is running
        Service ServiceSpooler
        {
            Name        = "Spooler"
            StartupType = "Automatic"
            State       = "Running"
        }
	}
}