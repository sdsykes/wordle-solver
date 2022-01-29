class Guesser
  FILTER_EXTRA_LETTERS = ["t","a","o","i"].freeze
  
  def initialize(cache:, tester:)
    @cache = cache
    @tester = tester
  end
  
  def guess(possible_words, word_list, status) 
    word, possible_words_map = @cache.cached(status.cache_key) do
      find(possible_words, word_list)
    end
    status.possible_words_map = possible_words_map
    word
  end
  
  def find(possible_words, word_list)
    possible_count = possible_words.count
    min = possible_count * possible_count + 1
    possible_words_map = {}
    best = nil

    word_list.each do |word|
      score = 0
      result_words = {}
      possible_words.each do |answer_word|
        result = @tester.test(word, answer_word)
        result_words[result] = (result_words[result] || []) << answer_word
        score += result_words[result].count * 2 - 1
        break if score >= min
      end

      min, best, possible_words_map = score, word, result_words if score < min
      break if score <= possible_count && possible_words.include?(word)
    end

    return best, possible_words_map
  end
  
  def next_word_list(possible_words, dictionary)
    @cache.cached(possible_words.hash) do
      filter_letters = possible_words.map(&:chars).flatten | FILTER_EXTRA_LETTERS
      (possible_words + words_containing_letters_in(filter_letters, dictionary)).uniq
    end
  end
  
  private

  def words_containing_letters_in(letters, words)
    words.grep(Regexp.new("[#{letters.join}]{5}"))
  end
end
