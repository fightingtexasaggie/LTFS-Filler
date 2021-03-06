#!/usr/bin/perl

use strict;
use warnings;
use File::Find;

# 2.25TB/tape for LTFS, with a little wiggle room.
my $dirMaxSize = 2.49e12;
my $dirSize=0;
my $bucketNum = 1;
my $OUTFILE;

my @searchdirs;
$searchdirs[0]=$ARGV[0];
open ($OUTFILE, ">packed.sh");
find(\&wanted, @searchdirs);
print $OUTFILE "# NOTICE: VOLUME $bucketNum total size: " . ($dirSize/1e12) . "TB\n";
close $OUTFILE;

sub wanted {
    # From Perl module File::Find
        # $File::Find::dir is the current directory name,
        # $_ is the current filename within that directory
        # $File::Find::name is the complete pathname to the file.

    my $file = $File::Find::name;
    if (-d $_) {
        # Create directory
        print $OUTFILE "mkdir -p '" . $bucketNum . '/' . $file . "\'" . "\n";
    } elsif (-f) {
        # get filesize on current file from stat array
        my $size= (stat)[7];
        # account for this file in total directory size
        $dirSize = $dirSize + $size;
        # if maximum directory size has been reached, create new one.
        if ($dirSize > $dirMaxSize) {
            print $OUTFILE "# NOTICE: VOLUME $bucketNum total size: " . (($dirSize-$size)/1e12) . "TB\n";
            $dirSize = $size;
            $bucketNum++;
        }
        # We have a file, so copy it to correct bucket directory.
        print $OUTFILE "mv \'$file\'  \'$bucketNum/$file\'\n";
    } else {
        print $OUTFILE "# ERROR: $file is neither file nor directory.\n";
    }
}
