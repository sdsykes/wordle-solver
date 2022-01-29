class Stats
  attr_reader :counts
  attr_reader :hard_words
  
  def initialize
    @counts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0}
    @hard_words = []
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
    puts "Hard words (>4 guesses): #{hard_words.join(" ")}"
  end
end
