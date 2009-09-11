package Expense::Budget;
use Moose;

use Expense::Date;

has 'filename' => (
    is  => 'rw',
    isa => 'Str',
);

has 'budget' => (
    is  => 'rw',
    isa => 'Int',
);

has 'from' => (
    is  => 'rw',
    isa => 'Str',
);

has 'to' => (
    is  => 'rw',
    isa => 'Str',
);



sub BUILD {
    my ($self) = @_;

    open BUDGET, $self->filename;

    chomp(my $budget = <BUDGET>);
    chomp(my $from   = <BUDGET>);
    chomp(my $to     = <BUDGET>);
    
    $self->budget($budget);
    $self->from  ($from);
    $self->to    ($to);

    close BUDGET;
}

sub update {
    my $self = shift;
    my %args = @_;

    my $filename = $self->{filename};
    open BUDGET, ">$filename";

    $self->budget($args{budget});
    $self->from  ($args{from});
    $self->to    ($args{to});

    print BUDGET $args{budget},$/;
    print BUDGET $args{from},$/;
    print BUDGET $args{to},$/;

    close BUDGET;
}

sub daily_budget {
    my ($self, $expenses) = @_;
    my $today             = Expense::Date->new(localtime);
    my $date              = Expense::Date->new(split /\./, $self->to);

    return int (($self->budget - $expenses) / $today->to($date));
}

1;
