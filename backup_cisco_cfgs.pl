#!/usr/bin/env perl 

=pod

=head1 Using the script for create backup of Cisco running configs 
#===============================================================================
#
#         FILE: backup_cisco_cfgs_test.pl
#
#        USAGE: cpanm install Net::OpenSSH
#        		./backup_cisco_cfgs.pl  
#
#  DESCRIPTION: Create Cisco running configs backup
#
#      OPTIONS: --- 
# REQUIREMENTS: Perl v5.14+
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Vladislav Sapunov 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 20.06.2024 16:43:52
#     REVISION: ---
#===============================================================================
=cut

use strict;
use warnings;
use v5.14;
use utf8;
use Net::OpenSSH;
use POSIX 'strftime';

my $timestamp = strftime('%Y-%m-%dT%H-%M-%S', localtime());
#say "$timestamp";
my $backupLogin = "cisco";
my $backupPassword = "Cisco";

# Log file
my $errorLog = "error.log";

# Source File
my $inFile = 'cisco_list.txt';

# open source file for reading
open(FHR, '<', $inFile) or die "Couldn't Open file $inFile"."$!\n";
my @cisco = <FHR>;

#my @cisco=('127.0.0.1', '127.0.0.2', '10.210.10.112');
foreach my $ciscoHost (@cisco) {
	chomp($ciscoHost);
	eval {
		my $ssh = Net::OpenSSH->new("$backupLogin\@$ciscoHost", password => $backupPassword, timeout => 30);
		$ssh->error and die "Unable to connect: ". $ssh->error;
		
		say "Connected to $ciscoHost";
		my $shRun = $ssh->capture("show running-config");
		$shRun =~ /(hostname)(\s+)([-0-9a-zA-Z_]+)/g;
		my $hName = $3;
		
		my $cfgFile="$hName" . "_" . "$timestamp" . ".cfg";
		
		$shRun =~ s/\r//g;
		
		# open cfg file for writing
		open(FHW, '>', $cfgFile) or die "Couldn't Open file $cfgFile"."$!\n";

		say FHW "#"x30;
		say FHW "$hName";
		say FHW "#"x30;
		say FHW "$shRun";
		say FHW "#"x30;
		
		undef $ssh;
		# Close the filehandles
		close(FHW) or die "$!\n";
	};

	if($@) {
		# open log file for write
		open(ERRORS, '>>', $errorLog) or die "Couldn't open error log file $errorLog"."$!\n"; 
		say ERRORS "Date: $timestamp Host: $ciscoHost Error: $@";
		
		# Close the filehandle
		close(ERRORS) or die "$!\n";
	}
}

