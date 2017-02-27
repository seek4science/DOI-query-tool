require 'test_helper'

class DoiQueryToolTest < Test::Unit::TestCase
  def setup
    @client = DOI::Query.new('test@localhost') # This is not a working email address
  end

  def test_doi_query
    VCR.use_cassette('fetch_comp_sci_book_chapter_doi') do
      result = @client.fetch('10.1007/978-3-540-70504-8_9')
      assert_equal 'A Semantics for a Query Language over Sensors, Streams and Relations', result.title
      assert_equal 4, result.authors.size
      assert_equal 'Christian Y. A.', result.authors.first.first_name
      assert_equal 'Lecture Notes in Computer Science 5071 : 87', result.citation
      assert_equal :book_chapter, result.publication_type
    end
  end

  def test_pre_print_doi
    VCR.use_cassette('fetch_pre_print_doi') do
      result = @client.fetch('10.1101/105437')
      assert_equal result.title, 'Linking circadian time to growth rate quantitatively via carbon metabolism'
      assert_equal result.authors.first.first_name, 'Yin Hoon'
      assert_equal result.publication_type, :pre_print
    end
  end
end
