package XML::XPathScript2::Stylesheet::Node::ProcessingInstructionTest;

use base qw/ XML::XPathScript2::Test /;

use Test::More;
use XML::LibXML;

use XML::XPathScript2::Stylesheet;
use XML::XPathScript2::Stylesheet::Element;

our $doc;
our $stylesheet;

sub parse_doc :Test(startup) {
    $doc = XML::LibXML->new->parse_string( '<doc><?foo bar="baz"?></doc>' );
    ( $doc ) = $doc->findnodes( '//doc' );
}

sub create_stylesheet :Test(setup) {
    $stylesheet = XML::XPathScript2::Stylesheet->new;
}

sub is_transform($) {
    is $stylesheet->transform( $doc ), shift;
}


sub clean_stylesheet :Test {
    is_transform '<doc><?foo bar="baz"?></doc>';
}

sub pre_post_filter :Test {

    $stylesheet->set_processing_instruction( 
        pre => '{',
        post => '}',
        filter => sub { s/a/i/g },
        showtag => 1,
        action => 1,
    );

    is_transform '<doc>{<?foo bir="biz"?>}</doc>';
}

sub replace_with_interpolation :Test {

    $stylesheet->set_processing_instruction( 
        replace => '{name(..)}',
        showtag => 0,
    );

    $stylesheet->processing_instruction->set_interpolation(1);

    is_transform '<doc>doc</doc>';
}

sub action_false :Test {

    $stylesheet->set_processing_instruction( 
        action => 0,
    );

    is_transform '<doc></doc>';
}

sub testcode :Test {
    $stylesheet->set_processing_instruction( 
        testcode => sub { $_[1]->set_replace('testcode') },
    );

    is_transform '<doc><?foo testcode?></doc>';
}

sub rename :Test {
    $stylesheet->set_processing_instruction(
        rename => 'pi',
    );

    is_transform '<doc><pi>bar="baz"</pi></doc>';
}

1;

__END__
