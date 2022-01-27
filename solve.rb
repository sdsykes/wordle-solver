# 1:0.0% 2:0.9% 3:42.7% 4:43.0% 5:11.7% 6:1.7% 7:0.0% 8:0.0% 9:0.0% (2315 words)
# {5=>272, 4=>995, 3=>989, 2=>20, 6=>39}
# 1:0.0% 2:0.8% 3:40.1% 4:45.9% 5:12.0% 6:1.2% 7:0.0% 8:0.0% 9:0.0% (2315 words)
# {5=>277, 4=>1063, 3=>929, 2=>19, 6=>27}

#1: 0
#2: 54
#3: 1113
#4: 1091
#5: 57
#6: 0
#Average guesses: 3.4971922246220304

require './stats.rb'
require './status.rb'

$w_list = File.readlines("wlist").map(&:chomp).freeze
$allowed_list = File.readlines("allowedlist").map(&:chomp).freeze
$full_list = $w_list + $allowed_list.freeze
$alphabet = ('a'..'z').to_a.freeze
# best initials are reais:168 aesir:168 raise:168 serai:168 arise:168
$initial_guess = "roate"
# "arise" 116 #"roate" 79 #"aesir" 109 # "oater" 100 #"reais" 105 #"serai" 130 # "raise" 107

def freq_of_letters(letters, in_words, in_positions = [0,1,2,3,4])
  freqs = {}
  letters.each do |letter|
    freqs[letter] = 0
  end
  
  letters.each do |letter|
    in_words.each do |w|
      in_positions.each do |op|
        if w[op] == letter
          freqs[letter] += 1
          break
        end
      end
    end
  end
  
  freqs
end

def words_containing_letter(letter, words)
  words.select {|w| w.include?(letter)}
end

def words_containing(letters, words)
  found_words = words
  letters.each do |letter|
    found_words = words_containing_letter(letter, found_words)
  end
  found_words
end

def words_containing_letters_in(letters, words)
#  words.grep(Regexp.new("[#{letters.join}]{5}")) # slower
  words.select do |word|
    word.chars.all? {|c| letters.include?(c)}
  end 
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

def initial_guess
  return $initial_guess if $initial_guess
  freqs = freq_of_letters($alphabet, $w_list)
  top_letters = freqs.sort_by {|k, v| -v}
  letters = top_letters[0..4].map(&:first)
  $initial_guess = words_containing(letters, $full_list).first
end

def elimination_guess(status, prio_letters = nil)
  poss_words = status.possible_words
  freqs = freq_of_letters(status.untried_letters, poss_words, status.open_positions)
  top_letters = freqs.sort_by {|k, v| -v}.map(&:first)
  top_letters = prio_letters + top_letters if prio_letters
  letters = top_letters[0..4]
  words = words_containing(letters, $full_list)
  sel = 5

  while words.empty? && sel < top_letters.count
    perms = top_letters[0..sel].combination(5) do |letters|
      words = words_containing(letters, $full_list)
      break unless words.empty?
    end
    sel += 1
  end

  words = poss_words if words.empty?
  words.first
end

def ideal_guess(status)
  words = status.possible_words
  all_words_letters = words.map(&:chars).reduce(&:|)
  # make sure possible words are first in the list as they are more likely to succeed
  extended_list = (words + words_containing_letters_in(all_words_letters | ["e","t"], $full_list)).uniq
  scores = {}
  extended_list.each do |word|
    score = 0
    min = scores.values.min || words.count * words.count
    words.each do |answer_word|
      _status = status.dup
      result = status.test(word, answer_word)
      _status.add_guess(word, result)
      new_word_count = _status.possible_words_count
      score += new_word_count
      break if score > min
    end
    scores[word] = score
    break if score <= words.count && words.include?(word)
  end
  best_score = scores.values.min
  best_words = scores.select {|k,v| v == best_score}.map {|t| t.first}
  best_words = best_words.sort_by {|w| -w.chars.uniq.count}
  best_words_that_are_a_possible = best_words & words
  chosen_words = best_words_that_are_a_possible + best_words

  puts "IDEAL #{scores.sort_by{|k,v| v}.map {|k,v| "#{k}:#{v}"}[0..9].join(" ")}"
  chosen_words
