package Net::Async::Webservice::UPS::Response::Rate;
$Net::Async::Webservice::UPS::Response::Rate::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Response::Rate::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

# ABSTRACT: response for request_rate


has services => (
    is => 'ro',
    isa => ArrayRef[Service],
    required => 1,
);


has warnings => (
    is => 'ro',
    isa => HashRef,
    required => 0,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::Rate - response for request_rate

=head1 VERSION

version 0.09_1

=head1 DESCRIPTION

Instances of this class are returned (in the Future) by calls to
L<Net::Async::Webservice::UPS/request_rate>.

=head1 ATTRIBUTES

=head2 C<services>

Array ref of services that you can use to ship the packages passed in
to C<request_rate>. Each one will have a set of rates, one per
package.

=head2 C<warnings>

Hashref of warnings extracted from the UPS response.

=head1 AUTHORS

=over 4

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
