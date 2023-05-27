#! /bin/env perl

# (c) 2023 kittennbfive - https://github.com/kittennbfive/

# written from scratch but idea stolen from pretty_timing.pl (c) 2020, Haakan T. Johansson
# see https://github.com/YosysHQ/nextpnr/issues/551

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

=pod
VERSION 0.02 - TO BE IMPROVED - CONSIDER OUTPUT WITH CAUTION

This script "beautifies" the critical timing report of nextpnr.

You can feed it a logfile or directly pipe the output of nextpnr to it. Caution, nextpnr writes to STDERR.

If you are using a pipe you can specify -p as an argument for this script to make it print everything else that isn't a critical timing report from nextpnr.

If you don't want to use -p but you are interested in the result (PASS/FAIL) you can specifiy -r as an argument to make the script print this line (and the beautified timing report of course). This will give you the essential informations without all the extra-stuff from nextpnr that you may not be interested in.

Examples (valid for bash, please check the documentation if you are using another shell, as i said nextpnr writes to STDERR):
./beautify-timing-report.pl < logfile.txt [ > logfile_out.txt ]
nextpnr-ecp5 [arguments] 2> >(./beautify-timing-report.pl -p)
nextpnr-ecp5 [arguments] 2> >(./beautify-timing-report.pl -p > log.txt)
nextpnr-ecp5 [arguments] 2> >(./beautify-timing-report.pl -r)
=cut

use strict;
use warnings FATAL=>'all';
no warnings 'experimental';
use v5.10;

use constant HEADER=>0;
use constant SINK=>1;
use constant SETUP=>2;
use constant TIME_TOTAL=>3;

my $print_non_matching=0;
my $print_pass_fail=0;

foreach (@ARGV)
{
	$print_non_matching=1 if($_ eq '-p'); # "passthrough"
	$print_pass_fail=1 if($_ eq '-r'); # "result"
}

my $running=0;
my $finished=0;

my %data=( clock_name=>undef, clock_edge1=>undef, clock_edge2=>undef, name=>undef, from_x=>undef, from_y=>undef, to_x=>undef, to_y=>undef, time_logic=>undef, time_net=>undef, time_setup=>undef, time_total_logic=>undef, time_total_routing=>undef, time_total_sum=>undef );

my $sink_last;

while((my $l=<STDIN>))
{
	chomp($l);
	
	if($finished)
	{
		print "$l\n" if($print_non_matching || ($print_pass_fail && $l=~/Max frequency for clock/));
		next;
	}
	
	$l=~s/^Info:\s+//;

	given($l)
	{
		when(/^Critical path report for clock '(.+?)'\s+\((\w+)\s+->\s+(\w+)\):$/)
		{
			$running=1;
			
			$data{clock_name}=$1;
			$data{clock_edge1}=$2;
			$data{clock_edge2}=$3;
			
			beauty_print(HEADER, \%data);
		}
		
		when(/^([\d\.]+)\s+[\d\.]+\s+Source\s+(.+)$/)
		{
			$data{time_logic}=$1;
			
			my $source=($2=~s/\.\w+$//r);
			
			die "beautify-timing-report.pl: error: expected $sink_last but got $source" if($sink_last && $source ne $sink_last);
		}
		
		when(/^([\d\.]+)\s+[\d\.]+\s+Net\s+(.+?)\s+budget\s+-?[\d\.]+\s+ns\s+\((\d+,\d+)\)\s+->\s+\((\d+,\d+)\)$/)
		{
			$data{time_net}=$1;
			$data{name}=$2;
			($data{from_x}, $data{from_y})=split(/,/, $3);
			($data{to_x}, $data{to_y})=split(/,/, $4);
		}
		
		when(/^Sink\s+(.+)$/)
		{
			$sink_last=($1=~s/\.\w+$//r);
			
			beauty_print(SINK, \%data);
		}
		
		when(/^([\d\.]+)\s+([\d\.]+)\s+Setup\s+(.+)$/)
		{
			$data{time_setup}=$1;
			$data{time_total_sum}=$2;
			$data{name}=$3;
			
			beauty_print(SETUP, \%data);
		}
		
		when(/^([\d\.]+)\sns\slogic,\s([\d\.]+)\sns\srouting$/)
		{
			$data{time_total_logic}=$1;
			$data{time_total_routing}=$2;
			
			if($running)
			{
				beauty_print(TIME_TOTAL, \%data);
				$finished=1;
				last unless($print_non_matching || $print_pass_fail);
			}
		}
		
		default: print "Info: $l\n" if($print_non_matching && (!$running || $finished));
	}
}

sub beauty_print
{
	my ($type, $ref)=(shift, shift);
	
	given($type)
	{
		when(HEADER)
		{
			printf("report for clock %s (%s -> %s):\n\n", $ref->{clock_name}, $ref->{clock_edge1}, $ref->{clock_edge2});
			print " x   y    logic     net   signal\n";
			print "--- ---   -----   -----   ----------------------------------------\n";
		}
		
		when(SINK)
		{
			printf("%03d %03d   %5.1f   %5.1f   %s\n", $ref->{from_x}, $ref->{from_y}, $ref->{time_logic}, $ref->{time_net}, $ref->{name});
		}
		
		when(SETUP)
		{
			printf("%03d %03d   %5.1f           %s\n", $ref->{to_x}, $ref->{to_y}, $ref->{time_setup}, $ref->{name});
		}
		
		when(TIME_TOTAL)
		{
			print "--- ---   -----   -----   ----------------------------------------\n";
			printf("TOTAL     %5.1f + %5.1f = %5.1f\n\n", $ref->{time_total_logic}, $ref->{time_total_routing}, $ref->{time_total_sum});
		}
		
		default: die("beautify-timing-report.pl: error: unknown \$type");
	}
}
