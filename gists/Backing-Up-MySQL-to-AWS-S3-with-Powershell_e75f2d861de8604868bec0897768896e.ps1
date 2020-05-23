# Make sure you have AWS PowerShell module installed
# Install-Module -Name AWSPowerShell

$ErrorActionPreference = 'Stop'

# MySQL Settings
$server = '.'
$database = '<DB NAME>'
$user = '<DB USER>'
$password = '<PASSWORD>'

# AWS Settings
$s3Bucket = '<BUCKET NAME>'
$region = '<AWS REGION (e.g eu-west1)>'
$accessKey = '<ACCESS KEY>'
$secretKey = '<SECRET KEY>'

# Local machine and file name settings
$dumFileExtension = '.sql'
$archiveExtension = '.zip'
$timestamp = Get-Date -format yyyyMMddHHmmss
$mysqldumpPath = "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe"
$fileName = "$database-$timestamp"
$backupPath = 'C:\HOME\MySQl-Backups\'
$dumpFileFullPath = "$backupPath$fileName$dumFileExtension"
$backupFileFullPath = "$backupPath$fileName$archiveExtension"
$filePath = Join-Path $backupPath $fileName

# Email settings
$enableEmailNotifications = $TRUE
$emailOnSuccess = $TRUE # Set to $FALSE if you want to receive email notifications for failures only 
$smtpServer = '<SES SMTP SERVER>'
$sesAccessKey = '<SES USER ACCESS KEY>'
$sesSecretKey = '<SES USER SECRET KEY>'
$senderEmailAddress = '<SENDER EMAIL ADDRESS>'
$recipientEmailAddress = '<RECIPIENT EMAIL ADDRESS>'
$subject = '[<APPLICATION NAME>][Backup]'


function Write-Log ($message) 
{
    $timestamp = get-date -format yyyyMMddHHmmss
    Write-Host [$timestamp] $message
}

function Send-Email ($body)
{
    Send-MailMessage -from $senderEmailAddress -to $recipientEmailAddress -subject $subject -body $body -SmtpServer $smtpServer -UseSsl -Port 587 -Credential $(New-Object System.Management.Automation.PSCredential -argumentlist $sesAccessKey, $(ConvertTo-SecureString -AsPlainText -String $sesSecretKey -Force)) 
}

Try
{
    #01. Execute mysqldump and create the backup file
    $command = "cmd.exe /C '$mysqldumpPath' -u $user -p$password --databases $database > $dumpFileFullPath"
    Invoke-Expression -Command:$command

    # 02. Create a zip file containing the backup to reduce the upload size
    Compress-Archive -LiteralPath $dumpFileFullPath -CompressionLevel Optimal -DestinationPath $backupFileFullPath

    # 03. Upload zip file to S3 bucket
    Write-S3Object -BucketName $s3Bucket -File $backupFileFullPath -Key $fileName$archiveExtension -Region $region -AccessKey $accessKey -SecretKey $secretKey

    # 04. Send notification email (if enabled for success) 
    if ($enableEmailNotifications -and $emailOnSuccess)
    {
        $body = "$fileName-'has been moved to AWS S3"
        Send-Email $body
    }

    # 05. Clear temp files
    Remove-Item $dumpFileFullPath
    Remove-Item $backupFileFullPath

    Write-Log "Backup has been uploaded successfully"
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $LogMessage = $ErrorMessage-$FailedItem
    Write-Log $LogMessage

    if ($enableEmailNotifications)
    {
        Send-Email $LogMessage 
    }

    Break
}