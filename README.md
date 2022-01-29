# Wordle solver

This code finds an efficient way to solve every possible wordle puzzle, or a list of puzzles passed to it. The wordlist passed to the solver should contain puzzle answers that are contained in the list in the file wlist.

Usage

```
ruby solve.rb [wordlist]
```

##Results

The solver solves all puzzles in 5 guesses or less. Here are the stats for each number of guesses (for all 2315 possible puzzles)

```
======================
1:0.0% 2:2.4% 3:48.8% 4:47.1% 5:1.7% 6:0.0% (2315 words)
======================
1: 0
2: 55
3: 1130
4: 1090
5: 40
6: 0
Average guesses: 3.4816414686825055
```

##Algorithm

The solver works out the next guess by choosing the word that results in, on average, fewest possible words for the next guess.
It does this by checking the results for all possible answers, and checking the average number of words that are the result of the same score (where by score I mean the number and placement of green/yellow/grey letters).

##Speed

The solver runs all 2315 possible puzzles in about 18.5s on my MacBook Air.