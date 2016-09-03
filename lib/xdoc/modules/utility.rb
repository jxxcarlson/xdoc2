module Utility


  def insert_into_string(name, insertion, separator)
    parts = name.split(separator)
    prefix = parts[0..-2].join(separator)
    suffix = parts[-1]
    "#{prefix}#{insertion}#{separator}#{suffix}"
  end


end