var targetEmail = '{TARGET_EMAIL_ADDRESS}'
var fromEmail = '{FROM_EMAIL_ADDRESS}'
var bccEmail = '{BCC_EMAIL_ADDRESS-TO_VERIFY}'
var sesAccessKey = '{ACCESS_KEY}'
var sesSecretKey = '{SECRET_KEY}'

exports.handler = function(event, context) {
	sendMail(context);
};

function sendMail(context) {
	var nodemailer = require('nodemailer');
	var smtpTransport = require('nodemailer-smtp-transport');

	var transporter = nodemailer.createTransport(smtpTransport({
	    host: 'email-smtp.eu-west-1.amazonaws.com',
	    port: 587,
	    auth: {
	        user: sesAccessKey,
	        pass: sesSecretKey
	    }
	}));

	var text = 'Text Goes here';

	var mailOptions = {
	    from: fromEmail,
	    to: targetEmail,
	    bcc: bccEmail,
	    subject: 'Invoice',
	    text: text 
	};
	
	transporter.sendMail(mailOptions, function(error, info){
          if(error){
              console.log(error);
          }

          context.done(null, 'Completed')
      });
}