#best_words
end


#Bad words: bevel blown bunch bunny cheer chili croup daddy daunt ember expel ferry fewer fiber fight filly finch 
#finer folly freak freed freer fried fudge fully funny fuzzy giddy golly goner happy hyper jaunt jazzy jiffy 
#jolly lucky mammy nanny never ninny parer patch perky picky pluck poker pouch proxy puppy shelf tatty taunt wafer witty wound

def do_guess(status, guess, theword, comment = nil)
  puts [guess, comment].join(" ")
  result = status.test(guess, theword)
  puts result
  status.add_guess(guess, result)
  result
end

def run_word_list(w_list)
  stats = Stats.new
  cache = {} # speed up second guess
  
  w_list.each do |theword|
    status = Status.new
  
    # first guess, always the same
    guesses = 1
    guess = initial_guess
    do_guess(status, guess, theword)
    
    # second guess to eliminate letters unless the first guess was super lucky
    if false #status.guessed_letters_count < 4
      guesses += 1
      guess = cache[status.hash] || elimination_guess(status)
      cache[status.hash] = guess
      do_guess(status, guess, theword)
    end
    
    result = "-----"
    while(result != "xxxxx") do
      guesses += 1
      words = status.possible_words
      
      if cache[status.hash]
        guess = cache[status.hash]
      else
        if words.count > 2
          guess = ideal_guess(status).first
        else
          guess = words.last

          if words.count == 2
            stats.bad_pairs << {theword => words}
            differing_letters = []
            a, b = words
            0.upto(4){|n| differing_letters << n if a[n] != b[n]}
            if differing_letters.count == 1
              differing_letter = differing_letters[0]
              if a[differing_letter].ord < b[differing_letter].ord
                guess = words.first
              end
            end
          end
        end
        cache[status.hash] = guess
      end

      # check whether to change strategy to eliminating letters
      if false #status.elimination_needed?(words)
        puts "ELIMINATE #{words.join(" ")}"
        letters_known = (status.letters_not_in_position + status.letters_in_position).map(&:first)

        letters_to_test = words.map do |word|
          letters = letters_known.dup
          word.chars.reject do |c|
            i = letters.index(c)
            letters.delete_at(i) if i
            i
          end
        end.flatten.uniq
        
        all_words_letters = words.map(&:chars).reduce(&:&)
        letters_to_test -= all_words_letters

        if letters_to_test.count < 2
#          puts "NOT ENOUGH LETTERS TO TEST"
        else
          elim_guess = elimination_guess(status, letters_to_test)
  
          if (elim_guess.split("") & letters_to_test).count > 1
            guess = elim_guess 
          else
            puts "FAILED TO FIND ELIM WORD (#{elim_guess})"
          end
        end
      end
  
      if guess.nil? # this should never happen
        puts "NO WORDS LEFT (#{theword})"
        pp status.letters
        exit 1
      end
      
      result = do_guess(status, guess, theword, "(#{words.count} #{words.join(" ")})")
    end
  
    stats.update(guesses)
    stats.report
    stats.bad_words << theword if guesses >= 5 # check and fix any failure to win
  end
  stats
end

if !ARGV.empty?
  w_list = ARGV
else
  w_list = $w_list
end

if w_list.count <= 5
  stats = run_word_list(ARGV)
  stats.final_report
  exit
end

process_count = 8
lists = w_list.each_slice(w_list.count / process_count + 1).to_a
read_ends = []
write_ends = []
lists.each do |list|
  read_stream, write_stream = IO.pipe
  Process.fork do 
    stats = run_word_list(list)
    write_stream.write(Marshal.dump(stats))
  end
  read_ends << read_stream
  write_ends << write_stream
end
Process.waitall
write_ends.each(&:close)

stats = Stats.new
read_ends.each do |read_end|
  stats.add(Marshal.load(read_end.read))
end
stats.final_report
