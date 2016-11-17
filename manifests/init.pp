##/vro_nc_setup_module/manifests/init.pp

class vro_nc_setup_module (
  $alternate_environment  = 'dev',
  $autosign_example_class = 'autosign_example',
#  $roles = ['linux_base', 'linux_mysql_database', 'linux_webserver', 'windows_base','windows_webserver']
){

  $all_nodes_id='00000000-0000-4000-8000-000000000000'
  $roles_group_id='235a97b3-949b-48e0-8e8a-000000000666'
  $dev_env_group_id='235a97b3-949b-48e0-8e8a-000000000888'
  $autosign_group_id='235a97b3-949b-48e0-8e8a-000000000999'

  vcsrepo { "/etc/puppetlabs/code/environments/${alternate_environment}":
    ensure   => latest,
    provider => git,
    source   => 'git@github.com:puppetlabs/puppet-vro-starter_content.git',
    revision => 'production',
    require  => Package['git'],
  }

  package { 'puppetclassify':
    ensure   => present,
    provider => puppet_gem,
  }

  Node_group {
    require => Package['puppetclassify'],
  }

  node_group { 'Autosign Config':
    ensure               => present,
    environment          => 'production',
    override_environment => false,
#    id                   => $autosign_group_id,
    parent               => 'All Nodes',
    rule                 => ['and', ['=', [ 'trusted', 'certname' ], $::hostname]],
    classes              => {
      'autosign_example_class' => {},
    },
  }

  node_group { 'Roles':
    ensure               => present,
    environment          => 'production',
    override_environment => false,
#    id                   => $roles_group_id,
    parent               => 'All Nodes',
  }

  $rolesfiles = generate ('/bin/bash', '-c', "/bin/ls  -1 /etc/puppetlabs/code/environments/${alternate_environment}")
  $rolesfilesarray = split($rolesfiles,'\n')
  $roles = regsubst($rolesfilesarray,'(.+?)(\.[^.]*$|$)', '\1')

  $roles.each |$role| {
      $role_class = "role::${role}"
      node_group { $role_class:
        ensure               => present,
        environment          => $alternate_environment,
        override_environment => false,
        parent               => $roles_group_id,
        rule                 => ['and', ['=', [ 'trusted', 'extensions', 'pp_role'],  $role_class]],
        classes              => {
          '$role_class' => {},
        },
      }
    }

  node_group { "${alternate_environment} environment":
    ensure               => present,
    environment          => 'production',
    override_environment => true,
#    id                   => $dev_env_group_id,
    parent               => 'Production',
    rule                 => ['and', ['=', [ 'trusted', 'extensions','pp_environment' ], $alternate_environment]],
    classes              => {},
  }

#  $pe_agent_specified_group = node_groups()
#  $agent_specified_env_group_id= $pe_agent_specified_group['Agent-specified environment']['id']
#  $agent_specified_group = 'Agent-specified environment'
#  $agent_specified_env_group_id= node_groups()['Agent-specified environment']['id']
  node_group { 'Agent-specified environment':
    ensure               => present,
    environment          => 'agent-specified',
    override_environment => true,
    parent               => 'Production',
    rule                 => ['and', ['=', [ 'trusted', 'extensions', 'pp_environment' ], 'agent-specified']],
    classes              => {},
  }

}
