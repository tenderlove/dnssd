# -*- ruby -*-

require 'rubygems'
require 'hoe'

HOE = Hoe.spec 'dnssd' do
  self.rubyforge_name = 'dnssd'

  developer 'Chad Fowler',     'chad@chadfowler.com'
  developer 'Charles Mills',   ''
  developer 'Rich Kilmer',     ''
  developer 'Phil Hagelberg',  'phil@hagelb.org'
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Eric Hodel',      'drbrain@segment.net'

  spec_extras[:extensions] = 'ext/dnssd/extconf.rb'

  clean_globs << 'lib/dnssd/*.{so,bundle,dll}'

  extra_dev_deps << ['rake-complier', '~> 0.6']
end

require 'rake/extensiontask'

Rake::ExtensionTask.new 'dnssd', HOE.spec do |ext|
  ext.lib_dir = File.join 'lib', 'dnssd'
end

# vim: syntax=Ruby
