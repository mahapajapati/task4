<#
.SYNOPSIS
Set network configuration for a Terminal Server.

.DESCRIPTION
Set the network configuration for a Terminal Server.

.PARAMETER NodeName
Hostname of the machine where the configuration will be applied.

.PARAMETER InterfaceAlias
Alias of the network interface for which the IP address should be set.

.PARAMETER AddressFamily
IP address family.
Possible values are IPv4, IPv6.

.PARAMETER IPAddress
The desired IP address, including prefix length using CIDR notation.

.PARAMETER DefaultGateway
The desired default gateway address.

.PARAMETER DnsServerAddress
The desired DNS Server address(es). Exclude to enable DHCP.

.PARAMETER Validate
Requires that the DNS Server addresses be validated if they are updated.

.EXAMPLE
. .\BaseNetworkConfiguration.ps1
$DSCParams = @{
    NodeName = $NodeName
    InterfaceAlias = $InterfaceAlias 
    IPAddress = $IPAddress
    DefaultGateway = $DefaultGateway
    DnsServerAddress = $DnsServerAddress
}
BaseNetworkConfiguration @DSCParams
Set-DscLocalConfigurationManager -Path .\BaseNetworkConfiguration.ps1

#>

Configuration BaseNetworkConfiguration
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName,
		
		[Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily = 'IPv4',

		[Parameter(Mandatory)]
        [string]$IPAddress,

		[Parameter(Mandatory)]
        [string]$DefaultGateway,

		[Parameter(Mandatory)]
        [array]$DnsServerAddress,

        [Parameter(Mandatory)]
        [String]$Domain,

        [Boolean]$Validate
    )
    
	Import-DscResource -Module xNetworking
    
	Node $NodeName
    {
        # Set IP Address
		xIPAddress NewIPAddress
        {
            IPAddress      = $IPAddress
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
        
        # Set default Gateway
		xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = $DefaultGateway
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
    
        # Set DNS Server addresses
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DnsServerAddress
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
            Validate       = $Validate
        }
        
        # Set connection-specific suffix to the network interface
        xDnsConnectionSuffix xDnsConnectionSuffix
        {
            InterfaceAlias = $InterfaceAlias
            ConnectionSpecificSuffix = $Domain
        }
    }
}