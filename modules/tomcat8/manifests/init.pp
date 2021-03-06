class tomcat8(
  $install_dir    = hiera('tomcat8::install_dir',    '/opt' ),
  $ensure         = 'installed',
  $from           = hiera('tomcat8::from'),
  $keypath           = hiera('tomcat8::keypath'),
  $xmx           = hiera('tomcat8::xmx', '4096M'),
  $xms           = hiera('tomcat8::xms', '1024M'),
  ) {

  if $ensure == 'installed' {
    # Set default exec path for this module
    Exec { path  => ['/usr/bin', '/usr/sbin', '/bin'] }

	#fixed mirror, version
        $downloadURI = "http://mirror.hosting90.cz/apache/tomcat/tomcat-8/v8.0.23/bin/apache-tomcat-8.0.23.tar.gz"

    if ! defined(File[$install_dir]) {
      file { $install_dir:
        ensure  => directory,
      }
    }

    $installerFilename = inline_template('<%= File.basename(@downloadURI) %>')

      exec { 'get_tomcat':
        cwd     => $install_dir,
        creates => "${install_dir}/${installerFilename}",
        command => "wget -c --no-cookies --no-check-certificate \"${downloadURI}\" -O ${installerFilename}",
        timeout => 600,
        require => [ Package['wget'], User['tomcat'] ],
      }

      file { "${install_dir}/${installerFilename}":
        mode    => '0755',
        require => Exec['get_tomcat'],
      }

      if ! defined(Package['wget']) {
        package { 'wget':
          ensure =>  present,
        }
      }

    # tarball so just extract it.
      $dirname = regsubst($installerFilename, '(.*)\.tar\.gz', '\1')
      exec { 'extract_tomcat':
        cwd     => "${install_dir}/",
        command => "tar -xzf ${installerFilename}",
        creates => "${install_dir}/${dirname}",
        require => Exec['get_tomcat'],
      }

      file { "${install_dir}/${dirname}":
        require => Exec['extract_tomcat'],
        ensure => directory,
        recurse => true,
        owner => 'tomcat',
      }

      file { "${install_dir}/tomcat8":
    	ensure => link,
	    target => "${install_dir}/${dirname}",
	    require => Exec['extract_tomcat'],
        owner => 'tomcat',
      }

    $var_dirs = ["/var/lib/tomcat8", "/var/lib/tomcat8/temp", "/var/lib/tomcat8/webapps",
    "/var/log/tomcat8", "/var/cache/tomcat8", "/var/cache/tomcat8/Catalina"]
    file {$var_dirs:
        ensure => directory,
        recurse => true,
        owner => 'tomcat',
    }
    file { '/var/lib/tomcat8/logs':
        ensure => link,
        target => '/var/log/tomcat8',
        owner => 'tomcat',
    }
    file { '/var/lib/tomcat8/work':
        ensure => link,
        target => '/var/cache/tomcat8',
        owner => 'tomcat',
    }
    file { '/var/lib/tomcat8/conf':
        ensure => link,
        target => "${install_dir}/tomcat8/conf",
        owner => 'tomcat',
    }
    file{ '/var/lib/tomcat8/work/catalina.policy':
        ensure => file,
        source => 'puppet:///modules/tomcat8/catalina.policy',
        owner => 'tomcat',
    }
    exec { 'scp_policy.d':
        command => "scp -r -i ${keypath} -o StrictHostKeyChecking=no ${from}:/opt/tomcat8/conf/policy.d ${install_dir}/tomcat8/conf/",
        creates => "${install_dir}/tomcat8/conf/policy.d",
        require => File["${install_dir}/tomcat8"],
    }
    exec { 'scp_config':
        command => "scp -r -i ${keypath} -o StrictHostKeyChecking=no ${from}:/opt/tomcat8/conf/server.xml ${install_dir}/tomcat8/conf/ && scp -r -i ${keypath} -o StrictHostKeyChecking=no ${from}:/opt/tomcat8/conf/tomcat-users.xml ${install_dir}/tomcat8/conf/",
        unless => "grep \"admin\" ${install_dir}/tomcat8/conf/tomcat-users.xml",
        require => File["${install_dir}/tomcat8"],
    }
    file { ["${install_dir}/tomcat8/conf/server.xml","${install_dir}/tomcat8/conf/tomcat-users.xml"]:
        owner => 'tomcat',
        require => Exec['scp_config'],
    }
    exec {"clean_server.xml":
        require => File["${install_dir}/tomcat8/conf/server.xml"],
        command => "sed -i '128,168 d' ${install_dir}/tomcat8/conf/server.xml", ###XXX hardcoded line numbers
        onlyif => "grep \"Context path\" ${install_dir}/tomcat8/conf/server.xml"
    }
    file { "${install_dir}/tomcat8/conf/policy.d":
        require => Exec['scp_policy.d'],
        ensure => directory,
        recurse => true,
        owner => 'tomcat',
    }
    exec { 'scp_init_script':
        command => "scp -r -i ${keypath} -o StrictHostKeyChecking=no ${from}:/etc/init.d/tomcat8 /etc/init.d/",
        creates => "/etc/init.d/tomcat8",
        require => File["${install_dir}/tomcat8"],
        notify => Exec['cleanup_init']
    }
    exec {'cleanup_init':
        command => "sed -i -e \"s/tomcat6/tomcat/g\" -e \"s#^CATALINA_HOME=.*#CATALINA_HOME=${install_dir}/tomcat8#\" -e \"s#^JDK_DIRS=.*#JDK_DIRS=$(dirname $(readlink -f $(which javac) | sed -e 's#bin/##'))#\" -e \"s#-Xmx[0-9]*[MmGg]#-Xmx${xmx}#\" -e \"s#-Xms[0-9]*[MmGg]#-Xms${xms}#\" /etc/init.d/tomcat8",
        before => Service["tomcat8"],
    }
    user { "tomcat":
        ensure => present,
        managehome => true,
        shell => '/bin/bash',
    }
    service { "tomcat8":
        ensure => running,
        enable => true,
        require => Exec['scp_init_script'],
    }

#probe
#server + users + context
#native


  }
}
