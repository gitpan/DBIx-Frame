#!/usr/local/bin/perl -Tw 
use vars qw( $VERSION $CLASS $DATABASE $DBUSER $DBPASS $DBHOST $DBTYPE 
	     $opt_h $opt_d $opt_c $opt_u $opt_p $opt_b $opt_v $opt_t $opt_a ); 
$VERSION = "0.6";

###############################################################################
### CONFIGURATION + PRIVATE DATA ##############################################
###############################################################################

## Load shared configurations and/or private data using 'do' commands, as
## seen below.  Note that several 'do's can be run if necessary.

# do '/FULL/PATH/TO/CODE/TO/RUN';

## This is the perl class that you will be using in this script.

$CLASS = "";

## Modify and uncomment this to use user code instead of just system-wide
## modules.  Note that this path must be set up as a standard Perl tree;
## I'd personally recommend just installing things system-wide unless you're
## a developer.

# use lib '/PATH/TO/USER/CODE';

## Database Information
## You may want to set these with a common config file, using 'do FILE'.
## Also, defaults may already be set within the class; only set these if
## you want to override the defaults.
## Note, this database must exist first!  This script only creates the
## tables within the database.

# $DBHOST   = "";               # System that hosts the database
# $DBTYPE   = "";               # The type of database that we're working on
# $DATABASE = "";               # Name of the database we're connecting to
# $DBUSER   = "";               # Username to connect to the database
# $DBPASS   = "";               # Password to connect to the database

###############################################################################
##### main() ##################################################################
###############################################################################

use strict;
use Getopt::Std;

use DBIx::Frame;

$0 =~ s%.*/%%;	 # Clean the path up
getopts('cdhvu:p:b:t:a');

Usage() if $opt_h;
Version() if $opt_v;
$DATABASE = $opt_b if $opt_b;
$DBUSER   = $opt_u if $opt_u;
$DBPASS   = $opt_p if $opt_p;

# Load the appropriate class module
{ local $@; eval "use $CLASS";  die "$@\n" if $@; }

# Confirm that the user really meant -d
if ($opt_d) {
  print "This will delete all contents of the current database.\n";
  print "Are you *sure* you really want to do this? (y/n) ";
  my $answer = <STDIN>;  chomp $answer;
  unless ($answer =~ /^\s*y/i) {
    print "Didn't think so\n";
    $opt_d = 0;
  }
} 

# Connect to the database
my $db = $CLASS->connect($DATABASE, $DBUSER, $DBPASS, $DBHOST, $DBTYPE) 
	|| Exit("Couldn't connect to '$DATABASE':  ", DBI::errstr, "\n");

my %tables = %{$db->fieldhash} if ($db->fieldhash && ref $db->fieldhash);
Exit("No tables to create!") unless %tables;

foreach my $table (sort keys %tables) {
  next unless ref $tables{$table};
  next unless ($opt_a || ( $opt_t && $opt_t eq $table ) );
  if ($opt_d) {
    $db->drop_table($table) 
	? print "Dropped '$table'\n" 
	: print "Couldn't drop '$table': ", $db->error || "", "\n";
  }
  if ($opt_c) {
    $db->create_table($table, $tables{$table}) 
	? print "Created '$table'\n" 
	: print "Couldn't create '$table': ", $db->error || "", "\n";
  }
  unless ($opt_c || $opt_d) {	# Don't bother printing here
    print "Table: $table\n";
    foreach my $column (sort keys %{$tables{$table}}) {
      printf("  %-26s %50s\n", $column, $tables{$table}->{$column});
    }
    print "\n";
  }
}

$db->disconnect;
exit(0);

###############################################################################
### Subroutines ###############################################################
###############################################################################

### Usage()
# Prints off help information and exits
sub Usage {
  warn <<EOM;

$0 v$VERSION
A database creation/deletion/status script for DBIx::Frame
Usage: $0 [-hvcd] [-b database] [-u user] [-p password]

Creates, deletes, or just prints off status information about a DBIx::Frame 
database.  Should be fairly self-explanatory.  Note that the database must
exist first; this only creates the tables.

	-b database	Database to investigate.  Defaults to $DATABASE
  	-u user		Username to connect with.  Defaults to $DBUSER
	-p password	Password to connect with.  

	-h		Prints this message and exit.
	-v		Prints the version number and exits.

	-t TABLE	Work on table TABLE
	-a		Work on all tables.

	-c		Create new database.  Can be used with -d to reset
			  the database.
	-d		Delete old database.  You may lose data with this.
EOM

  Exit();
}

### Version
# Prints the version
sub Version { Exit("$0 v$VERSION") }

### Exit
# Prints off whatever it gets to 
sub Exit { foreach (@_) { print "$_\n" } exit(0); }

###############################################################################
### License Information #######################################################
###############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2000-2003, Tim Skirvin and UIUC Board of Trustees.
# This program is part of the DBIx::Frame package, available at
#   http://www.ks.uiuc.edu/Development/MDTools/dbixframe/
# License terms are on this web page, or included in the main package.

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.5 	Fri Jul 13 11:18:07 CDT 2001
### First commented/properly supported version.
# v0.51 	Fri Mar 22 13:45:33 CST 2002
### Exits cleanly if there's no tables to work with.
# v0.6		Tue Oct 21 13:36:36 CDT 2003 
### Renamed to DBIx::Frame, updated this accordingly.
