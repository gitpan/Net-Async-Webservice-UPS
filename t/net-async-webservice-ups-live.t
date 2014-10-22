#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::Factory;

my ($ups,$loop) = Test::Net::Async::Webservice::UPS::Factory::from_config;

Test::Net::Async::Webservice::UPS::test_it($ups);

subtest 'connection failures' => sub {
    $ups->{base_url} = 'http://bad.hostname/';
    $ups->validate_address('1234')->then(
        sub { my ($response) = @_;
              fail "it connected to a non-existing host?";
              Future->wrap();
          },
        sub { my ($fail) = @_;
              cmp_deeply($fail,
                         all(
                             isa('Net::Async::Webservice::UPS::Exception::HTTPError'),
                             methods(
                                 request => isa('HTTP::Request'),
                                 response => undef,
                             ),
                         ),
                         'correctly failed to connect',
                     );
              Future->wrap();
          },
    )->get;
};

done_testing();
