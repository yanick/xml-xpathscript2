package XML::XPathScript2::Test;

use strict;
use warnings;

use base 'Test::Class';

INIT { Test::Class->runtests unless $XML::XPathScript2::Test::NO_SELF_RUN }

1;
