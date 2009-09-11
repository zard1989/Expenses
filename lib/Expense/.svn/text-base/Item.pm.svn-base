package Expense::Item;
use Moose;

has 'date' => (
    is  => 'rw',
    isa => 'Str',
);

has 'category' => (
    is  => 'rw',
    isa => 'Str',
);

has 'description' => (
    is  => 'rw',
    isa => 'Str',
);

has 'amount' => (
    is  => 'rw',
    isa => 'Int',
);

sub greater_than {
    my ($self, $num) = @_;
    $self->{amount} > $num;
}

sub greater_equal {
    my ($self, $num) = @_;
    $self->{amount} >= $num;
}

sub less_than {
    my ($self, $num) = @_;
    $self->{amount} < $num;
}

sub less_equal {
    my ($self, $num) = @_;
    $self->{amount} <= $num;
}

1;
