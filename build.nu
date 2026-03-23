# ---
# tags: context, nushell
# crystal-type: source
# crystal-domain: cyber
# ---
# build.nu — generate cyber context at all standard sizes
#
# Maps to real model context windows:
#   8k    — smallest useful (GPT-3.5 era, local 7B)
#   32k   — standard (GPT-4, local 13B-32B)
#   128k  — extended (Claude Haiku, Gemini, GPT-4 Turbo)
#   200k  — Claude Sonnet default
#   500k  — large context (Claude with 2/3 for dialogue)
#   900k  — full 1M window (Claude Opus, leave room for dialogue)
#   1400k — 2M window (full graph + all subgraphs)
#
# Usage:
#   nu build.nu                            # build all sizes
#   nu build.nu --sizes [128 500 900]      # specific sizes only
#   nu build.nu --cyber-path ~/git/cyber   # custom graph path

def main [
  --cyber-path: string = "",
  --sizes: list<int> = [8, 32, 128, 200, 500, 900, 1400],
  --output-dir: string = "",
] {
  let graph = if $cyber_path == "" {
    # try to find cyber repo relative to this script
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let parent = ($script_dir | path dirname)
    let candidate = $"($parent)/cyber"
    if ($candidate | path exists) { $candidate } else { "~/git/cyber" | path expand }
  } else {
    $cyber_path
  }

  let out = if $output_dir == "" {
    let default = $"($env.CURRENT_FILE | path dirname)/distribution"
    mkdir $default
    $default
  } else {
    $output_dir
  }

  let context_script = $"($graph)/analizer/context.nu"

  if not ($context_script | path exists) {
    print $"ERROR: context.nu not found at ($context_script)"
    return
  }

  # soul preamble — lives at repo root, not in distribution/
  let repo_root = ($env.CURRENT_FILE | path dirname)
  let soul_path = $"($repo_root)/SOUL.md"
  let has_soul = ($soul_path | path exists)
  if $has_soul {
    print $"Soul: ($soul_path)"
  }

  print $"Building cyber context for ($sizes | length) sizes"
  print $"Graph: ($graph)"
  print $"Output: ($out)"
  print ""

  for budget in $sizes {
    let needs_subgraphs = $budget >= 900
    let out_file = $"($out)/($budget)k.md"

    print $"--- ($budget)k ---"

    if $needs_subgraphs and $has_soul {
      nu $context_script $graph --subgraphs --budget $budget --soul $soul_path -o $out_file
    } else if $needs_subgraphs {
      nu $context_script $graph --subgraphs --budget $budget -o $out_file
    } else if $has_soul {
      nu $context_script $graph --budget $budget --soul $soul_path -o $out_file
    } else {
      nu $context_script $graph --budget $budget -o $out_file
    }

    # add CONTEXT.md header to the file
    let content = (open --raw $out_file)
    let size_kb = ($content | str length) / 1024 | math round -p 0
    print $"  → ($out_file): ($size_kb) KB"
    print ""
  }

  # build index
  print "Building index..."
  mut index_lines = ["# Cyber Context — Built Distributions"]
  $index_lines = ($index_lines | append "")
  $index_lines = ($index_lines | append $"Generated: (date now | format date '%Y-%m-%d')")
  $index_lines = ($index_lines | append $"Source: ($graph)")
  $index_lines = ($index_lines | append "")
  $index_lines = ($index_lines | append "| File | Budget | Size | Target |")
  $index_lines = ($index_lines | append "|---|---|---|---|")

  let targets = {
    "8": "local 7B, GPT-3.5"
    "32": "GPT-4, local 13B-32B"
    "128": "Claude Haiku, Gemini, GPT-4 Turbo"
    "200": "Claude Sonnet"
    "500": "Claude large context"
    "900": "Claude Opus 1M"
    "1400": "2M context window"
  }

  for budget in $sizes {
    let file = $"($budget)k.md"
    let path = $"($out)/($file)"
    if ($path | path exists) {
      let size_kb = ((open --raw $path | str length) / 1024 | math round -p 0)
      let target = ($targets | get -o ($budget | into string) | default "custom")
      $index_lines = ($index_lines | append $"| ($file) | ($budget)K tokens | ($size_kb) KB | ($target) |")
    }
  }

  $index_lines | str join "\n" | save -f $"($out)/INDEX.md"
  print "Done."
}
