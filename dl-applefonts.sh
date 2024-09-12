#!/bin/sh -e

# Copyright (c) 2022, 2024 Guilherme Janczak <guilherme.janczak@yandex.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

readonly progname="${0##*/}"
outdir="${XDG_DATA_HOME:-"$HOME/.local/share"}/fonts"

# This script downloads Apple's system fonts from Apple's website and installs
# them.
main()
{
	if ! command -v 7z >/dev/null; then
		err "p7zip dependency missing"
	fi

	while getopts ho: o; do
		case $o in
			h)	usage; rval=0;;
			o)	outdir="$OPTARG";;
			?)	exit 1;;
		esac
	done
	shift $((OPTIND - 1))
	if [ "$*" ]; then
		err "extraneous non-option arguments: '$*'"
	fi
	if [ "$rval" ]; then
		exit "$rval"
	fi

	trap cleanup EXIT INT TERM
	infile="$(mktemp)"
	outfile="$(mktemp)"

	getfont 'SF Pro'
	getfont 'SF Compact'
	getfont 'SF Mono'
	getfont 'SF Arabic'
	getfont 'NY'
}

# err: print an error message and error exit
err()
{
	printf '%s: %s\n' "$progname" "$1"
	exit 1
}

usage()
{
	printf 'usage:\t%s [-h] [-o outdir]\n' "$progname"
}

# cleanup: clean up before exiting.
# XXX: figure out a clean way to also remove the partial installed files
cleanup()
{
	rval="$?"
	rm -f "$infile" "$outfile"
	exit "$rval"
}

# getfont: download and install Apple font
#
# $1: one of {SF Pro, SF Compact, SF Mono, SF Arabic, NY}.
#
# global variable $outdir: output directory (created by the function if needed).
# global variables $infile $outfile: temporary files.
getfont()
{
	font="$1"

	# The filename of the font's .dmg in Apple's website is the name of the
	# font but with the space if any replaced by a dash.
	dl="$(printf '%s' "$font" | sed 's/ /-/')"
	url="https://devimages-cdn.apple.com/design/resources/download/$dl.dmg"
	download "$infile" "$url"

	# The .dmg file is full of random stuff we don't care about. What we do
	# care about is the .pkg file in it which contains the payload.
	#
	# Look at how the font's name becomes the .pkg's name:
	# font: SF Pro
	# .pkg: SFProFonts/SF Pro Fonts.pkg
	# font: NY
	# .pkg: NYFonts/NY Fonts.pkg
	#
	# The text processing here transforms the font name into the .pkg name.
	filt="$(printf '%s' "$font" | sed 's/ //')"
	filt="${filt}Fonts/$font Fonts.pkg"
	7z -so e "$infile" "$filt" > "$outfile"
	swap

	# Don't need to specify a filter here but I do anyway for strictness.
	7z -so e "$infile" 'Payload~' > "$outfile"
	swap

	# 7z creates the outdir if necessary.
	# The fonts are inside ./Library/Fonts/ in the payload. .ttf and .otf
	# fonts are in there, save for Arabic which only has .ttf, but we only
	# care about .otf.
	if [ "$font" = "SF Arabic" ]; then
		ext=ttf
	else
		ext=otf
	fi
	7z -o"$outdir/AppleFonts/$font" e "$infile" "./Library/Fonts/*.$ext" \
		>/dev/null
}

# download(): download $2 to $1
if command -v ftp >/dev/null && [ "$(uname -s)" != "FreeBSD" ]; then
	download()
	{
		# FreeBSD's ftp(1) doesn't support HTTPS.
		ftp -o "$1" "$2"
	}
elif command -v fetch >/dev/null; then
	download()
	{
		fetch -ao "$1" "$2"
	}
elif command -v curl >/dev/null; then
	download()
	{
		curl -o "$1" "$2"
	}
elif command -v wget >/dev/null; then
	download()
	{
		wget -O "$1" "$2"
	}
else
	err "downloader dependency missing, install any of: curl, wget, fetch, ftp"
fi

# swap(): swap global variables $infile and $outfile
swap()
{
	swap="$infile"
	infile="$outfile"
	outfile="$swap"
	unset swap
}

main "$@"
