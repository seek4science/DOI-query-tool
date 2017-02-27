module DOI
  class UnrecognizedTypeException < RuntimeError; end
  class FetchException < RuntimeError; end
  class ParseException < RuntimeError; end
end
