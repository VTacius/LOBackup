#!/usr/bin/perl
use strict;
use warnings;

use Net::LDAP;
use Net::LDAP::LDIF;
use Authen::SASL;

# Mensaje de ayuda
sub ayuda{
    print "\nUso: [ datos | configuracion ]\n\n"
}

# Manejamos las dos opciones posibles
if ($#ARGV < 0){
    ayuda();
    exit;
}

if ( $ARGV[0] !~ m/^(datos|configuracion)$/){
    ayuda();
    exit;
}

# Obtiene la base mínima del árbol LDAP
sub base{
    #my $ldap = Net::LDAP->new('ldap.hacienda.gob.sv') or die "$@";
    my $ldap = Net::LDAP->new("ldapi://%2fvar%2frun%2fslapd%2fldapi") or die "$@";
    my $dse = $ldap->root_dse();
    my $contexto = $dse->get_value('namingContexts');
    return $contexto;
}

# Realiza una busqueda en el arbol ldap especificado
sub busqueda {
    my ($base, $ambito) = @_;
    my $ldap = Net::LDAP->new("ldapi://%2fvar%2frun%2fslapd%2fldapi") or die "$@";
    my $sasl = Authen::SASL->new(mechanism => 'EXTERNAL');
    my $sasl_client = $sasl->client_new('ldap', 'localhost');
    $ldap->bind(undef, sasl => $sasl_client);
    my $msg = $ldap->search(
        base=>$base,
        filter=>"objectClass=*",
        scope=>$ambito,
        attrs => ['*']
        );

    $ldap->unbind();

    return $msg;
}

# Busca recursivamente en todas las entradas LDAP 
sub tuerca{
    my ($bases, $msg) = @_;
    foreach my $entries($msg->entries()){
        $bases = $entries->dn();
        $msg=busqueda($bases, "one");
        # La entrada, cualquiera que sea su naturaleza, tiene entradas hijas
        if ($msg->count()>0){
            my $ldif = Net::LDAP::LDIF->new( "$bases.ldif","w" ) or die "$@";
            $ldif->write( $msg->entries );
            tuerca($bases, $msg);
        }
    }
}

sub clavo{
    my ($msg) = @_;
    my $ldif = Net::LDAP::LDIF->new( "config.ldif","w" ) or die "$@";
    $ldif->write( $msg->entries );
}

# Acción a realizar
if ($ARGV[0] =~ "datos"){
    my $bases = base();
    my $msg=busqueda($bases, "one");
    tuerca($bases, $msg);
} else {
    my $bases = "cn=config";
    my $msg=busqueda($bases, "sub");
    clavo($msg);
}
