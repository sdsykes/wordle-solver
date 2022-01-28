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
  filter_letters = words.map(&:chars).flatten | ["t","a","o","i"]
  # make sure possible words are first in the list as they are more likely to succeed
  extended_list = (words + words_containing_letters_in(filter_letters, $full_list)).uniq

  min = words.count * words.count
  best = nil
  extended_list.each do |word|
    score = 0
    result_counts = {}
    words.each do |answer_word|
      result = status.test(word, answer_word)
      result_counts[result] = result_counts[result].to_i + 1
      score += result_counts[result] * 2 - 1
      break if score > min
    end
    min, best = score, word if score < min
    break if score <= words.count && words.include?(word)
  end
  best
end


def do_guess(status, guess, theword, comment = nil)
  puts [guess, comment].join(" ")
  result = status.test(guess, theword)
  puts result
  status.add_guess(guess, result)
  result
end

def cached(cache, status)
  cache[status.hash] or cache[status.hash] = yield(status)
end

def run_word_list(w_list)
  stats = Stats.new
  cache = {} # speed up second guess
  
  w_list.each do |theword|
    status = Status.new
  
    # first guess, always the same
    guesses = 1
    guess = $initial_guess
    result = do_guess(status, guess, theword)
        
    while(result != "xxxxx") do
      guesses += 1
      words = status.possible_words
      
      guess = cached(cache, status) do |status|
        if words.count > 2
          ideal_guess(status)
        else
          words.first
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

if true #w_list.count <= 5
  stats = run_word_list(w_list)
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
