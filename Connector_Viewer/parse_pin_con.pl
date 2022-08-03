#! /usr/bin/perl

=pod
This script parses pin_con.txt and stores the data in an internal Perl-format.

(c) 2020-2022 by kittennbfive
AGPLv3+
THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
=cut

use strict;
use warnings FATAL=>'all';
use autodie;
use Storable;

my %buffer_con; #{U<n>}->{<bitnr>}=[{ con=>J<n>, pin=><n> }]
my %connectors; #{J<n>}->{<pin>}={ buffer=>U<n>, bit=><bitnr>, fpga_pin=><alphanum> }
my %fpga; #{<alphanum>->[J<n>_<n>];

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
	elsif($line=~m!^\|\s*(\d+)\s*\|.+?\|\s*([A-Z0-9]+)\s*\|.+?\|\s*\*?(U\d+_B\d)\s*\|!)
	{
		my ($pin_j, $pin_fpga, $buffer)=($1, $2, $3);
		my $bitnr=($buffer=~s/U\d+_B//r);
		$buffer=~s/_B\d//;
		push @{$buffer_con{$buffer}->{$bitnr}}, { con=>$curr_j, pin=>$pin_j };
		$connectors{$curr_j}->{$pin_j}={ buffer=>$buffer, bit=>$bitnr, fpga_pin=>$pin_fpga };
		push @{$fpga{$pin_fpga}}, $curr_j.'_'.$pin_j;
	}
}
close $in;

store \%buffer_con, 'buffer_con.storable';
store \%connectors, 'connectors.storable';
store \%fpga, 'fpga_pins.storable';
