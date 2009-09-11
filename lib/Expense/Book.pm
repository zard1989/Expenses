package Expense::Book;
use Moose;
use Expense::Date;
use Expense::Item;

has 'filename' => (
    is  => 'rw',
    isa => 'Str',
);

has 'expense_items' => (
    is  => 'rw',
    isa => 'ArrayRef',
);

sub BUILD {
    my ($self) = @_;
    open EXPENSEBOOK, $self->filename;
    binmode EXPENSEBOOK, ":utf8";
    $self->expense_items([]);
    while (<EXPENSEBOOK>) {
        chomp;
        push @{ $self->expense_items }, parse_line($_);
    }
}

sub today {
    my $date = Expense::Date->new(localtime);
    my $today = $date->isTomorrow ? $date : $date->yesterday;

    return $today->show;
}

sub yesterday {
    my $date = Expense::Date->new(localtime);
    my $yesterday = $date->isTomorrow ? $date->yesterday : $date->yesterday->yesterday;

    return $yesterday->show;
}

sub parse_line {
    my $line = shift;
    my %data;
    @data{'date', 'category', 'description', 'amount'} = split /:/, $line;
    return Expense::Item->new(%data);
}

sub query {
    my ($self, %query) = @_;
    my @result = @{ $self->expense_items };
    if (not %query) {
        return @result;
    }
    for my $key (keys %query) {
        if ($key eq '>=' or $key eq 'greater-than') {
            @result = grep { $_->greater_equal($query{$key}) } @result;
            next;
        }

        if ($key eq '<=' or $key eq 'less-than') {
            @result = grep { $_->less_equal($query{$key}) } @result;
            next;
        }

        @result = grep { $_->{$key} =~ m/\Q$query{$key}/ } @result;
    }

    return @result;
}

sub between {
    my $self  = shift;
    my $date1 = Expense::Date->new(shift);
    my $date2 = Expense::Date->new(shift);

    my @results;

    for (@{$self->expense_items}) {
        my $that_day = Expense::Date->new($_->{date});
        push @results, $_ if $that_day->from($date1) >= 0 && $that_day->to($date2) >= 0;
    }

    return @results;
}

sub get_categories {
    my $self = shift;
    my %categories;
    for my $item (@{$self->expense_items}) {
        $categories{$item->category} ++;
    }
    return keys %categories;
}

sub total_amount {
    my $self = shift;
    my $sum  = 0;

    for (@{$self->expense_items}) {
        $sum += $_->amount;
    }

    return $sum;
}

sub daily_amount {
    my ($self, $date) = @_;
    if (not defined $date) {
        $date = today();
    }

    my @data = grep {$_->date =~ /$date/} @{$self->expense_items};

    my $sum = 0;
    $sum += $_->amount for @data;

    return $sum;
}

sub amount_between {
    my $self  = shift;

    my $sum = 0;
    $sum += $_->amount for $self->between(@_);
    return $sum;
}

sub new_item {
    my $self = shift;

    my $new_item = Expense::Item->new(@_);
    push @{$self->expense_items}, $new_item;
    open EXPENSEBOOK, ">>" . $self->filename;
    binmode EXPENSEBOOK, ':utf8';
    my @columns = @{$new_item} {'date','category','description','amount'};
    print EXPENSEBOOK join(":",@columns),$/;
    close EXPENSEBOOK;
}

1;
