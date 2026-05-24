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

# Define CMS profiles with realistic file size distributions
my %profiles = (
    small => {
        ii => 24,      # Folders (2 years of monthly folders)
        jj => 30,      # Subfolders (30 files per month)
        threads => 8,  # Moderate concurrent users
        # File size distribution: 70% small, 20% medium, 10% large
        file_sizes => [
            { weight => 70, min_kb => 10,  max_kb => 50   },  # Small: 10-50KB
            { weight => 20, min_kb => 50,  max_kb => 200  },  # Medium: 50-200KB
            { weight => 10, min_kb => 200, max_kb => 1000 },  # Large: 200KB-1MB
        ],
        desc => 'Small/Medium CMS site (720 files, avg ~100KB/file, 8 concurrent users)'
    },
    medium => {
        ii => 60,      # Folders (5 years × 12 months)
        jj => 100,     # Subfolders (100 files per month)
        threads => 16, # High concurrent traffic
        # File size distribution: 60% small, 25% medium, 15% large
        file_sizes => [
            { weight => 60, min_kb => 10,  max_kb => 100  },  # Small: 10-100KB
            { weight => 25, min_kb => 100, max_kb => 500  },  # Medium: 100-500KB
            { weight => 15, min_kb => 500, max_kb => 2000 },  # Large: 500KB-2MB
        ],
        desc => 'Large CMS site (6,000 files, avg ~300KB/file, 16 concurrent users)'
    },
    enterprise => {
        ii => 120,     # Folders (10 years of archives)
        jj => 200,     # Subfolders (200 media files per month)
        threads => 32, # Enterprise-level concurrency
        # File size distribution: 50% small, 30% medium, 20% large
        file_sizes => [
            { weight => 50, min_kb => 50,   max_kb => 200  },  # Small: 50-200KB
            { weight => 30, min_kb => 200,  max_kb => 1000 },  # Medium: 200KB-1MB
            { weight => 20, min_kb => 1000, max_kb => 5000 },  # Large: 1MB-5MB
        ],
        desc => 'Enterprise media site (24,000 files, avg ~800KB/file, 32 concurrent users)'
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
my $file_sizes = $profiles{$profile}{file_sizes};

print "Linux filesystems disk test (CMS Profile: $profile)\n";
print "$profiles{$profile}{desc}\n";
print "Parallel $num_threads workers\n\n";

# Pre-calculate weighted distribution for file sizes
my @size_cumulative;
my $total_weight = 0;
foreach my $size (@$file_sizes) {
    $total_weight += $size->{weight};
    push @size_cumulative, {
        cumulative => $total_weight,
        min_kb => $size->{min_kb},
        max_kb => $size->{max_kb}
    };
}

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

        # Phase 2: Creating files in directories with realistic sizes
        system('sync');
        $time1 = gettimeofday();
        for(my $i=0;$i<$ii;$i++ ){
            for(my $j=0;$j<$jj;$j++ ){
                my $f3name = "$root/".$i."/".$j."/file";
                
                # Generate random file size based on weighted distribution
                my $rand = rand($total_weight);
                my $selected_size;
                foreach my $size (@size_cumulative) {
                    if ($rand <= $size->{cumulative}) {
                        # Generate random size within the range (in KB)
                        my $file_size_kb = $size->{min_kb} + rand($size->{max_kb} - $size->{min_kb});
                        $file_size_kb = int($file_size_kb); # Round to integer KB
                        
                        # Convert to bytes and create appropriate dd command
                        # Use 4KB blocks for efficiency (most filesystems use 4KB blocks)
                        my $file_size_bytes = $file_size_kb * 1024;
                        my $block_size = 4096; # 4KB blocks
                        my $block_count = int($file_size_bytes / $block_size);
                        $block_count = 1 if $block_count < 1; # At least 1 block
                        
                        my $dd = "dd if=/dev/urandom of=$f3name bs=$block_size count=$block_count > /dev/null 2>&1";
                        system($dd);
                        last;
                    }
                }
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
              File sizes: 10KB-1MB (avg ~100KB)
              8 concurrent workers

  medium      Large CMS site (DEFAULT)
              60 folders × 100 subfolders = 6,000 files
              File sizes: 10KB-2MB (avg ~300KB)
              16 concurrent workers

  enterprise  Enterprise media site
              120 folders × 200 subfolders = 24,000 files
              File sizes: 50KB-5MB (avg ~800KB)
              32 concurrent workers

Examples:
  $0                     # Run with medium profile (default)
  $0 --profile small     # Run small CMS profile
  $0 -p enterprise       # Run enterprise profile

Note: Files now use realistic size distributions based on typical web CMS content.
HELP
}
