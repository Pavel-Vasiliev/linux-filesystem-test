#!/usr/bin/perl -w
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Getopt::Long;

# Default profile: medium (large CMS site)
my $profile = 'medium';

# Parse command line arguments
GetOptions(
    'profile|p=s' => \$profile,
    'help|h'      => sub { print_help(); exit 0; }
);

# Define CMS profiles
my %profiles = (
    small => {
        ii => 24,      # Folders (2 years of monthly folders)
        jj => 30,      # Subfolders (30 files per month)
        threads => 8,  # Moderate concurrent users
        desc => 'Small/Medium CMS site (720 files, 8 concurrent users)'
    },
    medium => {
        ii => 60,      # Folders (5 years × 12 months)
        jj => 100,     # Subfolders (100 files per month)
        threads => 16, # High concurrent traffic
        desc => 'Large CMS site (6,000 files, 16 concurrent users)'
    },
    enterprise => {
        ii => 120,     # Folders (10 years of archives)
        jj => 200,     # Subfolders (200 media files per month)
        threads => 32, # Enterprise-level concurrency
        desc => 'Enterprise media site (24,000 files, 32 concurrent users)'
    }
);

# Validate profile
if (!exists $profiles{$profile}) {
    warn "Unknown profile: '$profile'. Using 'medium' profile.\n";
    $profile = 'medium';
}

# Set parameters based on profile
my $ii = $profiles{$profile}{ii};
my $jj = $profiles{$profile}{jj};
my $num_threads = $profiles{$profile}{threads};

print "Linux filesystems disk test (CMS Profile: $profile)\n";
print "$profiles{$profile}{desc}\n";
print "Parallel $num_threads workers\n\n";

my @pids;
for my $thread (1..$num_threads) {
    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child process
        my $root = "./disk_test_data_dir_$thread";
        system('mkdir', '-p', $root);

        my ($t_dir, $t_write, $t_read, $t_rm);
        my ($time1, $time2);

        # Phase 1: Creating a directory structure
        system('sync');
        $time1 = gettimeofday();
        for(my $i=0;$i<$ii;$i++ ){
            my $d1name = "$root/".$i;
            system('mkdir', $d1name);

            for(my $j=0;$j<$jj;$j++ ){
                my $d2name = "$root/".$i."/".$j;
                system('mkdir', $d2name);
            }
        }
        system('sync');
        $time2 = gettimeofday();
        $t_dir = $time2 - $time1;

        # Phase 2: Creating files in directories
        system('sync');
        $time1 = gettimeofday();
        for(my $i=0;$i<$ii;$i++ ){
            for(my $j=0;$j<$jj;$j++ ){
                my $f3name = "$root/".$i."/".$j."/file";
                my $dd = "dd if=/dev/urandom of=$f3name bs=512 count=8 > /dev/null 2>&1";
                system($dd);
            }
        }
        system('sync');
        $time2 = gettimeofday();
        $t_write = $time2 - $time1;

        # Phase 3: Reading files from directories
        system('sync');
        $time1 = gettimeofday();
        for(my $i=0;$i<$ii;$i++ ){
            for(my $j=0;$j<$jj;$j++ ){
                my $f3name = "$root/".$i."/".$j."/file";
                my $cat = "cat $f3name > /dev/null 2>&1";
                system($cat);
            }
        }
        system('sync');
        $time2 = gettimeofday();
        $t_read = $time2 - $time1;

        # Phase 4: Remove all test data
        system('sync');
        $time1 = gettimeofday();
        system("rm -r $root");
        system('sync');
        $time2 = gettimeofday();
        $t_rm = $time2 - $time1;

        # Write thread results to temporary file
        open(my $fh, '>', "results_${thread}.txt") or die $!;
        print $fh "$t_dir\n$t_write\n$t_read\n$t_rm\n";
        close $fh;

        exit 0;
    } else {
        # Parent process
        push @pids, $pid;
    }
}

print "Waiting for $num_threads workers to complete benchmark...\n\n";

for my $pid (@pids) {
    waitpid($pid, 0);
}

my $sum_dir = 0;
my $sum_write = 0;
my $sum_read = 0;
my $sum_rm = 0;

for my $thread (1..$num_threads) {
    if (open(my $fh, '<', "results_${thread}.txt")) {
        my @lines = <$fh>;
        close $fh;
        chomp @lines;

        $sum_dir += $lines[0] || 0;
        $sum_write += $lines[1] || 0;
        $sum_read += $lines[2] || 0;
        $sum_rm += $lines[3] || 0;

        unlink("results_${thread}.txt");
    } else {
        warn "Could not read results for thread $thread\n";
    }
}

my $avg_dir = $sum_dir / $num_threads;
my $avg_write = $sum_write / $num_threads;
my $avg_read = $sum_read / $num_threads;
my $avg_rm = $sum_rm / $num_threads;

print "--- Results (Sum of $num_threads workers) ---\n";
printf "Creating a directory structure : %.4f s\n", $sum_dir;
printf "Creating files in directories  : %.4f s\n", $sum_write;
printf "Reading files from directories : %.4f s\n", $sum_read;
printf "Remove all test data           : %.4f s\n\n", $sum_rm;

print "--- Results (Average per worker) ---\n";
printf "Creating a directory structure : %.4f s\n", $avg_dir;
printf "Creating files in directories  : %.4f s\n", $avg_write;
printf "Reading files from directories : %.4f s\n", $avg_read;
printf "Remove all test data           : %.4f s\n\n", $avg_rm;

sub print_help {
    print <<"HELP";
Linux Filesystem Disk Test - CMS Profile Edition

Usage: $0 [OPTIONS]

Options:
  -p, --profile PROFILE    Test profile (small, medium, enterprise)
                           Default: medium
  -h, --help               Display this help message

Available Profiles:
  small       Small/Medium CMS site
              24 folders × 30 subfolders = 720 files
              8 concurrent workers

  medium      Large CMS site (DEFAULT)
              60 folders × 100 subfolders = 6,000 files
              16 concurrent workers

  enterprise  Enterprise media site
              120 folders × 200 subfolders = 24,000 files
              32 concurrent workers

Examples:
  $0                     # Run with medium profile (default)
  $0 --profile small     # Run small CMS profile
  $0 -p enterprise       # Run enterprise profile

HELP
}
