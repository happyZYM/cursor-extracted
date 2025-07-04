#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if PKGBUILD exists
if [[ ! -f "PKGBUILD" ]]; then
    print_error "PKGBUILD file not found in current directory!"
    exit 1
fi

# Check if required tools are available
for tool in curl jq sha512sum; do
    if ! command -v "$tool" &> /dev/null; then
        print_error "Required tool '$tool' is not installed!"
        exit 1
    fi
done

# Get current version from PKGBUILD
current_version=$(grep -oP '^pkgver=\K[^#]*' PKGBUILD | tr -d '"' | tr -d "'")
print_info "Current version: $current_version"

# Fetch latest version from Cursor API
print_info "Fetching latest version from Cursor API..."
api_response=$(curl -s -L "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest")

if [[ -z "$api_response" ]]; then
    print_error "Failed to fetch version info from API"
    exit 1
fi

# Parse JSON response
latest_version=$(echo "$api_response" | jq -r '.version')
download_url=$(echo "$api_response" | jq -r '.downloadUrl')

if [[ "$latest_version" == "null" || "$download_url" == "null" ]]; then
    print_error "Failed to parse API response"
    print_error "Response: $api_response"
    exit 1
fi

print_info "Latest version: $latest_version"

# Compare versions
if [[ "$current_version" == "$latest_version" ]]; then
    print_success "Already up to date! Current version $current_version is the latest."
    exit 0
fi

print_warning "New version available: $current_version -> $latest_version"
print_info "Updating PKGBUILD automatically..."

# Create temporary directory
temp_dir=$(mktemp -d)
appimage_file="$temp_dir/Cursor-${latest_version}-x86_64.AppImage"

print_info "Downloading new AppImage to calculate SHA512..."
if ! curl -L -o "$appimage_file" "$download_url"; then
    print_error "Failed to download AppImage"
    rm -rf "$temp_dir"
    exit 1
fi

# Calculate SHA512
print_info "Calculating SHA512..."
new_sha512=$(sha512sum "$appimage_file" | cut -d' ' -f1)
print_info "New SHA512: $new_sha512"

# Clean up temporary file
rm -rf "$temp_dir"

# Update PKGBUILD
print_info "Updating PKGBUILD..."

# Update version
sed -i "s/^pkgver=.*/pkgver=${latest_version}/" PKGBUILD

# Update pkgrel to 1 for new version
sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

# Extract the production ID from the download URL
production_id=$(echo "$download_url" | grep -oP 'production/\K[^/]+')

# Update the source URL
sed -i "s|production/[^/]*/|production/${production_id}/|" PKGBUILD
sed -i "s/Cursor-[0-9.]*-x86_64\.AppImage/Cursor-${latest_version}-x86_64.AppImage/g" PKGBUILD

# Update the first SHA512 in sha512sums_x86_64 (AppImage SHA512)
# Get the current first SHA512 value (on the same line as sha512sums_x86_64=)
old_sha512=$(grep "sha512sums_x86_64=" PKGBUILD | grep -oP "'\\K[^']*")
# Replace only the first SHA512 value
sed -i "0,/${old_sha512}/{s/${old_sha512}/${new_sha512}/}" PKGBUILD

# Verify the update
updated_version=$(grep -oP '^pkgver=\K[^#]*' PKGBUILD | tr -d '"' | tr -d "'")
updated_sha512=$(grep "sha512sums_x86_64=" PKGBUILD | grep -oP "'\\K[^']*")

print_success "PKGBUILD updated successfully!"
print_info "Updated version: $updated_version"
print_info "Updated AppImage SHA512: $updated_sha512"

print_success "Update completed successfully!"
print_info "You can now run 'makepkg' to build the updated package."

makepkg --printsrcinfo > .SRCINFO
print_success "Updated .SRCINFO"

git add PKGBUILD
git commit -m "Automatically updated to version $updated_version"
git push