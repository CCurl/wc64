COMP := fasm
opts := -m 65536 -d FOR_OS=LINUX

all: wc64

wc64: wc64.asm
	$(COMP) $(opts) wc64.asm
	chmod +x wc64
	ls -l wc64

force: clean wc64

clean:
	rm -f wc64

run: wc64
	./wc64

test:
	cat test.fth | ./wc64

bin: wc64
	cp -u -p wc64 ~/.local/bin/
