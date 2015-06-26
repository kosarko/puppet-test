Exec {path => ["/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin"]}
class probe(
  $source_dir    = hiera('probe::source_dir',    '/opt/sources' ),
  $tomcat_webapps = hiera('probe::tomcat_webapps', '/var/lib/tomcat8/webapps'),
  $ensure         = 'installed',
){
    exec{'install_probe':
        command => "sudo ${::settings::modulepath}/scripts/probe.sh $source_dir $tomcat_webapps",
        unless => "test -s ${tomcat_webapps}/probe.war",
        #require => Class["tomcat8"],
    }
    exec{'checkout':}
        com
    
    file{"${tomcat_webapps}/probe.war":
        require => Exec['install_probe'],
        owner => 'tomcat',
        ensure => file,
    }

}

class {'probe':}
