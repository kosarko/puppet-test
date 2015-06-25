exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}

package { 'git':
    require => Exec['apt-update'],
    ensure => latest,
}
