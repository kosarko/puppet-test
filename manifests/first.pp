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

class { 'jdk_oracle':
    ensure => installed,
    version => '8',
    install_dir => '/installations/java',
    require => File['/installations'],
}
