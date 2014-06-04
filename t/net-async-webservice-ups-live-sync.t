#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::Factory;

my ($ups,$ua) = Test::Net::Async::Webservice::UPS::Factory::from_config_sync;

Test::Net::Async::Webservice::UPS::test_it($ups);

done_testing();
