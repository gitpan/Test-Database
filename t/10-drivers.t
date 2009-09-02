use strict;
use warnings;
use Test::More;
use Test::Database;
use Test::Database::Driver;

my @drivers = Test::Database->list_drivers('available');

plan tests => 5 + @drivers * ( 1 + 2 * 11 ) + 2;

my $base = 'Test::Database::Driver';

# tests for Test::Database::Driver directly
{
    ok( !eval { Test::Database::Driver->new(); 1 },
        'Test::Database::Driver->new() failed'
    );
    like(
        $@,
        qr/^dbd or driver_dsn parameter required at/,
        'Expected error message'
    );
    my $dir = $base->base_dir();
    ok( $dir, "$base has a base_dir(): $dir" );
    like( $dir, qr/Test-Database-.*/,
        "$base\'s base_dir() looks like expected" );
    ok( -d $dir, "$base base_dir() is a directory" );
}

# now test the subclasses

for my $name ( Test::Database->list_drivers('available') ) {
    my $class = "Test::Database::Driver::$name";
    use_ok($class);

    for my $t (
        [ $base => eval { $base->new( dbd => $name ) } || ( '', $@ ) ],
        [ $class => eval { $class->new() } || ( '', $@ ) ],
        )
    {
        my ( $created_by, $driver, $at ) = @$t;
        $at =~ s/ at .*\n// if $at;
    SKIP: {
            skip "Failed to create $name driver with $created_by ($at)", 11
                if !$driver;
            diag "$name driver (created by $created_by)";

            # class and name
            my $desc = "$name driver";
            isa_ok( $driver, $class, $desc );
            is( $driver->name(), $name, "$desc has the expected name()" );

            # base_dir
            my $dir = $driver->base_dir();
            ok( $dir, "$desc has a base_dir(): $dir" );
            like( $dir, qr/Test-Database-.*\Q$name\E/,
                "$desc\'s base_dir() looks like expected" );
            ok( -d $dir, "$desc base_dir() is a directory" );

            # version
            my $version;
            ok( eval { $version = $driver->version() },
                "$desc has a version(): $version"
            );
            isa_ok( $version, 'version', "$desc version()" );
            diag $@ if $@;

            # driver_dsn, username, password, connection_info
            ok( $driver->driver_dsn(),       "$desc has a driver_dsn()" );
            ok( defined $driver->username(), "$desc has a username()" );
            ok( defined $driver->password(), "$desc has a password()" );
            is_deeply(
                [ $driver->connection_info() ],
                [ map { $driver->$_ } qw< driver_dsn username password > ],
                "$desc has a connection_info()"
            );
        }
    }
}

# get all loaded drivers
@drivers = Test::Database->list_drivers();
cmp_ok( scalar @drivers, '>=', 1, 'At least one driver loaded' );

# unload them
Test::Database->clean_config();
@drivers = Test::Database->list_drivers();
is( scalar @drivers, 0, 'All drivers were unloaded' );

