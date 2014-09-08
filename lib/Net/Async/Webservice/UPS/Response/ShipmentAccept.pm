package Net::Async::Webservice::UPS::Response::ShipmentAccept;
$Net::Async::Webservice::UPS::Response::ShipmentAccept::VERSION = '1.0.5';
{
  $Net::Async::Webservice::UPS::Response::ShipmentAccept::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

extends 'Net::Async::Webservice::UPS::Response::ShipmentBase';

# ABSTRACT: UPS response to a ShipAccept request


has pickup_request_number => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has control_log => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has package_results => (
    is => 'ro',
    isa => ArrayRef[PackageResult],
    required => 0,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::ShipmentAccept - UPS response to a ShipAccept request

=head1 VERSION

version 1.0.5

=head1 DESCRIPTION

This class is returned by
L<Net::Async::Webservice::UPS/ship_accept>. It's a sub-class of
L<Net::Async::Webservice::UPS::Response::ShipmentBase>.

=head1 ATTRIBUTES

=head2 C<pickup_request_number>

Not sure what this means.

=head2 C<control_log>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this means.

=head2 C<package_results>

Array ref of L<Net::Async::Webservice::UPS::Response::PackageResult>.

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
