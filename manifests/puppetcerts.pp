#
# @summary copy puppet certificates for Bacula use
#
# Copy puppet certificates to a place where Bacula daemons can find them. Note 
# that this class depends on puppetagent::params class for locating Puppet's 
# SSL certificates.
#
# Many of the settings come from module level hiera in zleslie/bacula or this
# module.
#
class bacula_extras::puppetcerts
(
  String $puppet_ssl_dir
)
{

  # Explicit lookups seem to resolve some ordering issues: zleslie/bacula may
  # not yet be loaded when this class is loaded.
  $bacula_conf_dir = lookup('bacula::conf_dir', String)
  $bacula_group = lookup('bacula::bacula_group', String)
  $bacula_storage_group = lookup('bacula::storage::group', String, 'first', $bacula_group)
  $bacula_ssl_dir = "${bacula_conf_dir}/ssl"

  file { $bacula_ssl_dir:
    ensure  => directory,
    mode    => '0750',
    owner   => 'root',
    group   => $bacula_group,
    require => File[$bacula_conf_dir],
  }

  posix_acl { $bacula_ssl_dir:
    action     => 'set',
    permission => [ "group:${bacula_storage_group}:r-x",
                    "default:group:${bacula_storage_group}:r" ],
    provider   => posixacl,
    recursive  => true,
    require    => File[$bacula_ssl_dir],
  }

  $keys = {   "${puppet_ssl_dir}/certs/${::fqdn}.pem"        => "${bacula_ssl_dir}/bacula.crt",
              "${puppet_ssl_dir}/private_keys/${::fqdn}.pem" => "${bacula_ssl_dir}/bacula.key",
              "${puppet_ssl_dir}/certs/ca.pem"               => "${bacula_ssl_dir}/bacula-ca.crt", }

  $keys.each |$key| {
    file { $key[1]:
      ensure  => 'present',
      name    => $key[1],
      source  => $key[0],
      mode    => '0640',
      owner   => 'root',
      group   => $bacula_group,
      require => Posix_acl[$bacula_ssl_dir],
    }

    #posix_acl { $key[1]:
    #  action     => 'set',
    #  permission => [ "group:${bacula_storage_group}:r" ],
    #  provider   => posixacl,
    #  recursive  => false,
    #  require    => File[$key[1]],
    #}
  }
}
