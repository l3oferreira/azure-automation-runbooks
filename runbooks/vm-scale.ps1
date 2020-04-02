<#
.SYNOPSIS
Through this Automation script you can schedule a specific Azure VM at specific times for resizing. 
 
This script is highly based on Siebert Timmermans's script for Vertical Scaling, I changed to use default connection. 
 
Note: Downtime of +- 4 minutes applies when the job starts. 

.DESCRIPTION
   This script will adjust the size of a Microsoft Azure virtual machine based on input given into the new schedule.

   When making a Schedule or doing a test run you are required to declare:
   * The subscription of the VM that is to be changed
   * The resource group name of the VM that is to be changed
   * The name of the VM that is to be changed
   * The desired to be VM Size
   
   This script is based on the runbook by Siebert Timmermans, 90% of credit goes to him.
   https://siebertt.github.io/Azure-ResourcegroupVM-Rescaling-Scheduler/

.PARAMETER SubscriptionId
    String that contains the id of subscription where your specified VM is a part of.

.PARAMETER ResourceGroup
    String that contains the name of resource group where your specified VM is a part of.

.PARAMETER VMSize
     String name of the desired size the specified VM will be receiving.

.PARAMETER VirtualMachineName
     String name of the VM that will be changed in size.

.NOTES
	Author: Leonardo Ferreira
	Last Updated: 04/01/2020
    Version 1.0 - Changed Siebert Timmermans`s script to change connection.
#>
workflow VMScale {
	
    Param (    
        [parameter(Mandatory=$true)]
        [string] $SubscriptionId,

        [parameter(Mandatory=$true)]
        [string] $ResourceGroup,    

        [parameter(Mandatory=$true)]
        [String] $VirtualMachineName,
        
        [parameter(Mandatory=$true)]
        [string] $VMSize
   
    )
	inlineScript {

        $connection = Get-AutomationConnection `
            -Name 'AzureRunAsConnection'

        Write-Output "`nConnected using AzureRunAsConnection"

        Add-AzureRmAccount -ServicePrincipal `
            -TenantId $connection.TenantId `
            -ApplicationId $connection.ApplicationId `
            -CertificateThumbprint $connection.CertificateThumbprint

        Select-AzureRmSubscription `
            -SubscriptionId $Using:SubscriptionId

        Write-Output "`nSet current subscription: $Using:SubscriptionId"

        # Check if specified VM can be found
        Try {
            $vm = Get-AzureRmVm `
                -ResourceGroupName $Using:ResourceGroup `
                -VMName $Using:VirtualMachineName `
                -ErrorAction Stop

        }
        Catch {
            Write-Error "Virtual machine not found"
            Exit
        }

        # Output current VM Size
        $currentVMSize = $vm.HardwareProfile.vmSize
        
        Write-Output "`nFound the specified virtual machine: $Using:VirtualMachineName"
        Write-Output "Current size: $currentVMSize"

        # Change to new VM Size and report
	    $newVMSize = $Using:VMSize
    
        Write-Output "`nNew size will be: $newVMSize"
        Write-Output "`n----------------------------------------------------------------------"
            
        $vm.HardwareProfile.VmSize = $newVMSize
        Update-AzureRmVm -VM $vm -ResourceGroupName $Using:ResourceGroup
        
        $updatedVm = Get-AzureRmVm -ResourceGroupName $Using:ResourceGroup -VMName $Using:VirtualMachineName
        $updatedVMSize = $updatedVm.HardwareProfile.vmSize
        
        Write-Output "`n----------------------------------------------------------------------"
        Write-Output "`nSize updated to: $updatedVMSize"
 	}
}
