ifeq ($(OS),Windows_NT)
    TARGET = binn-1.0.dll
else ifeq ($(PLATFORM),iPhoneOS)
    TARGET = ios
    CFLAGS += -fPIC
else ifeq ($(PLATFORM),iPhoneSimulator)
    TARGET = ios
    CFLAGS += -fPIC
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        OS = OSX
        TARGET = libbinn.1.dylib
        LINK1  = libbinn.dylib
    else
        TARGET = libbinn.so.1.0
        LINK1  = libbinn.so.1
        LINK2  = libbinn.so
    endif
    CFLAGS += -fPIC
endif

SHORT  = binn
PREFIX = /usr/local

CC     = gcc
STRIP  = strip

.PHONY: test

all: $(TARGET)

ios: libbinn.a libbinn.dylib

libbinn.so.1.0: binn.o
	$(CC) -shared -Wl,-soname,$(LINK1) -o $@ $^
	$(STRIP) $@

libbinn.1.dylib: binn.o
	$(CC) -dynamiclib -install_name "$@" -current_version 1.0.0 -compatibility_version 1.0 -o $@ $^
	$(STRIP) -x $@

libbinn.a: binn.o
	$(AR) rcs $@ $^

libbinn.dylib: binn.o
	$(CC) -dynamiclib -o $@ $^ $(LDFLAGS)
	$(STRIP) -x $@

binn-1.0.dll: binn.o dllmain.o
	$(CC) -shared -Wl,--out-implib,binn-1.0.lib -o $@ $^
	$(STRIP) $@

binn.o: src/binn.c src/binn.h
	$(CC) -Wall $(CFLAGS) -c $<

dllmain.o: src/win32/dllmain.c
	$(CC) -Wall -c $<

install:
ifeq ($(OS),Windows_NT)
	$(error install not supported on Windows)
else ifeq ($(OS),OSX)
	mkdir -p ${PREFIX}/lib
	mkdir -p ${PREFIX}/include
	install -m644 $(TARGET) ${PREFIX}/lib
	install -m644 src/binn.h ${PREFIX}/include
	cd ${PREFIX}/lib && ln -sf $(TARGET) $(LINK1)
else
	mkdir -p ${PREFIX}/lib
	mkdir -p ${PREFIX}/include
	install -m644 $(TARGET) ${PREFIX}/lib
	install -m644 src/binn.h ${PREFIX}/include
	cd ${PREFIX}/lib && ln -sf $(TARGET) $(LINK1)
	cd ${PREFIX}/lib && ln -sf $(TARGET) $(LINK2)
endif

clean:
	rm -f *.o $(TARGET) libbinn.a libbinn.dylib

uninstall:
	rm -f ${PREFIX}/lib/$(LINK1) ${PREFIX}/lib/$(LINK2) ${PREFIX}/lib/$(TARGET) ${PREFIX}/include/binn.h

test: test/test_binn.c test/test_binn2.c src/binn.c
	$(CC) -g -Wall -DDEBUG -o test/test_binn $^
	cd test && ./test_binn
