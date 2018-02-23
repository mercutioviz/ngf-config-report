#!/usr/bin/perl
#
# format-rcs-report.pl
#
# Reads in selected rcs report files and attempts to format nicely for human consumption

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Time::localtime;

my $report_path = '/opt/phion/config/reports';
my @files;
my $date;
my $debug;
my $test;
my $help;

my $opts_okay = GetOptions(
    'date=s'       => \$date,
    't|test'       => \$test,
    'd|debug'      => \$debug,
    'h|help'       => \$help,
    );

if ( $help ) {
  &usage();
}

if ( ! $date ) {
  print "No date specified, defaulting to yesterday...";
} elsif ( $date !~ m/20\d\d-[01]\d-[0-3]\d/ ) {
  die "Invalid date: $date";
} else {
  $date =~ tr/-/_/;  # File glob needs YYYY_MM_DD
}

my %TYPE = ( 'N' => 'New',
             'C' => 'Mod',
             'R' => 'Del',
             'X' => 'Del');

## Date calculations
my $now_epoch  = `date +%s`;
my $yest_epoch = $now_epoch - 86400;
my $tm         = localtime($yest_epoch);
my $yest_ymd   = sprintf("%04d_%02d_%02d",$tm->year+1900,$tm->mon+1,$tm->mday);
if ( ! $date ) { $date = $yest_ymd; }

## Report items here
my $header = "      NGF Config Change Report For $date\n\n";
$header =~ tr/_/-/;  # Filename uses underscores but report output should use hyphens for date
my @report_lines;

# Select report files for the given date
@files = glob($report_path . '/*.prp');
if ( @files ) {
  foreach my $file ( @files ) {
    next unless $file =~ m/$date/;
    my $fh;
    open($fh,'<',$file);
    if ( ! $fh && $debug ) {
      warn "Could not open $file: $! Skipping...";
      &dprint("Could not open $file: $! Skipping...");
      next;
    }

    &dprint("Reading in file '$file'");
    my @config_tree;     # Location in config tree where this change occurred (each node is array elem)
    my $config_page;     # Location formatted i.e. Virtual Servers > S1 > foo > bar > baz
    my @config_changes;  # array of config changes: item, op, old val, new val, time
    my $who;

    while(<$fh>) {
      next if m/^Version/;
      chomp;
      &dprint("Line: $_\n");
      my @data = split /\t/,$_;
      ## check for config tree info which comes first in the file
      if ( $data[1] == '1' ) {
	push @config_tree,$data[2];
        next;
      }

      ## Find out who made the change
      if ( ! $who ) {
        if ( $data[6] && $data[7] && $data[8] && $data[9] ) {
          $who  = $data[6] . ' ';     # 'session' or possibly 'api'
          $who .= $data[8] . '@';     # user name
          $who .= $data[9] . ' ';     # IP addr
          $who .= 'at ' . $data[7];   # date and time
        }
      }
	  
      #my @config_changes;
      my $operation;
      &dprint("Operation type: " . $data[3]);
      if ( $TYPE{$data[3]} ) { $operation = $TYPE{$data[3]}; }
      else                   { $operation = ' ';             }
      &dprint("Operation is '$operation'");
      my $old_value = $data[5] || ' ';
      my $new_value = $data[4] || ' ';
      &dprint("Old / New: '$old_value' / '$new_value'");

      #if ( $data[6] =~ m/\b(\d\d:\d\d:\d\d)\b/ && ! $timestamp ) { 
      #  $timestamp = $1;  
      #  &dprint("Timestamp: $timestamp");
      #} 
      push @config_changes, [$data[2],$operation,$old_value,$new_value];
      &dprint("Config change: " . join '||',$config_changes[$#config_changes]);
    } # while
    close($fh);

	if ( ! $who ) {
	  $who = 'unspecified';
	}

    &dprint("Config changes for file $file:");
    &dprint(join '|',@config_changes);
    $config_page = join ' > ' , @config_tree;
    &dprint("Config page: $config_page");
    #if ( ! $timestamp ) { $timestamp = ' '; }
    push @report_lines, ["Change by: $who"];
    push @report_lines, ["Location: $config_page"];
    &dprint("Added report line:\n" . join ':_:',@{$report_lines[$#report_lines]} );
    push @report_lines, ['Config Item','Operation','Old Value','New Value'];
    &dprint("Added report line:\n" . join ':_:',@{$report_lines[$#report_lines]} );
    push @report_lines, @config_changes;
    &dprint("Added report line:\n" . join ':_:',@{$report_lines[$#report_lines]} );
    push @report_lines, [' '];
    &dprint("Added report line:\n" . join ':_:',@{$report_lines[$#report_lines]} );
  } # foreach
} else {
  @report_lines = ['No changes for this date.'];
}

print "\n\n$header\n";
#print Dumper(\@report_lines);
foreach ( @report_lines ) {
  my @lines = @{$_};
  print " " . join "\t",@lines;
  print "\n";
  next;
}

sub usage {
  print "\n";
  print "$0 [--date=YYYY-MM-DD | [-t|--test] [-d|--debug] [-h|--help] ]\n";
  print "\n";
  print "  --date      Date for report changes. Defaults to today.\n";
  print "  -d|--debug  Print debug info.\n";
  print "  -t|--test   Test only, don't attempt to send email.\n";
  print "  -h|--help   Display this help page.\n";
  print "\n";

  exit(1);
}

sub dprint {
  my $info = shift;
  print "$info\n" if $debug;
}
