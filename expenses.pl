#!/usr/bin/perl
use strict;
use feature ':5.10';

use FindBin;
use lib "$FindBin::Bin/lib";
use Expense::Book;
use Expense::Date;
use Expense::Budget;
use Term::ANSIColor;
use Term::ReadLine;
use Encode;

use utf8;

binmode STDOUT, ':utf8';
binmode STDIN,  ':utf8';

my %conf = read_conf("$ENV{HOME}/.expenses");

my $expenses = Expense::Book->new(filename => $conf{expense_file});
my $budget   = Expense::Budget->new(filename => $conf{budget_file});

my %commands = (
    "show"           => \&command_show,
    "new"            => \&command_new,
    "amount"         => \&command_amount,
    "amount_between" => \&command_amount_between,
    "budget"         => \&command_budget,
    "category"       => \&command_category,
    "clear"          => \&command_clear,
    "welcome"        => \&print_welcome,
    "help"           => \&command_help,
    "daily"          => \&command_daily,
    "draw"           => \&command_draw,
);

my %commands_help = (
    "show"           => "show column value [column value] [>= number]....",
    "new"            => "Create a new expense.",
    "amount"         => "Show the amount in a particular date.",
    "amount_between" => "Show the amount between two particular dates",
    "budget"         => "Show the budget and how much you should spend per day.",
    "category"       => "Show all the categories.",
    "clear"          => "Clear the screen.",
    "welcome"        => "Show the welcome message.",
    "help"           => "Show this help.",
    "daily"          => "Show the daily expense.",
    "draw"           => "draw the chart...",
);

if (@ARGV != 0) {
    my ($command, @args) = @ARGV;
    die "\nCommand not found.\n\n" if not exists $commands{$command};
    say "";
    $commands{$command}->(@args);
    say "";
    exit 0;
}

system 'clear';

print_welcome();


print $/;

MAIN: while (1) {
    last MAIN if not prompt();
}

#################################################################

sub read_conf {
    my $conf_file = shift;
    open CONF, $conf_file or die "Can't open conf file!\n";
    binmode CONF, ':utf8';

    my %conf;
    while (<CONF>) {
        my ($key, $value) = split /\s*=\s*/;
        $conf{$key} = $value;
    }

    return %conf;
}

sub prompt {
    my $term   = Term::ReadLine->new("Expenses");
    my $prompt = colored("Expenses>", "bold yellow");

    my $input = $term->readline($prompt);
    return 1 if $input eq $/;
    chomp $input;

    $input = Encode::decode('utf8', $input);

    say "";

    my @commands = split /;/, $input;

    COMMAND: for my $command (@commands) {
        my ($cmd, @args) = split /\s+/, $command;

        if ($cmd =~ /exit/i || $cmd =~ /quit/i) {
            print "Bye.\n";
            return 0;
        }

        for my $key (keys %commands) {
            if ($cmd eq $key) {
                print color 'bold white';
                $commands{$key}->(@args);
                print color 'reset';
                print $/;
                next COMMAND;
            }
        }
        print "Command not found: $cmd\n\n";
        return 1;
    }

    return 1;
}

sub print_welcome {
    my $title = "St. Kevin's Expense Book, 2009";
    my $notes = "    (utf8) started on 2009.4.2";

    print color 'bold white';
    print $title, "\n\n";
    print $notes, "\n";
    print "-" x length $title, "\n\n";
    command_daily();

    print "\n";

    command_budget();

    print color 'reset';
}

sub command_show {
    if ($_[0] eq 'today' or $_[0] eq 'yesterday') {
        my $date = $_[0];
        my @result = $expenses->query('date'=>ExpenseBook->$date);
        for (@result) { $_->show,print $/ };
        my $sum = 0;
        $sum += $_->{amount} for @result;

        print scalar @result, " expenses founded.\n" if @result;
        print "Total amount = $sum NTD.\n";
    }
    else {
        my %query = @_;
        my $valid_query=0;
        while (my ($key,$value) = each %query) {
            $valid_query = 1 if defined $key and defined $value;
        }
        if ($valid_query) {
            my @result = $expenses->query(%query);
            show_item($_),print $/ for @result;
            my $sum = 0;
            $sum += $_->{amount} for @result;

            print scalar @result, " expenses founded.\n" if @result;
            print "Total amount = $sum NTD.\n" if @result;
        }
    }
}

sub show_item {
    my ($item) = shift;
    print "Date: ", $item->date, "\n";
    print "Category: ", $item->category, "\n";
    print "Description: ", $item->description, "\n";
    print "Amount: ", $item->amount, "\n";
}

sub command_new {
    my $today = Expense::Date->new(localtime);
    $today = $today->isTomorrow ? $today : $today->yesterday;
    
    my %data;
    my $term = Term::ReadLine->new("Command New");

    print  "Type 'exit' whenever you don't want to create a new expense.\n\n";
    
    $_ = $data{'date'} = $term->readline(sprintf "Date (%s):", $today->show);
    $data{'date'} = $today->show if not $_;
    return if $_ eq 'exit';

    $_ = $data{'category'} = $term->readline("Category:");
    return if $_ eq 'exit';

    $_ = $data{'description'} = $term->readline("Description:");
    return if $_ eq 'exit';

    $_ = $data{'amount'} = $term->readline("Amount:");
    return if $_ eq 'exit';

    for (keys %data) {
        $data{$_} = Encode::decode("utf8", $data{$_});
    }

    $expenses->new_item(%data);
}

