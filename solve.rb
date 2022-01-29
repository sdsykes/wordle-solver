# current best

# 1: 0
# 2: 55
# 3: 1126
# 4: 1093
# 5: 41
# 6: 0
# Average guesses: 3.4838012958963285

require './stats.rb'
require './status.rb'

$w_list = File.readlines("wlist").map(&:chomp).freeze
$allowed_list = File.readlines("allowedlist").map(&:chomp).freeze
$full_list = $w_list + $allowed_list.freeze
$alphabet = ('a'..'z').to_a.freeze
# best initials are reais:168 aesir:168 raise:168 serai:168 arise:168
$initial_guess = "roate"
# "arise" 116 #"roate" 79 #"aesir" 109 # "oater" 100 #"reais" 105 #"serai" 130 # "raise" 107


def words_containing_letters_in(letters, words)
#  words.grep(Regexp.new("[#{letters.join}]{5}")) # slower
  words.select do |word|
    word.chars.all? {|c| letters.include?(c)}
  end 
end

def ideal_guess(status)
  words = status.possible_words
#  return words.first if words.count <= 2
  
  filter_letters = words.map(&:chars).flatten | ["t","a","o","i"]
  # make sure possible words are first in the list as they are more likely to succeed
  extended_list = (words + words_containing_letters_in(filter_letters, $full_list)).uniq
  
  min = words.count * words.count + 1
  resulting_words = {}
  best = nil
  extended_list.each do |word|
    score = 0
    result_words = {}
    words.each do |answer_word|
      result = status.test(word, answer_word)
      result_words[result] = (result_words[result] || []) << answer_word
      score += result_words[result].count * 2 - 1
      break if score > min
    end
    # send the result_words to the status, it can use them to find possible words when next guess is scored
    min, best, resulting_words = score, word, result_words if score < min
    break if score <= words.count && words.include?(word)
  end

  return best, resulting_words
end


def do_guess(status, guess, theword, comment = nil)
  puts [guess, comment].join(" ")
  result = status.test(guess, theword)
  puts result
  status.add_guess(guess, result)
  result
end

def cached(cache, status)
  cache[status.hash] or cache[status.hash] = yield
end

def run_word_list(w_list)
  stats = Stats.new
  cache = {}
  
  w_list.each do |theword|
    status = Status.new
  
    guesses = 1
    guess, resulting_words = cached(cache, status) {ideal_guess(status)}
    status.prev_resulting_words = resulting_words
    result = do_guess(status, guess, theword)

    while(result != "xxxxx") do
      guesses += 1
      words = status.possible_words
      guess, resulting_words = cached(cache, status) {ideal_guess(status)}
      status.prev_resulting_words = resulting_words

      raise "NO WORDS LEFT (#{theword})" if guess.nil? 
      
      result = do_guess(status, guess, theword, "(#{words.count} #{words.join(" ")})")
    end
  
    stats.update(guesses)
    stats.report
    stats.bad_words << theword if guesses >= 5
  end
  stats
end

if !ARGV.empty?
  w_list = ARGV
else
  w_list = $w_list
end

stats = run_word_list(w_list)
stats.final_report
exit


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
