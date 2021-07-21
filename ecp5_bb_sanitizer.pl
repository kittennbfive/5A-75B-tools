#! /usr/bin/perl

use v5.12;
use strict;
use warnings FATAL=>'all';
no warnings 'experimental';
use autodie;

=pod
This script reads the module definitions for ECP5 from "cells_bb.v" and writes a wrapper with "_SANE" versions of the modules to "cells_bb_SANE.v".

"Sane" simple means that pins that should have been declared as a bus are now declared as a bus, ie
input DATA2, DATA1, DATA0;
becomes
input [2:0] DATA;

This should make code using these modules less painful to write and more readable.

cells_bb.v must be in the same directory as the script (symlink should be fine too). You can find it here: https://github.com/YosysHQ/yosys/blob/master/techlibs/ecp5/cells_bb.v

Warning: An existing cells_bb_SANE.v will be overwritten without asking!

TODO: put buses with same direction and same width on the same line?

(c) 2021 by kittennbfive
https://github.com/kittennbfive/

AGPLv3+ and NO WARRANTY! EXPERIMENTAL STUFF!

(version 2 21.07.21)
=cut

my $inputfile='cells_bb.v';
my $outputfile='cells_bb_SANE.v';

open my $inp, '<', $inputfile;

my %data;
#{primitive_name}->{ hints->$str, inputs->[],outputs->[], parameters->[] }

my $curr_module;

my %modules;
#{primitive_name}->{ inp_bus->[], inp_single->[], outp_bus->[], outp_single->[], parameters->[] }

while((my $line=<$inp>))
{
	chomp($line);
	
	given($line)
	{
		when(/module ([\w\d]+)\s*\(/)
		{
			$curr_module=$1;
			$data{$curr_module}={ 'inputs'=>[], 'outputs'=>[], 'parameters'=>[] };
		}
		
		when(/input (.+)$/)
		{
			push @{$data{$curr_module}->{'inputs'}}, split(/,\s*/, $1=~s/,$//r);
		}
		
		when(/output (.+)$/)
		{
			push @{$data{$curr_module}->{'outputs'}}, split(/,\s*/, $1=~s/,$//r);
		}
		
		when(/\s+parameter (.+)$/)
		{
			push @{$data{$curr_module}->{'parameters'}}, $1;
		}
		
		when(/endmodule/)
		{
			print "module $curr_module parsed\n";
			$curr_module=undef;
		}
	}
}

close $inp;

open my $out, '>', $outputfile;

print $out "//AUTOMATICALLY GENERATED FROM $inputfile BY ecp5_bb_sanitizer.pl on ".localtime()." - DO NOT EDIT!\n\n";

foreach my $module (sort keys %data)
{
	print "processing data for module $module...\n";
	
	$modules{$module}={ 'inp_bus'=>[], 'inp_single'=>[], 'outp_bus'=>[], 'outp_single'=>[], 'parameters'=>$data{$module}->{'parameters'} };
	
	process_io($module, 'inputs');
	process_io($module, 'outputs');
	
	print "writing output for module $module...\n";
	
	write_sane_module($module);
}

close $out;

print "script finished. Thank you.\n";

#### subs ####

sub process_io
{
	my($module, $input_or_output)=(@_);
	
	my $in_or_out=$input_or_output=~s/uts$//r;
	
	my %bus;
	#{name}->[$bitpos]
	
	foreach my $pin (sort @{$data{$module}->{$input_or_output}})
	{
		my $pin_stripped;
		if($pin=~/\d+$/)
		{
			$pin_stripped=$pin=~s/(\d+)$//r;
			my $number=$1;
			
			push @{$bus{$pin_stripped}}, $number;
		}
		else
		{
			push @{$modules{$module}->{$in_or_out.'_single'}}, $pin;
		}
	}
	
	foreach my $pin (sort keys %bus)
	{
		my @sorted=sort {$a<=>$b} @{$bus{$pin}};
		
		if(scalar(@sorted)==1 || $sorted[0]!=0) #we have a single bit name ending with a number (see module TSHX2DQA) or multiple pins ending with numbers that are not a bus however (see EHXPLLL)
		{
			foreach (@sorted)
			{
				push @{$modules{$module}->{$in_or_out.'_single'}}, $pin.$_;
			}
		}
		else
		{
			push @{$modules{$module}->{$in_or_out.'_bus'}}, '['.$sorted[$#sorted].':'.$sorted[0].'] '.$pin;
		}
	}
	
}

sub write_sane_module
{
	my($m)=(@_);
	
	print $out 'module ',$m,"_SANE(\n";
	
	my $flag_comma=0;
		
	foreach (@{$modules{$m}->{'inp_bus'}})
	{
		print $out ",\n" if($flag_comma);
		print $out "\tinput $_";
		$flag_comma=1;
	}
	
	foreach (@{$modules{$m}->{'inp_single'}})
	{
		print $out ",\n" if($flag_comma);
		print $out "\tinput $_";
		$flag_comma=1;
	}
	
	foreach (@{$modules{$m}->{'outp_bus'}})
	{
		print $out ",\n" if($flag_comma);
		print $out "\toutput $_";
		$flag_comma=1;
	}
	
	foreach (@{$modules{$m}->{'outp_single'}})
	{
		print $out ",\n" if($flag_comma);
		print $out "\toutput $_";
		$flag_comma=1;
	}
	
	print $out "\n);\n";
	
	print $out join("\n", map { "\t".'parameter '.$_ } @{$modules{$m}->{'parameters'}}),"\n\n" if(scalar(@{$modules{$m}->{'parameters'}}));
	
	print $out "\t$m ";
	
	write_parameters($m);
	
	print $out $m,"_i (";
	
	write_io_mapping($m, 'inp');
	write_io_mapping($m, 'outp');
	
	print $out "\n\t);\n";
	
	print $out "endmodule\n\n";
}

sub write_parameters
{
	my($m)=(@_);
	
	return if(!scalar(@{$modules{$m}->{'parameters'}}));
	
	print $out "# (\n";
	
	my $flag_comma=0;
	
	foreach my $par (@{$modules{$m}->{'parameters'}})
	{
		print $out ",\n" if($flag_comma);
		my $name=$par=~s/\s+=.+$//gr;
		$name=~s/^\[\d+:\d+\]\s//;
		print $out "\t\t.$name($name)";
		$flag_comma=1;
	}
	
	print $out "\n\t) ";
}

sub write_io_mapping
{
	my($m, $in_or_out)=(@_);
	
	state $flag_comma=0; #thats like "static" in C - we need to keep the value between the first (inputs) and the second (outputs) call
	
	foreach my $bus (sort @{$modules{$m}->{$in_or_out.'_bus'}})
	{
		my ($end, $start, $name)=$bus=~/\[(\d+):(\d+)\]\s(.+)/;
		foreach my $i ($start..$end)
		{
			print $out ",\n" if($flag_comma);
			print $out "\n" if($i==$start);
			print $out "\t\t.$name$i($name\[$i\])";
			$flag_comma=1;
		}
	}
	
	my $flag_first=1;
	foreach my $pin (sort @{$modules{$m}->{$in_or_out.'_single'}})
	{
		print $out ",\n" if($flag_comma);
		print $out "\n" if($flag_first);
		print $out "\t\t.$pin($pin)";
		$flag_comma=1;
		$flag_first=0;
	}
	
	$flag_comma=0 if($in_or_out eq 'outp');
}