sub command_amount {
    given ($_[0]) {
        when ($_ =~ /\d{4}\.\d{1,2}.\d{1,2}/) {
            print "The amount of $_ is ", $expenses->daily_amount($_), " NTD.\n";
        }
        
        when ($_ eq 'today' or $_ eq '') {
            print "The amount of today is ", $expenses->daily_amount(), " NTD.\n";
        }
        
        when ($_ eq 'yesterday') {
            print "The amount of yesterday was ", $expenses->daily_amount(Expense::Date->now->yesterday->show), " NTD.\n";
        }

        when ($_ eq 'weekly') {
            
        }
        
        default {
            print "Unknown parameter.\n";
            print "Total amount of this year is ", $expenses->total_amount(), " NTD.\n";
        }
    }
}

sub command_amount_between {
    for (@_) {
        my $today = Expense::Date->new(localtime);
        $today = $today->isTomorrow ? $today : $today->yesterday;
        my $yesterday = $today->yesterday;
        $_ = $today->show if /today/;
        $_ = $yesterday->show if /yesterday/;
    }
    my ($date1, $date2) = @_;
    print "The amount between $date1 and $date2 is ", $expenses->amount_between($date1, $date2), " NTD.\n";
}

sub command_budget {
    if ($_[0] =~ /set/) {
        set_budget();
        return;
    }

    my $today  = Expense::Date->new(localtime);
    my $amount = $expenses->amount_between($budget->from, $today->show);
    print "The budget due ", $budget->to, " is ", $budget->budget ," NTD.\n\n";
    print "You should spend ", $budget->daily_budget($amount), " a day.\n";

}

sub set_budget {
    print "Setting new budget duration:\n";
    print "Start date:";    chomp (my $from   = <STDIN>);
    print "End date:";      chomp (my $to     = <STDIN>);
    print "Budget amount:"; chomp (my $amount = <STDIN>);

    $budget->update(
        from   => $from,
        to     => $to,
        budget => $amount,
    );
}

sub command_category {
    my @categories = $expenses->get_categories;
    print "Recently we have categories below:\n\n";
    print "$_ " for @categories;
    print $/;
}

sub command_clear {
    system "clear";
}

sub command_help {
    my $command = shift;
    if ($command) {
        if (grep {/$command/} keys %commands_help) {
            print $commands_help{$command},$/;
        }
        else {
            print "There is no such command: $command.\n";
        }
    }
    else {
        print "All commands:\n\n", join("\n", sort keys %commands),"\n\n";

        print "Usage: help \"command_name\"\n";
    }
}

sub command_daily {
    my $date = shift;
    
    my $today = Expense::Date->now->isTomorrow ? Expense::Date->now : Expense::Date->now->yesterday;

    if (not defined $date  || $date eq 'today') {
        $date = $today->show;
    }
    elsif ($date eq 'yesterday') {
        $date = $today->yesterday->show;
    }

    my @results = $expenses->query(date=>$date);

    print $date, ":\n\n";

    if (not @results) {
        print "No Expenses.\n";
        return;
    }

    my ($breakfast) = grep { $_->{category} =~ /早餐/ } @results;
    my ($lunch)     = grep { $_->{category} =~ /午餐/ } @results;
    my ($dinner)    = grep { $_->{category} =~ /晚餐/ } @results;
    my @others      = sort { $a->{category} <=> $b->{category} } grep { not ($_->{category} =~ /餐/) } @results;
    
    my $amount = 0;
    
    my @meals;
    push @meals, $breakfast if $breakfast;
    push @meals, $lunch     if $lunch;
    push @meals, $dinner    if $dinner;
    for my $meal (@meals) {
        print $meal->{category}, ": ", $meal->{description}, ", ", $meal->{amount}, " NTD.\n";
        $amount += $meal->{amount};
    }

    print $/ if @others;

    my $current_category;
    for my $other (@others) {
        if ($other->{category} eq $current_category) {
	    print "  " x length($current_category), "  ";
        }
        else {
            $current_category = $other->{category};
            print "$current_category: ";
        }
        print $other->{description}, ", ", $other->{amount}, " NTD.\n";
        $amount += $other->{amount};
    }
    
    print "\nTotal amount: $amount NTD.\n";
}

sub command_draw {
    my @categories = $expenses->get_categories;
    my %data;
    
    for my $category (@categories) {
        my $amount;
        $amount += $_->{amount} for $expenses->query(category=>$category);
        $data{$category} = $amount;
    }

    for (keys %data) {
        print "$_ : $data{$_}$/";
    }

    use GD::Graph::bars;
    my $graph = GD::Graph::bars->new(1000,600);

    $graph->set_x_axis_font("/usr/share/fonts/truetype/cwtex/center/cwheib.ttf",12); 
    $graph->set_y_axis_font("/usr/share/fonts/truetype/cwtex/center/cwheib.ttf",12); 
    $graph->set_title_font("/usr/share/fonts/truetype/cwtex/center/cwheib.ttf",20);

    $graph->set(
        title       => "支出統計圖",
        bar_width   => 15,
        bgclr       => "white",
        fgclr       => "black",
        textclr     => "black",
        axislabelclr=> "black",
        transparent => 0,
    );

    $graph->set( dclrs => [ qw(black) ] );

    my $image = $graph->plot([
        [keys %data],
        [values %data],
    ]) or die $graph->error;

    open my $fh, '>', "$ENV{HOME}/expenses.png" or die $!;
    print $fh $image->png;
    close $fh;

    say "";
    say "The plot has been placed in your home directory.";
}
