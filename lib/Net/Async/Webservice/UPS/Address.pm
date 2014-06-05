package Net::Async::Webservice::UPS::Address;
$Net::Async::Webservice::UPS::Address::VERSION = '0.09_2';
{
  $Net::Async::Webservice::UPS::Address::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.10.0;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::UPS::Types ':types';

# ABSTRACT: an address for UPS


has city => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has postal_code => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has postal_code_extended => (
    is => 'ro',
    isa => Str,
    required => 0,
);

around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $args = $class->$orig(@etc);
    if ($args->{postal_code}
            and not defined $args->{postal_code_extended}
                and $args->{postal_code} =~ m{\A(\d+)-(\d+)\z}) {
        $args->{postal_code} = $1;
        $args->{postal_code_extended} = $2;
    }
    my @undef_k = grep {not defined $args->{$_} } keys %$args;
    delete @$args{@undef_k};
    return $args;
};


has state => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has country_code => (
    is => 'ro',
    isa => Str,
    required => 0,
    default => 'US',
);


has name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has building_name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has address => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has address2 => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has address3 => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has is_residential => (
    is => 'ro',
    isa => Bool,
    required => 0,
);


has quality => (
    is => 'ro',
    isa => StrictNum,
    required => 0,
);


sub is_exact_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality == 1);
}


sub is_very_close_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.95);
}


sub is_close_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.90);
}


sub is_possible_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.90);
}


sub is_poor_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality <= 0.69);
}


sub as_hash {
    my ($self, $shape) = @_;
    $shape //= 'AV';

    if ($shape eq 'AV') {
        return {
            Address => {
                CountryCode => $self->country_code || "US",
                PostalCode  => $self->postal_code,
                ( $self->city ? ( City => $self->city) : () ),
                ( $self->state ? ( StateProvinceCode => $self->state) : () ),
                ( $self->is_residential ? ( ResidentialAddressIndicator => undef ) : () ),
            }
        };
    }
    elsif ($shape eq 'XAV') {
        return {
            AddressKeyFormat => {
                CountryCode => $self->country_code || "US",
                PostcodePrimaryLow  => $self->postal_code,
                ( $self->postal_code_extended ? ( PostcodeExtendedLow => $self->postal_code_extended ) : () ),
                ( $self->name ? ( ConsigneeName => $self->name ) : () ),
                ( $self->building_name ? ( BuildingName => $self->building_name ) : () ),
                AddressLine  => [
                    ( $self->address ? $self->address : () ),
                    ( $self->address2 ? $self->address2 : () ),
                    ( $self->address3 ? $self->address3 : () ),
                ],
                ( $self->state ? ( PoliticalDivision1 => $self->state ) : () ),
                ( $self->city ? ( PoliticalDivision2 => $self->city ) : () ),
            }
        }
    }
    else {
        die "bad address to_hash shape $shape";
    }
}


sub cache_id {
    my ($self) = @_;
    return join ':',
        $self->name||'',
        $self->building_name||'',
        $self->address||'',
        $self->address2||'',
        $self->address3||'',
        $self->country_code,
        $self->state||'',
        $self->city||'',
        $self->postal_code,
        $self->postal_code_extended||'',
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Address - an address for UPS

=head1 VERSION

version 0.09_2

=head1 ATTRIBUTES

=head2 C<city>

String with the name of the city, optional.

=head2 C<postal_code>

String with the post code of the address, required.

=head2 C<postal_code_extended>

String with the extended post code of the address, optional. If a
postcode matching C<< \d+-\d+ >> is passed in to the constructor, the
first group of digits is assigned to L</postal_code> and the second
one to L</postal_code_extended>.

=head2 C<state>

String with the name of the state, optional.

=head2 C<country_code>

String with the 2 letter country code, optional (defaults to C<US>).

=head2 C<name>

String with the recipient name, optional.

=head2 C<building_name>

String with the building name, optional.

=head2 C<address>

String with the first line of the address, optional.

=head2 C<address2>

String with the second line of address, optional.

=head2 C<address3>

String with the third line of the address, optional.

=head2 C<is_residential>

Boolean, indicating whether this address is residential. Optional.

=head2 C<quality>

This should only be set in objects that are returned as part of a
L<Net::Async::Webservice::UPS::Response::Address>. It's a float
between 0 and 1 expressing how good a match this address is for the
one provided.

=head1 METHODS

=head2 C<is_exact_match>

True if L</quality> is 1. This method exists for compatibility with
L<Net::UPS::Address>.

=head2 C<is_very_close_match>

True if L</quality> is >= 0.95. This method exists for compatibility
with L<Net::UPS::Address>.

=head2 C<is_close_match>

True if L</quality> is >=0.9. This method exists for compatibility
with L<Net::UPS::Address>.

=head2 C<is_possible_match>

True if L</quality> is >= 0.9 (yes, the same as
L</is_close_match>). This method exists for compatibility with
L<Net::UPS::Address>.

=head2 C<is_poor_match>

True if L</quality> is <= 0.69. This method exists for compatibility
with L<Net::UPS::Address>.

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
address. Takes one parameter, either C<'AV'> or C<'XAV'>, to select
which representation to use (C<'XAV'> is the "street level validation"
variant).

=head2 C<cache_id>

Returns a string identifying this address.

=for Pod::Coverage BUILDARGS

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
