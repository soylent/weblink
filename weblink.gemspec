# frozen_string_literal: true

require 'pathname'

Gem::Specification.new do |s|
  s.name = 'weblink'
  s.version = Pathname(__dir__).join('VERSION').read.chomp
  s.summary = 'Web browser gateway'
  s.homepage = 'https://github.com/soylent/weblink'
  s.author = 'soylent'
  s.files = Dir['bin/*', 'lib/*', 'public/*', 'VERSION', 'CHANGELOG']
  s.executables = 'weblink'
  s.required_ruby_version = '>= 2.5.0'
  s.add_dependency 'em-websocket', '~> 0.5'
end
