class Status
  attr_reader :letters
  attr_writer :possible_words_cache, :prev_possible_words
  
  def initialize
    @letters = {}
    $alphabet.each do |letter|
      @letters[letter] = {
        included: 0,
        not_pos: [],
        right_pos: [],
        maxed: false
      }
    end
    @possible_words_cache = nil
    @prev_possible_words = nil
  end
  
  def dup
    status = Status.new
    $alphabet.each do |letter|
      status.letters[letter] = @letters[letter].dup
      status.letters[letter][:not_pos] = @letters[letter][:not_pos].dup
      status.letters[letter][:right_pos] = @letters[letter][:right_pos].dup
    end
    status.possible_words_cache = @possible_words_cache
    status.prev_possible_words = @prev_possible_words
    status
  end
  
  def add_guess(guess, result)
    prev_letters = @letters.dup

    guess.each_char do |c|
      prev_letters[c] = @letters[c].dup
      @letters[c][:included] = 0
    end

    n = 0
    guess.each_char do |c|
      case result[n]
      when "o"
        @letters[c][:included] += 1
        @letters[c][:not_pos] |= [n]
      when "x"
        @letters[c][:included] += 1
        @letters[c][:right_pos] |= [n]
      else
        @letters[c][:maxed] = true
      end
      n += 1
    end

    guess.each_char do |c|
      if prev_letters[c][:included] > @letters[c][:included]
        @letters[c][:included] = prev_letters[c][:included]
      end
    end
    
    @prev_possible_words = @possible_words_cache
    @possible_words_cache = nil
  end
  
  def untried_letters
    @letters.select {|letter, letter_status| !letter_status[:maxed] && letter_status[:included] == 0}.map(&:first)
  end
  
  def unused_letters
    @letters.select {|letter, letter_status| letter_status[:included] == 0 && letter_status[:maxed]}.map(&:first)
  end
  
  def letters_in_position
    selected = @letters.select {|letter, letter_status| letter_status[:right_pos].count > 0}
    result = []
    selected.each do |letter|
      letter[1][:right_pos].each do |position|
        result << [letter[0], position]
      end
    end
    result
  end
  
  def letters_excluded_from_position
    result = []
    @letters.select do |letter, letter_status|
      letter_status[:not_pos].each do |position|
        result << [letter, position]
      end
    end
    result
  end
  
  def letters_not_in_position
    selected = @letters.select {|letter, letter_status| letter_status[:included] > letter_status[:right_pos].count}
    result = []
    selected.each do |letter, letter_status|
      letter_status[:not_pos].each do |position|
        result << [letter, position]
      end
    end
    result    
  end
  
  def open_positions
    result = [0,1,2,3,4]
    @letters.each do |letter, letter_status|
      letter_status[:right_pos].each {|pos| result -= [pos]}
    end
    result
  end
  
  def max_occurrances
    result = []
    @letters.each do |letter, letter_status|
      if letter_status[:included] > 0 && letter_status[:maxed]
        result << [letter, letter_status[:included]]
      end
    end
    result
  end
  
  def guessed_letters_count
    @letters.sum {|letter, letter_status| letter_status[:included]}
  end
  
  def elimination_needed?(words)
    chars = words.join("").chars
    (chars.uniq.count <= words.count + 4 || (open_positions.count <= 2 && guessed_letters_count == 4)) && words.count > 2
  end
  
  def words_containing_letter_at_index(letter, index, words)
    words.select {|word| word[index] == letter}
  end

  def words_not_containing_letter_at_index(letter, index, words)
    words.select {|word| word[index] != letter}
  end

  def words_containing_letter_in_positions(letter, positions, words)
    words.select {|word| positions.any? {|index| word[index] == letter}}  
  end
  
  def words_not_containing_letters(letters, words)
    words.grep(Regexp.new("[^#{letters.join}]{5}"))
#    found_words = words
#    letters.each {|c| found_words = found_words.select{|w| !w.include?(c)}}
#    if x != found_words
#      p x
#      p found_words
#      exit
#    end
#    found_words
  end
  
  def possible_words_unordered
    words = @prev_possible_words || $w_list

    letters_in_position.each do |letter, pos|
      words = words_containing_letter_at_index(letter, pos, words)
    end

    letters_excluded_from_position.each do |letter, pos|
      words = words_not_containing_letter_at_index(letter, pos, words)    
    end

    words = words_not_containing_letters(unused_letters, words)

    open_poss = open_positions
    letters_not_in_position.each do |letter, pos|
      words = words_containing_letter_in_positions(letter, open_poss, words)
    end

    max_occurrances.each do |letter, max|
      words = words.select {|word| word.count(letter) <= max}
    end
    
    words
  end
  
  def possible_words_count
    possible_words_unordered.count
  end
  
  # returns all possible words at this point, first in array is the best one to guess
  def possible_words
    return @possible_words_cache if @possible_words_cache
    
    words = possible_words_unordered
    # order by words with most common unique chars
    scores = {}
    words.each do |word|
      score = 0
      word.each_char do |c|
        words.each do |w|
          score += 1 if w.include?(c)
        end
      end
      score += words.count if word.chars.uniq.count == word.chars.count
      scores[word] = score
    end
  
    @possible_words_cache = scores.sort_by{|k, v| -v}.map{|w, s| w}
  end
  
  def test(word, theword)
    test_word = word.dup
    secret_word = theword.dup
    n = 0
    result = "-----"
    test_word.each_char do |letter|
      if secret_word[n] == letter
        result[n] = "x"
        secret_word[n] = "."
        test_word[n] = "*"
      end
      n += 1
    end
  
    n = 0
    test_word.each_char do |letter|
      i = secret_word.index(letter)
      if i
        result[n] = "o"
        secret_word[i] = "."
      end
      n += 1
    end
    result
  end
  
  def hash
    str = ""
    letters.each do |letter, letter_status|
      ls = letter_status
      str << "#{ls[:included]} #{ls[:not_pos].join(" ")} #{ls[:right_pos].join(" ")} #{ls[:maxed]}"
    end
    str.hash
  end
end
