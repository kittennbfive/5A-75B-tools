#! /usr/bin/perl

=pod
This script parses the pinout-file from Latticesemi, extracts informations for the package we are interested in (CABGA256) and stores them in an internal Perl format.

(c) 2020 by kitten_nb_five
AGPLv3+
THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
=cut

use strict;
use warnings FATAL=>'all';
use autodie;
use Storable;

my %fpga_pins_cabga256; #{PIN}={pin_func, bank, dual_func}

$/="\r\n"; #this is needed to make chomp() work on Windows line-endings...

open my $in, '<', 'ECP5U25Pinout.csv';

print "parsing ECP5U25Pinout.csv... ";

my $line;
while(($line=<$in>))
{
	chomp($line);
	next if($line=~/^"?#/);
	next if($line=~/^,+\s+$/);
	
	my (undef, $pin_func, $bank, $dual_func, undef, undef, undef, undef, undef, $pin_256)=split(/,/, $line);
	
	next if($pin_256 eq 'CABGA256');
	next if($pin_256 eq '-');
	next if($pin_256 eq '');
	
	$dual_func='' if($dual_func eq '-');
	
	$fpga_pins_cabga256{$pin_256}={ pin_func=>$pin_func, bank=>$bank, dual_func=>$dual_func };
}
close $in;

die "error: wrong number of pins" if(scalar(keys %fpga_pins_cabga256)!=256);

store \%fpga_pins_cabga256, 'fpga_cabga256_data.storable';

print "done\n\n";
