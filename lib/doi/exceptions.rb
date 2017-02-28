module DOI
  class MyException < RuntimeError

    def initialize(msg = 'A DOI exception occurred')
      super(msg)
    end

    def backtrace
      cause ? cause.backtrace : super
    end

    def message
      cause ? "#{super} (#{cause.class.name}: #{cause.message})" : super
    end
  end

  class UnrecognizedTypeException < MyException; end
  class FetchException < MyException; end
  class ParseException < MyException; end
  class MalformedDOIException < MyException; end
  class NotFoundException < MyException; end
end
