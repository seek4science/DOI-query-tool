# frozen_string_literal: true

module DOI
  class Query
    attr_accessor :api_key

    def initialize(a)
      self.api_key = a
    end

    # Takes either a DOI and fetches the associated publication
    def fetch(id, params = {})
      params[:format] = 'unixref'
      params[:id] = "doi:#{id}" unless params[:id]
      params[:pid] = api_key unless params[:pid]
      params[:noredirect] = true
      uri = URI(DOI.fetch_url)
      uri.query = URI.encode_www_form(params.delete_if { |k, _v| k.nil? }.to_a)
      url = uri.to_s

      begin
        res = URI.open(url)
      rescue Exception
        raise DOI::FetchException
      end

      record = parse_xml(res)
      record.doi = id
      record
    end

    # Parses the XML returned from the DOI query, and creates an object
    def parse_xml(res)
      if res.content_type.include?('xml')
        doc = LibXML::XML::Parser.io(res).parse
        if doc.find_first('//error')
          process_error(doc)
        else
          process_content(doc)
        end
      elsif res.read.to_s.include?('Malformed DOI')
        raise DOI::MalformedDOIException
      else
        raise DOI::ParseException, 'Unrecognized response format'
      end
    end

    private

    def process_error(doc)
      error = doc.find_first('//error')

      message = error.content
      if message.start_with?('doi:')
        message = 'The DOI could not be resolved'
        raise DOI::NotFoundException, message
      else
        raise DOI::FetchException, message
      end
    end

    def process_content(doc)

      # Remove components-> supplemental material
      component_list = doc.find_first("//component_list")
      unless component_list.nil?
        component_list.remove!
      end

      params = {}

      params[:doi] = doc.find_first('//doi').nil? ? nil : doc.find_first('//doi').content
      params[:abstract] = doc.find_first('//abstract').nil? ? nil : doc.find_first('//abstract').content
      date = doc.find_first('//publication_date')
      params[:date_published] = date.nil? ? nil : parse_date(date)

      citation_first_page = doc.find_first('//pages/first_page').nil? ? nil : doc.find_first('//pages/first_page').content
      citation_last_page = doc.find_first('//pages/last_page').nil? ? nil : doc.find_first('//pages/last_page').content

      page = citation_last_page.nil? ? 'p.' : 'pp.'
      page += citation_first_page unless citation_first_page.nil?
      page += '-' + citation_last_page unless citation_last_page.nil?

      # parse publication types
      article = doc.find_first('//journal')
      params[:type] = :journal unless article.nil?

      if params[:type].nil?
        article = doc.find_first('//conference') 
        unless article.nil?
          conference_paper = doc.find_first('//conference_paper')
          params[:type] = if conference_paper.nil?
                            :proceedings
                          else
                            :inproceedings
                          end
        end
      end

      if params[:type].nil?
        article = doc.find_first('//book')
        params[:type] = :book unless article.nil?
        content_item = article.find_first("//content_item[@component_type='chapter']") unless article.nil?
        content_item ||= article.find_first("//content_item[@component_type='section']") unless article.nil?
        params[:type] = :book_chapter unless content_item.nil?
      end

      if params[:type].nil?
        article = doc.find_first('//posted_content')
        params[:type] = if !article.nil? && article.attributes['type'] == 'preprint'
                          :pre_print
                        else
                          :other
                        end
      end

      if article.nil?
        raise RecordNotSupported
      end

      case params[:type]

      when :journal

        title = article.find_first('//journal_article/titles/title')
        params[:title] = title.nil? ? nil : title.content
        journal_metadata = article.find_first('//journal_metadata')
        journal = journal_metadata.find_first('.//full_title')
        params[:journal] = journal.nil? ? nil : journal.content
        citation_iso_abbrev = if journal_metadata.find_first('.//abbrev_title')
                                journal_metadata.find_first('.//abbrev_title').content
                              else
                                params[:journal]
                              end
        journal_issue = article.find_first('//journal_issue')
        article_number = article.find_first("//journal_article/publisher_item/item_number[@item_number_type='article_number']") ? article.find_first("//journal_article/publisher_item/item_number[@item_number_type='article_number']").content : nil
        article_number ||= article.find_first("//journal_article/publisher_item/item_number[@item_number_type='article-number']") ? article.find_first("//journal_article/publisher_item/item_number[@item_number_type='article-number']").content : nil
        article_number ||= article.find_first("//journal_article/publisher_item/item_number[@item_number_type='sequence-number']") ? article.find_first("//journal_article/publisher_item/item_number[@item_number_type='sequence-number']").content : nil

        unless journal_issue.nil?
          citation_volume = journal_issue.find_first('.//volume') ? journal_issue.find_first('.//volume').content : nil
          citation_issue = journal_issue.find_first('.//issue') ? '(' + journal_issue.find_first('.//issue').content + ')' : nil
        end

        citation = citation_iso_abbrev
        citation += ' ' + citation_volume unless citation_volume.nil?
        citation += citation_issue unless citation_issue .nil?
        citation += ':'+ citation_first_page unless citation_first_page.nil?
        citation += '-'+citation_last_page unless citation_last_page.nil?
        citation += ','+ article_number if !article_number.nil? && citation_first_page.nil?
        params[:citation] = citation

      when :proceedings, :inproceedings
        event_metadata = article.find_first('//event_metadata')
        unless event_metadata.nil?
          conference_name = event_metadata.find_first('.//conference_name').nil? ? nil : event_metadata.find_first('.//conference_name').content
          conference_location = event_metadata.find_first('.//conference_location').nil? ? nil : event_metadata.find_first('.//conference_location').content
          conference_day = event_metadata.find_first('.//conference_date')
          conference_d = conference_day.content unless conference_day.nil?
          conference_d = Date::MONTHNAMES[Integer(conference_day['start_month'])] + ' ' + conference_day['start_year'] if conference_d.empty?
          params[:conference] = conference_name
          params[:conference] += ', ' + conference_location unless conference_location.nil?
          params[:conference] += ', ' + conference_d unless conference_d.empty?
        end

        proceedings_metadata = article.find_first('//proceedings_metadata')
        proceedings_metadata = article.find_first('//proceedings_series_metadata') if proceedings_metadata.nil?

        unless proceedings_metadata.nil?
          params[:booktitle] = proceedings_metadata.find_first('.//proceedings_title').nil? ? nil : proceedings_metadata.find_first('.//proceedings_title').content
          params[:booktitle] = proceedings_metadata.find_first('.//title').nil? ? nil : proceedings_metadata.find_first('.//title').content if params[:booktitle].nil?
          params[:publisher] = proceedings_metadata.find_first('.//publisher/publisher_name').nil? ? nil : proceedings_metadata.find_first('.//publisher/publisher_name').content
          #year = proceedings_metadata.find_first('.//publication_date/year').nil? ? nil : proceedings_metadata.find_first('.//publication_date/year').content
        end

        conference_paper = article.find_first('//conference_paper')
        unless conference_paper.nil?
          params[:title] = conference_paper.find_first('.//titles/title').nil? ? nil : conference_paper.find_first('.//titles/title').content
        end


        params[:citation] = params[:booktitle].nil? ? '' : params[:booktitle]
        params[:citation] += params[:citation].empty? ? '': ','
        params[:citation] += page unless citation_first_page.nil?
        params[:citation] += ',' unless citation_first_page.nil?
        params[:citation] += params[:publisher] unless params[:publisher].nil?

      when :book_chapter, :book
        booktitle = article.find_first('//book_series_metadata/titles/title')
        booktitle ||= article.find_first('//book_series_metadata/series_metadata/titles/title')
        booktitle ||= article.find_first('//book_metadata/titles/title')
        booktitle ||= article.find_first('//book_set_metadata/titles/title')

        params[:booktitle] = booktitle.nil? ? '' : booktitle.content
        publisher = article.find_first('//book_series_metadata/publisher/publisher_name')
        publisher ||=  article.find_first('//book_metadata/publisher/publisher_name')
        publisher ||=  article.find_first('//book_set_metadata/publisher/publisher_name')
        params[:publisher] = publisher.nil? ? nil : publisher.content

        if params[:type] == :book_chapter
          title = article.find_first('//content_item/titles/title')
          params[:title] = title.nil? ? nil : title.content

          citation_volume = article.find_first('//book_series_metadata/volume') ? article.find_first('//book_series_metadata/volume').content : ''
          citation_volume ||=article.find_first('//book_set_metadata/volume') ? article.find_first('//book_set_metadata/volume').content : ''

          citation = params[:booktitle]
          if citation_volume.empty?
            citation += ',' + page unless citation_first_page.nil?
          else
            citation += ' ' + citation_volume
            citation += ':'+ citation_first_page unless citation_first_page.nil?
            citation += '-'+citation_last_page unless citation_last_page.nil?
          end

          citation += ',' + params[:publisher] unless params[:publisher].nil?
          #citation += ',' + params[:date_published].year.to_s unless params[:date_published].nil?
          params[:citation] = citation
        else
          params[:title] = params[:booktitle]
          citation = params[:publisher] unless params[:publisher].nil?
          #citation += '. ' + params[:date_published].year.to_s unless params[:date_published].nil?
          params[:citation] = citation
        end



      when :pre_print
        title = article.find_first('//posted_content/titles/title')
        params[:title] = title.nil? ? nil : title.content
        if params[:date_published].nil?
          posted_date = article.find_first('//posted_content/posted_date')
          posted_date = article.find_first('//posted_content/acceptance_date') if posted_date.nil?
          params[:date_published] = posted_date.nil? ? nil : parse_date(posted_date)
        end

        citation = article.find_first('//posted_content/item_number')
        citation = citation.nil? ? '' : citation.content
        citation += citation.empty? ? '' : ','
        citation += '[Preprint]'
        #citation +=  params[:date_published].year.to_s unless params[:date_published].nil?
        params[:citation] = citation
      end

      params[:authors] = []
      params[:editors] = []

      # proceedings have no authors
      author_elements = article.find("//content_item/contributors/person_name[@contributor_role='author']")
      author_elements = article.find("//contributors/person_name[@contributor_role='author']") if author_elements.none?
      author_elements = article.find('//contributors/person_name') if author_elements.none?

      author_elements.each do |author|
        author_last_name = author.find_first('.//surname').nil? ? '' : author.find_first('.//surname').content
        author_first_name = author.find_first('.//given_name').nil? ? '' : author.find_first('.//given_name').content
        params[:authors] << DOI::Author.new(author_first_name, author_last_name)
      end

      editor_elements = article.find("//content_item/contributors/person_name[@contributor_role='editor']")
      editor_elements = article.find("//contributors/person_name[@contributor_role='editor']") if editor_elements.none?

      editor_elements.each do |editor|
        editor_last_name = editor.find_first('.//surname').nil? ? '' : editor.find_first('.//surname').content
        editor_first_name = editor.find_first('.//given_name').nil? ? '' : editor.find_first('.//given_name').content
        params[:editors] << DOI::Editor.new(editor_first_name, editor_last_name)
      end

      # in case of proceedings, there are no authors but editors
      if params[:editors] == [] && params[:type] == :proceedings
        params[:editors] = params[:authors]
      end

      params[:authors] = nil if params[:type] == :proceedings

      raise DOI::UnrecognizedTypeException if params[:type].nil?

      params[:doc] = article


      if params[:title].nil?
        title ||= article.find_first('//titles/title')
        params[:title] = title.nil? ? nil : title.content
      end

      if [:book_chapter, :inproceedings].include? params[:type]
        params[:journal] = params[:booktitle]
      end

      if [:book,:proceedings].include? params[:type]
        params[:title] = params[:booktitle]
      end

      DOI::Record.new(params)
    end
    def parse_date(xml_date)
      if xml_date.nil?
        nil
      else
        day = xml_date.find_first('.//day')
        day = day.nil? ? '01' : day.content
        month = xml_date.find_first('.//month')
        month = month.nil? ? '01' : month.content
        year = xml_date.find_first('.//year')
        year = year.nil? ? '1970' : year.content
        Date.strptime("#{year}-#{month}-#{day}")
      end
    end
  end
end
