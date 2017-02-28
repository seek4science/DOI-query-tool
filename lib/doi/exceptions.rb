module DOI
  class MyException < RuntimeError

    def initialize(msg = 'A DOI exception occurred')
      msg = "#{msg}: #{cause.message}" if cause
      super(msg)
    end

    def backtrace
      cause ? cause.backtrace : super
    end
  end

  class UnrecognizedTypeException < MyException; end
  class FetchException < MyException; end
  class ParseException < MyException; end
  class MalformedDOIException < MyException; end
end
