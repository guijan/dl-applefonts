# dl-applefonts: download and install Apple fonts
## Usage
This program depends on [p7zip](https://github.com/jinfeihan57/p7zip), 
a POSIX shell, a [mktemp](https://man.openbsd.org/mktemp.1) implementation, 
and a downloader program which can be any of BSD ftp,
[curl](https://github.com/curl/curl),
[fetch](https://man.freebsd.org/cgi/man.cgi?query=fetch),
or [wget](https://www.gnu.org/software/wget/).

Simply run the command:
```console
foo@bar$ sh dl-applefonts.sh
```
Apple's fonts will be installed to _$XDG_DATA_HOME/fonts_ by default. The `-o`
option allows specifying a custom directory.

This program has been tested on OpenBSD, but is expected to run on other
systems.
