package XML::XPathScript2::DOMWrapper::XML::LibXML::PI;

use MooseX::SemiAffordanceAccessor;
use Moose;

has node => ( is => 'ro' );

sub type { 'processing_instruction' };

sub content { $_[0]->node->getData } 

sub findvalue {
    $_[0]->node->findvalue( $_[1] );
}

sub name {
    $_[0]->node->nodeName;
}

1;
