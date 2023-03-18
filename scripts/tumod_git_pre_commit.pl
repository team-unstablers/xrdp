#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;

use Cwd;
use File::Copy;
use File::Path qw/make_path remove_tree/;

sub YES() { 1 }
sub NO()  { 0 }

sub get_staged_files {
    return split($/, `git diff --name-only --cached`);
}

sub needs_lint { shift =~ /\.[ch]$/; }

sub prepare_astyle {
    my $path = shift;

    system(
        'astyle',
        '--options=astyle_config.as',
        sprintf('%s/*', $path),
    );
}

my $result = YES;

my $base_path = sprintf('/tmp/xrdp_commit_%d', time());
my @sources = grep { needs_lint($_) } get_staged_files();

for my $source (@sources) {
    my $path = $base_path .'/'. ($source =~ s/\/.+?$//r);
    make_path($path) unless -e $path;

    copy($source, $base_path . '/' . $source);
}

prepare_astyle($base_path);

for my $source (@sources) {
    system('git', 'diff', '--exit-code',
        $source,
        $base_path . '/' . $source
    );

    $result &= ($? == 0);
    printf("WARN: check code formatting failed for %s\n", $source) if $? != 0;
}

remove_tree($base_path);

exit($result == YES ? 0 : 1);

