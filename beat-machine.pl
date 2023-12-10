#!/usr/bin/perl

use strict;
use warnings;
use 5.028;
use Data::Dumper;
use Digest::CRC qw(crc32);
use Time::HiRes qw(gettimeofday);

use constant INSTUMENTS_WEIGHT => {
	K => 1,
	S => 2,
	H => 3,
};

sub hex2dec {
	return unpack "d", reverse pack "H*", shift;
}

sub int2hex {
	return uc sprintf("%lx", shift);
}

sub hash {
	my $data = shift;
	return crc32(Dumper($data));
}

use constant KINDS => {
	holem  => sub {
		my ($step, $input) = shift;
		my ($seconds, $microseconds) = gettimeofday;
		srand($seconds.'.'.$microseconds*$step);
		return int rand(16);
	},
	punk   => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		srand($step / $bpm);
		return rand(16);
	},
	thief  => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		srand (hash({beat => $input->{beat}->[$step], bpm => $bpm}));
		return rand(16);
	},
	hippie => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		my @b = @{$input->{beat}};
		srand (hash({beat => [splice(@b, 0, $step+1)], bpm => $bpm}));
		return rand (16);
	},
	zen    => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		srand (hash($input));
		return rand(16);
	},
};

sub machine {
	my $input = shift;
	my $out_hex = shift;
	
	my $bpm   = $input->{bpm} or die "No bpm in beat";
	my $beat  = $input->{beat} or die "No beat";
	
	
	my @output = ();
	
	my $step = 0;
	for my $row (@$beat) {
		my %row = ();
		for my $instrument (sort {INSTUMENTS_WEIGHT->{$a} <=> INSTUMENTS_WEIGHT->{$b}} keys %$row) {
			die "Unsupported insrument: $instrument" unless INSTUMENTS_WEIGHT->{$instrument};
			
			my $k = $row->{$instrument};
			my @kinds = ();
			if (ref $k eq 'ARRAY') {
				@kinds = @$k;
			} else {
				push @kinds, $k;
			}
			
			my @buffer = ();
			for my $kind (grep {$_} @kinds) {
				my $processor = KINDS->{$kind} or die "Unsupported kind: $kind";
				my $r = int ($processor->($step, $input));
				push @buffer, $out_hex ? int2hex $r : $r;
			}
			$row{$instrument} = \@buffer;
		}
		push @output, \%row;
		$step ++;
	}
	
	return {
		bpm  => $bpm,
		beat => \@output,
	};
}

sub using {
	say "Using: $0 [-h] input-beat.txt\n\tFlags: -h - for HEX output";
	exit;
}

my @args = @ARGV;
my $file = pop @args;
my $flag = shift @args;
$flag //= 0;

using() unless $file;
using() unless -f $file;

my $s = '';
my $fi;
open $fi, $file;
$s = join '', <$fi>;
close $fi;

my $input = eval $s;
say Dumper (machine($input, $flag eq '-h' ? 1 : 0));


1;
