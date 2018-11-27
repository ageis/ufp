SRCS     = src/ufw $(wildcard src/*.py)
POTFILES = locales/po/ufw.pot
TMPDIR   = ./tmp
SNAPDIR   = ./snap
EXCLUDES = --exclude='.bzr*' --exclude='*~' --exclude='*.swp' --exclude='*.pyc' --exclude='debian' --exclude='ubuntu'
VERSION  = $(shell egrep '^ufw_version' ./setup.py | cut -d "'" -f 2)
SRCVER   = ufw-$(VERSION)
TARBALLS = ../tarballs
TARSRC   = $(TARBALLS)/$(SRCVER)
TARDST   = $(TARBALLS)/$(SRCVER).tar.gz
PYFLAKES = $(TMPDIR)/pyflakes.out
PYFLAKES_EXE = pyflakes

ifndef $(PYTHON)
export PYTHON=python2
endif

all:
	# Use setup.py to install. See README for details
	exit 1

install: all

translations: $(POTFILES)
$(POTFILES): $(SRCS)
	xgettext -d ufw -L Python -o $@ $(SRCS)

mo:
	make -C locales all

test:
	./run_tests.sh -s -i $(PYTHON)

unittest:
	./run_tests.sh -s -i $(PYTHON) unit

coverage:
	# No python3 coverage yet
	#$(PYTHON) ./tests/unit/runner.py
	python -m coverage run ./tests/unit/runner.py

coverage-report:
	# No python3 coverage yet
	#$(PYTHON) ./tests/unit/runner.py
	python -m coverage report --show-missing --omit="tests/*"

syntax-check: clean
	$(shell mkdir $(TMPDIR) && $(PYFLAKES_EXE) src 2>&1 | grep -v "undefined name '_'" > $(PYFLAKES))
	cat "$(PYFLAKES)"
	test ! -s "$(PYFLAKES)"

man-check: clean
	$(shell mkdir $(TMPDIR) 2>/dev/null)
	for manfile in `ls doc/*.8`; do \
		page=$$(basename $$manfile); \
		manout=$(TMPDIR)/$$page.out; \
		echo "Checking $$page for errors... "; \
		PAGER=cat LANG='en_US.UTF-8' MANWIDTH=80 man --warnings -E UTF-8 -l doc/$$page >/dev/null 2> "$$manout"; \
		cat "$$manout"; \
		test ! -s "$$manout" || exit 1; \
		echo "PASS"; \
	done; \

check: syntax-check man-check test unittest

# These are only used in development
clean:
	rm -rf ./build
	rm -rf ./staging
	rm -rf ./tests/testarea ./tests/unit/tmp
	rm -rf $(TMPDIR)
	rm -rf $(SNAPDIR)
	rm -f ./locales/mo/*.mo
	rm -f ./tests/unit/*.pyc ./tests/*.pyc ./src/*.pyc
	rm -rf ./tests/unit/__pycache__ ./tests/__pycache__ ./src/__pycache__
	rm -rf ./.coverage
	rm -f ./ufw               # unittest symlink

evaluate: clean
	mkdir -p $(TMPDIR)/ufw/usr $(TMPDIR)/ufw/etc
	UFW_SKIP_CHECKS=1 $(PYTHON) ./setup.py install --home=$(TMPDIR)/ufw
	PYTHONPATH=$(PYTHONPATH):$(TMPDIR)/ufw/lib/python $(PYTHON) $(TMPDIR)/ufw/usr/sbin/ufw version
	cp ./examples/* $(TMPDIR)/ufw/etc/ufw/applications.d
	# Test with:
	# PYTHONPATH=$$PYTHONPATH:$(TMPDIR)/ufw/lib/python $(PYTHON) $(TMPDIR)/ufw/usr/sbin/ufw ...
	# sudo sh -c "PYTHONPATH=$$PYTHONPATH:$(TMPDIR)/ufw/lib/python $(PYTHON) $(TMPDIR)/ufw/usr/sbin/ufw ..."

devel: evaluate
	cp -f ./tests/defaults/profiles/* $(TMPDIR)/ufw/etc/ufw/applications.d
	cp -f ./tests/defaults/profiles.bad/* $(TMPDIR)/ufw/etc/ufw/applications.d

debug: devel
	sed -i 's/DEBUGGING = False/DEBUGGING = True/' $(TMPDIR)/ufw/lib/python/ufw/util.py

tarball: syntax-check clean translations
	bzr export --format dir $(TARSRC)
	tar -zcv -C $(TARBALLS) $(EXCLUDES) -f $(TARDST) $(SRCVER)
	rm -rf $(TARSRC)


snap: clean
	mkdir $(SNAPDIR)
	python3 ./setup.py install --root=$(SNAPDIR) --install-layout=deb
	chmod 644 $(SNAPDIR)/lib/ufw/*.rules $(SNAPDIR)/etc/ufw/*.rules $(SNAPDIR)/etc/ufw/*.init $(SNAPDIR)/usr/share/ufw/iptables/*.rules
	sed -i 's/IPT_MODULES=.*/IPT_MODULES=""/g' $(SNAPDIR)/etc/default/ufw
	sed -i 's/IPT_SYSCTL=\(.*\)/IPT_SYSCTL="$$SNAP_APP_DATA_PATH\1"/g' $(SNAPDIR)/etc/default/ufw
	sed -i 's,net/ipv4/tcp_sack=,#net/ipv4/tcp_sack=,g'  $(SNAPDIR)/etc/ufw/sysctl.conf
	cp -a ./snappy-packaging/* $(SNAPDIR)
	chmod -R g-w $(SNAPDIR)
	mkdir $(SNAPDIR)/docs
	for manfile in `ls doc/*.8` ; do \
		page=$$(basename $$manfile); \
		manout=$(SNAPDIR)/docs/$$(basename -s .8 $$page); \
		echo "Creating $$page ... "; \
		LANG='C' MANWIDTH=80 man --warnings -E ascii doc/$$page | col -b > "$$manout"; \
	done; \
	for manfile in iptables ip6tables iptables-restore ip6tables-restore ; do \
		manout=$(SNAPDIR)/docs/$$(basename -s .8 $$manfile); \
		echo "Creating $$manfile ... "; \
		LANG='C' MANWIDTH=80 man --warnings -E ascii $$manfile | col -b > "$$manout"; \
	done; \
	snappy build $(SNAPDIR)
