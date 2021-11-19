#!/usr/bin/perl

# ===================================================
# Copyright (c) [2021] [Tencent]
# [OpenCloudOS Tools] is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2. 
# You may obtain a copy of Mulan PSL v2 at:
#            http://license.coscl.org.cn/MulanPSL2 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.  
# See the Mulan PSL v2 for more details.  
# ===================================================

#
# Compare 2 distribution tree
# v1.1
# by samuelliao
#
# 11-18-2011 v1.0 initial release
# 11-18-2011 v1.1 fix typo in same_id(): id0->id1
#

######################################
# GLOBALS
######################################

# difference counter
$diffs = 0;

# brief message, only print differ pathname, suppress contents
$brief = 0;


######################################
# EXCLUDED PATH MANAGEMENT
######################################

# left and right topdir string length
@prefixlength;

# a hash of excluded path
%excludedhash;

# add pattern to excluded path hash
sub add_excluded_pattern($) {
	my $fn = $_[0];
	if($fn =~ m{^\.[^/]*$}) {
		$excludedhash{$fn} = 1;
	} elsif($fn =~ m{^/}) {
		$excludedhash{$fn} = 1;
	} else {
		syntax("Invalid excluded pattern, must be /XXX, /XXX/ or .XXX");
	}
}

# load excluded pattern from file
sub load_excluded_list($) {
	my $fn = $_[0];

	open FILE, "<$fn" or do {
		print "ERROR: cannot open file $fn\n";
		return undef;
	};

	while(<FILE>) {
		chomp;
		add_excluded_pattern($_);
	}
	close FILE;
}

sub init_prefix($$) {
	@prefixlength = (length($_[0]), length($_[1]));
}

# check excluded list, second parameter is 0(left)/1(right) path name
sub excluded($$) {
	my $fn = $_[0];
	return 1 if $excludedhash{substr($fn, $prefixlength[$_[1]])};
	$fn =~ s{.*\.}{.};
	return 1 if $excludedhash{$fn};
	return 0;
}

# checl excluded subdir, always check left tree
sub excludeddir($) {
	return $excludedhash{substr($_[0], $prefixlength[0]).'/'};
}


################################################
# Ownership translation
################################################
%idhash = {};

sub load_mapping_file($$) {
	my $fn = $_[0];
	my $type = $_[1];

	open FILE, "<$fn" or return undef;
	
	while(<FILE>) {
		my @item = split /:/;
		$idhash{$type.$item[2]} = $item[0];
	}
	close FILE;
}

sub load_ownership_mapping($$$) {
	my $file0 = $_[0];
	my $file1 = $_[1];
	my $etcdir = $_[2];

	load_mapping_file("$file0/$etcdir/passwd", "u0");
	load_mapping_file("$file0/$etcdir/group", "g0");
	load_mapping_file("$file1/$etcdir/passwd", "u1");
	load_mapping_file("$file1/$etcdir/group", "g1");
}

sub same_id($$$) {
	my $id0 = $_[0];
	my $id1 = $_[1];
	my $t0 = $_[2];
	my $n0 = $idhash{$t0."0".$id0};
	my $n1 = $idhash{$t0."1".$id1};
	return $n0 eq $n1 if defined($n0) and defined($n1);
	return 1 if $id0 == $id1;
	return 0;
}

sub id2name($$$) {
	my $id = $_[0];
	my $t0 = $_[1];
	my $t1 = $_[2];
	my $name = $idhash{$t0.$t1.$id};
	$id .= "($name)" if defined($name) and $name ne '';
	return $id;
}

################################################
# File Summary display
################################################

