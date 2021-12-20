module DOI
  class Author
    attr_accessor :first_name, :last_name

    def initialize(first, last)
      self.first_name = first
      self.last_name = last
    end

    def name
      "#{first_name} #{last_name}"
    end

    def ==(other)
      self.class === other &&
        other.first_name == first_name &&
        other.last_name == last_name
    end

    alias eql? ==

    def hash
      "#{first_name} #{last_name}".hash
    end
  end
end
