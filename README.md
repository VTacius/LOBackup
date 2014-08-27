## L0Backup

Backup de LDAP escrito es Perl con la mínima configuracion

### Uso:
#### Antes de su primer uso:

Si ha seguido nuestra guía [Servidor Samba con LDAP NSS – PAM en Debian Wheezy](http://wiki.salud.gob.sv/wiki/Servidor_Samba_con_LDAP_NSS_%E2%80%93_PAM_en_Debian_Wheezy), podrá no necesitará más que obtener el archivo e instalar su única dependencia

    $ aptitude install libauthen-sasl-perl

Cree el fichero __parametros.conf__; copie y personalize el siguiente contenido
```ini

# Configuración adicional que podemos dejar por defecto
# Nombre con el que identificamos al servidor dentro del esquema de respaldo.
# Por defecto, su valor es `hostname`
ID_SERVER = `hostname`

# Usuario con que el tenemos configuradas las claves publicas para acceder al servidor de respaldo
usuario = "wwwserver"

# Configuración que mantiene compatibilidad con los demás script y de importancia capital
servidor_respaldo = "192.168.0.5"
ruta_respaldo = "/var/respaldo/ldap"
ruta_respaldo_remoto = "/var/respaldo/${ID_SERVER}/ldap"

# Configuramos las fechas para estampar el nombre de los ficheros.
# Claro que puede cambiarlas por una que sean más de su gusto,pero no olvide anteponer el signo +
fecha = "+%d / %m / %Y"
fecha_archivo = "+%s%m%Y-%H%M"

# Falta implementarlo
usuario_local = "administrador"
ruta_log_remoto = "/var/respaldo"
ruta_log_local = "/var/respaldo"
correos_notificacion = 'correo@dominio.com.sv'

# Directorio dentro de $ruta_respaldo donde guardaremos los ficheros.
# En vista a ser lo más configurable posible
ruta_respaldo_datos = "datos"
ruta_respaldo_conf = "config"
```

#### Instrucciones
Configurelo como una tarea con su gestor de tareas preferidas 
