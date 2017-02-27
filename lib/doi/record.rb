module DOI
  class Record
    attr_accessor :authors, :title, :abstract, :journal, :citation, :doi, :xml, :date_published,
                  :publication_type, :error

    PUBLICATION_TYPES = { :journal=>1, :conference=>2, :book_chapter=>3, :pre_print=>4, :other=>5 }

    def initialize(attributes={})
      self.title = attributes[:title]
      self.abstract = attributes[:abstract]
      self.journal = attributes[:journal]
      self.citation = attributes[:citation]
      self.doi = attributes[:doi]
      self.xml = attributes[:doc]
      self.date_published = attributes[:pub_date]
      self.authors = attributes[:authors] || []
      self.publication_type = attributes[:type] || PUBLICATION_TYPES[:journal]
      self.error=attributes[:error] || nil
    end

    def lookup_url
      "#{DOI.lookup_url.chomp('/')}/#{self.doi}"
    end
  end
end
