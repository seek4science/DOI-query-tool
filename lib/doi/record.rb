module DOI
  class Record
    attr_accessor :authors, :editors, :title, :abstract, :journal, :conference, :booktitle,:publisher, :citation, :doi, :xml, :date_published,
                  :publication_type, :error

    PUBLICATION_TYPES = [:journal, :conference, :book, :book_chapter, :pre_print,
                         :inproceedings,:proceedings,:other].freeze

    def initialize(attributes = {})
      self.title = attributes[:title]
      self.abstract = attributes[:abstract]
      self.journal = attributes[:journal]
      self.conference = attributes[:conference]
      self.citation = attributes[:citation]
      self.doi = attributes[:doi]
      self.xml = attributes[:doc]
      self.date_published = attributes[:date_published]
      self.authors = attributes[:authors] || []
      self.editors = attributes[:editors] || []
      self.booktitle = attributes[:booktitle]
      self.publisher = attributes[:publisher]
      self.publication_type = attributes[:type] || :journal
      self.error = attributes[:error] || nil
    end

    def lookup_url
      "#{DOI.lookup_url.chomp('/')}/#{doi}"
    end
  end
end
