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

def solve(list, all_answers, all_allowed_guesses)
  stats = Stats.new
  cache = Cache.new
  tester = Tester.new
  guesser = Guesser.new(cache: cache, tester: tester)
  
  list.each do |secret_word|
    status = Status.new
  
    guess = guesser.guess(all_answers, [INITIAL_GUESS], status)
    result = do_guess(guess, status, tester, secret_word)
    word_list = all_allowed_guesses

    while(result != "xxxxx") do
      possible_words = status.possible_words
      word_list = guesser.next_word_list(possible_words, word_list)
      guess = guesser.guess(possible_words, word_list, status)

      raise "NO WORDS LEFT (#{secret_word})" if guess.nil?
      
      result = do_guess(guess, status, tester, secret_word, "(#{possible_words.count} #{possible_words.join(" ")})")
    end
  
    stats.update(status.guess_count)
    stats.report
    stats.hard_words << secret_word if status.guess_count >= 5
  end
  stats
end

def do_interactive_guess(guess, status)
  puts guess
  result = $stdin.gets.chomp
  while result !~ /^[ox-]{5}$/
    puts "Bad result string, must match ^[-ox]{5}$"
    result = $stdin.gets.chomp
  end
  status.add_result(result)
  result
end

def interactive_solve(all_answers, all_allowed_guesses)
  cache = Cache.new
  tester = Tester.new
  guesser = Guesser.new(cache: cache, tester: tester)
  status = Status.new
  
  guess = guesser.guess(all_answers, [INITIAL_GUESS], status)
  result = do_interactive_guess(guess, status)
  word_list = all_allowed_guesses

  while(result != "xxxxx") do
    possible_words = status.possible_words

    raise "NO POSSIBLE WORDS" if possible_words.nil?

    if possible_words.count == 1 # shortcut when game is won
      puts possible_words[0], "xxxxx"
      return
    end

    word_list = guesser.next_word_list(possible_words, word_list)
    guess = guesser.guess(possible_words, word_list, status)
    result = do_interactive_guess(guess, status)
  end
end

if ARGV[0] == "-i"
  interactive_solve(W_LIST, FULL_LIST)
else
  to_solve = ARGV.empty? ? W_LIST : ARGV
  stats = solve(to_solve, W_LIST, FULL_LIST)
  stats.final_report
end
