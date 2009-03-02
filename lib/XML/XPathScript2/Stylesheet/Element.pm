package XML::XPathScript2::Stylesheet::Element;

use MooseX::SemiAffordanceAccessor;
use Moose;

no warnings qw/ uninitialized /;

use XML::Writer;
use Readonly;

extends 'XML::XPathScript2::Stylesheet::Node';
with 'XML::XPathScript2::Stylesheet::Detachable';

Readonly our $DO_NOTHING   => 0;
Readonly our $DO_SELF_ONLY => -1;
Readonly our $DO_ALL       => 1;

has showtag    => ( is => 'rw', default => 1 );
has $_ => ( is => 'rw' ) for qw/
  pre post intro extro prechildren postchildren
  prechild postchild
  /;
has insteadofchildren => (
    is        => 'rw',
    lazy      => 1,
    predicate => 'has_insteadofchildren',
    clearer   => 'clear_insteadofchildren',
    default   => sub { q{} },
);
has 'rename' => (
    is        => 'rw',
    predicate => 'has_rename',
    clearer   => 'clear_rename',
    lazy      => 1,
    default   => 0,
);
has action => ( is => 'rw', default => 1 );

has testcode => (
    is        => 'rw',
    predicate => 'has_testcode',
    clearer   => 'clear_testcode',
);

before "set_$_" => sub {
    my ($self) = shift;
    warn $self->_within_transformation;
    $self->detach_from_stylesheet if $self->_within_transformation;
  }
  for
  qw/ pre post intro extro prechildren postchildren 
      prechild postchild insteadofchildren rename action testcode showtag /;

sub type { 'element' }

sub clone {
    my $self = shift;
    bless {%$self}, ref $self;
}

sub set {
    my ( $self, %attrs ) = @_;

    $DB::single = 1;
    while ( my ( $method, $v ) = each %attrs ) {
        $method = 'set_' . $method;
        $self->$method($v);
    }

}

sub transform {
    my ( $self, $node, %args ) = @_;

    if ( $self->has_testcode ) {
        $self->testcode->( $node, $self, $args{args} );
    }

    my $action = $self->action;
    $action = $action->( $node, $self ) if ref $action eq 'CODE';

    return unless $action;

    my $output;

    $output .= $self->render( 'pre', $node, $args{args} );

    my $writer = new XML::Writer( OUTPUT => \$output );

    my $name = $node->name;

    #$name =~ s/^[^:]+(?=:)/ $node->lookupNamespaceURI( $& ) /e;

    if ( $self->showtag ) {
        $writer->startTag( $self->rename || $name,
            map { $_->name => $_->value } $node->attributes );
    }

    $output .= $self->render( 'intro', $node, $args{args} );

    #warn $name;

    $output .= $self->_transform_children( $action, $node, $args{args} );

    $output .= $self->render( 'extro', $node, $args{args} );

    $writer->endTag() if $self->showtag;

    $output .= $self->render( 'post', $node, $args{args} );

    return $output;

};

sub _transform_children {
    my ( $self, $action, $node, $args ) = @_;

    my @children;

    if ( $action =~ /^-?\d+$/ ) {
        return if $action < 0;
        @children = $node->children;
    }
    else {
        @children = $node->findnodes($action);
    }

    return unless @children;

    return $self->render( 'insteadofchildren', $node, $args )
      if $self->has_insteadofchildren;

    my $output = $self->render( 'prechildren', $node, $args );

    for (@children) {
        $output .= $self->render( 'prechild',  $node, $args );
        $output .= $self->stylesheet->transform($_);
        $output .= $self->render( 'postchild', $node, $args );
    }

    $output .= $self->render( 'postchildren', $node, $args );

    return $output;

}


42;

