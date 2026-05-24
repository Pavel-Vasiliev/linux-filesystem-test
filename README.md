# Linux filesystem test

A Perl-based disk I/O performance benchmarking tool with CMS-optimized profiles and realistic file size distributions.

## Requirements
- Linux operating system
- Perl 5.x
- Standard Unix utilities (mkdir, dd, cat, rm, sync)

## Installation
No installation required. Just make the script executable:
```bash
chmod +x disk_test.pl
```

## Usage

### Basic Usage
Run with default (medium) CMS profile:
```bash
./disk_test.pl
```

### Profile Selection
The tool now supports three CMS-optimized profiles with realistic file size distributions:

```bash
./disk_test.pl --profile small      # Small/Medium CMS site
./disk_test.pl --profile medium     # Large CMS site (DEFAULT)
./disk_test.pl --profile enterprise # Enterprise media site
```

Or use the short option:
```bash
./disk_test.pl -p small
```

### Help
Display available options:
```bash
./disk_test.pl --help
```

## Available Profiles

### 1. Small Profile (`--profile small`)
- **Folders**: 24 (2 years of monthly folders)
- **Subfolders**: 30 per folder
- **Total files**: 720
- **File size distribution**:
  - 70% small files: 10-50KB
  - 20% medium files: 50-200KB
  - 10% large files: 200KB-1MB
- **Average file size**: ~100KB
- **Total data volume**: ~72MB
- **Concurrent workers**: 8
- **Use case**: Small to medium WordPress/Joomla sites

### 2. Medium Profile (`--profile medium`) - DEFAULT
- **Folders**: 60 (5 years × 12 months)
- **Subfolders**: 100 per folder
- **Total files**: 6,000
- **File size distribution**:
  - 60% small files: 10-100KB
  - 25% medium files: 100-500KB
  - 15% large files: 500KB-2MB
- **Average file size**: ~300KB
- **Total data volume**: ~1.8GB
- **Concurrent workers**: 16
- **Use case**: Large CMS sites with moderate traffic

### 3. Enterprise Profile (`--profile enterprise`)
- **Folders**: 120 (10 years of archives)
- **Subfolders**: 200 per folder
- **Total files**: 24,000
- **File size distribution**:
  - 50% small files: 50-200KB
  - 30% medium files: 200KB-1MB
  - 20% large files: 1MB-5MB
- **Average file size**: ~800KB
- **Total data volume**: ~19GB
- **Concurrent workers**: 32
- **Use case**: Enterprise media sites, high-traffic portals

## Test Methodology

The benchmark performs four sequential phases:

1. **Directory Structure Creation** - Creates hierarchical directory tree
2. **File Writing** - Generates files with realistic size distributions based on web CMS statistics
3. **File Reading** - Reads all created files sequentially
4. **Cleanup** - Removes all test data and directories

Each phase is timed with microsecond precision using `Time::HiRes`.

### File Size Realism
Unlike previous versions that used fixed 4KB files, the tool now implements:
- **Weighted random distribution** of file sizes per profile
- **Realistic web file sizes** based on CMS statistics (HTML, CSS, images, media)
- **Variable block sizes** using 4KB blocks for filesystem efficiency
- **Statistical accuracy** matching typical web server file distributions

## Output

The tool displays:
- Profile information and configuration including file size statistics
- Progress during test execution
- Results showing time for each phase (sum of all workers)
- Average time per worker for each phase

Example output on SSD:
```
Linux filesystems disk test (CMS Profile: medium)
Large CMS site (6,000 files, avg ~300KB/file, 16 concurrent users)
Parallel 16 workers

Waiting for 16 workers to complete benchmark...

--- Results (Sum of 16 workers) ---
Creating a directory structure : 5.1234 s
Creating files in directories  : 45.6789 s
Reading files from directories : 38.9012 s
Remove all test data           : 2.3456 s

--- Results (Average per worker) ---
Creating a directory structure : 0.3202 s
Creating files in directories  : 2.8549 s
Reading files from directories : 2.4313 s
Remove all test data           : 0.1466 s
```

## Performance Notes

- **File size impact**: Larger realistic files increase I/O times compared to 4KB files
- **Storage type**: Results vary significantly between SSD/HDD/NVMe
- **Filesystem**: Performance depends on filesystem type (ext4, XFS, Btrfs, etc.)
- **Cache effects**: Realistic file sizes better test disk I/O vs page cache
- **Total data**: Profiles now generate 72MB to 19GB of test data

The test creates significant I/O load - avoid running on production systems.

## License

This is free and unencumbered software released into the public domain.
See LICENSE file for details.
