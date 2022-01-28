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


def words_containing_letters_in(letters, words)
#  words.grep(Regexp.new("[#{letters.join}]{5}")) # slower
  words.select do |word|
    word.chars.all? {|c| letters.include?(c)}
  end 
end

def ideal_guess(status)
  words = status.possible_words
  all_words_letters = words.map(&:chars).reduce(&:|)
  # make sure possible words are first in the list as they are more likely to succeed
  extended_list = (words + words_containing_letters_in(all_words_letters | ["e","t","a","o","i"], $full_list)).uniq
# e t
#  2: 55
#  3: 1119
#  4: 1088
#  5: 53
#  6: 0
# e t a
#  2: 55
#  3: 1120
#  4: 1093
#  5: 47
#  6: 0
# e t a o
#  2: 55
#. 3: 1120
#. 4: 1094
#. 5: 46
#. 6: 0
# e t a o i
# 2: 55
# 3: 1119
# 4: 1096
# 5: 45
# 6: 0
# e t a o i n
#same
# e t a o i n s
#same
# full
# 2: 46
# 3: 1056
# 4: 1167
# 5: 45
# 6: 1
# e t a o r
# 2: 55
# 3: 1120
# 4: 1094
# 5: 46

  scores = {}
  extended_list.each do |word|
    score = 0
    min = scores.values.min || words.count * words.count
    groups = {}
    words.each do |answer_word|
#      _status = status.dup
      result = status.test(word, answer_word)
      groups[result] ||= 0
      groups[result] += 1
#      _status.add_guess(word, result)
#      new_word_count = _status.possible_words_count
#      score += new_word_count
#      break if score > min
    end
#    scores[word] = score
    scores[word] = groups.values.sum{|v| v * v} #.to_f / groups.values.sum #- (words.include?(word) ? 0.01 : 0)

#    break if score <= words.count && words.include?(word)

    break if scores[word] <= words.count && words.include?(word)
  end
  best_score = scores.values.min
  best_words = scores.select {|k,v| v == best_score}.map {|t| t.first}
  #  2: 56
  #  3: 1122
  #  4: 1084
  #  5: 52
  #  6: 1
  best_words = best_words.sort_by {|w| -w.chars.uniq.count}
#    2: 55
#    3: 1119
#    4: 1088
#    5: 53
#    6: 0

  best_words

#  best_words_that_are_a_possible = best_words & words
#  chosen_words = best_words_that_are_a_possible + best_words
#    2: 56
#    3: 1122
#    4: 1083
#    5: 54
#    6: 0
#  puts "IDEAL #{scores.sort_by{|k,v| v}.map {|k,v| "#{k}:#{v}"}[0..9].join(" ")}"
#  chosen_words
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
    do_guess(status, guess, theword)
        
    result = "-----"
    while(result != "xxxxx") do
      guesses += 1
      words = status.possible_words
      
      guess = cached(cache, status) do |status|
        if words.count > 2
          ideal_guess(status).first
        else
          words.last
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
