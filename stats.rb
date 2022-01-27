class Stats
  attr_reader :counts
  attr_reader :bad_words
  attr_accessor :bad_pairs
  
  def initialize
    @counts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0}
    @bad_words = []
    @bad_pairs = []
  end
  
  def update(guesses)
    @counts[guesses] += 1
    puts "#{guesses} guesses"
  end
  
  def report
    puts "======================"
    tot = @counts.values.sum
    1.upto(6) {|n| print "#{n}:#{"%.1f" % (@counts[n].to_i / tot.to_f * 100)}% "}
    puts "(#{tot} words)"
    puts "======================"
  end
  
  def final_report
    1.upto(6) {|n| puts "#{n}: #{@counts[n]}"}
    puts "Average guesses: #{@counts.sum{|k,v| k * v} / @counts.values.sum.to_f}"
    puts "Bad words: #{bad_words.join(" ")}"
    puts "Pairs: #{bad_pairs.count}"
  end
  
  def add(other)
    1.upto(6) {|n| @counts[n] += other.counts[n]}
    @bad_words += other.bad_words
    @bad_pairs += other.bad_pairs
  end
end
