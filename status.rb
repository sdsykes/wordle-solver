class Status
  attr_writer :possible_words_map

  def initialize
    @results = []
  end
  
  def cache_key
    @results.join.intern
  end
  
  def add_result(result)
    @results << result
  end
  
  def possible_words
    @possible_words_map[@results.last]
  end
  
  def guess_count
    @results.count
  end
end