# constants from stat(), lstat() results:
#     0 dev      device number of filesystem
#     1 ino      inode number
#     2 mode     file mode  (type and permissions)
#     3 nlink    number of (hard) links to the file
#     4 uid      numeric user ID of file's owner
#     5 gid      numeric group ID of file's owner
#     6 rdev     the device identifier (special files only)
#     7 size     total size of file, in bytes
#     8 atime    last access time in seconds since the epoch
#     9 mtime    last modify time in seconds since the epoch
#    10 ctime    inode change time in seconds since the epoch (*)
#    11 blksize  preferred block size for file system I/O
#    12 blocks   actual number of blocks allocated
sub MODE(){ 2 }
sub UID() { 4 }
sub GID() { 5 }
sub RDEV() { 6 }
sub SIZE() { 7 }
# constants replace stat results
sub TYPE() { 0 }
sub PATH() { 1 }
sub TREE() { 3 }
sub SYMLINK() { 6 }	#SYMLINK and RDEV is exclusive
sub COMPARE() { 8 }
sub SUMMARY() { 9 }

sub summary_with_size($$) {
	my $info = $_[0];

	my $head = $$info[TREE] ? '+' : '-';
	my $file = $$info[PATH];
	my $type = $$info[TYPE];
	my $mode = sprintf "%o", $$info[MODE];
	my $uid = id2name($$info[UID], "u", $$info[TREE]);
	my $gid = id2name($$info[GID], "g", $$info[TREE]);
	my $size = $$info[SIZE];
	print "$head$type mode=$mode uid=$uid gid=$gid size=$size  $file\n";
}

sub summary_with_symlink($$) {
	my $info = $_[0];

	my $head = $$info[TREE] ? '+' : '-';
	my $file = $$info[PATH];
	my $type = $$info[TYPE];
	my $mode = sprintf "%o", $$info[MODE];
	my $uid = id2name($$info[UID], "u", $$info[TREE]);
	my $gid = id2name($$info[GID], "g", $$info[TREE]);
	my $symlink = $$info[SYMLINK];
	print "$head$type uid=$uid gid=$gid  $file --> $symlink\n";
}

sub summary_with_device($$) {
	my $info = $_[0];

	my $head = $$info[TREE] ? '+' : '-';
	my $file = $$info[PATH];
	my $type = $$info[TYPE];
	my $mode = sprintf "%o", $$info[MODE];
	my $uid = id2name($$info[UID], "u", $$info[TREE]);
	my $gid = id2name($$info[GID], "g", $$info[TREE]);
	my $devno = sprintf "%d:%d", $$info[RDEV]>>8, $$info[RDEV]&255;
	print "$head$type mode=$mode uid=$uid gid=$gid devno=$devno  $file\n";
}

sub summary_base($$) {
	my $info = $_[0];

	my $head = $$info[TREE] ? '+' : '-';
	my $file = $$info[PATH];
	my $type = $$info[TYPE];
	my $mode = sprintf "%o", $$info[MODE];
	my $uid = id2name($$info[UID], "u", $$info[TREE]);
	my $gid = id2name($$info[GID], "g", $$info[TREE]);
	printf "$head$type mode=$mode uid=$uid gid=$gid  $file\n";
}

################################################
# File Compare Routines
################################################

# print differ reason and summary info
sub printdiff($$$) {
	my $msg = $_[0];
	my $info0 = $_[1];
	my $info1 = $_[2];
	++$diffs;
	print "$msg $$info0[PATH] and $$info1[PATH] differ\n";
	unless($brief) {
		my $func;
		$func = $$info0[SUMMARY]; &$func($info0);
		$func = $$info1[SUMMARY]; &$func($info1);
	}
}

# scan file list in a directory
sub getfilelist($) {
	my $dirname = shift;
	my @filelist;
	if(opendir DIR, $dirname) {
		my @tmp = readdir DIR;
		for my $f(@tmp) {
			next if $f eq '.';
			next if $f eq '..';
			push @filelist, $f;
		}
		closedir DIR;
	}
	return sort {$a cmp $b} @filelist;
}

#nothing to compare
sub compare_none($$) {
	return 0;
}

