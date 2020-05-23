. "PATH\TO\EMAIL\SCRIPT\send-email.ps1"

$configPath="PATH\TO\CONFIG\config.xml"
$tempFilePath = "C:\Temp\temp.xml"
$nmapBucketAccessKey = "ACCESS KEY"
$nmapBucketSecretKey = "SECRET KEY"

Write-Host "Reading configuration file"
$xdocConfig = [xml] (Get-Content $configPath)

Write-Host "Download latest asset list from S3. Filter XML files to exclude logs"
$latestList = Get-S3Object -BucketName vp-nmap-output `
				  -AccessKey $nmapBucketAccessKey `
				  -SecretKey $nmapBucketSecretKey `
			| Where-Object {$_.Key -match "xml"} `
            		| Sort-Object LastModified -descending `
			| Select -First 1

If ($latestList -eq $null)
{
    Write-Host "No output file is found"
    Exit
}

Read-S3Object -BucketName BUCKET_NAME `
		  -AccessKey $nmapBucketAccessKey `
		  -SecretKey $nmapBucketSecretKey `
                  -File $tempFilePath `
                  -Key $latestList.Key

$xdocAssetList = [xml] (Get-Content $tempFilePath)

$assetList = $xdocAssetList.SelectNodes("//host")
foreach ($asset in $assetList)
{
    $foundMacAddress = $asset.SelectSingleNode("./address[@addrtype=""mac""]")
    # Nmap resolves MAC addresses by using ARP and it cannot get its own MAC address so there is no MAC address
    # for the machine running the scan. 
    If ($foundMacAddress -eq $null)
    {
        Write-Host "No MAC address. Skipping." # Maybe just check IP?
        continue
    }

    $foundMacAddress = $foundMacAddress.Attributes["addr"].Value
    $foundIpAddress = $asset.SelectSingleNode("./address[@addrtype=""ipv4""]").Attributes["addr"].Value
    
    $nodeInConfig = $xdocConfig.SelectSingleNode("//host[@mac=""$foundMacAddress"" and @ip=""$foundIpAddress""]")
    If ($nodeInConfig -eq $null)
    {
        Write-Host "Discovered a new device. Sending notification"
	    
        $timestamp = Get-Date -format F
        $subject = "New device discovered"
	    $body =  [string]::Format("Discovery time: {0}, MAC Address of the device = {1}, IP Address: {2}", $timestamp, $foundMacAddress, $foundIpAddress)
        
        Send-Mail $subject $body
    }
    else
    {
        Write-Host "Known device"
    }
}
