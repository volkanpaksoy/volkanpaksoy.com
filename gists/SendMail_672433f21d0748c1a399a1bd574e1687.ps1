function Send-Mail
{
	param(
	  [string]$emailsubject,
	  [string]$emailBody
	)
	
	$smtpServer = "email-smtp.eu-west-1.amazonaws.com"
	$smtpPort = 587  
	$username = "{ACCESS KEY}"
	$password = "{SECRET KEY}"
	$from = "{FROM EMAIL}"
	$to = "{TO EMAIL}"
	$subject = $emailsubject
	$body = $emailBody
	
	$smtp = new-object Net.Mail.SmtpClient($smtpServer, $smtpPort)
	$smtp.EnableSsl = $true 

	$smtp.Credentials = new-object Net.NetworkCredential($username, $password)
	$msg = new-object Net.Mail.MailMessage
	$msg.From = $from
	$msg.To.Add($to)
	$msg.Subject = $subject
	$msg.Body = $body
	$smtp.Send($msg)	
}