#compare two symlink target
sub compare_symlink($$) {
	my $info0 = $_[0];
	my $info1 = $_[1];

	printdiff("Symlinks", $info0, $info1) if $$info0[SYMLINK] ne $$info1[SYMLINK];
}

#compare device's devno
sub compare_device($$) {
	my $info0 = $_[0];
	my $info1 = $_[1];

	printdiff("Devices", $info0, $info1) if $$info0[RDEV] ne $$info1[RDEV];
}

#bridge to external diff compare regular files
sub compare_file($$) {
	my $info0 = $_[0];
	my $info1 = $_[1];

	my @cmdline = ( "diff", "-u", $$info0[PATH], $$info1[PATH]);
	$cmdline[1] = "-uq" if $brief;
	# use fork+exec+wait instead system, because system ignore SIGINT
	if(fork()==0) {
		exec @cmdline;
		exit(254);
	}
	wait;
	++$diffs if $?;
}

#report only in left/right tree, arguments: $dir $fn $pos
sub onlyin($$$) {
	my $dir = $_[0];
	my $fn  = $_[1];
	my $pos = $_[2];

	unless(excluded("$dir/$fn", $pos)) {
		++$diffs;
		print "Only in $dir/$fn\n";
		unless($brief) {
			my $info = fileinfo("$dir/$fn", $pos);
			my $func = $$info[SUMMARY];
			&$func($info);
		}
	}
}

#compare directory tree
sub compare_subdir($$) {
	my $info0 = $_[0];
	my $info1 = $_[1];

	my $dir0 = $$info0[PATH];
	return 1 if excludeddir($dir0);
	my $dir1 = $$info1[PATH];

	my @list0 = getfilelist($dir0);
	my @list1 = getfilelist($dir1);

	for my $f (@list0) {
		onlyin($dir1, shift @list1, 1) while $#list1 >= 0 && $f gt $list1[0];
		if($#list1 < 0 || $f lt $list1[0]) {
			onlyin($dir0, $f, 0);
		} else {
			&compare_all("$dir0/$f", "$dir1/$f") unless excluded("$dir0/$f", 0);
			shift @list1;
		}
	}
	onlyin($dir1, $_, 1) foreach @list1;
}

# return file information object
sub fileinfo($$) {
	my $fn = $_[0];
	my @info = lstat($fn);

	if($#info < 0) {
		$info[TREE] = $_[1];
		$info[PATH] = $fn;
		$info[TYPE] = "NOTFOUND";
		$info[COMPARE] = \&compare_none;
		$info[SUMMARY] = \&compare_none;
		return \@info;
	}

	$info[TREE] = $_[1];
	$info[PATH] = $fn;
	$info[MODE] = $info[MODE] & 07777;
	$info[TYPE] = 'UNKNOWN';
	$info[COMPARE] = \&compare_none;
	$info[SUMMARY] = \&summary_with_size;

	if(-l $fn) {
		$info[TYPE] = 'SYMLINK';
		$info[COMPARE] = \&compare_symlink;
		$info[SUMMARY] = \&summary_with_symlink;
		$info[SYMLINK] = readlink $fn;
	} elsif(-d $fn) {
		$info[TYPE] = 'DIR';
		$info[COMPARE] = \&compare_subdir;
		$info[SUMMARY] = \&summary_with_size;
	} elsif(-b $fn) {
		$info[TYPE] = 'BLOCKDEV';
		$info[COMPARE] = \&compare_device;
		$info[SUMMARY] = \&summary_with_device;
	} elsif(-c $fn) {
		$info[TYPE] = 'CHARDEV';
		$info[COMPARE] = \&compare_device;
		$info[SUMMARY] = \&summary_with_device;
	} elsif(-S $fn) {
		$info[TYPE] = 'SOCKET';
		$info[SUMMARY] = \&summary_base;
	} elsif(-p $fn) {
		$info[TYPE] = 'PIPE';
		$info[SUMMARY] = \&summary_base;
	} elsif(-f $fn) {
		$info[TYPE] = 'FILE';
		$info[COMPARE] = \&compare_file;
		$info[SUMMARY] = \&summary_with_size;
	}
	return \@info;
}

