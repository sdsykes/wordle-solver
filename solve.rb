# current best

# 1: 0
# 2: 55
# 3: 1130
# 4: 1090
# 5: 40
# 6: 0
# Average guesses: 3.4816414686825055

require './stats.rb'
require './status.rb'
require './guesser.rb'
require './tester.rb'
require './cache.rb'

W_LIST = File.readlines("wlist").map(&:chomp).freeze
allowed_list = File.readlines("allowedlist").map(&:chomp)
FULL_LIST = (W_LIST + allowed_list).freeze
# This word will be found by the algorithm, but as that takes over 30s we can take a shortcut and specify it
INITIAL_GUESS = "roate".freeze

def do_guess(guess, status, tester, secret_word, comment = nil)
  puts [guess, comment].join(" ")
  result = tester.test(guess, secret_word)
  puts result
  status.add_result(result)
  result
end

def solve(list)
  stats = Stats.new
  cache = Cache.new
  tester = Tester.new
  guesser = Guesser.new(cache: cache, tester: tester)
  
  list.each do |secret_word|
    status = Status.new
  
    guess = guesser.guess(W_LIST, [INITIAL_GUESS], status)
    result = do_guess(guess, status, tester, secret_word)
    word_list = FULL_LIST

    while(result != "xxxxx") do
      possible_words = status.possible_words
      word_list = guesser.next_word_list(possible_words, word_list)
      guess = guesser.guess(possible_words, word_list, status)

      raise "NO WORDS LEFT (#{secret_word})" if guess.nil? 
      
      result = do_guess(guess, status, tester, secret_word, "(#{possible_words.count} #{possible_words.join(" ")})")
    end
  
    stats.update(status.guess_count)
    stats.report
    stats.bad_words << secret_word if status.guess_count >= 5
  end
  stats
end

if !ARGV.empty?
  w_list = ARGV
else
  w_list = W_LIST
end

stats = solve(w_list)
stats.final_report
