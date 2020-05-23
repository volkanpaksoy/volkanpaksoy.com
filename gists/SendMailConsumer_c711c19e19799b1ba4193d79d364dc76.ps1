. ".\send-email.ps1" 

# Get the last uploaded image
$latestImage = Get-S3Object -BucketName {BUCKET} `
				  -AccessKey {ACCESS KEY} `
				  -SecretKey {SECRET KEY} `
				  -Key {SUBFOLDER} `
			| Sort-Object LastModified -descending `
			| Select -First 1
Write-Host "Last image uploaded at" $latestImage.LastModified

# Compare with current time
$currentTime = Get-Date
Write-Host "Current system time:" $currentTime

# If it's older than a day send notification
If ( ($currentTime - $latestImage.LastModified).Days -ge 1)
{
	Write-Host "Something's wrong. Better bug someone about it."
	
	$subject = "Security footage upload failure"
	$body = "Better have a look. Last image uploaded at" + $latestImage.LastModified
	Send-Mail $subject $body
}
else
{
	Write-Host "Relax, your Pi is working just fine"
}
