Gem::Specification.new do |s|
  s.name        = 'doi_query_tool'
  s.version     = '1.0.1'
  s.date        = '2017-02-27'
  s.summary     = 'Download DOI publication metadata from crossref.org'
  s.authors     = ['Finn Bacall', 'Ian Dunlop', 'Quyen Nguyen', 'Xiaoming Hu', 'Alain Becam']
  s.email       = 'seek4science@googlegroups.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/seek4science/DOI-query-tool'
  s.require_paths = ['lib']
  s.add_runtime_dependency 'libxml-ruby', '>=2.6.0'
  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'webmock', '~> 3.14.0'
  s.add_development_dependency 'vcr', '~> 3.0.3'
  s.add_development_dependency 'simplecov'
end
