# Wordle solver

This code finds an efficient way to solve every possible wordle puzzle, or a list of puzzles passed to it. The wordlist passed to the solver should contain puzzle answers that are contained in the file wlist.

Usage

```
ruby solve.rb [-i | wordlist]
```

Pass -i to enter interactive mode.
Scores are entered like ```-x-oo``` where x indicates an exact match, and o indicates a incorrectly placed match.

## Results

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

## Algorithm

The solver works out the next guess by choosing the word that results in, on average (after checking all possible solutions), fewest solution word possibilities in the next round.

## Speed

The solver runs all 2315 possible puzzles in about 10.8s on my MacBook Air (Ruby 3.1.0).

The solver is quite optimised, with caching in apprioriate places. One thing that didn't work is caching/memoizing the results of Tester#test, which is the most called piece of code of all. The cost of writing to the cache hash was greater than the benefit of the cached results, and it made things slower.

