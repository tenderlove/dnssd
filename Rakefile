# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :minitest
Hoe.plugin :email
Hoe.plugin :git
Hoe.plugin :compiler

HOE = Hoe.spec 'dnssd' do
  self.rubyforge_name = 'dnssd'

  developer 'Eric Hodel',      'drbrain@segment.net'
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Phil Hagelberg',  'phil@hagelb.org'
  developer 'Chad Fowler',     'chad@chadfowler.com'
  developer 'Charles Mills',   ''
  developer 'Rich Kilmer',     ''

  clean_globs << 'lib/dnssd/*.{so,bundle,dll}'
end

# vim: syntax=Ruby
