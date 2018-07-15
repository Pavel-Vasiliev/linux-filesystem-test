#!/usr/bin/perl -w
use Time::HiRes qw(gettimeofday);

$ii = 50; #number of folgers
$jj = 100; #number of subfolgers
print "Linux filesystems disk test\n\n";
system('mkdir ./disk_test_data_dir');

print "Creating a directory structure\n";
system('sync');
$time1 = gettimeofday/10*10;
for($i=0;$i<$ii;$i++ ){
    $d1name = "./disk_test_data_dir/".$i;
    system('mkdir', $d1name);

    for($j=0;$j<$jj;$j++ ){
	$d2name = "./disk_test_data_dir/".$i."/".$j;
	system('mkdir', $d2name);
    }
}
system('sync');
$time2 = gettimeofday/10*10;
print ($time2-$time1,"\n\n");

print "Creating files in directories\n";
system('sync');
$time1 = gettimeofday/10*10;
for($i=0;$i<$ii;$i++ ){
    for($j=0;$j<$jj;$j++ ){
	$f3name = "./disk_test_data_dir/".$i."/".$j."/file";
	$dd = "dd if=/dev/urandom of=$f3name bs=512 count=8  > /dev/null 2>&1";
	system ($dd);
    }
}
system('sync');
$time2 = gettimeofday/10*10;
print ($time2-$time1,"\n\n");

print "Reading files from directories\n";
system('sync');
$time1 = gettimeofday/10*10;
for($i=0;$i<$ii;$i++ ){
    for($j=0;$j<$jj;$j++ ){
	$f3name = "./disk_test_data_dir/".$i."/".$j."/file";
	$cat = "cat $f3name  > /dev/null 2>&1";

	system ($cat);
    }
}
system('sync');
$time2 = gettimeofday/10*10;
print ($time2-$time1,"\n\n");

print "Remove all test data\n";
system('sync');
$time1 = gettimeofday/10*10;
system('rm -r ./disk_test_data_dir');
system('sync');
$time2 = gettimeofday/10*10;
print ($time2-$time1,"\n\n");
