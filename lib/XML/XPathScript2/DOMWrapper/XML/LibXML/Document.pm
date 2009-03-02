package XML::XPathScript2::DOMWrapper::XML::LibXML::Document;

use MooseX::SemiAffordanceAccessor;
use Moose;

has 'node' => ( is => 'rw' );
has type => ( is => 'ro', default => 'document' );

sub children { 
    # FIXME we have to wrap'em all
    return $_[0]->node->childNodes; 
}

sub findvalue {
    $_[0]->node->findvalue( $_[1] );
}

sub findnodes {
    $_[0]->node->findnodes( $_[1] );
}

1;

