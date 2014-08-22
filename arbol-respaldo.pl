#!/usr/bin/perl
use strict;
use warnings;
use POSIX;
use Net::LDAP;
use Net::LDAP::LDIF;
use Authen::SASL;

# Configuración adicional que podemos dejar por defecto
my $ID_SERVER = "";
my $usuario = "";

# Configuración que mantiene compatibilidad con los demás script y de importancia capital
my $servidor_respaldo = "192.168.2.16";
# Configuración que mantiene compatibilidad con los demás script
my $fecha = strftime( "%Y%m%d", localtime(time) );
my $fecha_archivo = strftime( "%s%m%Y-%H%M", localtime(time) );
my $ruta_respaldo = "/var/respaldo/ldap";
my $ruta_respaldo_remoto = "/var/respaldo/$ID_SERVER/ldap";

# Falta implementarlo
my $ruta_log_remoto = "/var/respaldo";
my $ruta_log_local = "/var/respaldo";
my $correos_notificacion = 'correo@dominio.com.sv';

# Creamos rutas en base a los datos anteriores recogidos
my $ruta_respaldo_datos = "$ruta_respaldo/datos";
my $ruta_respaldo_conf = "$ruta_respaldo/config";
my $estado="Ejecución correcta";

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
            my $ldif = Net::LDAP::LDIF->new( "$ruta_respaldo_datos/$bases.ldif", "w") or die "$@";
            $ldif->write( $msg->entries );
            tuerca($bases, $msg);
        }
    }
}

sub clavo {
    my ($msg) = @_;
    my $ldif = Net::LDAP::LDIF->new( "$ruta_respaldo_conf/config.ldif","w" ) or die "$@";
    $ldif->write( $msg->entries );
}

sub empaquetar {
    my ($archivo) = @_;
    my $resultado_tar = `tar -czvf $archivo.tar.gz $archivo 2>&1`;
}

sub envio {
    my ($origen, $destino) = @_;
    my $resultado_env = `scp $origen $usuario\@$servidor_respaldo:$destino`;
}

# Acción a realizar
if ($ARGV[0] =~ "datos"){
    my $bases = base();
    my $msg=busqueda($bases, "one");
    tuerca($bases, $msg);
    empaquetar($ruta_respaldo_datos);
    envio("$ruta_respaldo_datos.tar.gz", $ruta_respaldo_remoto)
} else {
    my $bases = "cn=config";
    my $msg=busqueda($bases, "sub");
    clavo($msg);
    empaquetar($ruta_respaldo_conf);
    envio("$ruta_respaldo_conf.tar.gz", $ruta_respaldo_remoto)
}
