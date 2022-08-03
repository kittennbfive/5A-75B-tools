#! /usr/bin/perl

=pod
VALID ONLY FOR 5A-75B V7.0

This script lists all FPGA-IO that are differential pairs and connected to any buffer. The output is sorted by FPGA-banks.

This might be useful if you want to remove the buffers and connect the IO to some other hardware directly and if you need differential pairs.

NEEDED: ECP5U25Pinout.csv from Lattice, see https://www.latticesemi.com/view_document?document_id=50485 (download using wget does no longer work, error 403, use a browser)

(c) 2022 by kittennbfive
AGPLv3+
THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
=cut

use strict;
use warnings FATAL=>'all';
use autodie;

## first step: extract differential pairs from csv-file from Lattice

my @diff_pairs; #[$bank]->{True_OF_$pinfunc}=<Comp_OF_$pinfunc>

$/="\r\n"; #this is needed to make chomp() work on Windows line-endings...

open my $csv, '<', 'ECP5U25Pinout.csv';
my $line;
while(($line=<$csv>))
{
	chomp($line);
	next if($line=~/^"?#/);
	next if($line=~/^,+\s+$/);
	
	my (undef, $pin_func, $bank, undef, $differential, undef, undef, undef, undef, undef)=split(/,/, $line);
	
	if($differential=~/^Comp_OF_([A-Z0-9]+)/)
	{
		my $true_of=$1;
		$diff_pairs[$bank]->{$true_of}=$pin_func;
	}
}
close $csv;

## second step: parse pin_con.txt and extract informations about how the 12 buffers are connected

my %buffers; #{U<n>}->{<bitnr>}={pin_fpga=><alphanum>, bank=><bank>, pinfunc=><pinfunc>}

$/="\n"; #switch back to UNIX line-endings...

open my $in, '<', 'pin_con.txt';
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

my %true_of_shown;

## third and final step: look for differential pairs that are connected to buffers and print them sorted by FPGA-bank

print "differential pairs on Buffers:\n";

foreach my $bank (qw/0 1 2 3 6 7 8/)
{
	print "BANK $bank:\n";
	foreach my $buf (sort {($a=~s/U//r)<=>($b=~s/U//r)} keys %buffers)
	{
		foreach my $bitnr (sort keys %{$buffers{$buf}})
		{
			my $pinfunc=$buffers{$buf}->{$bitnr}->{pinfunc};
			if($diff_pairs[$bank]->{$pinfunc} && !exists($true_of_shown{$pinfunc}))
			{
				my $comp_of=$diff_pairs[$bank]->{$pinfunc};
				my $buf_true_of=$buf.'_'.$bitnr;
				my $fpga_pin_comp_of;
				my $buf_comp_of=search_buf_pos($comp_of, \$fpga_pin_comp_of);
				my $fpga_pin_true_of=$buffers{$buf}->{$bitnr}->{pin_fpga};
				
				if($buf_comp_of)
				{
					print "pair $pinfunc - $comp_of ($buf_true_of [$fpga_pin_true_of], $buf_comp_of [$fpga_pin_comp_of])\n";
					$true_of_shown{$pinfunc}=1;
				}
			}
		}
	}
}

sub search_buf_pos
{
	my ($pinfunc, $ref_fpga_pin)=(shift, shift);
	
	foreach my $buf (sort {($a=~s/U//r)<=>($b=~s/U//r)} keys %buffers)
	{
		foreach my $bitnr (sort keys %{$buffers{$buf}})
		{
			if($pinfunc eq $buffers{$buf}->{$bitnr}->{pinfunc})
			{
				$$ref_fpga_pin=$buffers{$buf}->{$bitnr}->{pin_fpga};
				return $buf.'_'.$bitnr;
			}
		}
	}
	
	return undef;
}
