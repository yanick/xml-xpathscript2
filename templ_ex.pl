use XML::XPathScript2::Template;

my $template = XML::XPathScript2::Template->new( 
    string => '<%= "hello world" %>' );

print $template->as_string;

