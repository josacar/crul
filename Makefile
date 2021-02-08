all: bin/crul

bin/crul: crul.cr src/**/*.cr
	shards install
	shards build --release --no-debug --static --link-flags "-lxml2 -llzma"
	@strip bin/crul
	@du -sh bin/crul

clean:
	rm -rf .crystal crul .deps .shards libs

PREFIX ?= /usr/local

install: bin/crul
	install -d $(PREFIX)/bin
	install bin/crul $(PREFIX)/bin
