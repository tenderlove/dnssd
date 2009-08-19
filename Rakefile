# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :minitest
Hoe.plugin :email
Hoe.plugin :git

HOE = Hoe.spec 'dnssd' do
  self.rubyforge_name = 'dnssd'

  developer 'Eric Hodel',      'drbrain@segment.net'
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Phil Hagelberg',  'phil@hagelb.org'
  developer 'Chad Fowler',     'chad@chadfowler.com'
  developer 'Charles Mills',   ''
  developer 'Rich Kilmer',     ''

  spec_extras[:extensions] = 'ext/dnssd/extconf.rb'

  clean_globs << 'lib/dnssd/*.{so,bundle,dll}'

  extra_dev_deps << ['hoe-seattlerb', '~> 1.2']
  extra_dev_deps << ['minitest', '~> 1.4']
  extra_dev_deps << ['rake-compiler', '~> 0.6']
end

require 'rake/extensiontask'

Rake::ExtensionTask.new 'dnssd', HOE.spec do |ext|
  ext.lib_dir = File.join 'lib', 'dnssd'
  ext.config_options << '--with-warnings'
end

task :test => :compile

# vim: syntax=Ruby
