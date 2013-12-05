
=head1 NAME

Alma::UserWS.pm

=head1 DESCRIPTION

Interface to Alma User Management web services

=cut

package Alma::UserWS;
require Exporter;
@ISA = Exporter;
@EXPORT = qw( get update create delete );

$Alma::UserWS::VERSION = "2013.07.15";
sub Version { $VERSION; }

use Alma::Connector;

=head1 FUNCTIONS

=over

=item get

This Web service retrieves information related to a given
user—user details, blocks, identifiers, addresses, roles, etc.—if
the input parameters provide a match.

If the input parameters do not provide a match, an error message
is returned, stating the reason why the information cannot be
retrieved.

Input Parameters

    $id – A unique identifier for the user.

    $type (optional) – The type of identifier that is being
    searched.  If this is not provided, all unique identifier
    types are used. The values that can be used are user_name or
    any of the values in the User Identifier Type code table.

=cut

sub get {
    my ($id, $type) = @_;
    my @params = ();
    push @params, $id;
    push @params, $type if defined $type;
    my $message = buildMessage( 'getUserDetails', @params );
    return makeRequest( 'UserWebServices', $message );
};

=item update

This Web service updates the user details of a user that already
exists in Alma, according to information provided as input.

Input Parameters:

User identifier – A unique identifier for the user.

Identifier type (optional) – The type of identifier that is being
searched. If this is not provided, all unique identifier types are
used. The values that can be used are user_name or any of the
values in the User Identifier Type
code table.

External system code – Determines the system that is updating the
user.  If the field is populated, the system will make changes as
if the external system made the changes. If the field is left
empty, the user is managed internally by Alma. This may affect the
fields that can be modified.  The value in this field should match
the code of an SIS profile, which can be viewed on the External
Systems page in Alma.

User record – User information XML, as described on the Alma
Developers page.

=cut

sub update {
    my ($id, $type, $externalSystemCode, $userRecord) = @_;
    my $message = buildMessage( 'updateUser', $id, $type, $externalSystemCode, $userRecord );
    return makeRequest( 'UserWebServices', $message );
}

=item create

This Web service creates a new user in Alma, containing
information provided as input.

External system code – Determines the type of user to be created.
If the field is left empty, the user is managed internally by
Alma.  If the field is populated, an external user is created,
managed by the external system as provided in the parameter.
The value in this field should match the code of an SIS profile.

User record – User information XML, as described on the Alma Developers page.

issueWarning – Determines whether a warning is issued if a
duplicate user exists. The values that can be used are true,
false, or empty.Note that other values will return an error
message. By default, this parameter is set to true.
A duplicate user means that another user with same first name,
middle name, last name, and birth date already exists. If the new
user does not have a birth date, a duplication check is not
performed.

=cut

sub create {
    my ( $externalSystemCode, $userRecord, $warn ) = @_;
    my $message = buildMessage( 'createUser', $externalSystemCode, $userRecord, $warn );
    return makeRequest( 'UserWebServices', $message );
}

=item delete

This Web service removes a user from Alma.

Input Parameters:

User identifier – A unique identifier for the user.

Identifier type (optional) – The type of identifier that is being
searched. If this is not provided, all unique identifier types are
used. The values that can be used are user_name or any of the
values in the User Identifier Type
code table.

=cut

sub delete {
    my ( $id, $type ) = @_;
    my $message = buildMessage( 'deleteUser', $id, $type );
    return makeRequest( 'UserWebServices', $message );
}

__END__

=back

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2013.07.15

=cut

#qq|<?xml version="1.0"?>
#<soap:Envelope
#    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
#    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
#  <soap:Body xmlns:m="http://alma.exlibris.com/">
#    <m:getUserDetails>
#      <arg0>$id</arg0>
#    </m:getUserDetails>
#  </soap:Body>
#</soap:Envelope>
#|;

#my $almaws = {
#    host => 'ap01.alma.exlibrisgroup.com',
#    path => '/almaws/repository/',
#    auth => [ "AlmaSDK-passepartout-institutionCode-61ADELAIDE_INST", 'We.l1ke.cak3' ]
#};

#sub _send {
#    my ( $service, $message ) = @_;
#
#    use HTTP::Request::Common;
#    use LWP::UserAgent;
#
#    my $request = HTTP::Request->new;
#    $request->method("POST");
#    $request->uri("https://$almaws->{host}$almaws->{path}$service" );
#    $request->authorization_basic( @{ $almaws->{auth} } );
#    $request->content_type( 'text/xml' );
#    $request->content( $message );
#
#    my $ua = LWP::UserAgent->new;
#    my $response = $ua->request( $request );
#
#    unless ( $response->is_success ) {
#	print "Content-type: text/html\n\n";
#	print $response->error_as_HTML;
#	exit;
#    }
#
#    my $xml = $response->{_content};
#    $xml =~ s/&lt;/</gs; $xml =~ s/&gt;/>/gs;
#    return $xml;
#}

sub _message {
    my ($service, @args) = @_;
    my $k = 0;
    foreach $arg (@args) {
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
