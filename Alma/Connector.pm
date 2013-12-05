package Alma::Connector;

=head1 NAME

Alma::Connector.pm

=head1 USAGE

    use Alma::Connector;

Build a web service request using

    $message = Alma::Connect::buildMessage( $service, $arg0, ... );

Make the actual request and return the response using

    $result = Alma::Connect::makeRequest( $service, $message );

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2013.07.24

=cut

require Exporter;
@ISA = Exporter;
@EXPORT = qw( buildMessage makeRequest );

$Alma::Connector::VERSION = "2013.07.24";
sub Version { $VERSION; }

## Very Private credentials for connecting and requesting

my $host = 'ap01.alma.exlibrisgroup.com';
my $path = '/almaws/repository/';
my $inst = '61ADELAIDE_INST';
my $user = 'passepartout';
my $pass = 'We.l1ke.cak3';

sub makeRequest {
    my ( $service, $message ) = @_;
    my $result = {};

    use HTTP::Request::Common;
    use LWP::UserAgent;

    my $request = HTTP::Request->new;
    $request->method("POST");
    $request->uri( "https://${host}${path}$service" );
    $request->authorization_basic( "AlmaSDK-${user}-institutionCode-${inst}", "$pass" );
    $request->content_type( 'text/xml' );
    $request->content( $message );

    my $ua = LWP::UserAgent->new;
    my $response = $ua->request( $request );

    unless ( $response->is_success ) {
	print "Content-type: text/html\n\n";
	print $response->error_as_HTML;
	exit;
    }

    my $xml = $response->{_content};
    $xml =~ s/&lt;/</gs; $xml =~ s/&gt;/>/gs;

    for ($xml) {
	if ( /<errorsExist>false<\/errorsExist/ ) {
	    $result->{error} = 0;
	    if ( /<result>\s*(.+)<\/result>/s ) { $result->{xml} = $1; }
	}
	if ( /<errorsExist>true<\/errorsExist/ ) {
	    if ( /<errorCode>(.+)<\/errorCode>/s ) { $result->{error} = $1; }
	    if ( /<errorMessage>(.+)<\/errorMessage>/s ) { $result->{message} = $1; }
	}
    }

    return $result;
}

sub buildMessage {
    my ($service, @args) = @_;
    my $k = 0;
    my $arglist = '';
    foreach my $arg (@args) {
        $arglist .= "      <arg$k>$arg</arg$k>\n";
	$k++;
    }
    return 
qq|<?xml version="1.0"?>
<soap:Envelope
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Body xmlns:m="http://alma.exlibris.com/">
    <m:$service>
$arglist
    </m:$service>
  </soap:Body>
</soap:Envelope>
|;
}

1;

__END__
