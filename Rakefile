# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'rake/extensiontask'

Hoe.plugin :minitest
Hoe.plugin :email
Hoe.plugin :git

HOE = Hoe.spec 'dnssd' do
  developer 'Eric Hodel',      'drbrain@segment.net'
  developer 'Aaron Patterson', 'aaron.patterson@gmail.com'
  developer 'Phil Hagelberg',  'phil@hagelb.org'
  developer 'Chad Fowler',     'chad@chadfowler.com'
  developer 'Charles Mills',   ''
  developer 'Rich Kilmer',     ''

  license "MIT"

  clean_globs << 'lib/dnssd/*.{so,bundle,dll}'

  self.spec_extras = {
    :extensions            => ["ext/dnssd/extconf.rb"],
    :required_ruby_version => '>= 2.0.0'
  }
end

Rake::ExtensionTask.new("dnssd", HOE.spec) do |ext|
end

# vim: syntax=Ruby
