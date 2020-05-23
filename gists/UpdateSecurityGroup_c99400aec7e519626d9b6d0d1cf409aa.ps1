$urlToCheckIp = "http://check-ip.herokuapp.com"
$accessKey = "{ACCESS KEY}"
$secretKey = "{SECRET KEY}"
$region = "eu-west-1"
$dryRun = $true

$currentIp = Invoke-RestMethod -Uri $urlToCheckIp -Method GET
Write-Host "Current IP address:" $currentIp.ipAddress

$secGroup = Get-EC2SecurityGroup -Region $region -AccessKey $accessKey -SecretKey $secretKey 
$secGroupListWithSshOrRdp = $secGroup | Where-Object {$_.IpPermissions.ToPort -eq "22" -or $_.IpPermissions.ToPort -eq "3389"}
$resultSetCount = $secGroupListWithSshOrRdp.Count
Write-Host "Found" $resultSetCount "groups with SSH or RDP ports open"

foreach ($secGroup in $secGroupListWithSshOrRdp)
{
	$sshOrRdpPermissionList = $secGroup.IpPermissions | Where ToPort -in "22", "3389"

	
	foreach ($ipPermisson in $sshOrRdpPermissionList)
	{
		Write-Host "-----------------------------------"
		Write-Host "Name :" $secGroup.GroupName
		Write-Host "Id:" $secGroup.GroupId

		$ipInSecurityGroup = $ipPermisson.IpRange.Split("/")[0]
		
		Write-Host "IP address in security group:" $ipInSecurityGroup "for port:" $ipPermisson.FromPort
		
		If ($currentIp.ipAddress -ne $ipInSecurityGroup)
		{
			Write-Host "Revoking permission for IP" $ipPermisson.Iprange "for port: " $ipPermisson.FromPort 
			if (!$dryRun)
			{
				Revoke-EC2SecurityGroupIngress -GroupId $secGroup.GroupId -IpPermissions $ipPermisson `
											  -Region $region -AccessKey $accessKey -SecretKey $secretKey			
			}

			$cidrBlocks = New-Object 'collections.generic.list[string]'
			$cidrBlocks.add($currentIp.ipAddress + "/32")
			$newIpPermissions = New-Object Amazon.EC2.Model.IpPermission 
			$newIpPermissions.IpProtocol = $ipPermisson.IpProtocol
			$newIpPermissions.FromPort = $ipPermisson.FromPort 
			$newIpPermissions.ToPort = $ipPermisson.ToPort 
			$newIpPermissions.IpRanges = $cidrBlocks
			
			Write-Host "Granting permission for IP" $newIpPermissions.Iprange "for port" $newIpPermissions.FromPort 
			
			if (!$dryRun)
			{
				Grant-EC2SecurityGroupIngress -GroupId $secGroup.GroupId -IpPermissions $newIpPermissions `
											  -Region $region -AccessKey $accessKey -SecretKey $secretKey
			}
		}
		else
		{
			Write-Host "Security group is up-to-date"
		}
		Write-Host "-----------------------------------"
	}

}

