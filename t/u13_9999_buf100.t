#!/usr/bin/env perl

use Test::More tests => 1;

my $project_dir = "~/p/qidtrace/";
my $program_under_test = "perl -I lib " . $project_dir . "bin/qidtrace -m u13\@h2.net ";
my $infile = 'data/9999-lines.mx';
my $test_output_filename = "u13_9999_buf100.out";
my $outdir = "tmp/";

my $test_out = `$program_under_test $infile` or die "Cannot run $program_under_test: [$!]";

open my $outfile, ">", "$outdir/$test_output_filename"  or die "Cannot open [$outdir/$outfile]."; 
print { $outfile } $test_out;

# Compare two files on disk: reference o/p to program under test o/p.
my $ref_out = "refout/$test_output_filename";
my $diff_out = `diff -s  "$outdir/$test_output_filename" $ref_out`;
like( $diff_out, qr{Files.*are.identical.*}, "Found all (2319) o/p lines for u13\@h2.net in 9999-line i/p file.");

