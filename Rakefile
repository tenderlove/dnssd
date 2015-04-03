# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :minitest
Hoe.plugin :email
Hoe.plugin :git
Hoe.plugin :compiler

HOE = Hoe.spec 'dnssd' do
  developer 'Eric Hodel',      'drbrain@segment.net'
  developer 'Aaron Patterson', 'aaron.patterson@gmail.com'
  developer 'Phil Hagelberg',  'phil@hagelb.org'
  developer 'Chad Fowler',     'chad@chadfowler.com'
  developer 'Charles Mills',   ''
  developer 'Rich Kilmer',     ''

  rdoc_locations << 'docs.seattlerb.org:/data/www/docs.seattlerb.org/dnssd/'

  clean_globs << 'lib/dnssd/*.{so,bundle,dll}'

  self.spec_extras = {
    :extensions            => ["ext/dnssd/extconf.rb"],
    :required_ruby_version => '>= 2.0.0'
  }
end

# vim: syntax=Ruby
