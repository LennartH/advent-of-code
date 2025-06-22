### Notes

#### Runtime / Performance

- Performance counter stats: `perf stat -r 10 -B <cmd>`
- Output cleanup:
  - regex: `(\d+\.\d+ \+- \d\.\d+ seconds)[\w ]+\s\s\( \+-  (\d\.\d+%) \)`
  - substitution: `$1 (+- $2)`