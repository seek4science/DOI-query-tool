# doi_query_tool

![Tests](https://github.com/seek4science/DOI-query-tool/actions/workflows/tests.yml/badge.svg)

This is the Gem version of DOI-query-tool Plugin (More information please read the Plugin)
Download DOI publication metadata from crossref.org. You may need to register an email address with them which gets passed into the query.

## Installation
Put this line into the Gemfile:
```
gem 'doi_query_tool', git: 'https://github.com/seek4science/DOI-query-tool.git'
```

## Example
Replace `email_address` with the one registered at crossref.
```
#replace email_address with the one registered at crossref

email_address="me@somewhere.com"
doi = "10.1007/978-3-540-70504-8_9"

query = DOI::Query.new(email_address)
result = query.fetch(doi)

puts result.authors.first.first_name
puts result.title
puts result.date_published
```

Copyright 2010 University of Manchester, released under the MIT license
