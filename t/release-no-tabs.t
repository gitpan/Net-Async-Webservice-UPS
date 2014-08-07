
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Async/Webservice/UPS.pm',
    'lib/Net/Async/Webservice/UPS/Address.pm',
    'lib/Net/Async/Webservice/UPS/Contact.pm',
    'lib/Net/Async/Webservice/UPS/CreditCard.pm',
    'lib/Net/Async/Webservice/UPS/Exception.pm',
    'lib/Net/Async/Webservice/UPS/Label.pm',
    'lib/Net/Async/Webservice/UPS/Package.pm',
    'lib/Net/Async/Webservice/UPS/Payment.pm',
    'lib/Net/Async/Webservice/UPS/Rate.pm',
    'lib/Net/Async/Webservice/UPS/Response/Address.pm',
    'lib/Net/Async/Webservice/UPS/Response/Image.pm',
    'lib/Net/Async/Webservice/UPS/Response/PackageResult.pm',
    'lib/Net/Async/Webservice/UPS/Response/Rate.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentAccept.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentBase.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentConfirm.pm',
    'lib/Net/Async/Webservice/UPS/ReturnService.pm',
    'lib/Net/Async/Webservice/UPS/Service.pm',
    'lib/Net/Async/Webservice/UPS/Shipper.pm',
    'lib/Net/Async/Webservice/UPS/Types.pm'
);

notabs_ok($_) foreach @files;
done_testing;
