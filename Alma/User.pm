
=head1 NAME

Alma::User.pm

=head1 DESCRIPTION

Handy tools for dealing with Alma user record

=cut

package Alma::User;
require Exporter;
@ISA = Exporter;
@EXPORT = qw( getUserRecord getAddress getPhone getEmailAddr getStatCategories getBarcode );

$Alma::UserWS::VERSION = "2013.11.28";
sub Version { $VERSION; }

use Alma::UserWS;

=head1 FUNCTIONS

=over

=item getUser

Fetches a userRecord for the given id.

Input:

    A unique identifier for the user.

Output:

    A hash of the userRecord data

=cut

sub getUser {
    my $id = shift;
    my $data = {};

    my $response;

    if ( $id =~ /^\d{10}\w$/ ) {
	$response = Alma::UserWS::get( $id, 'BARCODE' );
    } else {
	$response = Alma::UserWS::get( $id );
    }

    #my $response = Alma::UserWS::get( $id );

    if ( $response->{error} ) {

	$data->{error} = "Error $response->{error} : $response->{message}\n";

    } else {

        my $xml = $response->{xml};
	$xml =~ s/xb://g;

	## turn the xml into a hash
	use XML::Simple;
	$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
	$data = XMLin( $xml,
	    ForceArray => [ 'userEmail', 'userAddress', 'userPhone', 'userIdentifier',
			    'userCategory',
			    'userNoteList', 'userBlockList', 'userRole' ],
	    ValueAttr => { userAddress => 'preferred', userEmail => 'preferred' } );

    }

    return $data;
}

=item getAddress

Returns the email address of the user

Input:

    A hash of the userRecord data

Output:

    A hash containing the preferred address (if any), or if
    preferred not indicated, the one with type work or school. If
    neither of those is present, returns the last address found.

    The hash has the same fields as the Alma user record address,
    viz.:
	line1 line2 line3 line4 line5
	city stateProvince postalCode country

    Returns undefined if there are no addresses in the record.

=cut

sub getAddress {
    my $data = shift;
    my $address;
    foreach $a ( @{ $data->{userAddressList}->{userAddress} } ) {
	$address = $a;
	last if ( $address->{preferred} eq 'true' );
	last if ( $address->{types}->{userAddressTypes} eq 'work' );
	last if ( $address->{types}->{userAddressTypes} eq 'school' );
    }

    ## Empty fields are a hash with xsi:nil => true ; replace with null...
    foreach $f ( qw( line1 line2 line3 line4 line5 city stateProvince postalCode country ) ) {
	if ( ref($address->{$f}) eq 'HASH' ) { $address->{$f} = ''; }
    }

    return $address;
}

=item getPhone

Returns the preferred phone number of the user

Input:

    A hash of the userRecord data

Output:

    A string containing the preferred phone number (if any), or if
    preferred not indicated, the last one found.
    Returns the null string if there are no phone number in the 
    record.

=cut

sub getPhone {
    my $data = shift;
    my $phone = ''; # default to empty
    foreach my $e ( @{ $data->{userAddressList}->{userPhone} } ) {
	$phone = $e->{phone};
	last if ( $e->{preferred} eq 'true' );
    }
    # i.e. if there is an phone address we will use it; if there is a
    # preferred one, we will use that.
    return $phone;
}

=item getEmailAddr

Returns the preferred email address of the user

Input:

    A hash of the userRecord data

Output:

    A string containing the preferred email address (if any), or if
    preferred not indicated, the last one found.
    Returns the null string if there are no email addresses in the 
    record.

=cut

sub getEmailAddr {
    my $data = shift;
    my $email = ''; # default to empty
    foreach my $e ( @{ $data->{userAddressList}->{userEmail} } ) {
	$email = $e->{email};
	last if ( $e->{preferred} eq 'true' );
    }
    # i.e. if there is an email address we will use it; if there is a
    # preferred one, we will use that.
    return $email;
}

=item getCategories

Returns a list of statistical categories for the user.

Input:

    A hash of the userRecord data

Output:

    A list of categories.

=cut

sub getCategories {
    my $data = shift;
    my @stats = ();
    foreach my $c ( @{ $data->{userStatisticalCategoriesList}->{userCategory} } ) {
	push @stats, $c->{statisticalCategory};
    }
    return @stats;
}

=item getBarcode

Returns the active barcode for the user.

Input:

    A hash of the userRecord data

Output:

    A barcode number ; or the empty string if there are no active barcodes.

=cut

