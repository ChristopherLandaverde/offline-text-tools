# Evaluation

Quality should be measured with a local test set before trusting auto-apply behavior.

## Test Set

Track examples with:

- `input`
- `task`
- `expected`
- `notes`
- `risk`

Include:

- short English grammar mistakes
- short Portuguese grammar mistakes
- already-correct text
- informal text that should stay informal
- mixed English and Portuguese text

## Pass Criteria

Each output should be reviewed for:

- meaning preserved
- grammar improved
- tone preserved
- minimal rewrite
- unchanged when already correct

## Failure Signals

- meaning drift
- excessive rewrite
- broken accents or punctuation
- changed names, numbers, links, or code
- wrong target language
