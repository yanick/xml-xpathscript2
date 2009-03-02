package XML::XPathScript2::DOMWrapper::XML::LibXML::Attribute;

use MooseX::SemiAffordanceAccessor;
use Moose;

has node => ( is => 'ro' );
has name => ( is => 'ro', lazy => 1, default => sub { $_[0]->nodeName } );
has value => ( is => 'ro', lazy => 1, default => sub { $_[0]->value } );

1;