sub getBarcode {
    my $data = shift;
    my $barcode = '';
    foreach my $id ( @{ $data->{userIdentifiersList}->{userIdentifier} } ) {
	if ( $id->{status} = 'Active' ) {
	    $barcode = $id->{value};
	    last;
	}
    }
    return $barcode;
}

__END__

=back

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2013.11.28

=head1 APPENDIX

<?xml version="1.0" encoding="UTF-8"?>
<xs:schema targetNamespace="http://com/exlibris/urm/user_record/xmlbeans" xmlns="http://com/exlibris/urm/user_record/xmlbeans"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">

  <xs:element name="userRecord">
    <xs:complexType>
      <xs:all>
        <xs:element name="userDetails" type="userDetails" minOccurs="1" maxOccurs="1" />
        <xs:element name="owneredEntity" type="owneredEntity" minOccurs="1" maxOccurs="1" />
        <xs:element name="userNoteList" type="userNoteList" minOccurs="0" maxOccurs="1" />
        <xs:element name="userBlockList" type="userBlockList" minOccurs="0" maxOccurs="1" />
        <xs:element name="userIdentifiers" type="userIdentifiersList" minOccurs="0" maxOccurs="1" />
        <xs:element name="userAddressList" type="userAddressList" minOccurs="0" maxOccurs="1" />
        <xs:element name="userRoleList" type="userRoleList" minOccurs="0" maxOccurs="1" />
        <xs:element name="userStatisticalCategoriesList" type="userStatList" minOccurs="0" maxOccurs="1" />
      </xs:all>
    </xs:complexType>
  </xs:element>

  <xs:complexType name="userDetails">
    <xs:all>
      <xs:element name="status" 	type="userStatus" minOccurs="1" maxOccurs="1" />
      <xs:element name="recordType" 	type="recordType" minOccurs="0" maxOccurs="1" default="Public" />
      <xs:element name="userType" 	type="userType" minOccurs="0" maxOccurs="1" default="External" />
      <xs:element name="expiryDate" 	type="formattedDateType" minOccurs="0" maxOccurs="1" />
      <xs:element name="defaultLanguage" type="xs:string" minOccurs="1" maxOccurs="1" />
      <xs:element name="userName" 	type="xs:string" minOccurs="0" maxOccurs="1">
        <xs:annotation>
          <xs:documentation>The value of the 'Primary identifier' of the User Information section in the UI</xs:documentation>
        </xs:annotation>
      </xs:element>
      <xs:element name="firstName"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="lastName"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="middleName"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="jobTitle"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="jobDescription"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="userGroup"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="externalId"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="webSiteUrl"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="birthDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />
      <xs:element name="purgeDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />
      <xs:element name="gender"		type="gender" minOccurs="0" maxOccurs="1" />
      <xs:element name="password"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="forcePasswordChange"	type="yesNo" minOccurs="0" maxOccurs="1" />
      <xs:element name="pinNumber"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="campusCode"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="resourceSharingLibraryCode"	type="xs:string" minOccurs="0" maxOccurs="1">
        <xs:annotation>
          <xs:documentation>
	    The code of resource sharing library related to the user.
	    Possible codes are libraries that are marked as resource sharing library.
          </xs:documentation>
        </xs:annotation>
      </xs:element>
    </xs:all>
  </xs:complexType>

  <xs:complexType name="userNoteList">
    <xs:sequence>
      <xs:element name="userNote"	type="userNote" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="userNote">
    <xs:all>
      <xs:element name="owneredEntity"	type="owneredEntity" minOccurs="0" maxOccurs="1" />
      <xs:element name="note"	type="xs:string" minOccurs="1" maxOccurs="1" />
      <xs:element name="userViewable"	type="xs:boolean" minOccurs="0" maxOccurs="1" default="false" />
      <xs:element name="type"	type="noteType" minOccurs="1" maxOccurs="1" />

    </xs:all>
  </xs:complexType>

  <xs:complexType name="userBlockList">
    <xs:sequence>
      <xs:element name="userBlock"	type="userBlock" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="userBlock">
    <xs:all>
      <xs:element name="owneredEntity"	type="owneredEntity" minOccurs="1" maxOccurs="1" />
      <xs:element name="status"	type="blockStatus" minOccurs="0" maxOccurs="1" default="Active" />
      <xs:element name="type"	type="blockType" minOccurs="0" maxOccurs="1" default="General" />
      <xs:element name="note"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="blockDefinitionId"	type="xs:string" minOccurs="1" maxOccurs="1" />
    </xs:all>
  </xs:complexType>

  <xs:complexType name="userIdentifiersList">
    <xs:sequence>
      <xs:element name="userIdentifier"	type="userIdentifier" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="userIdentifier">
    <xs:all>
      <xs:element name="owneredEntity"	type="owneredEntity" minOccurs="0" maxOccurs="1" />
      <xs:element name="type"		type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="status"		type="idStatus" minOccurs="0" maxOccurs="1" default="Active" />
      <xs:element name="note"		type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="value"		type="xs:string" minOccurs="1" maxOccurs="1" />

    </xs:all>
  </xs:complexType>

  <xs:complexType name="userRoleList">
    <xs:sequence>
      <xs:element name="userRole"	type="userRole" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="userRole">
    <xs:all>
      <xs:element name="owneredEntity"	type="owneredEntity" minOccurs="1" maxOccurs="1" />
      <xs:element name="status"		type="roleStatus" minOccurs="1" maxOccurs="1" />
      <xs:element name="expiryDate"	type="formattedDateType" minOccurs="1" maxOccurs="1" />
      <xs:element name="scope"		type="xs:string" minOccurs="1" maxOccurs="1" />
      <xs:element name="roleType"	type="digitString" minOccurs="1" maxOccurs="1" />
      <xs:element name="details"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="note"		type="xs:string" minOccurs="0" maxOccurs="1" />
    </xs:all>
  </xs:complexType>

  <xs:complexType name="userAddressList">
    <xs:choice maxOccurs="unbounded">
      <xs:element name="userAddress"	type="userAddress" minOccurs="0" maxOccurs="unbounded" />
      <xs:element name="userPhone"	type="userPhone" minOccurs="0" maxOccurs="unbounded" />
      <xs:element name="userEmail"	type="userEmail" minOccurs="0" maxOccurs="unbounded" />
    </xs:choice>
  </xs:complexType>

  <xs:complexType name="userAddress">
    <xs:all>
      <xs:element name="line1"		type="xs:string" />
      <xs:element name="line2"		type="xs:string" />
      <xs:element name="line3"		type="xs:string" />
      <xs:element name="line4"		type="xs:string" />
      <xs:element name="line5"		type="xs:string" />
      <xs:element name="city"		type="xs:string" />
      <xs:element name="stateProvince"	type="xs:string" />
      <xs:element name="postalCode"	type="xs:string" />
      <xs:element name="country"	type="xs:string">
        <xs:annotation>
          <xs:documentation>Values taken from CountryCodes Alma Code Table
          </xs:documentation>
        </xs:annotation>
      </xs:element>
      <xs:element name="note"		type="xs:string" />
      <xs:element name="startDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />
      <xs:element name="endDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />
      <xs:element name="types">
        <xs:complexType>
          <xs:choice minOccurs="1" maxOccurs="unbounded">
            <xs:element name="userAddressTypes">
              <xs:simpleType>
                <xs:restriction base="xs:string">
                  <xs:enumeration value="order" />
                  <xs:enumeration value="claim" />
                  <xs:enumeration value="payment" />
                  <xs:enumeration value="returns" />
                  <xs:enumeration value="home" />
                  <xs:enumeration value="work" />
                  <xs:enumeration value="billing" />
                  <xs:enumeration value="shipping" />
                  <xs:enumeration value="school" />
                  <xs:enumeration value="alternative" />
                </xs:restriction>
              </xs:simpleType>
            </xs:element>
          </xs:choice>
        </xs:complexType>
      </xs:element>
    </xs:all>
    <xs:attribute name="preferred"	type="xs:boolean" default="false" />
  </xs:complexType>

  <xs:complexType name="userPhone">
    <xs:all>
      <xs:element name="phone"	type="xs:string" />
      <xs:element name="types">
        <xs:complexType>
          <xs:choice maxOccurs="unbounded">
            <xs:element name="userPhoneTypes">
              <xs:simpleType>
                <xs:restriction base="xs:string">
                  <xs:enumeration value="orderPhone" />
                  <xs:enumeration value="claimPhone" />
                  <xs:enumeration value="paymentPhone" />
                  <xs:enumeration value="returnsPhone" />
                  <xs:enumeration value="orderFax" />
                  <xs:enumeration value="claimFax" />
                  <xs:enumeration value="paymentFax" />
                  <xs:enumeration value="returnsFax" />
                  <xs:enumeration value="home" />
                  <xs:enumeration value="mobile" />
                  <xs:enumeration value="office" />
                  <xs:enumeration value="officeFax" />
                </xs:restriction>
              </xs:simpleType>
            </xs:element>
          </xs:choice>
        </xs:complexType>
      </xs:element>
    </xs:all>
    <xs:attribute name="preferred"	type="xs:boolean" default="false" />
    <xs:attribute name="preferredSMS"	type="xs:boolean" default="false" />
  </xs:complexType>

  <xs:complexType name="userEmail">
    <xs:all>
      <xs:element name="email"	type="xs:string" />
      <xs:element name="description"	type="xs:string" />
      <xs:element name="types">
        <xs:complexType>
          <xs:choice maxOccurs="unbounded">
            <xs:element name="userEmailTypes">
              <xs:simpleType>

                <xs:restriction base="xs:string">
                  <xs:enumeration value="orderMail" />
                  <xs:enumeration value="claimMail" />
                  <xs:enumeration value="paymentMail" />
                  <xs:enumeration value="returnsMail" />
                  <xs:enumeration value="personal" />
                  <xs:enumeration value="school" />
                  <xs:enumeration value="work" />
                  <xs:enumeration value="order" />
                  <xs:enumeration value="queries" />
                </xs:restriction>
              </xs:simpleType>
            </xs:element>
          </xs:choice>
        </xs:complexType>
      </xs:element>
    </xs:all>
    <xs:attribute name="preferred"	type="xs:boolean" default="false" />
  </xs:complexType>

  <xs:simpleType name="digitString">
    <xs:restriction base="xs:string">
      <xs:pattern value="[0-9]*" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="userStatus">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Active" />
      <xs:enumeration value="Inactive" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="roleStatus">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Active" />
      <xs:enumeration value="Inactive" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="noteType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Library" />
      <xs:enumeration value="Circulation" />
      <xs:enumeration value="Registrar" />
      <xs:enumeration value="Erp" />
      <xs:enumeration value="Barcode" />
      <xs:enumeration value="Address" />
      <xs:enumeration value="Popup" />
      <xs:enumeration value="Other" />
    </xs:restriction>
  </xs:simpleType>
  <xs:simpleType name="blockStatus">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Active" />
      <xs:enumeration value="Inactive" />
    </xs:restriction>
  </xs:simpleType>
  <xs:simpleType name="blockType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Loan" />
      <xs:enumeration value="Ill" />
      <xs:enumeration value="Cash" />
      <xs:enumeration value="User" />
      <xs:enumeration value="General" />
      <xs:enumeration value="Renew" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="idStatus">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Active" />
      <xs:enumeration value="Inactive" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="emailStatus">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Active" />
      <xs:enumeration value="Inactive" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="recordType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Staff" />
      <xs:enumeration value="Public" />
    </xs:restriction>
  </xs:simpleType>
  <xs:simpleType name="userType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Internal" />
      <xs:enumeration value="External" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="gender">

    <xs:restriction base="xs:string">
      <xs:enumeration value="Male" />
      <xs:enumeration value="Female" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="yesNo">
    <xs:restriction base="xs:string">
      <xs:enumeration value="yes" />
      <xs:enumeration value="no" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="formattedDateType">
    <xs:annotation>
      <xs:documentation>The format is yyyyMMddHHmmss</xs:documentation>
    </xs:annotation>
    <xs:restriction base="xs:string">
      <xs:pattern value="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" />
    </xs:restriction>

  </xs:simpleType>

  <xs:complexType name="owneredEntity">
    <xs:all>
      <xs:element name="creationDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />

      <xs:element name="modificationDate"	type="formattedDateType" minOccurs="0" maxOccurs="1" />

      <xs:element name="createdBy"	type="xs:string" minOccurs="0" maxOccurs="1" />

      <xs:element name="modifiedBy"	type="xs:string" minOccurs="0" maxOccurs="1" />

    </xs:all>
  </xs:complexType>

  <xs:complexType name="userStatList">
    <xs:sequence>
      <xs:element name="userCategory"	type="userCategory" minOccurs="1" maxOccurs="unbounded" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="userCategory">
    <xs:all>
      <xs:element name="owneredEntity"	type="owneredEntity" minOccurs="1" maxOccurs="1" />
      <xs:element name="note"	type="xs:string" minOccurs="0" maxOccurs="1" />
      <xs:element name="statisticalCategory"	type="xs:string" minOccurs="1" maxOccurs="1">
        <xs:annotation>
          <xs:documentation>This is the code from the User Statistical Categories code table
          </xs:documentation>
        </xs:annotation>
      </xs:element>
    </xs:all>
  </xs:complexType>

</xs:schema>

=cut
