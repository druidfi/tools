# About writing tests

Create tests for individual targets, not for chained commands. Chained commands e.g. `@make foobar ENV=production`will
output full path to `make` binary.

## Output files

Output files are the expected outputs from make targets.

Output file can be named what ever, but we use following syntaxes:

- `{target).txt`
- `{target)-{variation}.txt`

Output file structure is following:

```
target
---
output lines
per line
```
