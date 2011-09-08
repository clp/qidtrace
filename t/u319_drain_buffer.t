#!/usr/bin/env perl

use Test::More tests => 1;

my $project_dir = "/home/clpoda/p/qidtrace/";
my $program_under_test = "perl -I lib " . $project_dir . "bin/qidtrace -m u319\@h2.net ";
my $infile = 'data/u319_drain_buffer.mx' ;
my $test_output_filename = "u319_drain_buffer.out";
my $outdir = "tmp/";

my $test_out = `$program_under_test $infile` or die "Cannot run $program_under_test: [$!]";

open my $outfile, ">", "$outdir/$test_output_filename"  or die "Cannot open [$outdir/$outfile]."; 
print { $outfile } $test_out;

# Compare two files on disk: reference o/p to program under test o/p.
my $ref_out = "refout/$test_output_filename";
my $diff_out = `diff -s  "$outdir/$test_output_filename" $ref_out`;
like( $diff_out, qr{Files.*are.identical.*}, "Compare reference o/p to program o/p for 4 volumes.");

