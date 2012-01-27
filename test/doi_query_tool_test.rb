require 'test/unit'
require 'lib/doi_query'
require 'lib/doi_author'
require 'lib/doi_query_tool'
require 'lib/doi_record'

class DoiQueryToolTest < Test::Unit::TestCase

  def test_doi_query
    email_address="methodbox@gmail.com"
    doi = "10.1007/978-3-540-70504-8_9"
    query = DoiQuery.new(email_address)
    result = query.fetch(doi)
    assert_equal(result.authors.first.first_name, "Christian Y. A.")
    assert_equal(result.title,"A Semantics for a Query Language over Sensors, Streams and Relations")
    assert_equal(result.authors.size, 4)
  end  

end
