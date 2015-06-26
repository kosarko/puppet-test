### Globals
Exec {path => ["/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin"]}

exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}

$no_conf_packages = hiera_array("my::packages_no_conf")
package { $no_conf_packages:
    require => Exec['apt-update'],
    ensure => latest,
}

$my_dirs = [ "/opt/installations", "/opt/sources", "/opt/sources/dspace", "/opt/installations/dspace" ]
file { $my_dirs:
    ensure => directory,
}

file { '/installations':
    ensure => link,
    target => '/opt/installations',
    require => File['/opt/installations'],
}

file { '/sources':
    ensure => link,
    target => '/opt/sources',
    require => File['/opt/sources'],
}

##### SUN JAVA
class { 'jdk_oracle':
    ensure => installed,
    version => '8',
    version_update => '45',
    version_build => '14',
    install_dir => '/usr/lib/jvm',
    default_java => false,      #this seems broken and incomplete, use own script on ubuntu
    require => File['/installations'],
}

$jdk_alias = "jdk1.8.0_45"
exec { 'generate-jinfo':
    command => "sudo ${::settings::modulepath}/scripts/generate-jinfo.sh $jdk_alias",
    require => Class['jdk_oracle'],
    creates => "/usr/lib/jvm/.${jdk_alias}.jinfo",
}

exec { 'update-java-alternatives':
    command => "update-java-alternatives -s $jdk_alias",
    require => Exec["generate-jinfo"],
    user => 'root',
}

#### Tomcat 8
