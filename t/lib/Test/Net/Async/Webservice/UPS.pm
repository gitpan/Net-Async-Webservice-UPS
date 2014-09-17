package Test::Net::Async::Webservice::UPS;
use strict;
use warnings;
use Test::Most;
use Data::Printer;
use Net::Async::Webservice::UPS::Package;
use Net::Async::Webservice::UPS::Address;
use Net::Async::Webservice::UPS::Payment;
use Net::Async::Webservice::UPS::Shipper;

sub conf_file {
    my $upsrc = $ENV{NAWS_UPS_CONFIG} || File::Spec->catfile($ENV{HOME}, '.naws_ups.conf');
    if (not -r $upsrc) {
        plan(skip_all=>'need a ~/.naws_ups.conf file, or a NAWS_UPS_CONFIG env variable pointing to a valid config file');
        exit(0);
    }
    return $upsrc;
}

sub package_comparator {
    my (@p) = @_;

    return map {
        my $p = $_;
        all(
            isa('Net::Async::Webservice::UPS::Package'),
            methods(
                map { $_ => $p->$_ } qw(length width height weight packaging_type linear_unit weight_unit)
            )
        );
    } @p;
}

sub test_it {
    my ($ups) = @_;

    subtest 'setting live / testing' => sub {
        is($ups->live_mode,0,'starts in testing');
        my $test_url = $ups->base_url;

        $ups->live_mode(1);
        is($ups->live_mode,1,'can be set live');
        isnt($ups->base_url,$test_url,'live proxy different than test one');

        $ups->live_mode(0);
        is($ups->live_mode,0,'can be set back to testing');
        is($ups->base_url,$test_url,'test proxy same as before');
    };

    my @postal_codes = ( 15241, 48823 );
    my @addresses = map { Net::Async::Webservice::UPS::Address->new(postal_code=>$_) } @postal_codes;
    my @address_comparators = map {
        all(
            isa('Net::Async::Webservice::UPS::Address'),
            methods(
                postal_code => $_,
            ),
        ),
    } @postal_codes;

    my @street_addresses = (Net::Async::Webservice::UPS::Address->new({
        name        => 'Some Place',
        address     => '2231 E State Route 78',
        city        => 'East Lansing',
        state       => 'MI',
        country_code=> 'US',
        postal_code => '48823',
    }), Net::Async::Webservice::UPS::Address->new({
        name        => 'John Doe',
        building_name => 'Pearl Hotel',
        address     => '233 W 49th St',
        city        => 'New York',
        state       => "NY",
        country_code=> "US",
        postal_code => "10019",
    }) );

    my @packages = (
        Net::Async::Webservice::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>1,
            measurement_system => 'english',
            description => 'some stuff',
        ),
        Net::Async::Webservice::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>2,
            measurement_system => 'english',
        ),
    );

    my @rate_comparators = map {
        methods(
            warnings => undef,
            services => [
                all(
                    isa('Net::Async::Webservice::UPS::Service'),
                    methods(
                        label => 'GROUND',
                        code => '03',
                        rates => [
                            all(
                                isa('Net::Async::Webservice::UPS::Rate'),
                                methods(
                                    rated_package => package_comparator($_),
                                    from => $address_comparators[0],
                                    to => $address_comparators[1],
                                    billing_weight => num($_->weight,0.01),
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    } @packages;

    my $full_rate_comparator = methods(
        warnings => undef,
        services => [
            all(
                isa('Net::Async::Webservice::UPS::Service'),
                methods(
                    label => 'GROUND',
                    code => '03',
                    rated_packages => bag(map {package_comparator($_)} @packages),
                    rates => bag(map {
                        all(
                            isa('Net::Async::Webservice::UPS::Rate'),
                            methods(
                                rated_package => package_comparator($_),
                                from => $address_comparators[0],
                                to => $address_comparators[1],
                                billing_weight => num($_->weight,0.01),
                            ),
                        ),
                    } @packages),
                ),
            ),
        ],
    );

    my $rate1;
    subtest 'rating a package via postcodes' => sub {
        $rate1 = $ups->request_rate({
            customer_context => 'test 1',
            from => $postal_codes[0],
            to => $postal_codes[1],
            packages => $packages[0],
        })->get;

        cmp_deeply(
            $rate1,
            $rate_comparators[0],
            'sensible rate returned',
        ) or note p $rate1;
        cmp_deeply(
            $rate1->services->[0]->rated_packages,
            [package_comparator($packages[0])],
            'service refers to the right package'
        );
        cmp_deeply($rate1->customer_context,'test 1','context passed ok');
    };

    subtest 'rating a package via addresss' => sub {
        my $rate2 = $ups->request_rate({
            # need this, otherwise the result is different from $rate1
            customer_context => 'test 1',
            from => $addresses[0],
            to => $addresses[1],
            packages => $packages[0],
        })->get;

        cmp_deeply(
            $rate1,
            $rate_comparators[0],
            'sensible rate returned',
        ) or note p $rate2;
        cmp_deeply(
            $rate2->services->[0]->rated_packages,
            [package_comparator($packages[0])],
            'service refers to the right package'
        );

        cmp_deeply($rate2,$rate1,'same result as with postcodes');
    };

    subtest 'rating multiple packages' => sub {
        my $rate = $ups->request_rate({
            from => $postal_codes[0],
            to => $postal_codes[1],
            packages => \@packages,
        })->get;

        cmp_deeply(
            $rate,
            $full_rate_comparator,
            'sensible rate returned',
        ) or note p $rate;

        my $service = $rate->services->[0];
        cmp_deeply(
            $service->rated_packages,
            [package_comparator(@packages)],
            'service refers to the both packages'
        );
        my $rates = $rate->services->[0]->rates;
        cmp_deeply(
            $service->total_charges,
            num($rates->[0]->total_charges + $rates->[1]->total_charges,0.01),
            'total charges add up',
        );
    };

    subtest 'shop for rates, single package' => sub {
        my $services = $ups->request_rate({
            from => $addresses[0],
            to => $addresses[1],
            packages => $packages[0],
            mode => 'shop',
        })->get;

        cmp_deeply(
            $services,
            methods(
                warnings => undef,
                services => all(
                    array_each(all(
                        isa('Net::Async::Webservice::UPS::Service'),
                        methods(
                            rated_packages => [package_comparator($packages[0])],
                        ),
                    )),
                    superbagof(all(
                        isa('Net::Async::Webservice::UPS::Service'),
                        methods(
                            label => 'GROUND',
                            code => '03',
                        ),
                    )),
                ),
            ),
            'services are returned, including ground',
        );

        my $services_aref = $services->services;
        cmp_deeply(
            $services_aref,
            [ sort { $a->total_charges <=> $b->total_charges } @$services_aref ],
            'sorted by total_charges',
        );
    };

    subtest 'shop for rates, multiple packages' => sub {
        my $services = $ups->request_rate({
            from => $addresses[0],
            to => $addresses[1],
            packages => \@packages,
            mode => 'shop',
        })->get;

        cmp_deeply(
            $services,
            methods(
                warnings => undef,
                services => all(
                    array_each(all(
                        isa('Net::Async::Webservice::UPS::Service'),
                        methods(
                            rated_packages => [package_comparator(@packages)],
                            rates => bag(
                                map {
                                    all(
                                        isa('Net::Async::Webservice::UPS::Rate'),
                                        methods(
                                            rated_package => package_comparator($_),
                                            from => $address_comparators[0],
                                            to => $address_comparators[1],
                                        ),
                                    ),
                                } @packages,
                            ),
                        ),
                    )),
                    superbagof(all(
                        isa('Net::Async::Webservice::UPS::Service'),
                        methods(
                            label => 'GROUND',
                            code => '03',
                        ),
                    )),
                ),
            ),
            'services are returned, including ground, with multiple rates each',
        ) or note p $services;

        my $services_aref = $services->services;
        cmp_deeply(
            $services_aref,
            [ sort { $a->total_charges <=> $b->total_charges } @$services_aref ],
            'sorted by total_charges',
        );

        for my $service (@$services_aref) {
            my $rates = $service->rates;
            cmp_deeply(
                $service->total_charges,
                num($rates->[0]->total_charges + $rates->[1]->total_charges,0.01),
                'total charges add up',
            );
        }
        ;
    };

    subtest 'validate address' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            city        => "East Lansing",
            state       => "MI",
            country_code=> "US",
            postal_code => "48823",
            is_residential=>1
        });

        my $addresses = $ups->validate_address($address, 0)->get;

        cmp_deeply(
            $addresses,
            methods(
                warnings => undef,
                addresses => all(
                    array_each( all(
                        isa('Net::Async::Webservice::UPS::Address'),
                        methods(
                            city => "EAST LANSING",
                            state => "MI",
                            country_code=> "US",
                            quality => num(1,0.01),
                        ),
                    ) ),
                    superbagof( all(
                        isa('Net::Async::Webservice::UPS::Address'),
                        methods(
                            city => "EAST LANSING",
                            state => "MI",
                            country_code=> "US",
                            quality => num(1,0.01),
                        ),
                    ) ),
                ),
            ),
            'sensible addresses returned',
        ) or note p $addresses;
    };

    subtest 'validate address, failure' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            city        => "Bad Place",
            state       => "NY",
            country_code=> "US",
            postal_code => "998877",
            is_residential=>1
        });

        my $addresses = $ups->validate_address($address, 0)->get;

        cmp_deeply(
            $addresses,
            methods(
                warnings => undef,
                addresses => [],
            ),
            'sensible failure returned',
        ) or note p $addresses;
    };

    subtest 'validate address, street-level' => sub {
        my $addresses = $ups->validate_street_address($street_addresses[1])->get;

        cmp_deeply(
            $addresses,
            methods(
                warnings => undef,
                addresses => [
                    all(
                        isa('Net::Async::Webservice::UPS::Address'),
                        methods(
                            city => re(qr{\ANew York\z}i),
                            state => "NY",
                            country_code=> "US",
                            postal_code_extended => '7404',
                            quality => 1,
                        ),
                    ),
                ],
            ),
            'sensible address returned',
        ) or note p $addresses;
    };

    subtest 'validate address, street-level, failure' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            name        => 'Bad Place',
            address     => '999 Not a Road',
            city        => 'Bad City',
            state       => 'NY',
            country_code=> 'US',
            postal_code => '998877',
        });
        my $failure = $ups->validate_street_address($address)->failure;

        cmp_deeply(
            $failure,
            methods(
                error_code => 'NoCandidates',
            ),
            'sensible failure returned',
        ) or note p $failure;
    };

    subtest 'validate address, non-ASCII' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            name        => "Snowman \x{2603}",
        address     => '233 W 49th St',
        city        => 'New York',
        state       => "NY",
        country_code=> "US",
        postal_code => "10019",
