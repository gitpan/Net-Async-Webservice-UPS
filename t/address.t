#!perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use Test::Most;
use Net::Async::Webservice::UPS;
use Net::Async::Webservice::UPS::Address;
use File::Spec;
use Sub::Override;
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::TestCache;
eval { require IO::Async::Loop; require Net::Async::HTTP }
    or do {
        plan(skip_all=>'this test only runs with IO::Async and Net::Async::HTTP');
        exit(0);
    };

my $loop = IO::Async::Loop->new;

my $orig_post = \&Net::Async::Webservice::UPS::post;
my @calls;
my $new_post = Sub::Override->new(
    'Net::Async::Webservice::UPS::post',
    sub {
        push @calls,[@_];
        $orig_post->(@_);
    }
);

my $cache = Test::Net::Async::Webservice::UPS::TestCache->new();
my $ups = Net::Async::Webservice::UPS->new({
    config_file => Test::Net::Async::Webservice::UPS->conf_file,
    cache => $cache,
    loop => $loop,
});

my $address = Net::Async::Webservice::UPS::Address->new({
    city => 'East Lansing',
    postal_code => '48823',
    state => 'MI',
    country_code => 'US',
    is_residential => 1,
});

my $addresses = $ups->validate_address($address)->get;

cmp_deeply($addresses->addresses,
           array_each(
               all(
                   isa('Net::Async::Webservice::UPS::Address'),
                   methods(
                       quality => num(1.0,0),
                       is_residential => undef,
                       is_exact_match => bool(1),
                       is_poor_match => bool(0),
                       is_close_match => bool(1),
                       is_very_close_match => bool(1),
                   ),
               ),
           ),
           'address validated',
) or p $addresses;
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ]],
           'one call to the service');

my $addresses2 = $ups->validate_address($address)->get;
cmp_deeply($addresses2,$addresses,'the same answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ]],
           'still only one call to the service');

# build with no cache
$ups = Net::Async::Webservice::UPS->new({
    config_file => Test::Net::Async::Webservice::UPS->conf_file,
    loop => $loop,
});
my $addresses3 = $ups->validate_address($address)->get;
cmp_deeply($addresses3,$addresses,'the same answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ],
            [ ignore(),re(qr{/AV$}),ignore() ]],
           'two calls to the service');

done_testing();

