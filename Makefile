EXECUTABLE=lambdircd

all: build-plugins build-main

build-plugins:
	ghc -W -isrc plugins/*.hs

build-main:
	ghc -W -isrc src/Main -o $(EXECUTABLE)

clean:
	rm -fv $(EXECUTABLE)
	rm -fv plugins/*.o plugins/*.hi
	find src -name '*.o' -print0 | xargs -0 rm -fv
	find src -name '*.hi' -print0 | xargs -0 rm -fv

test:
	runhaskell -isrc spec/*.hs
