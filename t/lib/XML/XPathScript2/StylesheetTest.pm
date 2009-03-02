package XML::XpathScript2::StylesheetTest;

use base 'XML::XPathScript2::Test';

use Test::More;

use XML::LibXML;

use XML::XPathScript2::Stylesheet;

our $doc;
our $stylesheet;

sub document :Test(startup) {
	$doc = XML::LibXML->new->parse_string( '<doc><one/><two/></doc>' );
}

sub stylesheet :Test(setup) {
	$stylesheet = XML::XPathScript2::Stylesheet->new;
}

sub stash :Tests(4) {
	is $stylesheet->transform( $doc ) 
		=> '<doc><one></one><two></two></doc>';

	$stylesheet->set( '*' => {
    		pre => sub {
        		++$_[2]->stash->{counter};
    		}
	} );

	is $stylesheet->transform( $doc ) 
		=> '1<doc>2<one></one>3<two></two></doc>';

	is $stylesheet->transform( $doc ) 
		=> '4<doc>5<one></one>6<two></two></doc>';

	$stylesheet->clear_stash;

	is $stylesheet->transform( $doc ) 
		=> '1<doc>2<one></one>3<two></two></doc>';
}

sub additive_changes :Test {

	# check that subsequent changes to an element are additives

	$stylesheet->set( '*' => { pre  => '[', } );
	$stylesheet->set( '*' => { post => ']', } );
	$stylesheet->set( '*' => { showtag => 0, } );

	is $stylesheet->transform( $doc ) => '[[][]]';
}

1;
