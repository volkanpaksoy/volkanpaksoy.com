var bucketName = "{BUCKET_NAME}";
var fileName = "mail-automation-last-sent-date.txt";
var targetDayOfMonth = 7;

exports.handler = function(event, context) {

	var async = require('async');
	var AWS = require('aws-sdk');
	var s3 = new AWS.S3();
	var nodemailer = require('nodemailer');
	var smtpTransport = require('nodemailer-smtp-transport');
	var currentMonth;
	
	async.waterfall(
		[ function downloadLog(next) {
			s3.getObject({
					Bucket: bucketName,
					Key: fileName
				},
				next);
		},

		function checkDate(response, next) {
			var message = JSON.parse(event.Records[0].Sns.Message);
			var currentDay = parseInt(message.day);
			currentMonth = parseInt(message.month);
			var lastMailMonth = parseInt(response.Body.toString());
			if (isNaN(lastMailMonth)) {
				lastMailMonth = currentMonth - 1;
			}

			if ((currentDay == targetDayOfMonth) && (currentMonth > lastMailMonth)) {
				next();
			} else {
				context.done(null, 'No action needed');
			}
		},

		function sendMail(response, next) {
			var transporter = nodemailer.createTransport(smtpTransport({
			    host: 'email-smtp.eu-west-1.amazonaws.com',
			    port: 587,
			    auth: {
			        user: '{ACCESS KEY}',
			        pass: '{SECRET KEY}'
			    }
			}));

			var text = 'Hi, Invoice! Thanks!';
			var mailOptions = {
			    from: 'from@me.net',
			    to: 'to@someone.net',
			    bcc: 'me2@me.com',
			    subject: 'Invoice',
			    text: text 
			};
			
			transporter.sendMail(mailOptions, function(error, info){
		          if(error){
		              console.log(error);
		          }else{
		              s3.putObject({
							Bucket: bucketName,
							Key: fileName,
							Body: currentMonth.toString(),
							ContentType: "text/plain"
						},
						function(err, data) {
							console.log('Updated log');
							context.done(null, 'Completed')
						});
		          }
		      });
		} ], function (err) {
			if (err) {
				context.fail(err);
			} else {
				context.succeed('Success');
			}
		});
};