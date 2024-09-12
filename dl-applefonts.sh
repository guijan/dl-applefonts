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

	while getopts Dho: o; do
		case $o in
			D)	set -vx;;
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

	# Order by size to speed up debugging.
	getfont 'SF Arabic'
	getfont 'SF Mono'
	getfont 'NY'
	getfont 'SF Compact'
	getfont 'SF Pro'
}

# err: print an error message and error exit
err()
{
	printf '%s: %s\n' "$progname" "$1"
	exit 1
}

usage()
{
	printf 'usage:\t%s [-Dh] [-o outdir]\n' "$progname"
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
	filt="${filt}Fonts" 
	7z -so e "$infile" "$filt/$font Fonts.pkg" > "$outfile"
	swap

	# p7zip 16.02 has incomplete xar support, it can only extract the payload, 
	# and it extracts the payload and gzip decompresses it.
	# p7zip 24.07 has complete xar support, it extracts everything in the xar, 
	# and it doesn't gzip decompress the payload.
	# In 16.02, the payload is named 'Payload~'
	# In 24.07, the payload is named 'SFArabicFonts.pkg/Payload' (or equivalent 
	# for other fonts).
	7z -so e "$infile" "${filt}.pkg/Payload" > "$outfile"
	outsize="$(wc -c "$outfile" | awk '{print $1}')"
	if [ "$outsize" -ne 0 ]; then
		# New p7zip.
		swap
	fi
	7z -so e "$infile" > "$outfile"
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
	7z -y -o"$outdir/AppleFonts/$font" e "$infile" "./Library/Fonts/*.$ext" \
		>/dev/null
}

# download(): download $2 to $1
if command -v curl >/dev/null; then
	download()
	{
		curl -o "$1" "$2"
	}
elif command -v wget >/dev/null; then
	download()
	{
		wget -O "$1" "$2"
	}
elif command -v fetch >/dev/null; then
	download()
	{
		fetch -ao "$1" "$2"
	}
elif command -v ftp >/dev/null && [ "$(uname -s)" != "FreeBSD" ]; then
	download()
	{
		# A lot of ftp commands out there don't support HTTPS, so leave it last.
		ftp -o "$1" "$2"
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
