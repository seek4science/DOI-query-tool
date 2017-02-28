module DOI
  class Exception < RuntimeError
    attr_reader :original
    def initialize(msg = '', original=$!)
      super(msg)
      @original = original
    end

    def backtrace
      @original ? @original.backtrace : super
    end
  end

  class UnrecognizedTypeException < Exception; end
  class FetchException < Exception; end
  class ParseException < Exception; end
  class MalformedDOIException < Exception; end
end
