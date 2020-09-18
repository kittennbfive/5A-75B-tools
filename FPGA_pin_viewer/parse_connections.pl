#! /usr/bin/perl

=pod
This script generates a list of connections for each FPGA-pin and stores it in an internal Perl-format.

Connections for each part are in separate files to make parsing and modifications easier.

Each file must be named "pin_$part.txt".

Lines beginning with # are ignored.

(c) 2020 by kitten_nb_five
AGPLv3+
THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
=cut

use strict;
use warnings FATAL=>'all';
use autodie;
use Storable;

my %connections_fpga; #{PIN}->()

foreach my $pinfile (split(/\s+/, `ls pin_*.txt`)) #yeah... it works, so...
{
	next if($pinfile eq 'pin_con.txt'); #needs special treatment, below
	
	$pinfile=~/pin_(\w+)\.txt/;
	my $part=$1;
	
	print "parsing $pinfile\n";
	
	open my $in, '<', $pinfile;
	my $line;
	while(($line=<$in>))
	{
		chomp($line);
		next if($line=~/^#/);
		$line=~s/^\|\s*//;
		$line=~s/\s*\|$//;
		my ($pin, $pin_fpga)=split(/\s+\|\s+/, $line);
		next if($pin_fpga eq '*3.3V*' || $pin_fpga eq '*GND*');
		push @{$connections_fpga{$pin_fpga}}, $part.'_'.$pin;
	}
	close $in;
}

print "parsing pin_con.txt\n";
open my $in, '<', 'pin_con.txt';
my $line;
my $curr_j;
while(($line=<$in>))
{
	chomp($line);
	if($line=~m!^\|\s*(J\d) Pin!)
	{
		$curr_j=$1;
	}
	elsif($line=~m!^\|\s*(\d+)\s*\|.+?\|\s*([A-Z0-9]+)\s*\|.+?\|\s*\*?(U\d+_[A-Z0-9_]+)\s*\|!)
	{
		my ($pin_j_con, $pin_fpga, $pin_buffer)=($1, $2, $3);
		push @{$connections_fpga{$pin_fpga}}, $pin_buffer.' ('.$curr_j.'_'.$pin_j_con.')';
	}
}
close $in;

print "adding manual entries\n";
$connections_fpga{'P6'}=["Clock_25MHz"];
$connections_fpga{'P11'}=["DATA_LED-"];
$connections_fpga{'M13'}=["KEY+"];

store \%connections_fpga, 'connections_fpga.storable';

print "done\n\n";
