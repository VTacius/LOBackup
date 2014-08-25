#!/usr/bin/perl
use strict;
use warnings;
use POSIX;
use Net::LDAP;
use Net::LDAP::LDIF;
use Authen::SASL;

=pod

=head1 DESCRIPTION

El script requiere que el paquete Authen::SASL este instalado. 
A cambio, no habra que preocuparse en configurar contrasenias.
Tampoco se precupe en hallar la base correcta de su arbol LDAP:
El script ha de preocuparse de todas esas cuestiones
=cut

sub configuracion{
    my ($fichero) = @_;
    my ($config_line, %Config, $item, $valor, @cadena);
    open(my $conf, "<", $fichero) or die("Error Abriendo el fichero de configuracion");
    while(<$conf>){
        $config_line=$_;
        if ( ($config_line !~ /^(#|$)/) ){ 
            my @cadena = split (/=/, $config_line, 2); 
            $item = $cadena[0];        
            $valor = $cadena[1];
            $Config{$item} = $valor;
        }
    }
    return %Config;
}

# Configuración adicional que podemos dejar por defecto
# Nombre con el que identificamos al servidor dentro del esquema de respaldo. 
# Por defecto, su valor es `hostname`
my $ID_SERVER = "base";
# Usuario con que el tenemos configuradas las claves publicas para acceder al servidor de respaldo
my $usuario = "cpenate";

# Configuración que mantiene compatibilidad con los demás script y de importancia capital
my $servidor_respaldo = "192.168.2.16";
my $ruta_respaldo = "/var/respaldo/ldap";
my $ruta_respaldo_remoto = "/var/respaldo/$ID_SERVER/ldap";

# Configuramos las fechas para estampar el nombre de los ficheros. 
# Claro que puede cambiarlas por una que sean más de su gusto
my $fecha = strftime( "%d / %m / %Y", localtime(time) );
my $fecha_archivo = strftime( "%s%m%Y-%H%M", localtime(time) );

# Falta implementarlo
my $usuario_local = "root";
my $ruta_log_remoto = "/var/respaldo";
my $ruta_log_local = "/var/respaldo";
my $correos_notificacion = 'correo@dominio.com.sv';

# Directorio dentro de $ruta_respaldo donde guardaremos los ficheros.
# En vista a ser lo más configurable posible
my $ruta_respaldo_datos = "datos";
my $ruta_respaldo_conf = "config";

# Mensaje de ayuda sobre el uso, a desplegarse si no da una opción correcta
sub ayuda{
    print "\nUso: [ datos | configuracion ]\n\n"
}

# Manejamos las dos opciones posibles
if ($#ARGV < 0){
    ayuda();
    exit;
}

# Confirmamos que sea una opción correcta
if ( $ARGV[0] !~ m/^(datos|configuracion)$/){
    ayuda();
    exit;
}
#### Empiezan los procedimientos para backup propiamente dichos
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
            my $ldif = Net::LDAP::LDIF->new( "$bases.ldif", "w") or die "$@";
            $ldif->write( $msg->entries );
            tuerca($bases, $msg);
        }
    }
}

sub clavo {
    my ($msg) = @_;
    my $ldif = Net::LDAP::LDIF->new( "config.ldif","w" ) or die "$@";
    $ldif->write( $msg->entries );
}

sub empaquetar {
    my ($archivo, $estampa) = @_;
    my $resultado_tar = `tar -czvf $archivo-$estampa.tar.gz $archivo 2>&1`;
    return $resultado_tar;
}

sub envio {
    my ($origen, $destino) = @_;
    my $resultado_env = `scp $origen $usuario\@$servidor_respaldo:$destino 2>&1`;
    return $resultado_env;
}

sub mensaje{
    my ($operacion, $codigo_devuelto, $msg_devuelto) = @_;
    my $estado = $codigo_devuelto =~ 0 ? "Correcto": "Error";
    my $mensaje = "\tLa operacion $operacion ha terminado con Estado: $estado \n";
    #my $retorno = $msg_devuelto =~ '' ? "La operacion no devuelve mensaje de error desde consola en una ejecución exitosa\n" : $msg_devuelto . "\n" ;
    return $mensaje . $msg_devuelto;
}

# Acción a realizar
if ($ARGV[0] =~ "datos"){
    # Nos movemos al área de trabajo
    chdir($ruta_respaldo);

    # Creamos los ficheros con el backup
    my $bases = base();
    my $msg = busqueda($bases, "one");
    tuerca($bases, $msg);

    # Empaquetamos y enviamos archivos
    $msg = empaquetar($ruta_respaldo_datos, $fecha_archivo);
    print mensaje("Empaquetado", $?, $msg);
    $msg = envio("$ruta_respaldo_datos-$fecha_archivo.tar.gz", $ruta_respaldo_remoto);
    print mensaje("Envio", $?, $msg);
} else {
    my $bases = "cn=config";
    my $msg=busqueda($bases, "sub");
    clavo($msg);
    #empaquetar($ruta_respaldo_conf);
    print $?;
    #envio("$ruta_respaldo_conf.tar.gz", $ruta_respaldo_remoto)
}
