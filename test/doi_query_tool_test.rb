require 'test_helper'

class DoiQueryToolTest < Test::Unit::TestCase
  def setup
    DOI.fetch_url = DOI::FETCH_URL
    DOI.lookup_url = DOI::LOOKUP_URL
    @client = DOI::Query.new('test@localhost') # This is not a working email address
  end

  def test_book_chapter_doi
    VCR.use_cassette('fetch_comp_sci_book_chapter_doi') do
      #book
      result = @client.fetch('10.1007/978-3-540-70504-8_9')
      assert_equal 'A Semantics for a Query Language over Sensors, Streams and Relations', result.title
      assert_equal 4, result.authors.size
      assert_equal 'Christian Y. A. Brenninkmeijer', result.authors.first.name
      assert_equal 'Sharing Data, Information and Knowledge,pp.87-99,Springer Berlin Heidelberg', result.citation
      assert_equal 'Sharing Data, Information and Knowledge',result.journal
      assert_equal :book_chapter, result.publication_type
    end
  end

  def test_book_chapter_doi_2
    VCR.use_cassette('fetch_book_chapter_doi') do
      result = @client.fetch('10.1007/978-3-319-67008-9_24')
      assert_equal :book_chapter, result.publication_type
      assert_equal 'Research and Advanced Technology for Digital Libraries',result.journal
      assert_equal  result.booktitle, result.journal
      assert_equal 'Semantic Author Name Disambiguation with Word Embeddings', result.title
      assert_equal '10.1007/978-3-319-67008-9_24', result.doi
      assert_equal 'Research and Advanced Technology for Digital Libraries 10450:300-311,Springer International Publishing', result.citation
      assert_equal 1, result.authors.size
      assert_equal 5, result.editors.size
    end
  end

  def test_book_doi
    VCR.use_cassette('fetch_book_doi') do
      result = @client.fetch('10.23943/princeton/9780691161914.003.0002')
      assert_equal :book, result.publication_type
      assert_equal 'Milton’s Book of Numbers: Book 1 and Its Catalog', result.title
      assert_equal 'Princeton University Press',result.citation
      assert_equal '10.23943/princeton/9780691161914.003.0002', result.doi
      assert_equal result.title, result.booktitle
      assert_equal 1, result.authors.size
      assert_equal 'Princeton University Press',result.publisher

    end
  end

  def test_article_doi
    VCR.use_cassette('fetch_article_doi') do
      result = @client.fetch('10.1214/17-AOAS122ED')
      assert_equal :journal, result.publication_type
      assert_equal 'Ann. Appl. Stat. 12(2)', result.citation
    end
  end

  def test_pre_print_doi
    VCR.use_cassette('fetch_pre_print_doi') do
      result = @client.fetch('10.20944/preprints201909.0043.v1')
      assert_equal 'An Isolated Complex V Inefficiency and Dysregulated Mitochondrial Function in Immortalized Lymphocytes from ME/CFS Patients', result.title
      assert_equal 'Daniel', result.authors.first.first_name
      assert_equal :pre_print, result.publication_type
      assert_match(/\[Preprint\]/, result.citation)
    end
  end

  def test_inproceedings_doi
    VCR.use_cassette('fetch_inproceedings_doi') do
      result = @client.fetch('10.1117/12.2275959')
      assert_equal'10.1117/12.2275959',result.doi
      assert_equal 'The NOVA project: maximizing beam time efficiency through synergistic analyses of SRμCT data', result.title
      assert_equal result.booktitle,result.journal
      assert_equal 20, result.authors.size
      assert_equal 2, result.editors.size
      assert_equal 'Sebastian Schmelzle', result.authors.first.name
      assert_equal 'Bert Müller', result.editors.first.name
      assert_equal 'Developments in X-Ray Tomography XI, San Diego, United States, August 2017', result.conference
      assert_equal '2017-09-07', result.date_published.to_s
      assert_equal 'Developments in X-Ray Tomography XI',result.booktitle
      assert_equal 'SPIE',result.publisher
      assert_equal 'Developments in X-Ray Tomography XI,p.24,SPIE', result.citation
      assert_equal :inproceedings, result.publication_type
    end
  end


  def test_inproceedings_doi_3
    VCR.use_cassette('fetch_inproceedings_doi_3') do
      result = @client.fetch('10.1063/1.2128263')
      assert_equal :inproceedings, result.publication_type
      assert_equal 'AIP Conference Proceedings,pp.29-34,AIP', result.citation
    end
  end

  def test_proceedings_doi_conference
    VCR.use_cassette('test_proceedings_doi_conference') do
      result = @client.fetch('10.18653/v1/W18-08')
      assert_equal'10.18653/v1/W18-08',result.doi
      assert_equal :proceedings, result.publication_type
      assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing', result.title
      assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing', result.booktitle
      assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing,Association for Computational Linguistics', result.citation
      assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing, New Orleans, Louisiana, USA, June 2018', result.conference
      assert_equal 0, result.authors.size
      assert_equal 4, result.editors.size
    end
  end

  def test_journal_doi
    VCR.use_cassette('fetch_journal_doi') do
      result = @client.fetch('10.1002/ca.22295')
      assert_equal :journal, result.publication_type
      assert_equal 'Clinical Anatomy',result.journal
      assert_equal 'The anatomy of the aortic root', result.title
      assert_equal 'Clin. Anat. 27(5):748-756', result.citation
      assert_equal '2014-07-01',result.date_published.to_s
      assert_equal '10.1002/ca.22295', result.doi
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
      assert_raises(DOI::NotFoundException) do
        @client.fetch('10.5072/1234')
      end
    end
  end

  def test_unrecognized_type
    VCR.use_cassette('unrecognized_type') do
      assert_raises(DOI::NotFoundException) do
        @client.fetch('10.5072/5678')
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

  def test_no_extra_authors_from_components
    VCR.use_cassette('extra_authors_in_components') do
      result = @client.fetch('10.3897/rio.6.e57602')
      assert_equal 14, result.authors.size
    end
  end

  def test_dataset_not_supported
    VCR.use_cassette('dataset_support') do
      assert_raises(DOI::RecordNotSupported) do
        @client.fetch('10.13003/83B2GP')
      end
    end
  end
end

