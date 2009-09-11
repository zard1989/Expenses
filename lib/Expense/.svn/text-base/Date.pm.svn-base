package Expense::Date;
use strict;
use feature ':5.10';

sub isTomorrow {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @$self;

    if ($hour >= 0 and $hour <= 6) {
        return 0;
    }
    else {
        return 1;
    }
}

sub new {
    my $class = shift;
    if (@_ == 3) {
        my $year = $_[0] - 1900;
        my $mon  = $_[1] - 1;
        my $day  = $_[2];
        return bless [0,0,0,$day,$mon,$year,0,0,0], $class;
    }

    if (@_ == 1) {
        my @date = split /\./, shift;
        my $year = $date[0] - 1900;
        my $mon  = $date[1] - 1;
        my $day  = $date[2];
        return bless[0,0,0,$day,$mon,$year,0,0,0], $class;
    }

    bless [@_], $class;
}

sub now {
    return Expense::Date->new(localtime);
}

sub f {
    my ($year, $month) = @_;
    return $year-1 if $month <= 2;
    return $year;
}

sub g {
    my $month = shift;
    return $month+13 if $month <= 2;
    return $month+1;
}

sub to {
    my ($self, $other) = @_;
    my $n1 = 1461 * f($self->year, $self->month) / 4 + 153 * g($self->month) / 5 + $self->day;
    my $n2 = 1461 * f($other->year, $other->month) / 4 + 153 * g($other->month) / 5 + $other->day;

    return int ($n2 - $n1);
}

sub from {
    my ($self, $other) = @_;
    return $other->to($self);
}

sub yesterday {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @$self;
    if ($mday == 1) {
        if (($mon+1) ~~ (1,5,7,8,10,12)) {
            $mday = 30;
        }
        elsif (($mon+1) == 3) {
            $mday = 28;
        }
        else {
            $mday = 31;
        }
        $mon--;
    }
    else {
        $mday--;
    }

    return Expense::Date->new($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
};

sub show {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)  = @$self;
    $year += 1900;
    $mon  += 1;

    return "$year.$mon.$mday";
}

sub get {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @$self;
    $year += 1900;
    $mon  += 1;

    return ($year, $mon, $mday);
}

sub year {
    my $self = shift;
    ($self->get)[0];
    
}

sub month {
    my $self = shift;
    ($self->get)[1];
}

sub day {
    my $self = shift;
    ($self->get)[2];
}

1;
