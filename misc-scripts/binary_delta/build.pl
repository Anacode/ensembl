#!/usr/bin/perl -w

# $Id$
#
# build.pl
#
# A program that creates binary delta files containing the
# differences between two revisions of an ensembl database.  The
# delta files must be applied with the apply.pl Perl program.
#
# See also build.README
#
# Author: Andreas Kahari, <andreas.kahari@ebi.ac.uk>
#

use strict;
use warnings;

use Cwd;

use File::Basename;
use File::Copy;

use Getopt::Std;

use aux qw(:default :build);

my %opts;
my $xdelta_cmd	= $opts{'c'} = 'xdelta';
my $src_prefix	= $opts{'s'} = '.';
my $dst_prefix	= $opts{'d'} = '.';

my $too_big	= 2_147_483_648;    # 2 Gb
#my $too_big	=       307_200;    # 300 Kb (for debugging gzipping)

if (!getopts('c:s:d:', \%opts)) {
    usage_build(\%opts);
    die;
}

$xdelta_cmd = $opts{'c'};
$src_prefix = $opts{'s'};
$dst_prefix = $opts{'d'};

if ($#ARGV != 2) {
    usage_build(\%opts);
    die;
}

my $db = $ARGV[0];
my $v1 = $ARGV[1]; my $v1_dir = sprintf "%s/%s_%s", $src_prefix, $db, $v1;
my $v2 = $ARGV[2]; my $v2_dir = sprintf "%s/%s_%s", $src_prefix, $db, $v2;

my $delta_dir = sprintf "%s/%s_%s_delta_%s", $dst_prefix, $db, $v1, $v2;

die $! if (! -d $v1_dir);
die $! if (! -d $v2_dir);

if (! -d $delta_dir) {
    printf STDERR "Creating delta directory '%s'\n", $delta_dir;
    mkdir($delta_dir) or die $!;
}

my $v1_all_size = 0;
my $v2_all_size = 0;
my $delta_all_size = 0;

foreach my $v2_file (glob($v2_dir . '/*')) {
    my $base_name  = basename($v2_file);
    my $v1_file    = sprintf "%s/%s", $v1_dir, $base_name;
    my $delta_file = sprintf "%s/%s", $delta_dir, $base_name;

    printf "Processing '%s'\n", $base_name;
    my $v1_sum = '(none)';
    my $v2_sum;
    my $delta_sum = '(none)';

    print "\tCalculating checksum of new file\n";
    $v2_sum = make_checksum($v2_file);

    my $v1_size = 0;
    my $v2_size = (stat $v2_file)[7];
    my $delta_size = 0;

    my $patch_command;

    if (-f $v1_file) {
	print "\tCalculating checksum of old file\n";
	$v1_sum = make_checksum($v1_file);

	$v1_size = (stat $v1_file)[7];

	if ($v1_sum eq $v2_sum && $v1_size == $v2_size) {
	    $patch_command = 'COPY';
	    print "\tThe files are identical\n";
	} elsif ($v1_size >= $too_big || $v2_size >= $too_big) {
	    $patch_command = 'ZIP';
	    print "\tFiles are huge, compressing new file\n";
	    do_compress($v2_file, $delta_file);
	} else {
	    $patch_command = 'PATCH';
	    print "\tCreating delta file\n";
	    system($xdelta_cmd, 'delta', '-9', $v1_file, $v2_file, $delta_file);
	}
    } else {
	$patch_command = 'ZIP';	    # (was 'ADD')
	print "\tCopying (and compressing) new file\n";
	do_compress($v2_file, $delta_file);
    }

    if ($patch_command ne 'COPY') {
	print "\tCalculating checksum of delta file\n";
	$delta_sum = make_checksum($delta_file);
	$delta_size = (stat $delta_file)[7];
    }

    print "\tWriting info file\n";
    open(INFO, '>' . $delta_file . '.info') or die $!;
    printf INFO "%s\n%s\t%d\n%s\t%d\n%s\t%d\n",
	$patch_command,
	$v1_sum, $v1_size,
	$v2_sum, $v2_size,
	$delta_sum, $delta_size;
    close INFO;

    $v1_all_size += $v1_size;
    $v2_all_size += $v2_size;
    $delta_all_size += $delta_size;

    printf "This file:\nOld %s, New %s, Delta %s, Saved %s (%.2f%%)\n",
	make_human_readable($v1_size),
	make_human_readable($v2_size),
	make_human_readable($delta_size),
	make_human_readable($v2_size - $delta_size),
	($v2_size == 0 ? 0 : 100 * (1.0 - $delta_size / $v2_size));
    printf "Overall:\nOld %s, New %s, Delta %s, Saved %s (%.2f%%)\n\n",
	make_human_readable($v1_all_size),
	make_human_readable($v2_all_size),
	make_human_readable($delta_all_size),
	make_human_readable($v2_all_size - $delta_all_size),
	($v2_all_size == 0 ? 0 : 100 * (1.0 - $delta_all_size / $v2_all_size));
}
