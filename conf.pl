#!/usr/bin/perl
use strict;
use warnings;
use POSIX;
use Net::LDAP;
use Net::LDAP::LDIF;
use Authen::SASL;

sub configuracion{
    my ($fichero) = @_;
    my ($config_line, %Config, $item, $valor, @cadena);
    open(my $conf, "<", $fichero) or die("Error Abriendo el fichero de configuracion");
    while(<$conf>){
        $config_line=$_;
        if ( ($config_line !~ /^(#|$)/) ){ 
            chop($config_line);
            my @cadena = split (/=/, $config_line, 2); 
            $item = $cadena[0];        
            $valor = $cadena[1];
            $Config{$item} = eval($valor);
        }
    }
    return %Config;
}
my %Config = configuracion("respaldo.conf");
print %Config;
