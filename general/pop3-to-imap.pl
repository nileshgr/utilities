#!/usr/bin/perl

# Transfer mails from POP3 server to a folder on another IMAP server
# replace the configuration parameters below appropriately
#
# You need to install IO::Socket::SSL, Mail::IMAPClient and Mail::POP3Client
# before running this. You can install them using CPAN or whatever other method you like

use strict;
use warnings;

my %config = (
	pop3_username => 'POP3_USERNAME',
	pop3_password => 'POP3_PASSWORD',
	pop3_host => 'POP3_SERVER',
	pop3_ssl => 1,

	imap_username => 'IMAP_USERNAME',
	imap_password => 'IMAP_PASSWORD',
	imap_server => 'IMAP_SERVER',
	imap_ssl => 1,
	imap_dest_folder => 'IMAP_DESTINATION_FOLDER',
);

use Mail::IMAPClient;
use Mail::POP3Client;
use IO::Socket::SSL;

my $pop = Mail::POP3Client->new(
	USER => $config{pop3_username},
	PASSWORD => $config{pop3_password},
	HOST => $config{pop3_host},
	USESSL => $config{pop3_ssl}
	);

die "pop3 connection error" if($pop->Count == -1);

my $imap;

if($config{imap_ssl}) {
	my $ssl = IO::Socket::SSL->new("$config{imap_server}:993") or die "ssl connection error to imap";

	$imap = Mail::IMAPClient->new(
		User => $config{imap_username},
		Password => $config{imap_password},
		Socket => $ssl,
		State => Mail::IMAPClient::Connected
		);
}
else {
	$imap = Mail::IMAPClient->new(
		User => $config{imap_username},
		Password => $config{imap_password},
		Server => $config{imap_server},
		);
}

die "imap connection / login failed" unless($imap);

my $messageCount = 0;

for (my $i = 1; $i <= $pop->Count; $i++) {
	my $msg = $pop->HeadAndBody($i);
	unless($imap->append($config{imap_dest_folder}, $msg)) {
		print STDERR "Unable to upload POP3 message number $i, so I will leave it at the POP3 server\n\n";
		print STDERR "Contents of the message: \n\n$msg\n\n";
		next;
	}
	$pop->Delete($i);
	$messageCount++;
}

print "$messageCount message(s) successfully uploaded to IMAP\n";

# no cleanup required, this is the end of the script
