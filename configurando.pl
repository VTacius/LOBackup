#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use configuracion;
my %Config = configurando("parametros.conf");

foreach my $item (keys(%Config)){
    print $item . ": " .$Config{$item} . "\n"
}
