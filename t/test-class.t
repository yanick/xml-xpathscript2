use strict;
use warnings;

BEGIN {
    $XML::XPathScript2::Test::NO_SELF_RUN = 1;  # no-one start before I say so
    use Test::Class::Load 't/lib';
}

Test::Class->runtests;

1;
