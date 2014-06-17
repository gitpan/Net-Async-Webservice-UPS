package Net::Async::Webservice::UPS::Types;
$Net::Async::Webservice::UPS::Types::VERSION = '0.09_6';
{
  $Net::Async::Webservice::UPS::Types::DIST = 'Net-Async-Webservice-UPS';
}
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( PickupType CustomerClassification
                    Cache Cacheable
                    Address Package PackageList
                    Rate RateList
                    RequestMode Service
                    ServiceCode ServiceLabel
                    PackagingType MeasurementSystem
                    Measure MeasurementUnit Currency
                    Tolerance
              );
use Type::Utils -all;
use Types::Standard -types;
use Scalar::Util 'weaken';
use namespace::autoclean;

# ABSTRACT: type library for UPS


enum PickupType,
    [qw(
           DAILY_PICKUP
           DAILY
           CUSTOMER_COUNTER
           ONE_TIME_PICKUP
           ONE_TIME
           ON_CALL_AIR
           SUGGESTED_RETAIL
           SUGGESTED_RETAIL_RATES
           LETTER_CENTER
           AIR_SERVICE_CENTER
   )];


enum CustomerClassification,
    [qw(
           WHOLESALE
           OCCASIONAL
           RETAIL
   )];


enum RequestMode, # there are probably more
    [qw(
           rate
           shop
   )];


enum ServiceCode,
    [qw(
           01
           02
           03
           07
           08
           11
           12
           12
           13
           14
           54
           59
           65
           86
           85
           83
           82
   )];


enum ServiceLabel,
    [qw(
        NEXT_DAY_AIR
        2ND_DAY_AIR
        GROUND
        WORLDWIDE_EXPRESS
        WORLDWIDE_EXPEDITED
        STANDARD
        3_DAY_SELECT
        3DAY_SELECT
        NEXT_DAY_AIR_SAVER
        NEXT_DAY_AIR_EARLY_AM
        WORLDWIDE_EXPRESS_PLUS
        2ND_DAY_AIR_AM
        SAVER
        TODAY_EXPRESS_SAVER
        TODAY_EXPRESS
        TODAY_DEDICATED_COURIER
        TODAY_STANDARD
   )];


enum PackagingType,
    [qw(
        LETTER
        PACKAGE
        TUBE
        UPS_PAK
        UPS_EXPRESS_BOX
        UPS_25KG_BOX
        UPS_10KG_BOX
   )];


enum MeasurementSystem,
    [qw(
           metric
           english
   )];


enum MeasurementUnit,
    [qw(
           LBS
           KGS
           IN
           CM
   )];


declare Currency,
    as Str;


declare Measure,
    as StrictNum,
    where { $_ >= 0 },
    inline_as {
        my ($constraint, $varname) = @_;
        my $perlcode =
            $constraint->parent->inline_check($varname)
                . "&& ($varname >= 0)";
        return $perlcode;
    },
    message { ($_//'<undef>').' is not a valid measure, it must be a non-negative number' };


declare Tolerance,
    as StrictNum,
    where { $_ >= 0 && $_ <= 1 },
    inline_as {
        my ($constraint, $varname) = @_;
        my $perlcode =
            $constraint->parent->inline_check($varname)
                . "&& ($varname >= 0 && $varname <= 1)";
        return $perlcode;
    },
    message { ($_//'<undef>').' is not a valid tolerance, it must be a number between 0 and 1' };


class_type Address, { class => 'Net::Async::Webservice::UPS::Address' };
coerce Address, from Str, via {
    require Net::Async::Webservice::UPS::Address;
    Net::Async::Webservice::UPS::Address->new({postal_code => $_});
};


class_type Package, { class => 'Net::Async::Webservice::UPS::Package' };
declare PackageList, as ArrayRef[Package];
coerce PackageList, from Package, via { [ $_ ] };


class_type Service, { class => 'Net::Async::Webservice::UPS::Service' };
coerce Service, from Str, via {
    require Net::Async::Webservice::UPS::Service;
    Net::Async::Webservice::UPS::Service->new({label=>$_});
};


class_type Rate, { class => 'Net::Async::Webservice::UPS::Rate' };
declare RateList, as ArrayRef[Rate];
coerce RateList, from Rate, via { [ $_ ] };


duck_type Cache, [qw(get set)];
duck_type Cacheable, [qw(cache_id)];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Types - type library for UPS

=head1 VERSION

version 0.09_6

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::UPS>.

=head1 TYPES

=head2 C<PickupType>

C<E>num, one of C<DAILY_PICKUP> C<DAILY> C<CUSTOMER_COUNTER>
C<ONE_TIME_PICKUP> C<ONE_TIME> C<ON_CALL_AIR> C<SUGGESTED_RETAIL>
C<SUGGESTED_RETAIL_RATES> C<LETTER_CENTER> C<AIR_SERVICE_CENTER>

=head2 C<CustomerClassification>

C<E>num, one of C<WHOLESALE> C<OCCASIONAL> C<RETAIL>

=head2 C<RequestMode>

Enum, one of C<rate> C<shop>

=head2 C<ServiceCode>

Enum, one of C<01> C<02> C<03> C<07> C<08> C<11> C<12> C<12> C<13>
C<14> C<54> C<59> C<65> C<86> C<85> C<83> C<82>

=head2 C<ServiceLabel>

Enum, one of C<NEXT_DAY_AIR> C<2ND_DAY_AIR> C<GROUND>
C<WORLDWIDE_EXPRESS> C<WORLDWIDE_EXPEDITED> C<STANDARD>
C<3_DAY_SELECT> C<3DAY_SELECT> C<NEXT_DAY_AIR_SAVER>
C<NEXT_DAY_AIR_EARLY_AM> C<WORLDWIDE_EXPRESS_PLUS> C<2ND_DAY_AIR_AM>
C<SAVER> C<TODAY_EXPRESS_SAVER> C<TODAY_EXPRESS>
C<TODAY_DEDICATED_COURIER> C<TODAY_STANDARD>

=head2 C<PackagingType>

Enum, one of C<LETTER> C<PACKAGE> C<TUBE> C<UPS_PAK>
C<UPS_EXPRESS_BOX> C<UPS_25KG_BOX> C<UPS_10KG_BOX>

=head2 C<MeasurementSystem>

Enum, one of C<metric> C<english>.

=head2 C<MeasurementUnit>

Enum, one of C<LBS> C<KGS> C<IN> C<CM>

=head2 C<Currency>

String.

=head2 C<Measure>

Non-negative number.

=head2 C<Tolerance>

Number between 0 and 1.

=head2 C<Address>

Instance of L<Net::Async::Webservice::UPS::Address>, with automatic
coercion from string (interpreted as a US postal code).

=head2 C<Package>

Instance of L<Net::Async::Webservice::UPS::Package>.

=head2 C<PackageList>

Array ref of packages, with automatic coercion from a single package
to a singleton array.

=head2 C<Service>

Instance of L<Net::Async::Webservice::UPS::Service>, with automatic
coercion from string (interpreted as a service label).

=head2 C<Rate>

Instance of L<Net::Async::Webservice::UPS::Rate>.

=head2 C<RateList>

Array ref of rates, with automatic coercion from a single rate to a
singleton array.

=head2 C<Cache>

Duck type, any object with a C<get> and a C<set> method.

=head2 C<Cacheable>

Duck type, any object with a C<cache_id> method.

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
