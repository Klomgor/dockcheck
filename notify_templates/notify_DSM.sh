### DISCLAIMER: This is a third party addition to dockcheck - best effort testing.
NOTIFY_DSM_VERSION="v0.4"
# INFO: ssmtp is deprecated - consider to use msmtp instead.
#
# mSMTP/sSMTP has to be installed and configured manually.
# The existing DSM Notification Email configuration will be used automatically.
# Leave (or place) this file in the "notify_templates" subdirectory within the same directory as the main dockcheck.sh script.
# If you instead wish make your own modifications, make a copy in the same directory as the main dockcheck.sh script.
# Do not modify this file directly within the "notify_templates" subdirectory. Set DSM_SENDMAILTO and DSM_SUBJECTTAG in your dockcheck.config file.

MSMTP=$(which msmtp)
SSMTP=$(which ssmtp)
SENDMAIL=$(which sendmail)

if [ -n "$MSMTP" ] ; then
	MailPkg=$MSMTP
elif [ -n "$SSMTP" ] ; then
	MailPkg=$SSMTP
elif [ -n "$SENDMAIL" ] ; then
	MailPkg=$SENDMAIL
else
	echo "No msmtp, ssmtp or sendmail binary found in PATH: $PATH" ; exit 1
fi

trigger_DSM_notification() {
CfgFile="/usr/syno/etc/synosmtp.conf"

# User variables:
# Automatically sends to your usual destination for synology DSM notification emails.
# You can also manually override by assigning something else to DSM_SENDMAILTO in dockcheck.config.
SendMailTo=${DSM_SENDMAILTO:-$(grep 'eventmail1' $CfgFile | sed -n 's/.*"\([^"]*\)".*/\1/p')}
# e.g. DSM_SENDMAILTO="me@mydomain.com"

SubjectTag=${DSM_SUBJECTTAG:-$(grep 'eventsubjectprefix' $CfgFile | sed -n 's/.*"\([^"]*\)".*/\1/p')}
# e.g. DSM_SUBJECTTAG="Email Subject Prefix"
SenderName=$(grep 'smtp_from_name' $CfgFile | sed -n 's/.*"\([^"]*\)".*/\1/p')
SenderMail=$(grep 'smtp_from_mail' $CfgFile | sed -n 's/.*"\([^"]*\)".*/\1/p')
SenderMail=${SenderMail:-$(grep 'eventmail1' $CfgFile | sed -n 's/.*"\([^"]*\)".*/\1/p')}

$MailPkg $SendMailTo << __EOF
From: "$SenderName" <$SenderMail>
date:$(date -R)
To: <$SendMailTo>
Subject: $SubjectTag $MessageTitle
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding: 7bit

$MessageBody
 From $SenderName
__EOF

if [[ $? -gt 0 ]]; then
  NotifyError=true
fi

# This ensures DSM's container manager will also see the update
/var/packages/ContainerManager/target/tool/image_upgradable_checker
}
