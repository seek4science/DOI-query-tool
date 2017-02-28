require 'test_helper'

class DoiQueryToolTest < Test::Unit::TestCase
  def setup
    DOI.fetch_url = DOI::FETCH_URL
    DOI.lookup_url = DOI::LOOKUP_URL
    @client = DOI::Query.new('test@localhost') # This is not a working email address
  end

  def test_doi_query
    VCR.use_cassette('fetch_comp_sci_book_chapter_doi') do
      result = @client.fetch('10.1007/978-3-540-70504-8_9')

      assert_equal 'A Semantics for a Query Language over Sensors, Streams and Relations', result.title
      assert_equal 4, result.authors.size
      assert_equal 'Christian Y. A. Brenninkmeijer', result.authors.first.name
      assert_equal 'Lecture Notes in Computer Science 5071 : 87', result.citation
      assert_equal :book_chapter, result.publication_type
    end
  end

  def test_pre_print_doi
    VCR.use_cassette('fetch_pre_print_doi') do
      result = @client.fetch('10.1101/105437')

      assert_equal 'Linking circadian time to growth rate quantitatively via carbon metabolism', result.title
      assert_equal 'Yin Hoon', result.authors.first.first_name
      assert_equal :pre_print, result.publication_type
    end
  end

  def test_journal_doi
    VCR.use_cassette('fetch_journal_doi') do
      result = @client.fetch('10.1002/ca.22295')

      assert_equal 'The anatomy of the aortic root', result.title
      assert_equal :journal, result.publication_type
      assert_equal 'Clin. Anat. 27(5) : 748', result.citation
    end
  end

  def test_malformed_doi
    VCR.use_cassette('malformed_doi') do
      assert_raises(DOI::MalformedDOIException) do
        @client.fetch('hello-world')
      end
    end
  end

  def test_valid_but_non_existent_doi
    VCR.use_cassette('non_existent_doi') do
      assert_raises(DOI::FetchException) do
        @client.fetch('10.5072/1234')
      end
    end
  end

  def test_404_response
    DOI.fetch_url = 'http://404.host'
    stub_request(:get, /http\:\/\/404\.host.*/).to_return(status: 404)

    assert_raises(DOI::FetchException) do
      client = DOI::Query.new('test@localhost')
      client.fetch('10.5072/1234')
    end
  end

  def test_change_fetch_url
    DOI.fetch_url = 'http://somewhere.else'
    VCR.use_cassette('doi_from_somewhere_else') do
      client = DOI::Query.new('test@localhost')
      result = client.fetch('10.1101/105437')

      assert_equal 'This came from somewhere else', result.title
    end
  end

  def test_change_lookup_url
    DOI.lookup_url = 'http://somewhere.else'
    record = DOI::Record.new(doi: '10.1101/105437')

    assert_equal 'http://somewhere.else/10.1101/105437', record.lookup_url
  end
end
