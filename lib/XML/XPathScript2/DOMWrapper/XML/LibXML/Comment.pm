package XML::XPathScript2::DOMWrapper::XML::LibXML::Comment;

use MooseX::SemiAffordanceAccessor;
use Moose;

has node => ( is => 'ro' );

sub type { 'comment' };

sub content { $_[0]->node->data } 

sub findvalue {
    $_[0]->node->findvalue( $_[1] );
}

1;
