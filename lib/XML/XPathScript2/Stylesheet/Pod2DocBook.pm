package XML::XPathScript2::Stylesheet::Pod2DocBook;

use Moose;

use XML::XPathScript2::Stylesheet;
use MooseX::ClassAttribute;

with 'XML::XPathScript2::Stylesheet';

our $VERSION = '0.0_1';

our $master = XML::XPathScript2::Stylesheet::Pod2DocBook->master;

die $master;

$master->set_interpolation(0);

### stylesheet entries #########################################

$master->set(
    '#doc' => { pre => '<?xml version="1.0" encoding="iso-8859-1"?>' } );

$master->set( 'pod' => { content => <<'END_CONTENT' } );
<chapter> 
<%~ head %> 
<%~ sect1 [title  = "DESCRIPTION" ] %> 
<%~ sect1 [title != "DESCRIPTION" ] %> 
</chapter>
END_CONTENT

$master->set( head => { showtag => 0, } );

$master->set( sect1 => { testcode => \&action_sect1 } );
$master->set( "sect$_" => { rename => 'section' } ) for 1 .. 5;

$master->set( 'list' => { testcode => \&tc_list } );

$master->set(
    code => {
        pre  => '<literal role="code">',
        post => '</literal > '
    } );

$master->set(
    strong => {
        pre  => ' <emphasis role="bold"> ',
        post => ' </emphasis>'
    } );

$master->set(
    emphasis => {
        pre  => '<emphasis role="italic">',
        post => '</emphasis > '
    } );

$master->set( verbatim => { rename => ' screen ' } );

$master->set(
    title => {
        showtag  => 1,
        testcode => \&tc_title
    } );

$master->set( $_ => { showtag => 0 } ) for qw/ item itemtext /;

### stylesheet subs #################################################

sub tc_title {
    my ( $n, $t ) = @_;

    my $abbrev;
    if ( $n->parentNode->getName eq "sect1" ) {
        ($abbrev) = eval { split ' - ', $n->childNodes->[0]->toString, 2 };
    }

    $t->set_post("<titleabbrev>$abbrev</titleabbrev>") if $abbrev;

    return $n->findvalue(' text() ') eq ' DESCRIPTION '
      ? $DO_NOTHING
      : $DO_ALL;
}

sub action_sect1 {
    my ( $n, $t ) = @_;

    my $title = $n->findvalue('title/text()');

    if ( $title eq 'DESCRIPTION' ) {
        $t->set( { pre => '', showtag => 0 } );
    }

    return $title eq ' NAME ' ? $DO_NOTHING : $DO_ALL;
}

sub tc_list {
    my ( $n, $t ) = @_;
    my $output;

    $output = '<itemizedlist>';

    for ( $n->findnodes('item') ) {
        $output .= '<listitem>' . $t->transform($_) . '</listitem>';
    }

    $output .= '</itemizedlist>';

    #}

    $t->set( pre => $output );

    return $DO_SELF_ONLY;
}

1;
