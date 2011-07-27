export DIR=/usr/src/redhat
export SOURCES=SOURCES
export RPMS=RPMS

all:
	@(cd ../rpms && $(MAKE) $@)
	rpmbuild -ba onecontext.spec

