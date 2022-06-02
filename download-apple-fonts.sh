#!/bin/sh -e

swap()
{
	swap="$infile"
	infile="$outfile"
	outfile="$swap"
	unset swap
}

infile="$(mktemp)"
outfile="$(mktemp)"

# SF Pro
ftp -o "$infile" \
	https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg

7z -so e "$infile" 'SFProFonts/SF Pro Fonts.pkg' > "$outfile"
swap

# don't need to specify a file here but I do anyway in case the format changes.
7z -so e "$infile" 'Payload~' > "$outfile"
swap

7z -o"$HOME/.local/share/fonts/Apple/SF Pro" e "$infile" \
	'./Library/Fonts/*.otf' > /dev/null


# SF Compact
ftp -o "$infile" \
	https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg

7z -so e "$infile" 'SFCompactFonts/SF Compact Fonts.pkg' > "$outfile"
swap

7z -so e "$infile" 'Payload~' > "$outfile"
swap

7z -o"$HOME/.local/share/fonts/Apple/SF Compact" e "$infile" \
	'./Library/Fonts/*.otf' > /dev/null


# SF Mono
ftp -o "$infile" \
	https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg
7z -so e "$infile" 'SFMonoFonts/SF Mono Fonts.pkg' > "$outfile"
swap

7z -so e "$infile" 'Payload~' > "$outfile"
swap

7z -o"$HOME/.local/share/fonts/Apple/SF Mono" e "$infile" \
	'./Library/Fonts/*.otf' > /dev/null


# SF Arabic

ftp -o "$infile" \
	https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg
7z -so e "$infile" 'SFArabicFonts/SF Arabic Fonts.pkg' > "$outfile"
swap

7z -so e "$infile" 'Payload~' > "$outfile"
swap

# Arabic only has TTF
7z -o"$HOME/.local/share/fonts/Apple/SF Arabic" e "$infile" \
	'./Library/Fonts/*.ttf' > /dev/null


# NY
ftp -o "$infile" \
	https://devimages-cdn.apple.com/design/resources/download/NY.dmg
7z -so e "$infile" 'NYFonts/NY Fonts.pkg' > "$outfile"
swap

7z -so e "$infile" 'Payload~' > "$outfile"
swap

7z -o"$HOME/.local/share/fonts/Apple/New York" e "$infile" \
	'./Library/Fonts/*.otf' > /dev/null


rm "$infile" "$outfile"
