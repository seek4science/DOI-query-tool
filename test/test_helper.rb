require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'webmock/test_unit'
require 'vcr'
require 'doi_query_tool'

VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr'
  config.hook_into :webmock
end
