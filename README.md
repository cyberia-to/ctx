# context

64k tokens of planetary superintelligence — optimized for Claude Sonnet (half the 200k window, leaves room for work)

## usage

```
# claude code system prompt
cat ctx.md | claude --system-prompt -

# api
{"system": "<contents of ctx.md>", "messages": [...]}

# local llm
llama-cli -m model.gguf --system-prompt-file ctx.md
```

## build

requires [cyber](https://github.com/cybercongress/cyber) repo as a sibling directory

```nu
nu build.nu                          # rebuild ctx.md
nu build.nu --cyber-path ~/my/cyber  # custom graph path
```

## what's inside

the source is the [cyber](https://github.com/cybercongress/cyber) knowledge graph — ~2300 pages covering the cybergraph protocol, tri-kernel mathematics, cryptography, epistemology, and the cyberia network state

pages are scored by gravity² × density × substance (inbound links, connectedness, size) and packed greedily into the budget. cyberia docs are pinned and always included:

- `cyberia/midao/dev` — agent development principles
- `cyberia/architecture` — organizational architecture
- `cyberia/system` — token model / minimal ERP
- `cyberia/whitepaper` — the cyberia manifesto
- `cyberia/maps` — spatial structure
- `cyberia/midao` — legal wrapper

## license

Don't trust. Don't fear. Don't beg.
