#!/usr/bin/env sh
# Build the site and publish it to Cloudflare Pages (project: pressenter).
#
# The duckquill theme pinned in themes/ does not build on Zola 0.23+, and
# zola.toml (rather than config.toml) needs 0.22+, so the build is pinned to
# 0.22.1. If the zola on PATH is a different version, a pinned copy is
# downloaded into .tools/ and used instead.
set -eu

ZOLA_VERSION=0.22.1
PROJECT=pressenter
cd "$(dirname "$0")"

if [ ! -f themes/duckquill/theme.toml ]; then
	echo "==> initialising theme submodule"
	git submodule update --init --recursive
fi

resolve_zola() {
	if [ -n "${ZOLA:-}" ]; then
		echo "$ZOLA"; return
	fi
	if command -v zola >/dev/null 2>&1 && \
	   [ "$(zola --version)" = "zola $ZOLA_VERSION" ]; then
		command -v zola; return
	fi
	pinned=".tools/zola-$ZOLA_VERSION/zola"
	if [ ! -x "$pinned" ]; then
		case "$(uname -s)-$(uname -m)" in
			Darwin-arm64)  target=aarch64-apple-darwin ;;
			Darwin-x86_64) target=x86_64-apple-darwin ;;
			Linux-x86_64)  target=x86_64-unknown-linux-gnu ;;
			*) echo "no pinned zola for $(uname -s)-$(uname -m); set ZOLA=/path/to/zola" >&2; exit 1 ;;
		esac
		echo "==> fetching zola $ZOLA_VERSION ($target)" >&2
		mkdir -p "$(dirname "$pinned")"
		curl -fsSL "https://github.com/getzola/zola/releases/download/v$ZOLA_VERSION/zola-v$ZOLA_VERSION-$target.tar.gz" \
			| tar xz -C "$(dirname "$pinned")"
	fi
	echo "$pinned"
}

zola_bin=$(resolve_zola)
echo "==> building with $("$zola_bin" --version)"
rm -rf public
"$zola_bin" build

echo "==> deploying to Cloudflare Pages project '$PROJECT'"
wrangler pages deploy public --project-name="$PROJECT" --commit-dirty=true
