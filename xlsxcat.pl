#!/usr/bin/perl -w
# xlsxcat [--col (cols)] [--sep (separator)] [filename]
# where 'cols' is a comma separated list of columns
#
# Return contens of selected column(s), from all sheets
# 
# Requires Spreadsheet::XLSX
#	Ubuntu: $ sudo apt-get install libspreadsheet-xlsx-perl
#	Arch: $ https://aur.archlinux.org/perl-spreadsheet-xlsx.git

use strict;
use Spreadsheet::XLSX;
use Getopt::Long;

my %opt;
GetOptions(\%opt, "col|c=s", "sep|s=s");

my $filename = shift;
my $separator = "\t";
my $value;
my $col_nr;
my $workbook = Spreadsheet::XLSX->new($filename);

if(exists($opt{sep})) {
	$separator = $opt{sep}
}

my @cols = split(/,/, $opt{col});

foreach my $sheet (@{$workbook->{Worksheet}}) {
	$sheet->{MaxRow} ||= $sheet->{MinRow};

	foreach my $row (0 .. $sheet->{MaxRow}) { 
		$sheet->{MaxCol} ||= $sheet->{MinCol};
		$col_nr = 0;
		foreach my $col (@cols) {
			my $cell = $sheet->{Cells}[$row][$col];

			print $separator unless($col_nr eq 0);

			if ($cell) {
				$value = $cell->{Val};
				if ($value =~ /\r/) {
					# Remove any carriage returns that
					# might exist in cells
					$value =~ tr/\r//d;
					# Excel quotes the value if it
					# contains newlines
					$value = "\"$value\"";
				}
				if ($value =~ /;/) {
				# Excel quotes the value if it contains
				# semicolon
					$value = "\"$value\"";
				}
				printf $value;
			}

			$col_nr++;
		}

		print "\n";
	}
}
