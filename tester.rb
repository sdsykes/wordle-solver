class Tester
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
end
