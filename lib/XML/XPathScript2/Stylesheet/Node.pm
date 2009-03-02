package XML::XPathScript2::Stylesheet::Node;

use MooseX::SemiAffordanceAccessor;
use Moose;

has stylesheet => ( is => 'rw', weaken  => 1 );

has does_interpolate =>
  ( is => 'ro', writer => 'set_interpolation', default => 0 );

sub interpolate {
    my ( $self, $string, $node ) = @_;

    my $regex = $self->stylesheet->interpolation_regex;

    $string =~ s/$regex/ $node->findvalue( $1 ) /eg;

    return $string;
}

sub render {
    my ( $self, $item, $node, $args ) = @_;

    $item = $self->$item or return;

    my @args;

    @args = @$args if $args;

    $item = $item->( $node, $self, $self->stylesheet, @args )
      if ref $item eq 'CODE';

    $item = $self->interpolate( $item => $node )
        if $self->does_interpolate;

    return $item;
}

1;
