#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

sub espacios{
    my ($palabrejo) = @_;
    $palabrejo =~ s/^\s|\s$//;
    $palabrejo =~ s/["|;]//g;
    return $palabrejo;
}

sub fechador{
    my $Config= $_[0];
    my $clave = $_[1];
    $Config->{$clave} = strftime($Config->{$clave}, localtime(time));
}

sub configuracion{
    my ($fichero) = @_;
    my ($config_line, %Config, $item, $valor, @cadena);
    open(my $conf, "<", $fichero) or die("Error Abriendo el fichero de configuracion");
    while(<$conf>){
        $config_line=$_;
        if ( ($config_line !~ /^(#|$)/) ){
            chop($config_line);
            my @cadena = split (/=/, $config_line, 2);
            $item = espacios($cadena[0]);
            $valor = espacios($cadena[1]);
            if ($valor =~ m/^\+/){
                $valor =~ s/\+//;
                $Config{$item} = strftime($valor, localtime(time));
            } elsif ($valor =~ m/\$\{(.+)\}/) {
                my $e = $1;
                $valor =~ s/\$\{$e\}/$Config{$e}/;
                $Config{$item} = $valor;
            } else {
                $Config{$item} = $valor;
            }
        }
    }
    return %Config;
}

my %Config = configuracion("parametros.conf");

#foreach my $item (keys(%Config)){
#    print $item . ": " .$Config{$item} . "\n"
#}
