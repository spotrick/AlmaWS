package Alma::Connector;

require Exporter;
@ISA = Exporter;
@EXPORT = qw( buildMessage makeRequest );

$Alma::Connector::VERSION = "2014.02.05";
sub Version { $VERSION; }

## Very Private credentials for connecting and requesting

my $host = '****.alma.exlibrisgroup.com';
my $path = '/almaws/repository/';
my $inst = '**********';
my $user = '**********';
my $pass = '**********';

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
    $xml =~ s/&lt;/</gs;
    $xml =~ s/&gt;/>/gs;
    $xml =~ s/&quot;/"/gs;

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


=head1 NAME

Alma::Connector.pm

=head1 SYNOPSIS

    use Alma::Connector;
    ...
    $message = Alma::Connect::buildMessage( $service, $arg0, ... );
    $result = Alma::Connect::makeRequest( $service, $message );

=head1 DESCRIPTION

Provides a connection with Alma web services, and makes requests.

=head1 METHODS

=over

=item * buildMessage

    my $message = Alma::Connect::buildMessage( $service, $arg0, ... );

builds a service request message with the argument(s) provided.

=item * makeRequest

    my $result = Alma::Connect::makeRequest( $service, $message );

makes the actual request and return the response.

=back

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2014.02.05

=cut
