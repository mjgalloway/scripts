#Do not edit in an ASCII editor.

#region Description
<#

.SYNOPSIS
    Configures Nutanix cluster options that are typically set during the intial deployment. 
	
.DESCRIPTION
    The script will configure the following Nutanix settings:
	DNS
	NTP
	SMTP
	Storage Pool
	Storage Container
	Mounting to ESXi host

#>	
#endregion Description

#region Syntax Example
<#

.Example
	Remember to change username and password in "Connect to the Nutanix Cluster" section.
	Remember to change IP info in "Variable Input" section.
	
	PS C:\PSScript > .\Nutanix_Cluster_Configure_v1.ps1

#>
#endregion Syntax Example

#region Author
<#

.Author
    NAME: Nutanix_Cluster_Configure_v1.ps1
    VERSION: 1.0
    AUTHOR: Marc Galloway
	CONTACT: mgalloway@evtcorp.com
    LASTEDIT: August 15, 2015
	
#>
#endregion Author

#region Variable Input 

##Modify IP address and naming to reflect values for your deplyment.##

##Nutanix Cluster IP##
	$nutanixClusterIP = "172.16.203.135"

##DNS Servers##
	$nameServer1 = "8.8.8.8"
	$nameServer2 = "192.168.1.1"

##NTP Servers##
	$ntpServer1 = "0.north-america.pool.ntp.org"
	$ntpServer2 = "1.north-america.pool.ntp.org"
	
##SMTP Settings##
	$smtpServer = "mail.fake.com"
	$smtpPort = "25"
	$smtpFromAddress = "john.doe@acme.com"
	
##Storage Parameters##
	$storagePool = "SP1"
	$containerName = "NTNX-container1"
	
##Verbosity Type##
##Options: BASIC, BASIC-COREDUMP, NONE##
	$pulseLevel = "Basic"
	
#endregion Variable Input	

#region Loading cmdlets

Add-PsSnapin NutanixCmdletsPSSnapin

#endregion Loading cmdlets completed

#region Connect to Nutanix Cluster

##Connect to the Nutanix Cluster##
Connect-NutanixCluster -Server $nutanixClusterIP -UserName Admin -Password nutanix/4u -AcceptInvalidSSLCerts | Out-Null

#endregion Connect to Nutanix Cluster

#region Main Code Loop

##Set DNS servers##
if( ($nameServer1.length -gt 0) -and ($nameServer2.length -gt 0) ) {
   
   ##Clean up old records##
   [void](get-NTNXnameServer | remove-NTNXnameServer)
 
   write-host "Adding DNS servers: "$nameServer1","$nameServer2
   [void](add-NTNXnameServer -input $nameServer1)
   [void](add-NTNXnameServer -input $nameServer2)
 
} else {
   write-host "Adding DNS server: "$nameServer1
   [void](add-NTNXnameServer -input $nameServer1)
}
 
##Set NTP servers##
if( ($ntpServer1.length -gt 0) -and ($ntpServer2.length -gt 0) ) {
   
   ##Clean up old records##
   [void](get-NTNXntpServer | remove-NTNXntpServer)
 
   write-host "Adding NTP servers: "$ntpServer1","$ntpServer2
   [void](add-NTNXntpServer -input $ntpServer1)
   [void](add-NTNXntpServer -input $ntpServer2)
   
} else {
	write-host "Adding NTP server: "$ntpServer1
	[void](add-NTNXntpServer -input $ntpServer1)
}
 
##Set SMTP server##
if( $smtpServer -gt 0) {
   
   ##Clean up old records##
   [void](remove-NTNXsmtpServer)
 
   write-host "Adding SMTP server: "$smtpServer
   [void](set-NTNXsmtpServer -address $smtpServer -port $smtpPort -fromEmailAddress $smtpFromAddress)
}
 
##Create Storage##
$array =@()
 
(get-ntnxdisk) |% {
   $hardware = $_
   write-host "Adding disk "$hardware.id" to the array"
   $array += $hardware.id
}
 
write-host "Creating a new storage: $storagePool"
new-NTNXStoragePool -name $storagePool -disks $array
$newStoragePool=get-NTNXStoragePool
 
write-host "Creating container: $containerName"
new-NTNXContainer -storagepoolid $newStoragePool.id -name $containerName
sleep 3
write-host "Adding container $containerName to ESXi hosts"
add-NTNXnfsDatastore -containerName $containerName
 
##Set Pulse verbosity level##
write-host "Setting Pulse verbosity level to: "$pulseLevel
[void](set-NTNXcluster -supportVerbosityType $pulseLevel)

#endregion Main Code Loop