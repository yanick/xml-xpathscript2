package XML::XpathScript2::TemplateTest;

use strict;

use base 'XML::XPathScript2::Test';

use Test::More;

use XML::XPathScript2::Template;

sub templ_eval($$) {
    my ( $t, $result ) = @_;

    my $output = XML::XPathScript2::Template->new( string => $t )->as_sub( output => 'return' )->();

    is $output => $result;
}


sub noop :Test {
    templ_eval 'blah blah' => 'blah blah';
}

sub misc :Test {
    templ_eval '<% my $x = 13 %>  <%-= $x %>'  => '13';
}

sub cond_if :Tests(5) {
    templ_eval '<% if ( 1 ) { %>foo<% } %>'  => 'foo';
    templ_eval '<% if ( 0 ) { %>foo<% } %>'  => undef;
    templ_eval '<% if  1 %>foo<%/if%>'  => 'foo';
    templ_eval '<% if  0 %>foo<%/if%>'  => undef;
    templ_eval '<% if 1 %><% if "true" %>foo<%/if%><%/if%>'  => 'foo';
}

sub comments :Tests(4) {
    templ_eval 'X<%# nothing to see here %>Y'  => 'XY';
    templ_eval 'X<%#%> nothing to see here <%/#%>Y'  => 'XY';
    templ_eval 'X<%comment nothing to see here %>Y'  => 'XY';
    templ_eval 'X<%comment%> nothing to see here <%/comment%>Y'  => 'XY';
}

sub transform :Tests(3) {
    use XML::XPathScript2::Stylesheet;
    use XML::LibXML;

    my $stylesheet = XML::XPathScript2::Stylesheet->new;
    $stylesheet->set( 'foo' => {
            showtag => 0,
            pre     => '[',
            post    => ']',
    } );

    my $doc = XML::LibXML->new->parse_string(
        '<doc><foo>X</foo><bar>Y</bar></doc>' 
    );

    my @t = ( 
        '<%~ //foo %>',
        '<% my $x = "//foo" %><%~ $x %>',
        '<% my @x = ( "//foo" ) %><%~ @x %>',
    );

    for my $t ( @t ) {
        my $sub = XML::XPathScript2::Template->new( 
            string => $t
        )->as_sub( output => 'return' );

        is $sub->( $doc, $stylesheet ) => '[X]', $t;
    }

}


1;
