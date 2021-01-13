# -*- mode: ruby -*-
# vi: set ft=ruby :

## Install required vagrant plugins
REQUIRED_PLUGINS = %w(dotenv deep_merge vagrant-disksize)
REQUIRED_PLUGINS.each do |plugin|
  unless Vagrant.has_plugin?(plugin) || ARGV[0] == 'plugin' then
    system "vagrant plugin install #{plugin}"
    exec "vagrant #{ARGV.join(" ")}"
  end
end

begin
  Dotenv.load
rescue => e
  puts 'problem loading dotenv'
  puts e
  exit 1
end

begin
  require 'deep_merge'
rescue => e
  puts 'problem loading deep_merge'
  puts e
  exit 1
end

require 'yaml'
require 'pathname'
require 'fileutils'

DIR = Pathname.new(__FILE__).dirname

## These environment variables allows the Vagrant Environment to be used to
## prototype any environment at runtime. The same functionality allows
## Vagrant to act as a fixture in an environment (to build containers, act as
## CI containers, and clean-room packaging environment)

module Vagrant
  class Stack
    require 'yaml'
    attr_reader :defaults
    attr_accessor :stack

    def initialize
      @servers = {}
      @defaults = defaults
      @stack = 'default'
    end

    def defaults
      @defaults ||= {
        'memory'    => ENV['memory'] || 2048,
        'cpus'      => ENV['cpus'] || 2,
        'hostname'  => ENV['hostname'] || 'olympus',
        'box'       => ENV['box'] || 'ubuntu/xenial64',
        'sync_type' => ENV['sync_type'] || 'rsync',
        'ssh'       => {
          'pty'           => false,
          'forward_agent' => true,
          'username'      => ENV['ssh_username'] || 'vagrant'
        },
      }
    end

    def servers
      @servers.delete_if {|k, v| k == 'defaults' }
    end

    def add_server(server, config = {})
      @servers[server] = config.deep_merge(defaults)
    end

    def load_stack(stack)
      @stack = ENV['stack'] || 'boxes'
      stack_dir = ENV['stack_dir'] || "#{DIR}/stacks"
      stack_file = "#{stack_dir}/#{@stack}.yaml"

      begin
        yaml = YAML::load_file(stack_file)
        yaml.each { |server, config| add_server(server, config) }
      rescue => e
        puts e.message
      end
    end
  end
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

## Load up a pre-defined stack for development
@stack = Vagrant::Stack.new
@stack.load_stack(ENV['stack'])

Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant|
  @stack.servers.each do |node, config|
    vagrant.vm.define node do |n|
      n.vm.box            = config['box']
      n.ssh.username      = config['ssh']['username']
      n.ssh.forward_agent = config['ssh']['forward_agent'] || true
      n.ssh.pty           = config['ssh']['pty'] || false

      n.vm.provider 'virtualbox' do |virtualbox|
        virtualbox.name   = node.upcase
        virtualbox.memory = config['memory'].to_i
        virtualbox.cpus   = config['cpus'].to_i
        virtualbox.customize ['modifyvm', :id, '--nested-hw-virt', 'on']
      end

      if config.has_key?('hostname')
        n.vm.hostname = config['hostname'].downcase
      end

      if config.has_key?('disk_size')
        n.disksize.size = config['disk_size']
      end

      if config.has_key?('private_networks')
        config['private_networks'].each do |nic|
          n.vm.network 'private_network', ip: nic
        end
      end

      if config.has_key?('mounts')
        config['mounts'].each do |mount|
          vm_mount, local_mount = mount.split(/:/)
          local_mount = File.expand_path(local_mount)
          n.vm.synced_folder local_mount, vm_mount
        end
      end

      if config.has_key?('provisions')
        config['provisions'].each do |script|
          n.vm.provision :shell, :path => script
        end
      end

      if config.has_key?('forward_ports')
        config['forward_ports'].each do |port_config|
          guest_port, host_port, port_type = port_config.split(/:/)
          n.vm.network :forwarded_port, guest: guest_port, host: host_port, protocol: port_type
        end
      end

    end
  end
end
