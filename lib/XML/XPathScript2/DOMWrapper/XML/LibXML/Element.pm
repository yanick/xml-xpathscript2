package XML::XPathScript2::DOMWrapper::XML::LibXML::Element;

use MooseX::SemiAffordanceAccessor;
use Moose;

has node => ( is => 'ro' );
has type => ( is => 'ro', default => 'element' );

sub name { $_[0]->node->nodeName; }

sub attributes { 
    return map { 
        XML::XPathScript2::DOMWrapper::XML::LibXML::Attribute->new( 
            node => $_ ) } $_[0]->node->attributes; 
} 

sub children { 
    # FIXME we have to wrap'em all
    return $_[0]->node->childNodes; 
}

sub transform {
    my ( $self, $stylesheet ) = @_;
}

sub findvalue {
    $_[0]->node->findvalue( $_[1] );
}

sub findnodes {
    $_[0]->node->findnodes( $_[1] );
}

1;

