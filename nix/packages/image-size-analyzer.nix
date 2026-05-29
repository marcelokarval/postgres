{
  runCommand,
  makeWrapper,
  dive,
  jq,
  docker,
  coreutils,
  gawk,
  gnused,
  bc,
}:
runCommand "image-size-analyzer"
  {
    nativeBuildInputs = [ makeWrapper ];
    buildInputs = [
      dive
      jq
      docker
      coreutils
      gawk
      gnused
      bc
    ];
  }
  ''
        mkdir -p $out/bin
        cat > $out/bin/image-size-analyzer << 'SCRIPT'
    #!/usr/bin/env bash
    set -euo pipefail

    # Default values
    MULTIGRES=false
    NO_BUILD=false
    ORIOLEDB=false
    OUTPUT_JSON=false
    TIMESTAMP=$(date +%s)
    VERSION=false

    TEMP_DIR="/tmp/image-size-analyzer-$TIMESTAMP"

    show_help() {
      cat << EOF
    Usage: image-size-analyzer [OPTIONS]

    Analyze Docker image sizes for Supabase Postgres images.

    Options:
      --json              Output results as JSON instead of TUI
      --multigres         Enable Multigres
      --no-build          Skip building images, analyze existing ones
      --orioledb          Enable OrioleDB
      --version 15|17     Select Postgres base version
      --help              Show this help message

    Examples:
      image-size-analyzer                                     # Analyze all images
      image-size-analyzer --json                              # Output as JSON
      image-size-analyzer --version 15                        # Analyze only PG15
      image-size-analyzer --version 17                        # Analyze only PG17
      image-size-analyzer --version 17 --multigres            # Analyze only PG17 Multigres
      image-size-analyzer --version 17 --orioledb             # Analyze only PG17 OrioleDB
      image-size-analyzer --version 17 --multigres --orioledb # Analyze only PG17 OrioleDB Multigres
      image-size-analyzer --no-build                          # Skip build step
    EOF
    }

    cleanup() {
      rm -rf "$TEMP_DIR" 2>/dev/null || true
    }
    trap cleanup EXIT

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        --json) OUTPUT_JSON=true;;
        --multigres) MULTIGRES=true;;
        --no-build) NO_BUILD=true;;
        --orioledb) ORIOLEDB=true;;
        --version)
          VERSION=$2
          case $VERSION in
            15|17) ;;
            "")
              echo "Error: --version requires a value"
              show_help
              exit 1
              ;;
            *)
              echo "Uknown version:$VERSION"
              show_help
              exit 1
              ;;
            esac
          shift
          ;;
        --help) show_help && exit 0;;
        *)
          echo "Error: Unknown option: $1"
          show_help
          exit 1
          ;;
      esac
      shift
    done

    # Check Docker is running
    if ! docker info &>/dev/null; then
      echo "Error: Docker daemon is not running"
      exit 3
    fi

    mkdir -p "$TEMP_DIR"

    # Helper to format bytes
    format_bytes() {
      local bytes=$1
      if [[ $bytes -ge 1073741824 ]]; then
        printf "%.2f GB" "$(echo "scale=2; $bytes / 1073741824" | bc)"
      elif [[ $bytes -ge 1048576 ]]; then
        printf "%.2f MB" "$(echo "scale=2; $bytes / 1048576" | bc)"
      elif [[ $bytes -ge 1024 ]]; then
        printf "%.2f KB" "$(echo "scale=2; $bytes / 1024" | bc)"
      else
        printf "%d B" "$bytes"
      fi
    }

    # Build a single image
    build_image() {
      local tag=$1
      shift

      echo "Building $tag..."
      if ! docker build -t "$tag" "$@" . ; then
        echo "Error: Failed to build $tag"
        return 1
      fi
    }

    # Get total image size
    get_total_size() {
      local tag=$1
      docker inspect --format='{{.Size}}' "$tag" 2>/dev/null || echo "0"
    }

    # Get layer info using dive
    get_layers() {
      local tag=$1
      local safe_tag=''${tag//[:\/]/-}
      local output_file="$TEMP_DIR/dive-$safe_tag.json"

      if ! dive "$tag" --json "$output_file" >/dev/null; then
        echo "Warning: dive failed for $tag" >&2
        echo "[]"
        return
      fi

      # Extract layer info from dive output (note: dive uses sizeBytes not size)
      jq -c '[.layer[] | {index: .index, size_bytes: .sizeBytes, command: .command}] | sort_by(-.size_bytes) | .[0:10]' "$output_file" 2>/dev/null || echo "[]"
    }

    # Get directory sizes from dive output
    get_directories() {
      local tag=$1
      local safe_tag=''${tag//[:\/]/-}
      local output_file="$TEMP_DIR/dive-$safe_tag.json"

      if [[ ! -f "$output_file" ]]; then
        echo "[]"
        return
      fi

      # Aggregate file sizes by top-level directory from all layers
      jq -c '
        [.layer[].fileList[] | select(.isDir == false and .size > 0)]
        | group_by(.path | split("/")[0])
        | map({path: ("/" + (.[0].path | split("/")[0])), size_bytes: (map(.size) | add)})
        | sort_by(-.size_bytes)
        | .[0:10]
      ' "$output_file" 2>/dev/null || echo "[]"
    }

    # Get Nix package sizes
    get_nix_packages() {
      local tag=$1

      docker run --rm "$tag" sh -c 'du -sb /nix/store/*/ 2>/dev/null | sort -rn | head -15' 2>/dev/null | \
        awk '{
          size=$1
          path=$2
          # Extract package name from path like /nix/store/abc123-packagename-1.0/
          n=split(path, parts, "/")
          store_path=parts[n-1]  # Get the nix store hash-name part
          # Remove the hash prefix (32 chars + dash)
          if (length(store_path) > 33) {
            name=substr(store_path, 34)
          } else {
            name=store_path
          }
          # Remove trailing slash from name
          gsub(/\/$/, "", name)
          printf "{\"name\":\"%s\",\"size_bytes\":%d}\n", name, size
        }' | jq -s '.' 2>/dev/null || echo "[]"
    }

    # Get system package sizes (handles both Debian/Ubuntu and Alpine)
    get_system_packages() {
      local tag=$1
      local result

      # Try dpkg first (Debian/Ubuntu), then apk (Alpine)
      result=$(docker run --rm "$tag" sh -c '
        if command -v dpkg-query >/dev/null 2>&1; then
          dpkg-query -W -f="''${Package}\t''${Installed-Size}\n" 2>/dev/null | sort -t"	" -k2 -rn | head -15 | awk -F"\t" "{printf \"{\\\"name\\\":\\\"%s\\\",\\\"size_bytes\\\":%d}\\n\", \$1, \$2 * 1024}"
        elif command -v apk >/dev/null 2>&1; then
          # Get all installed packages and their sizes
          # apk info -s outputs "pkg installed size:\nNNNN KiB" with warnings to stdout
          for pkg in $(apk info 2>&1 | grep -v "^WARNING"); do
            size_line=$(apk info -s "$pkg" 2>&1 | grep -E "^[0-9]+ [KMG]iB$")
            # Extract number and unit (e.g., "3214 KiB" -> 3214 * 1024)
            size_num=$(echo "$size_line" | awk "{print \$1}")
            size_unit=$(echo "$size_line" | awk "{print \$2}")
            if [ -n "$size_num" ] && [ "$size_num" -gt 0 ] 2>/dev/null; then
              case "$size_unit" in
                KiB) size_bytes=$((size_num * 1024)) ;;
                MiB) size_bytes=$((size_num * 1024 * 1024)) ;;
                GiB) size_bytes=$((size_num * 1024 * 1024 * 1024)) ;;
                *) size_bytes=$size_num ;;
              esac
              printf "{\"name\":\"%s\",\"size_bytes\":%s}\n" "$pkg" "$size_bytes"
            fi
          done
        else
          echo ""
        fi
      ' 2>/dev/null)

      if [[ -n "$result" ]]; then
        echo "$result" | jq -s 'sort_by(-.size_bytes) | .[0:15]' 2>/dev/null || echo "[]"
      else
        echo "[]"
      fi
    }

    # Analyze a single image
    analyze_image() {
      local tag=$1

      local total_size
      total_size=$(get_total_size "$tag")
      [[ -z "$total_size" || "$total_size" == "" ]] && total_size="0"

      local layers
      layers=$(get_layers "$tag")
      [[ -z "$layers" || "$layers" == "" ]] && layers="[]"

      local directories
      directories=$(get_directories "$tag")
      [[ -z "$directories" || "$directories" == "" ]] && directories="[]"

      local nix_packages
      nix_packages=$(get_nix_packages "$tag")
      [[ -z "$nix_packages" || "$nix_packages" == "" ]] && nix_packages="[]"

      local system_packages
      system_packages=$(get_system_packages "$tag")
      [[ -z "$system_packages" || "$system_packages" == "" ]] && system_packages="[]"

      # Build JSON result for this image
      jq -n \
        --arg tag "$tag" \
        --argjson directories "$directories" \
        --argjson layers "$layers" \
        --argjson nix_packages "$nix_packages" \
        --argjson system_packages "$system_packages" \
        --argjson total_size_bytes "$total_size" \
        '{
          $directories,
          $layers,
          $nix_packages,
          $system_packages,
          $tag,
          $total_size_bytes,
        }'
    }

    # Print TUI output for a single image
    print_tui() {
      local json=$1

      local tag
      tag=$(echo "$json" | jq -r .tag)

      local total_size
      total_size=$(echo "$json" | jq -r '.total_size_bytes')

      echo ""
      echo "================================================================================"
      echo "IMAGE: $tag"
      echo "================================================================================"
      echo "Total Size: $(format_bytes "$total_size")"
      echo ""

      echo "LAYERS (top 10 by size)"
      echo "--------------------------------------------------------------------------------"
      printf "  %-4s %-12s %s\n" "#" "SIZE" "COMMAND"
      echo "$json" | jq -r '.layers[] | "\(.index)\t\(.size_bytes)\t\(.command)"' 2>/dev/null | \
        while IFS=$'\t' read -r idx size cmd; do
          cmd_short=$(echo "$cmd" | cut -c1-60)
          printf "  %-4s %-12s %s\n" "$idx" "$(format_bytes "$size")" "$cmd_short"
        done
      echo ""

      echo "DIRECTORIES (top 10 by size)"
      echo "--------------------------------------------------------------------------------"
      echo "$json" | jq -r '.directories[] | "\(.path)\t\(.size_bytes)"' 2>/dev/null | \
        while IFS=$'\t' read -r path size; do
          printf "  %-45s %s\n" "$path" "$(format_bytes "$size")"
        done
      echo ""

      echo "NIX PACKAGES (top 15 by size)"
      echo "--------------------------------------------------------------------------------"
      echo "$json" | jq -r '.nix_packages[] | "\(.name)\t\(.size_bytes)"' 2>/dev/null | \
        while IFS=$'\t' read -r name size; do
          printf "  %-45s %s\n" "$name" "$(format_bytes "$size")"
        done
      echo ""

      echo "SYSTEM PACKAGES (top 15 by size)"
      echo "--------------------------------------------------------------------------------"
      echo "$json" | jq -r '.system_packages[] | "\(.name)\t\(.size_bytes)"' 2>/dev/null | \
        while IFS=$'\t' read -r name size; do
          printf "  %-45s %s\n" "$name" "$(format_bytes "$size")"
        done
    }

    # Main execution
    main() {
      if [[ $MULTIGRES$ORIOLEDB$VERSION == falsefalsefalse ]]; then
        # all images
        recipes=(
          'supabase-postgres:15 --target=postgres --build-arg=PG_VERSION=15'
          'supabase-postgres:17 --target=postgres --build-arg=PG_VERSION=17'
          'supabase-postgres:orioledb-17 --target=postgres --build-arg=PG_VERSION=17 --build-arg=VARIANT=orioledb'
          'supabase-postgres:orioledb-multigres-17 --target=multigres --build-arg=PG_VERSION=17 --build-arg=VARIANT=orioledb'
          'supabase-postgres:multigres-17 --target=multigres --build-arg=PG_VERSION=17'
        )
      else
        tag=supabase-postgres:
        args=()
        if $ORIOLEDB; then
          tag+=(orioledb-)
          args+=(--build-arg=VARIANT=orioledb)
        fi
        if $MULTIGRES; then
          tag+=(multigres-)
          args+=(--target=multigres)
        else
          args+=(--target=postgres)
        fi
        if [[ $VERSION == false ]]; then
          VERSION=17
        fi
        tag+=$VERSION
        recipes=("$tag ''${args[*]}")
      fi

      # Build images if needed
      if [[ "$NO_BUILD" == "false" ]]; then
        for recipe in "''${recipes[@]}"; do
          build_image $recipe || exit 1
        done
      fi

      # Analyze each image
      declare -a results=()
      for recipe in "''${recipes[@]}"; do
        local tag=''${recipe%% *}

        # Check image exists
        if ! docker image inspect "$tag" &>/dev/null; then
          echo "Error: Image $tag not found. Run without --no-build to build it first."
          exit 1
        fi

        echo "Analyzing $tag..." >&2
        local result
        result=$(analyze_image "$tag")
        results+=("$result")
      done

      # Output results
      if [[ "$OUTPUT_JSON" == "true" ]]; then
        # Combine all results into JSON array
        printf '%s\n' "''${results[@]}" | jq -s '{images: .}'
      else
        for result in "''${results[@]}"; do
          print_tui "$result"
        done
      fi
    }

    main
    SCRIPT
        chmod +x $out/bin/image-size-analyzer
        wrapProgram $out/bin/image-size-analyzer \
          --prefix PATH : ${dive}/bin \
          --prefix PATH : ${jq}/bin \
          --prefix PATH : ${docker}/bin \
          --prefix PATH : ${coreutils}/bin \
          --prefix PATH : ${gawk}/bin \
          --prefix PATH : ${gnused}/bin \
          --prefix PATH : ${bc}/bin
  ''
