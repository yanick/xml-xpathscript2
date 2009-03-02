package XML::XPathScript2::Stylesheet::Detachable;

use Moose::Role;

has _within_transformation => ( 
    is => 'ro',
    writer => '_set_within_transformation'
);

has 'is_instance' => ( is => 'rw' );

requires 'transform';

sub detach_from_stylesheet {
    my $self = shift;
    $self->stylesheet->detach($self) unless $self->is_instance;
}

before 'transform' => sub {
    $_[0]->_set_within_transformation(1);
};

after 'transform' => sub {
    $_[0]->_set_within_transformation(0);
};

1;

