package XML::XPathScript2::Stylesheet::Node::CommentTest;

use base 'XML::XPathScript2::Test';

use Test::More;
use XML::LibXML;

use XML::XPathScript2::Stylesheet;
use XML::XPathScript2::Stylesheet::Element;

our $doc;
our $stylesheet;

sub parse_doc :Test(startup) {
    $doc = XML::LibXML->new->parse_string( '<doc><!--foo--></doc>' );
    ( $doc ) = $doc->findnodes( '//doc' );
}

sub create_stylesheet :Test(setup) {
    $stylesheet = XML::XPathScript2::Stylesheet->new;
}

sub is_transform($) {
    is $stylesheet->transform( $doc ), shift;
}


sub clean_stylesheet :Test {
    is_transform '<doc><!--foo--></doc>';
}

sub pre_post_filter :Test {

    $stylesheet->set_comment( 
        pre => '{',
        post => '}',
        filter => sub { s/oo/u/ },
        showtag => 0,
    );

    is_transform '<doc>{fu}</doc>';
}

sub replace_with_interpolation :Test {

    $stylesheet->set_comment( 
        replace => '{name(..)}',
        showtag => 0,
    );

    $stylesheet->comment->set_interpolation(1);

    is_transform '<doc>doc</doc>';
}

sub action_false :Test {

    $stylesheet->set_comment( 
        action => 0,
    );

    is_transform '<doc></doc>';
}

sub testcode :Test {
    $stylesheet->set_comment( 
        testcode => sub { $_[1]->set_replace('testcode') },
    );

    is_transform '<doc><!--testcode--></doc>';
}

sub rename :Test {
    $stylesheet->set_comment(
        rename => 'comment',
    );

    is_transform '<doc><comment>foo</comment></doc>';
}


1;

__END__
