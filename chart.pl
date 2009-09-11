#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/programming/Expenses/lib";

use ExpenseBook;

my $expenses = ExpenseBook->new();

use GD::Graph::bars3d;
my $graph = GD::Graph::bars3d->new(800, 600);       # 新增柱狀圖
my @files = </var/log/maillog.*.bz2>;

my $image = $graph->plot([              # 訂出橫座標，縱座標內容
    [map /(\d+)\./g, @files],
        [map -s, @files],
        ]) or die $graph->error;

        open my $fh, '>', '3.png' or die $!;
        print $fh $image->png;      # 儲存影像
:wq

