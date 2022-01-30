class Tester
  def test(word, secret_word)
    result = "-----"
    test_word = word.chars
    answer_word = secret_word.chars

    0.upto(4) do |n|
      if test_word[n] == answer_word[n]
        result[n] = "x"
        answer_word[n] = nil
        test_word[n] = false
      end
    end

    0.upto(4) do |n|
      i = answer_word.index(test_word[n])
      if i
        result[n] = "o"
        answer_word[i] = nil
      end
    end

    result
  end
end
