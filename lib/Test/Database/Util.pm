package Test::Database::Util;
use strict;
use warnings;
use Carp;

# export everything
sub import {
    my $caller = caller();
    no strict 'refs';
    *{"${caller}::$_"} = \&$_ for qw( _read_file );
}

# return a list of hashrefs representing each configuration section
sub _read_file {
    my ($file) = @_;
    my @config;

    open my $fh, '<', $file or croak "Can't open $file for reading: $!";
    my %args;
    while (<$fh>) {
        next if /^\s*(?:#|$)/;    # skip blank lines and comments
        chomp;

        /\s*(\w+)\s*=\s*(.*)\s*/ && do {
            my ( $key, $value ) = ( $1, $2 );
            if ( $key eq 'dsn' || $key eq 'driver_dsn' ) {
                push @config, {%args} if keys %args;
                %args = ();
            }
            $args{$key} = $value;
            next;
        };

        # unknown line
        croak "Can't parse line at $file, line $.:\n  <$_>";
    }
    push @config, {%args} if keys %args;
    close $fh;

    return @config;
}

'USING';

__END__

=head1 NAME

Test::Database::Util - Utility functions for Test::Database modules

=head1 SYNOPSIS

    use Test::Database::Util;

    # exports a collection of underscore functions

=head1 DESCRIPTION

C<Test::Database::Util> exports a collection of functions used by
several modules in the C<Test-Database> distribution.

=head1 EXPORTED FUNCTIONS

All functions provided by C<Test::Database::Util> are exported in the
calling package.

The following functions are provided:

=over 4

=item _read_file( $file )

Return a list of hash references, read in the given C<$file> file.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2009 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

