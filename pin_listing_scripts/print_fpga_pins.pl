#! /usr/bin/perl

=pod
VALID ONLY FOR 5A-75B V7.0

This hacked together script lists all available FPGA IO that are connected to some buffer, sorted by FPGA-banks.

This might be useful for some hardware-hacking.

On 5A-75B V7 we have a total of 56 IO available on the inputs of the 12 buffers, that's not too bad.

(c) 2022 by kittennbfive
AGPLv3+
THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
=cut

use strict;
use warnings FATAL=>'all';
use autodie;

my %buffers; #{U<n>}->{<bitnr>}={pin_fpga=><alphanum>, bank=><bank>, pinfunc=><pinfunc>}

open my $in, '<', 'pin_con.txt';
my $line;
while(($line=<$in>))
{
	chomp($line);
	if($line=~m!^\|\s*\d+\s*\|.+?\|\s*([A-Z0-9]+)\s*\|\s+Bank\s+(\d)\s+-\s+([A-Z0-9_]+)\s+/.+\|\s*\*?(U\d+_B\d)\s*\|!)
	{
		my ($pin_fpga, $bank, $pinfunc, $buffer)=($1, $2, $3, $4);
		my $bitnr=($buffer=~s/U\d+_B//r);
		$buffer=~s/_B\d//;
		$pinfunc=~s/_//g;
		
		$buffers{$buffer}->{$bitnr}={pin_fpga=>$pin_fpga, bank=>$bank, pinfunc=>$pinfunc};
	}
}
close $in;

my %already_shown; #as some FPGA IO are connected to more than one buffer

foreach my $bank (qw/0 1 2 3 6 7 8/)
{
	print "BANK $bank:\n";
	foreach my $buf (sort {($a=~s/U//r)<=>($b=~s/U//r)} keys %buffers)
	{
		foreach my $bitnr (sort keys %{$buffers{$buf}})
		{
			my $bank_pin=$buffers{$buf}->{$bitnr}->{bank};
			next if($bank_pin!=$bank);
			my $pinfunc=$buffers{$buf}->{$bitnr}->{pinfunc};
			my $fpga_pin=$buffers{$buf}->{$bitnr}->{pin_fpga};
			if(!exists($already_shown{$fpga_pin}))
			{
				print "$fpga_pin $pinfunc ($buf","_$bitnr)\n";
			}
			$already_shown{$fpga_pin}=1;
		}
	}
}

