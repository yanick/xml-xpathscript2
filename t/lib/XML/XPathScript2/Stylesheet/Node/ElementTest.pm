package XML::XPathScript2::Stylesheet::Node::ElementTest;

use base 'XML::XPathScript2::Test';

use Test::More;
use XML::LibXML;

use XML::XPathScript2::Stylesheet;
use XML::XPathScript2::Stylesheet::Element;

our $doc;
our $stylesheet;

sub parse_doc :Test(startup) {
    $doc = XML::LibXML->new->parse_string( '<doc><one/><two/></doc>' );
    ( $doc ) = $doc->findnodes( '//doc' );
}

sub create_stylesheet :Test(setup) {
    $stylesheet = XML::XPathScript2::Stylesheet->new;
}

sub is_transform($) {
    is $stylesheet->transform( $doc ), shift;
}

sub is_transform_like($) {
    like $stylesheet->transform( $doc ), shift;
}


sub pre_post :Test {

    $stylesheet->set( doc => {
        pre => '{',
        post => '}',
    });

    is_transform_like qr/^\{.*\}$/;
}

sub all_pres_and_posts :Test {
    $stylesheet->set( doc => {
        showtag => 1,
        map { $_ => "[$_]" }
            qw/ pre post intro extro prechildren postchildren
                prechild postchild /
    });

    is_transform '[pre]<doc>[intro][prechildren][prechild]<one></one>'
               . '[postchild][prechild]<two></two>[postchild]'
               . '[postchildren][extro]</doc>[post]'
               ;

}

sub showtag_disabled :Test {
    $stylesheet->set( doc => {
        showtag => 0,
    } );

    is_transform '<one></one><two></two>';
}

sub action :Tests(4) {

    my %result = (
        -1 => '<doc></doc>',
         1 => '<doc><one></one><two></two></doc>',
         0 => undef,
         'one' => '<doc><one></one></doc>',
    );
    
    while( my ( $t, $r ) = each %result ) {
        $stylesheet->set( doc => { action => $t } );
        is_transform $r;
    }
}

sub insteadofchildren :Test {
    $stylesheet->set( doc => { insteadofchildren => 'XXX' } );

    is_transform '<doc>XXX</doc>';
}

sub rename :Test {
    $stylesheet->set( doc => { rename => 'elmer' } );

    is_transform_like qr#^<elmer>.*</elmer>$#;

}

sub testcode :Tests(2) {
    $stylesheet->set( doc => { testcode =>  
    sub { $_[1]->set_action(0); 
    } 
} );

    is_transform undef;

    # changes in testcode are only valid for this element

    isnt $stylesheet->element('doc')->action => 0;

}

1;

__END__
