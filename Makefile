VER=1.4.2

release:
	tar zcf ../cad-$(VER).tar.gz --exclude=.svn *.php *.inc *.css *.sql *.sh README CHANGES VERSION Makefile Logos Images font js *.example
