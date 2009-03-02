package XML::XPathScript2::Stylesheet::Document;

use MooseX::SemiAffordanceAccessor;
use Moose;

no warnings 'uninitialized';

use XML::Writer;

has stylesheet => ( is => 'rw', weaken => 1 );
has pre      => ( is => 'rw' );
has post     => ( is => 'rw' );

sub transform {
    my ( $self, $node ) = @_;

    my $output;

    $output .= $self->pre;

    my @children = $node->children;

    $output .= $self->stylesheet->transform( $_ ) for @children;

    $output .= $self->post;

    return $output;

}


42;