#            address     => "St\x{e4}ndehausstra\x{df}e 1",
#            city        => "D\x{fc}sseldorf",
#            country_code=> 'DE',
#            postal_code => '40217',
        });
        my $validated = $ups->validate_street_address($address)->get;

        cmp_deeply(
            $validated,
            methods(
                warnings => undef,
                addresses => [
                    all(
                        isa('Net::Async::Webservice::UPS::Address'),
                        methods(
                            city => re(qr{\ANew York\z}i),
                            state => "NY",
                            country_code=> "US",
                            postal_code_extended => '7404',
                            quality => 1,
                        ),
                    ),
                ],
            ),
            'sensible address returned',
        ) or note p $validated;
    };

    my $bill_shipper = Net::Async::Webservice::UPS::Payment->new({
        method => 'prepaid',
        account_number => $ups->account_number,
    });

    my $shipper = Net::Async::Webservice::UPS::Shipper->new({
        name => 'Test Shipper',
        company_name => 'Test Shipper Company',
        address => $street_addresses[0],
        account_number => $ups->account_number,
    });

    my $destination = Net::Async::Webservice::UPS::Contact->new({
        name => 'Test Contact',
        company_name => 'Test Contact Company',
        address => $street_addresses[1],
    });

    subtest 'book shipment' => sub {
        my $confirm = $ups->ship_confirm({
            customer_context => 'test ship1',
            from => $shipper,
            to => $destination,
            shipper => $shipper,
            packages => \@packages,
            description => 'Testing packages',
            payment => $bill_shipper,
            label => 'EPL',
        })->get;
        cmp_deeply(
            $confirm,
            methods(
                billing_weight => num(3),
                unit => 'LBS',
                currency => 'USD',
                customer_context => 'test ship1',
            ),
            'shipment confirm worked',
        );
        cmp_deeply(
            $confirm->transportation_charges + $confirm->service_option_charges,
            num($confirm->total_charges,0.01),
            'charges add up',
        );
        ok($confirm->shipment_digest,'we have a digest');
        ok($confirm->shipment_identification_number,'we have an id number');

        my $accept = $ups->ship_accept({
            customer_context => 'test acc1',
            confirm => $confirm,
        })->get;

        cmp_deeply(
            $accept,
            methods(
                customer_context => 'test acc1',
                billing_weight => num(3),
                unit => 'LBS',
                currency => 'USD',
                service_option_charges => num($confirm->service_option_charges),
                transportation_charges => num($confirm->transportation_charges),
                total_charges => num($confirm->total_charges),
                shipment_identification_number => $confirm->shipment_identification_number,
                package_results => [ map {
                    all(
                        isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                        methods(
                            label => isa('Net::Async::Webservice::UPS::Response::Image'),
                            package => $_,
                        ),
                    )
                } @packages ],
            ),
            'shipment accept worked',
        );
    };

    subtest 'book shipment, 1 package' => sub {
        my $confirm = $ups->ship_confirm({
            from => $shipper,
            to => $destination,
            shipper => $shipper,
            packages => $packages[0],
            description => 'Testing 1 package',
            payment => $bill_shipper,
            label => 'EPL',
        })->get;
        cmp_deeply(
            $confirm,
            methods(
                billing_weight => num(1),
                unit => 'LBS',
                currency => 'USD',
            ),
            'shipment confirm worked',
        );
        cmp_deeply(
            $confirm->transportation_charges + $confirm->service_option_charges,
            num($confirm->total_charges,0.01),
            'charges add up',
        );
        ok($confirm->shipment_digest,'we have a digest');
        ok($confirm->shipment_identification_number,'we have an id number');

        my $accept = $ups->ship_accept({
            confirm => $confirm,
        })->get;

        cmp_deeply(
            $accept,
            methods(
                billing_weight => num(1),
                unit => 'LBS',
                currency => 'USD',
                service_option_charges => num($confirm->service_option_charges),
                transportation_charges => num($confirm->transportation_charges),
                total_charges => num($confirm->total_charges),
                shipment_identification_number => $confirm->shipment_identification_number,
                package_results => [
                    all(
                        isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                        methods(
                            label => isa('Net::Async::Webservice::UPS::Response::Image'),
                            package => $packages[0],
                        ),
                    )
                ],
            ),
            'shipment accept worked',
        );
    };

    subtest 'book return shipment, 1 package' => sub {
        my $confirm = $ups->ship_confirm({
            from => $destination,
            to => $shipper,
            shipper => $shipper,
            packages => $packages[0],
            description => 'Testing 1 package return',
            payment => $bill_shipper,
            return_service => 'PRL',
            label => 'EPL',
        })->get;
        cmp_deeply(
            $confirm,
            methods(
                billing_weight => num(1),
                unit => 'LBS',
                currency => 'USD',
            ),
            'shipment confirm worked',
        );
        cmp_deeply(
            $confirm->transportation_charges + $confirm->service_option_charges,
            num($confirm->total_charges,0.01),
            'charges add up',
        );
        ok($confirm->shipment_digest,'we have a digest');
        ok($confirm->shipment_identification_number,'we have an id number');

        my $accept = $ups->ship_accept({
            confirm => $confirm,
        })->get;

        cmp_deeply(
            $accept,
            methods(
                billing_weight => num(1),
                unit => 'LBS',
                currency => 'USD',
                service_option_charges => num($confirm->service_option_charges),
                transportation_charges => num($confirm->transportation_charges),
                total_charges => num($confirm->total_charges),
                shipment_identification_number => $confirm->shipment_identification_number,
                package_results => [
                    all(
                        isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                        methods(
                            label => isa('Net::Async::Webservice::UPS::Response::Image'),
                            package => $packages[0],
                        ),
                    )
                ],
            ),
            'shipment accept worked',
        );
    };
}

1;