#generic routine,  compare all file types
sub compare_all($$) {
	my $info0 = fileinfo($_[0], 0);
	my $info1 = fileinfo($_[1], 1);

	if($$info0[TYPE] ne $$info1[TYPE]) {
		printdiff("Filetype", $info0, $info1);
		return 1;
	}

	if(same_id($$info0[UID], $$info1[UID], 'u') == 0) {
		printdiff("Ownership", $info0, $info1);
	} elsif(same_id($$info0[GID], $$info1[GID], 'g') == 0) {
		printdiff("Ownership", $info0, $info1);
	} elsif($$info0[MODE] ne $$info1[MODE]) {
		printdiff("Permissions", $info0, $info1);
	}

	my $func = $$info0[COMPARE];
	return &$func($info0, $info1);
}

################################################
# Syntax
################################################

sub syntax(;$) {
	my $msg = $_[0];
	print "Syntax Error: $msg\n\n" if $msg ne '';
	print "Usage: treediff.pl [-q] [-x path] [-X file] path0 path1\n";
	print "       -q         only print diff file names\n";
	print "       -c subdir  pathname to /etc to lookup passwd/group file\n";
	print "       -x pattern exclude pattern, eg:\n";
	print "                       /tmp      excude /tmp and subdir contents\n";
	print "                       /tmp/     excude subdir contents, keep compare /tmp\n";
	print "                       /etc/mtab excude file /etc/mtab\n";
	print "                       .tmp      exclude all *.tmp files\n";
	print "       -X file    read excluded pattern from file\n";
	print "\n";
	print "Return value:\n";
	print "        0: same\n";
	print "        1: some difference\n";
	print "      254: Interrupted\n";
	print "      255: Syntax error\n";
	
	exit(255);
}

################################################
# Main routines
################################################

syntax() if $#ARGV == -1;

#parse command line
$file0 = undef;
$file1 = undef;
$etcdir = "/etc";
while(defined($arg = shift @ARGV)) {
	if(substr($arg, 0, 1) eq '-') {
		if($arg eq '-q') {
			$brief = 1;
		} elsif($arg eq '-c') {
			syntax("option -c requre a pathname") if $#ARGV < 0;
			$etcdir = shift @ARGV;
		} elsif($arg eq '-x') {
			syntax("option -x requre a pathname") if $#ARGV < 0;
			add_excluded_pattern(shift @ARGV);
		} elsif($arg eq '-X') {
			syntax("option -X requre a list file") if $#ARGV < 0;
			load_excluded_list(shift @ARGV);
		} else {
			syntax("unknown option $arg");
		}
	} elsif(defined($file1)) {
		syntax("too many arguments");
	} elsif(defined($file0)) {
		syntax("$arg non-exists") unless -e $arg;
		$file1 = $arg;
	} else {
		syntax("$arg non-exists") unless -e $arg;
		$file0 = $arg;
	}
}

syntax("missing left tree argument") unless defined($file0);
syntax("missing right tree argument") unless defined($file1);

sub intr() {
	print "\n<<<INTRRUPTED>>>\n";
	exit(254);
}
$SIG{'HUP'} = 'IGNORE';
$SIG{'CHLD'} = 'DEFAULT';
$SIG{'QUIT'} = \&intr;
$SIG{'INT'} = \&intr;
$SIG{'TERM'} = \&intr;
# for excluded pathname checking
init_prefix($file0, $file1);
# for ownership checking
load_ownership_mapping($file0, $file1, $etcdir);
# do the compare
compare_all($file0, $file1);

# zero is same, one has difference
exit($diffs?1:0);
