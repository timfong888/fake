require_relative 'request-generator'

FakeRequest.new.generate(filename: ARGV[0])