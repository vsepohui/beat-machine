#!/usr/bin/perl

use strict;
use warnings;
use 5.028;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

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

use constant KINDS => {
	holem  => sub {
		my ($step, $input) = shift;
		return int rand(255);
	},
	punk   => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		return int (sin ($step / $bpm) * 255);
	},
	thief  => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		return int (sin ((hex2dec (md5_hex(Dumper({beat => $input->{beat}->[$step], bpm => $bpm}))) % 255) / $bpm) * 255);
	},
	hippie => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		my @b = @{$input->{beat}};
		return int (sin ((hex2dec (md5_hex(Dumper({beat => [splice(@b, 0, $step)], bpm => $bpm}))) % 255) / $bpm) * 255);
	},
	zen    => sub {
		my ($step, $input) = @_;
		my $bpm = $input->{bpm};
		return int (sin ((hex2dec (md5_hex(Dumper($input))) % 255) / $bpm) * 255);
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
				my $r = $processor->($step, $input);
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
