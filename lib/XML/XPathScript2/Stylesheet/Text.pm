package XML::XPathScript2::Stylesheet::Text;

use MooseX::SemiAffordanceAccessor;
use Moose;

no warnings qw/ uninitialized /;

use XML::Writer;

has stylesheet => ( is => 'rw', weaken => 1 );

has filter   => ( is => 'rw' );
has pre      => ( is => 'rw' );
has post     => ( is => 'rw' );
has testcode => ( is => 'rw' );
has replace  => ( is => 'rw' );
has action   => ( is => 'rw', default => 1 );

has does_interpolate => ( 
    is => 'ro', 
    writer => 'set_interpolation',
    default => 0,
);
            

sub set {
    my ( $self, %attrs ) = @_;

    for ( keys %attrs ) {
        my $method = 'set_'.$_;
        $self->$method( $attrs{$_} );
    }

}

sub transform {
    my ( $self, $node, $args ) = @_;

    $self->testcode->( $node, $self ) if $self->testcode;

    my $action = $self->action;

    $action = $action->( $node, $self ) if ref $action eq 'CODE';
    if ( ref $action eq 'CODE' ) {
        $action = $action->( $node, $self );
    }

    return unless $action;

    my $output;

    $output  .= $self->render( $self->pre, $node, $args );

    my $content  = $self->replace ? $self->render( $self->replace, $node, $args )
                                  : $node->content
                                  ;

    if ( $self->filter ) {
        $self->filter->() for $content;  # quick way to tie $content to $_
    }

    $output .= $content;
    
    $output  .= $self->render( $self->{post}, $node, $args );

    return $output;

}


sub interpolate {
    my( $self, $string, $node ) = @_;

    my $regex = $self->stylesheet->interpolation_regex;

    $string =~ s/$regex/ $node->findvalue( $1 ) /eg;

    return $string;
}

sub render {
    my ( $self, $item, $node, $args ) = @_;

    return unless defined $item;

    my @args;

    @args = @$args if $args;


    $item = $item->( $node, $self, @args ) if ref $item eq 'CODE';    

    if ( $self->does_interpolate ) {
        $item = $self->interpolate( $item => $node );    
    }

    return $item;
}

42;

