# ---
# tags: context, nushell
# crystal-type: source
# crystal-domain: cyber
# ---
# build.nu — generate ctx.md at 64k tokens
#
# Target: Claude Sonnet (half the 200k window — leaves room for dialogue)
#
# Usage:
#   nu build.nu                            # build ctx.md
#   nu build.nu --cyber-path ~/my/cyber    # custom graph path

def main [
  --cyber-path: string = "",
] {
  let graph = if $cyber_path == "" {
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let parent = ($script_dir | path dirname)
    let candidate = $"($parent)/cyber"
    if ($candidate | path exists) { $candidate } else { "~/git/cyber" | path expand }
  } else {
    $cyber_path
  }

  let out_file = ($env.CURRENT_FILE | path dirname | path join "ctx.md")
  let context_script = $"($graph)/analizer/context.nu"

  if not ($context_script | path exists) {
    print $"ERROR: context.nu not found at ($context_script)"
    return
  }

  let repo_root = ($env.CURRENT_FILE | path dirname)
  let soul_path = $"($repo_root)/SOUL.md"
  let has_soul = ($soul_path | path exists)

  # cyberia docs to always include regardless of gravity score
  let pinned = [
    "root/cyberia/midao/dev.md"
    "root/cyberia/architecture.md"
    "root/cyberia/system.md"
    "root/cyberia/whitepaper.md"
    "root/cyberia/maps.md"
    "root/cyberia/midao.md"
  ]

  print $"Graph: ($graph)"
  print $"Output: ($out_file)"
  print $"Pinned: ($pinned | length) cyberia pages"
  print ""

  let nu_bin = (["/opt/homebrew/bin/nu" "/usr/local/bin/nu"] | where {|p| $p | path exists} | first)
  let pinned_json = ($pinned | to json)

  if $has_soul {
    ^$nu_bin $context_script $graph --budget 64 --soul $soul_path --pinned $pinned_json -o $out_file
  } else {
    ^$nu_bin $context_script $graph --budget 64 --pinned $pinned_json -o $out_file
  }

  let size_kb = ((open --raw $out_file | str length) / 1024 | math round -p 0)
  print $"Done: ($out_file) ($size_kb) KB"
}
