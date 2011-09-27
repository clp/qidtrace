#!/usr/bin/env perl

use Test::More tests => 1;

my $project_dir = "~/p/qidtrace/";
my $program_under_test = "perl -I lib " . $project_dir . "bin/most_frequent ";
my $infile = 'data/9999-lines.mx' ;
my $test_output_filename = "most_freq_9999.out";
my $outdir = "tmp/";

my $test_out = `$program_under_test $infile` or die "Cannot run $program_under_test: [$!]";

open my $outfile, ">", "$outdir/$test_output_filename"  or die "Cannot open [$outdir/$outfile]."; 
print { $outfile } $test_out;

# Compare two files on disk: reference o/p to program under test o/p.
my $ref_out = "refout/$test_output_filename";
my $diff_out = `diff -s  "$outdir/$test_output_filename" $ref_out`;
like( $diff_out, qr{Files.*are.identical.*}, "Most frequent uids & qids match for 9999-line file.");

