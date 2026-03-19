# Get git repo root
__repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || {
        echo "Not inside a git repo"
        return 1
    }
}

# Return the counterpart parent directory (toggle -slop)
__counterpart_parent() {
    local parent base
    parent="$(dirname "$1")"
    base="$(basename "$parent")"

    if [[ "$base" == *-slop ]]; then
        echo "${parent%-slop}"
    else
        echo "${parent}-slop"
    fi
}

# Return full counterpart repo root path
__counterpart_root() {
    local root parent repo
    root="$1"
    parent="$(__counterpart_parent "$root")"
    repo="$(basename "$root")"
    echo "$parent/$repo"
}

ai()  {
    local root parent base repo
    local rel target_parent target_root

    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "Not inside a git repo" >&2
        return 1
    }

    parent="$(dirname "$root")"
    base="$(basename "$parent")"
    repo="$(basename "$root")"

    # relative path inside repo
    rel="$(realpath --relative-to="$root" "$PWD" 2>/dev/null || true)"
    rel="${rel:+/$rel}"

    if [[ "$base" == *-slop ]]; then
        # Currently in slop → go to human
        target_parent="${parent%-slop}"
        target_root="$target_parent/${repo#slop-}"

        [[ -d "$target_root" ]] || {
            echo "Human workspace not found: $target_root" >&2
            return 1
        }

        cd "$target_root$rel"
        return
    fi

    # Currently in human → go to slop
    target_parent="${parent}-slop"
    target_root="$target_parent/slop-$repo"

    if [[ ! -d "$target_root" ]]; then
        echo "Cloning into $target_root"
        mkdir -p "$target_parent"
        git clone "$root" "$target_root" || return 1
    fi

    mkdir -p "$target_root$rel" 2>/dev/null
    cd "$target_root$rel"
}

function slop_prompt_indicator() {
  local root parent base

  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  parent=$(dirname "$root")
  base=$(basename "$parent")

  if [[ "$base" == *-slop ]]; then
    echo "%F{yellow}[SLOP]%f "
  fi
}
