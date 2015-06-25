exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}

package { 'git':
    require => Exec['apt-update'],
    ensure => latest,
}

$my_dirs = [ "/opt/installations", "/opt/sources" ]
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
