#! /bin/bash
# Pinned third-party sources for the Pi 5 / Trixie fork (testing branch).
# Update these when you deliberately refresh upstream.

BAP_UPSTREAM_REPO="https://github.com/km4ack/73Linux.git"
BAP_UPSTREAM_SHA="c9a99dafb297387a1713e99dc1e6a3f1963b73fb"

# Hamlib version used when SourceForge scrape fails or is skipped.
BAP_HAMLIB_VERSION="4.6.2"

# Optional SHA256 files live next to downloaded artifacts if you add them later:
#   ${BAPDIR}/data/checksums/*.sha256
BAP_CHECKSUM_DIR="${BAPDIR:-}/data/checksums"

bap_safe_token() {
	# Allow only simple version/tag/filename tokens.
	case "$1" in
		''|*[!A-Za-z0-9._-]*) return 1 ;;
		.*) return 1 ;;
		*) return 0 ;;
	esac
}

bap_clean_source_prefix() {
	local prefix="$1"
	local root="${HOME}/.bap-source-files"
	[ -d "$root" ] || return 0
	bap_safe_token "$prefix" || return 1
	find "$root" -maxdepth 1 -mindepth 1 -type d -name "${prefix}*" -exec rm -rf {} +
}

bap_verify_sha256_if_listed() {
	local file="$1"
	local sumfile="${BAP_CHECKSUM_DIR}/$(basename "$file").sha256"
	if [ -f "$sumfile" ]; then
		(cd "$(dirname "$file")" && sha256sum -c "$sumfile")
	fi
}
