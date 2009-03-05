package XML::XPathScript2::Stylesheet;

#use MooseX::SemiAffordanceAccessor;

use Moose::Role;

#use MooseX::ClassAttribute;
use MooseX::AttributeHelpers;

use XML::XPathScript2::Stylesheet::Text;
use XML::XPathScript2::Stylesheet::Element;
use XML::XPathScript2::Stylesheet::Comment;
use XML::XPathScript2::Stylesheet::ProcessingInstruction;
use XML::XPathScript2::Stylesheet::Document;

use Readonly;

use Exporter 'import';

Readonly our $DO_NOTHING   => 0;
Readonly our $DO_SELF_ONLY => -1;
Readonly our $DO_ALL       => 1;

our @EXPORT = qw/ $DO_NOTHING $DO_SELF_ONLY $DO_ALL /;

class_has 'master' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_init_master',
);

has 'text' => (
    is => 'ro',
    default =>
      sub { XML::XPathScript2::Stylesheet::Text->new( stylesheet => $_[0] ) },
    handles => { set_text => 'set', },
);

has 'comment' => (
    is      => 'ro',
    default => sub {
        XML::XPathScript2::Stylesheet::Comment->new( stylesheet => $_[0] );
    },
    handles => { set_comment => 'set', },
);

has 'processing_instruction' => (
    is      => 'ro',
    default => sub {
        XML::XPathScript2::Stylesheet::ProcessingInstruction->new(
            stylesheet => $_[0] );
    },
    handles => { set_processing_instruction => 'set', },
);

has '_elements' => (
    isa       => 'HashRef[XML::XPathScript2::Stylesheet::Element]',
    metaclass => 'Collection::Hash',
    default   => sub { {} },
    provides  => {
        set    => '_set_element',
        get    => '_element',
        'keys' => 'element_keys',
    },
);

has 'catchall_element' => (
    is      => 'rw',
    default => sub {
        XML::XPathScript2::Stylesheet::Element->new( stylesheet => $_[0] );
    },
);

has document => (
    is      => 'rw',
    default => sub {
        XML::XPathScript2::Stylesheet::Document->new( stylesheet => $_[0] );
    },
);

has interpolation => (
    is      => 'rw',
    default => 0,
);

has interpolation_regex => (
    is      => 'rw',
    default => sub { qr/{([^}]+)}/s } );

has stash => (
    is      => 'ro',
    writer  => '_set_stash',
    isa     => 'HashRef',
    default => sub { {} },
);

sub _init_master {
    warn join ":", @_;

    my $class = shift;

    my $stylesheet = XML::XPathScript2::Stylesheet->new;

    warn $class;
    warn $class->meta->superclasses;

    return $stylesheet;
}

### methods ###############################################

sub clear_stash { $_[0]->_set_stash( {} ) }

sub element {
    my ( $self, $name ) = @_;
    my $elt = $self->_element($name);
    unless ($elt) {
        $elt =
          XML::XPathScript2::Stylesheet::Element->new( stylesheet => $self );
        $self->_set_element( $name => $elt );
    }
    return $elt;
}

sub set {
    my ( $self, $name, $transformer ) = @_;

    if ( $name =~ s/^#// ) {
        if ( $name eq 'text' ) {
            $self->set_text($transformer);
        }
    }
    elsif ( $name eq '*' ) {
        $self->catchall_element->set(%$transformer);
    }
    else {
        $self->set_element( $name => $transformer );
    }

}

sub set_element {
    my $self = shift;
    my ( $name, $args ) = @_;

    if ( ref $args eq 'HASH' ) {
        $self->element($name)->set(%$args);
    }
    else {
        $self->_set_element( $name => $args );
    }
}

sub transform {
    my ( $self, $node ) = @_;

    $node = $self->wrap($node);

    my $transformator = $self->resolve($node);

    # warn "$node => $transformator\n";

    return $transformator->transform($node);
}

sub wrap {
    my ( $self, $node ) = @_;

    my $type = ref $node;

    return $node if $type =~ /^XML::XPathScript2::DOMWrapper/;

    my $wrapper = eval <<"END_EVAL";
        use XML::XPathScript2::DOMWrapper::$type;
        XML::XPathScript2::DOMWrapper::${type}->new( node => \$node );
END_EVAL

    die $@ if $@;

    die "couldn't create wrapping for node" unless $wrapper;

    return $wrapper;
}

#--------------------------------------------------------

sub resolve {
    my ( $self, $node ) = @_;

    if ( $node->type eq 'element' ) {
        return $self->_element( $node->name )
          || $self->catchall_element;
    }

    my $type = $node->type;

    return $self->$type;
}

sub detach {
    my ( $self, $node ) = @_;

    # iterate through the nodes and replace the node by a copy

    my $copy = $node->clone;
    $node->set_is_instance(1);

    if ( $node->type eq 'text' ) {
        $self->set_text($copy);
        return;
    }
    elsif ( $node->type eq 'element' ) {
        for ( $self->element_keys ) {
            if ( $self->element($_) eq $node ) {    # FIXME
                    # FIXME set_element in Stylesheet
                $self->set_element( $_ => $copy );
            }
        }
    }
    else {
        die;
    }

}

1;
