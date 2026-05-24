# Linux filesystem test

A Perl-based disk I/O performance benchmarking tool with CMS-optimized profiles.

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
The tool now supports three CMS-optimized profiles:

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
- **Concurrent workers**: 8
- **Use case**: Small to medium WordPress/Joomla sites

### 2. Medium Profile (`--profile medium`) - DEFAULT
- **Folders**: 60 (5 years × 12 months)
- **Subfolders**: 100 per folder
- **Total files**: 6,000
- **Concurrent workers**: 16
- **Use case**: Large CMS sites with moderate traffic

### 3. Enterprise Profile (`--profile enterprise`)
- **Folders**: 120 (10 years of archives)
- **Subfolders**: 200 per folder
- **Total files**: 24,000
- **Concurrent workers**: 32
- **Use case**: Enterprise media sites, high-traffic portals

## Test Methodology

The benchmark performs four sequential phases:

1. **Directory Structure Creation** - Creates hierarchical directory tree
2. **File Writing** - Generates 4KB random data files in each directory
3. **File Reading** - Reads all created files sequentially
4. **Cleanup** - Removes all test data and directories

Each phase is timed with microsecond precision using `Time::HiRes`.

## Output

The tool displays:
- Profile information and configuration
- Progress during test execution
- Results showing time for each phase (sum of all workers)
- Average time per worker for each phase

Example output on SSD:
```
Linux filesystems disk test (CMS Profile: medium)
Large CMS site (6,000 files, 16 concurrent users)
Parallel 16 workers

Waiting for 16 workers to complete benchmark...

--- Results (Sum of 16 workers) ---
Creating a directory structure : 5.1234 s
Creating files in directories  : 12.4567 s
Reading files from directories : 11.2345 s
Remove all test data           : 0.4321 s

--- Results (Average per worker) ---
Creating a directory structure : 0.3202 s
Creating files in directories  : 0.7785 s
Reading files from directories : 0.7022 s
Remove all test data           : 0.0270 s
```

## Performance Notes

- On SSD: Typical results show ~5s directory creation, ~12s writing, ~11s reading, ~0.4s cleanup
- Results vary based on storage type (SSD/HDD/NVMe), filesystem, and system load
- The test creates significant I/O load - avoid running on production systems

## License

This is free and unencumbered software released into the public domain.
See LICENSE file for details.
