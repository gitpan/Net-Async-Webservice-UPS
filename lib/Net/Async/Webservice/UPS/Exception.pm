package Net::Async::Webservice::UPS::Exception;
$Net::Async::Webservice::UPS::Exception::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Exception::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
with 'Throwable','StackTrace::Auto';
use overload
  q{""}    => 'as_string',
  fallback => 1;

# ABSTRACT: base exception class for UPS


around _build_stack_trace_args => sub {
    my ($orig,$self) = @_;

    my $ret = $self->$orig();
    push @$ret, (
        no_refs => 1,
        respect_overload => 1,
        message => '',
        indent => 1,
    );

    return $ret;
};


sub as_string { "something bad happened at ". $_[0]->stack_trace->as_string }

{package Net::Async::Webservice::UPS::Exception::ConfigError;
$Net::Async::Webservice::UPS::Exception::ConfigError::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Exception::ConfigError::DIST = 'Net-Async-Webservice-UPS';
}
 use Moo;
 extends 'Net::Async::Webservice::UPS::Exception';

 # ABSTRACT: exception thrown when the configuration file can't be parsed


 has file => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return 'Bad config file: %s, at %s',
         $self->file,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::UPS::Exception::BadPackage;
$Net::Async::Webservice::UPS::Exception::BadPackage::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Exception::BadPackage::DIST = 'Net-Async-Webservice-UPS';
}
 use Moo;
 extends 'Net::Async::Webservice::UPS::Exception';

 # ABSTRACT: exception thrown when a package is too big for UPS to carry


 has package => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return sprintf 'Package size/weight not supported: %fx%fx%f %s %f %s, at %s',
         $self->package->length//'<undef>',
         $self->package->width//'<undef>',
         $self->package->height//'<undef>',
         $self->package->linear_unit,
         $self->package->weight//'<undef>',
         $self->package->weight_unit,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::UPS::Exception::HTTPError;
$Net::Async::Webservice::UPS::Exception::HTTPError::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Exception::HTTPError::DIST = 'Net-Async-Webservice-UPS';
}
 use Moo;
 extends 'Net::Async::Webservice::UPS::Exception';

 # ABSTRACT: exception thrown when the HTTP request fails


 has request => ( is => 'ro', required => 1 );
 has response => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return sprintf 'Error %sing %s: %s, at %s',
         $self->request->method,$self->request->uri,
         $self->response->status_line,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::UPS::Exception::UPSError;
$Net::Async::Webservice::UPS::Exception::UPSError::VERSION = '0.09_1';
{
  $Net::Async::Webservice::UPS::Exception::UPSError::DIST = 'Net-Async-Webservice-UPS';
}
 use Moo;
 extends 'Net::Async::Webservice::UPS::Exception';

 # ABSTRACT: exception thrown when UPS signals an error


 has error => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return sprintf 'UPS returned an error: %s, severity %s, code %d, at %s',
         $self->error->{ErrorDescription}//'<undef>',
         $self->error->{ErrorSeverity}//'<undef>',
         $self->error->{ErrorCode}//'<undef>',
         $self->stack_trace->as_string;
 }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Exception - base exception class for UPS

=head1 VERSION

version 0.09_1

=head1 DESCRIPTION

This class is based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.

=head1 ATTRIBUTES

=head2 C<file>

The name of the configuration file.

=head2 C<package>

The package object that's too big.

=head2 C<request>

The request that failed.

=head2 C<response>

The failure response returned by the user agent

=head2 C<error>

The error data structure extracted from the UPS response.

=head1 METHODS

=head2 C<as_string>

Generic "something bad happened", with stack trace.

=head2 C<as_string>

Mentions the file name, and gives the stack trace.

=head2 C<as_string>

Shows the size of the package, and the stack trace.

=head2 C<as_string>

Mentions the HTTP method, URL, response status line, and stack trace.

=head2 C<as_string>

Mentions the description, severity, and code of the error, plus the
stack trace.

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
