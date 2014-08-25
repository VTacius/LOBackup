#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

# Configuración adicional que podemos dejar por defecto
$ID_SERVER = `hostname`;
$usuario = "cpenate";

# Configuración que mantiene compatibilidad con los demás script
my $fecha = strftime( "%Y%m%d", localtime(time) );
my $fecha_archivo = strftime( "%s%m%Y-%H%M", localtime(time) );
my $ruta_respaldo = "/var/respaldo/ldap";
my $ruta_respaldo_remoto = "/var/respaldo/$ID_SERVER/ldap";
my $servidor_respaldo = "192.168.2.16";

# Falta implementarlo
my $ruta_log_remoto = "/var/respaldo";
my $ruta_log_local = "/var/respaldo";
my $correos_notificacion = 'vtacius@gmail.com';

# Creamos rutas en base a los datos anteriores recogidos
my $ruta_respaldo_datos = "$ruta_respaldo/datos";
my $ruta_respaldo_conf = "$ruta_respaldo/config";
my $estado="Ejecución correcta"

# Empaquetamos
my $resultado_tar = `tar -czvf $ruta_respaldo_datos.tar.gz $ruta_respaldo_datos 2>&1`;
my $resultado_tar = `tar -czvf $ruta_respaldo_conf.tar.gz $ruta_respaldo_conf 2>&1`;

# Enviamos
my $resultado_env = `scp $ruta_respaldo_datos.tar.gz $ruta_respaldo_conf.tar.gz $usuario@$servidor_respaldo:$ruta_respaldo_remoto`;
