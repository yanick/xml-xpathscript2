#! /usr/local/bin/perl -sw

use strict;
use warnings;

use Parse::RecDescent;

use Test::More qw/ no_plan /;

$::RD_HINT = 1;

my $grammar = join '' => <DATA>;

%X::transform = (
    execute => sub { return $_[0]; },
    print => sub { return "print $_[0];" },
);

sub X::safequote {
    my $x = shift;
    $x =~ s/#/\\#/g;
    return "q#$x#";
}

my $parse = new Parse::RecDescent ($grammar) or die;

sub parse {
    return $parse->template( shift );
}

sub parse_eval {
    local *STDOUT;
    open STDOUT, '>', \my $stdout;
    eval parse( shift );
    return $stdout;
}

is parse_eval( 'blah blah' ) => 'blah blah';

is parse_eval( '<% my $x = 13 %>  <%-= $x %>' ) => '13';

is parse_eval( '<% if ( 1 ) { %>foo<% } %>' ) => 'foo';
is parse_eval( '<% if ( 0 ) { %>foo<% } %>' ) => undef;
is parse_eval( '<% if  1 %>foo<%/if%>' ) => 'foo';
is parse_eval( '<% if  0 %>foo<%/if%>' ) => undef;
is parse_eval( '<% if 1 %><% if "true" %>foo<%/if%><%/if%>' ) => 'foo';
is parse_eval( 'X<%# nothing to see here %>Y' ) => 'XY';
is parse_eval( 'X<%#%> nothing to see here <%/#%>Y' ) => 'XY';
is parse_eval( 'X<%comment nothing to see here %>Y' ) => 'XY';
is parse_eval( 'X<%comment%> nothing to see here <%/comment%>Y' ) => 'XY';

#Parse::RecDescent->Precompile($grammar, "Foo");
if(0){
print $parse->template( <<'END' );
    blah blah
    <% foo %><%= blah %>
    blah blah
    <% if $stuff %>
        Boof
    <%/if%>

    <% if ( $x ) { print } %>
    # hey #
    <%-~ /foo/bar -%>

END
}

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

if_operator : opening_code 'if' /^.+?(?=\s*-?%>)/ spaces(?) closing_code 
                block(s?)  opening_code  '/if' closing_code {
                    $return = $item[1] . 'if ( ' . $item[3] . ' ) { ' . ( join
                    '', @{$item[6]} ) . $item[7] . '}' ;
                }

comment_keyword : '#' | 'comment'

comment_operator : opening_code comment_keyword /^.*?(?=-?%>)/ closing_code 
                   { $return = $item[1] }

comment_wrapper : opening_code comment_keyword spaces(?) closing_code
                  block(s?) opening_code '/' "$item[2]" closing_code 
                  { $return = $item[1] }

simple_code_segment : opening_code ...!m#^/# simple_operator inner_code closing_code
    { $return = $item[1].$X::transform{ $item[3] }->( $item[4] ).';' } 

transform_operator : opening_code 
                        ( '~' | 'transform' )
                        spaces
                        ...!m#^/#
                        /^.*?(?=\s*-?%>)/
                        spaces(?)
                     closing_code
                     { $return = 'transform( ' . X::safequote( $item[5] ) .  ');'; }

operator : comment_wrapper 
         | comment_operator 
         | if_operator 
         | transform_operator 
         | simple_code_segment

block : operator 
      | verbatim_text

template : <skip: ''> block(s) eofile { $return = join '', @{$item[2]} } | <error>

