package XML::XPathScript2::Template;

use MooseX::SemiAffordanceAccessor;
use Moose;

use Parse::RecDescent;

our $parser = Parse::RecDescent->new( join '', <DATA> ) or die;

has string => ( is => 'rw' );

has code => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    $self->set_code( $parser->template( $self->string ) );
}

our %transform = (
    execute => sub { return $_[0]; },
    print   => sub { return "print $_[0];" },
);

sub safequote {
    my $x = shift;
    $x =~ s/#/\\#/g;
    return "q#$x#";
}

sub as_string {
    my ( $self, %arg ) = @_;

    my $code = $self->code;

    if ( $arg{output} eq 'return' ) {
        $code = <<END_CODE;
local *STDOUT;
my \$output;
open STDOUT, '>', \\\$output;
{
$code
}
\$output;
END_CODE
    }

    if ( $arg{wrapper} eq 'sub' ) {
        $code =
          'sub { ' . 'my( $node, $stylesheet ) = @_;' . "\n" . $code . '}';
    }

    return $code;
}

sub as_sub {
    my ( $self, %arg ) = @_;

    my $sub = eval $self->as_string( %arg, wrapper => 'sub' );

    die $@ if $@;
    return $sub;
}

1;

__DATA__
eofile : /^\z/

trimcode : '-' { $return = 'trim' } | { $return = 'no' }

inner_code : /.*?(?=-?%>|\z)/s { $return = $item[1] }

verbatim_text : ...!/^<%/ /^.+?(?=\s*<%|\z)/s { 
    $item[-1] =~ s!(?=#)!\\!g;
    $return = "print q#$item[-1]#;";
}

spaces : /\s+/

opening_code : spaces(?) '<%' trimcode { 
        if ( $item[-1] eq 'trim' or ! @{$item[1]} ) {
            $return = '';
        }
        else {
            $return = join '' => 'print q#', @{$item[1]}, '#;';
        }
    } spaces(?) 

closing_code : trimcode '%>' {
    $text =~ s/^\s+// if $item[1] eq 'trim'; 1
}

execute_operator : { $return = 'execute' }

print_operator : '=' { $return = 'print' }

simple_operator : print_operator | execute_operator

if_operator :   opening_code 
                    'if' /^.+?(?=\s*-?%>)/ spaces(?) 
                closing_code 
                block(s?)  
                opening_code  
                    '/if' 
                closing_code 
                {
                    $return = $item[1] . 'if ( ' . $item[3] . ' ) { ' . ( join
                    '', @{$item[6]} ) . $item[7] . '}' ;
                }

set_token : 'set' | '@'

set_operator : opening_code
                    set_token spaces(?) /\S+/ spaces(?) /\S*/ spaces(?) 
                closing_code 
                block(s?)  
                opening_code  
                    '/' $item[2] 
                closing_code 
                {
                    # FIXME BIG TIME
                    $stylesheet->set( $item[4], { ( $item[6] || 'content' ) =>
                    sub { blocks } }
                }


comment_keyword : '#' | 'comment'

comment_operator : opening_code comment_keyword /^.*?(?=-?%>)/ closing_code 
                   { $return = $item[1] }

comment_wrapper : opening_code comment_keyword spaces(?) closing_code
                  block(s?) opening_code '/' "$item[2]" closing_code 
                  { $return = $item[1] }

simple_code_segment : opening_code ...!m#^/# simple_operator inner_code closing_code
    { $return = $item[1].$XML::XPathScript2::Template::transform{ $item[3] }->( $item[4] ).';' } 

transform_operator : opening_code 
                        ( '~' | 'transform' )
                        spaces
                        /^.*?(?=\s*-?%>)/
                        spaces(?)
                     closing_code
                     { 
                        my $word = $item[4];
                        $word = XML::XPathScript2::Template::safequote( $word ) 
                               unless $word =~ /^[\$\@]/;

                        $return = 'print $stylesheet->transform( $_ ) for ' 
                                . 'map { ref $_ ? $_ : $node->findnodes( $_ ) } '
                                .  $word 
                                . ';'
                    }

operator : comment_wrapper 
         | comment_operator 
         | if_operator 
         | transform_operator 
         | simple_code_segment

block : operator 
      | verbatim_text

template : <skip: ''> block(s) eofile { $return = join '', @{$item[2]} } | <error>

