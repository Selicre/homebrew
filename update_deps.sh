#!/bin/sh


yikes() {
	tput setaf 1
	tput bold
	echo -n "Error: "
	tput sgr0
	echo $1
	exit $2
}
info() {
	tput setaf 2
	tput bold
	echo $1
	tput sgr0
}

test_for_exec() {
	echo "Testing for $1.."
	command -v $1 >/dev/null || yikes "\`$1\` not found; please install it using your package manager or make it accessible with \$PATH." 1
}
update_repo() {
	echo "Updating $2.."
	git clone $1 $2 2>/dev/null || (cd $2; git pull) || yikes "Failed to fetch dependancy $2. This isn't nice." 3
}
mkdir -p deps || yikes "You don't have write permissions for this directory." 5
mkdir -p build

info "Testing system dependancies.."
test_for_exec git
test_for_exec cargo
test_for_exec rustup
echo "Testing for nightly Rust toolchain.."
rustup show | grep "nightly" >/dev/null || yikes "You don't have to seem the nightly toolchain for rust installed, which is required to build piped-asm. Please install it using \`rustup toolchain install nightly\`." 2
rustup override set nightly

info "Updating dependancies.."
(
cd deps
update_repo https://hyper.is-a.cat/gogs/x10A94/snesgfx snesgfx
update_repo https://hyper.is-a.cat/gogs/x10A94/tiled tiled
update_repo https://github.com/x10A94/piped-asm piped-asm
)
info "Building binaries.."
cargo build --all-targets --release --manifest-path=deps/snesgfx/Cargo.toml || yikes "Failed to build snesgfx. This isn't nice." 4
cargo build --all-targets --release --manifest-path=deps/piped-asm/Cargo.toml || yikes "Failed to build piped-asm. This isn't nice." 4
