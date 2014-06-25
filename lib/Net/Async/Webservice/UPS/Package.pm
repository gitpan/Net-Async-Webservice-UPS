package Net::Async::Webservice::UPS::Package;
$Net::Async::Webservice::UPS::Package::VERSION = '1.0.0';
{
  $Net::Async::Webservice::UPS::Package::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Type::Params qw(compile);
use Types::Standard qw(Int Object);
use Net::Async::Webservice::UPS::Types ':types';
use Net::Async::Webservice::UPS::Exception;
use namespace::autoclean;
use 5.010;

# ABSTRACT: a package for UPS


has packaging_type => (
    is => 'ro',
    isa => PackagingType,
    default => sub { 'PACKAGE' },
);


has measurement_system => (
    is => 'ro',
    isa => MeasurementSystem,
    required => 1,
);


has length => (
    is => 'ro',
    isa => Measure,
);


has width => (
    is => 'ro',
    isa => Measure,
);


has height => (
    is => 'ro',
    isa => Measure,
);


has weight => (
    is => 'ro',
    isa => Measure,
);


has id => (
    is => 'rw',
    isa => Int,
);

my %code_for_packaging_type = (
    LETTER          => '01',
    PACKAGE         => '02',
    TUBE            => '03',
    UPS_PAK         => '04',
    UPS_EXPRESS_BOX => '21',
    UPS_25KG_BOX    => '24',
    UPS_10KG_BOX    => '25'
);


sub linear_unit {
    state $argcheck = compile(Object);
    my ($self) = $argcheck->(@_);

    $self->measurement_system eq 'metric' ? 'CM' : 'IN';
}


sub weight_unit {
    state $argcheck = compile(Object);
    my ($self) = $argcheck->(@_);

    $self->measurement_system eq 'metric' ? 'KGS' : 'LBS';
}


sub as_hash {
    state $argcheck = compile(Object);
    my ($self) = $argcheck->(@_);

    my %data = (
        PackagingType       => {
            Code => $code_for_packaging_type{$self->packaging_type},
        },
    );

    if ( $self->length || $self->width || $self->height ) {
        $data{Dimensions} = {
            UnitOfMeasurement => {
                Code => $self->linear_unit,
            }
        };

        if ( $self->length ) {
            $data{Dimensions}->{Length}= $self->length;
        }
        if ( $self->width ) {
            $data{Dimensions}->{Width} = $self->width;
        }
        if ( $self->height ) {
            $data{Dimensions}->{Height} = $self->height;
        }
    }

    if ( $self->weight ) {
        $data{PackageWeight} = {
            UnitOfMeasurement => {
                Code => $self->weight_unit,
            },
            Weight => $self->weight,
        };
    }

    if (my $oversized = $self->is_oversized ) {
        $data{OversizePackage} = $oversized;
    }

    return \%data;
}


sub is_oversized {
    state $argcheck = compile(Object);
    my ($self) = $argcheck->(@_);

    unless ( $self->width && $self->height && $self->length && $self->weight) {
        return 0;
    }

    my @sides = sort { $a <=> $b } ($self->length, $self->width, $self->height);
    my $len = pop(@sides);  # Get longest side
    my $girth = ((2 * $sides[0]) + (2 * $sides[1]));
    my $size = $len + $girth;

    my ($max_len,$max_weight,$max_size,
        $min_size,
        $os1_size,$os1_weight,
        $os2_size,$os2_weight,
        $os3_size,$os3_weight) =
            $self->measurement_system eq 'english' ?
                ( 108, 150, 165,
                  84,
                  108, 30,
                  130, 70,
                  165, 90 ) :
                ( 270, 70, 419,
                  210,
                  270, 10,
                  330, 32,
                  419, 40 );

    if ($len > $max_len or $self->weight > $max_weight or $size > $max_size) {
        Net::Async::Webservice::UPS::Exception::BadPackage->throw({package=>$self});
    }

    return 0 if ( $size <= $min_size ); # Below OS1
    if ($size <= $os1_size) { # OS1 pgk is billed for 30lbs
        return (($self->weight < $os1_weight) ? 1 : 0); # Not OS1 if weight > 30lbs
    }
    if ($size <= $os2_size) { # OS2 pgk is billed for 70lbs
        return (($self->weight < $os2_weight) ? 2 : 0); # Not OS2 if weight > 70lbs
    }
    if ($size <= $os3_size) { # OS3 pgk is billed for 90lbs
        return (($self->weight < $os3_weight) ? 3 : 0); # Not OS3 if weight > 90lbs
    }
}


sub cache_id {
    state $argcheck = compile(Object);
    my ($self) = $argcheck->(@_);

    return join ':',
        $self->packaging_type,$self->measurement_system,
        $self->length||0, $self->width||0, $self->height||0,
        $self->weight||0,;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Package - a package for UPS

=head1 VERSION

version 1.0.0

=head1 ATTRIBUTES

=head2 C<packaging_type>

Type of packaging (see
L<Net::Async::Webservice::UPS::Types/PackagingType>), defaults to
C<PACKAGE>.

=head2 C<measurement_system>

Either C<metric> (centimeters and kilograms) or C<english> (inches and
pounds), required.

=head2 C<length>

Length of the package, in centimeters or inches depending on
L</measurement_system>.

=head2 C<width>

Width of the package, in centimeters or inches depending on
L</measurement_system>.

=head2 C<height>

Height of the package, in centimeters or inches depending on
L</measurement_system>.

=head2 C<weight>

Weight of the package, in kilograms or pounds depending on
L</measurement_system>.

=head2 C<id>

Integer, usually only used internally when requesting rates.

=head1 METHODS

=head2 C<linear_unit>

Returns C<CM> or C<IN> depending on L</measurement_system>.

=head2 C<weight_unit>

Returns C<KGS> or C<LBS> depending on L</measurement_system>.

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
package.

=head2 C<is_oversized>

Returns an I<integer> indicating whether this package is to be
considered "oversized", and if so, in which oversize class it fits.

Mostly used internally by L</as_hash>.

=head2 C<cache_id>

Returns a string identifying this package.

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
