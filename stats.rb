class Stats
  attr_reader :counts
  attr_reader :bad_words
  
  def initialize
    @counts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0}
    @bad_words = []
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
  end
  
  def add(other)
    1.upto(6) {|n| @counts[n] += other.counts[n]}
    @bad_words += other.bad_words
  end
end
