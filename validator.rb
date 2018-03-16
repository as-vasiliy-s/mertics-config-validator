require 'yaml'
require 'hashie/mash'

require_relative './schema'

config = YAML.load(File.read('./example.yaml'))

config = Hashie::Mash.new(config)

pp config
puts '', '*' * 80, ''

pp Schema::Main.call(config).messages
