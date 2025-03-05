#!/bin/bash
#
# version.sh - Script for managing semantic versioning
#

# Get current version from mix.exs
get_current_version() {
  grep 'version:' mix.exs | sed -E 's/.*version: "([^"]+)".*/\1/'
}

# Calculate next version
calculate_next_version() {
  local version_type="$1"
  local current_version=$(get_current_version)
  local major=$(echo $current_version | cut -d. -f1)
  local minor=$(echo $current_version | cut -d. -f2)
  local patch=$(echo $current_version | cut -d. -f3)
  
  case "$version_type" in
    patch)
      echo "$major.$minor.$((patch + 1))"
      ;;
    minor)
      echo "$major.$((minor + 1)).0"
      ;;
    major)
      echo "$((major + 1)).0.0"
      ;;
    *)
      echo "Invalid version type: $version_type" >&2
      exit 1
      ;;
  esac
}

# Update version in mix.exs
update_version() {
  local current_version=$(get_current_version)
  local new_version="$1"
  
  sed -i.bak "s/version: \"$current_version\"/version: \"$new_version\"/" mix.exs && rm mix.exs.bak
  echo "Version bumped from $current_version to $new_version"
}

# Check for clean git state
check_git_clean() {
  if [ -n "$(git status --porcelain)" ]; then
    echo "Error: There are uncommitted changes. Please commit or stash them first."
    exit 1
  fi
  
  if [ -n "$(git log @{u}.. 2> /dev/null)" ]; then
    echo "Error: There are unpushed commits. Please push them first with 'git push'."
    exit 1
  fi
}

# Create and push a release
create_release() {
  local version_type="$1"
  
  # Check for clean git state
  check_git_clean
  
  # Calculate new version
  local new_version=$(calculate_next_version "$version_type")
  
  # Update version in mix.exs
  update_version "$new_version"
  
  # Commit and tag
  git add mix.exs
  git commit -m "Bump version to $new_version"
  git tag -a "v$new_version" -m "Release v$new_version"
  
  # Push commit and tag
  git push && git push origin --tags
  
  echo "Tagged and pushed as v$new_version"
}

# Show version information
show_version_info() {
  local current_version=$(get_current_version)
  local next_patch=$(calculate_next_version "patch")
  local next_minor=$(calculate_next_version "minor")
  local next_major=$(calculate_next_version "major")
  
  echo "Current version: $current_version"
  echo
  echo "Next versions:"
  echo "  Patch: $next_patch (make release-patch)"
  echo "  Minor: $next_minor (make release-minor)"
  echo "  Major: $next_major (make release-major)"
}

# Main
case "$1" in
  get)
    get_current_version
    ;;
  next)
    calculate_next_version "$2"
    ;;
  update)
    update_version "$2"
    ;;
  release)
    create_release "$2"
    ;;
  info)
    show_version_info
    ;;
  *)
    echo "Usage: $0 {get|next|update|release|info}"
    exit 1
    ;;
esac