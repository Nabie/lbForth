TARGET = c
TDIR = targets/$(TARGET)
TMAKE = $(MAKE) -f$(TDIR)/forth.mk
DEPS = kernel.fth dictionary.fth $(TDIR)/nucleus.fth

GREP = grep -a
ERROR_PATTERNS = -e 'INCORRECT RESULT' -e 'WRONG NUMBER'
EXPECTED_ERRORS = 77


all: forth

forth: .bootstrap $(DEPS)
	$(TMAKE) $@ DEPS="$(DEPS)"

.bootstrap:
	$(MAKE) -ftargets/c/bootstrap.mk
	touch .bootstrap


check: test-errors test-assembler
	test `cat $<` -eq $(EXPECTED_ERRORS)

test-errors: test-output
	$(GREP) $(ERROR_PATTERNS) $< | wc -l > $@

test-output: test/test-input smoke-test
	./forth < $< > $@
	$(GREP) Test-OK $@

test-assembler: test/test-asm.fth targets/x86/asm.fth forth
	echo 'include $< .( Asm-OK )' | ./forth > $@
	$(GREP) Asm-OK $@

smoke-test: forth
	echo 'words cr .( Smoke-OK )' | ./forth > $@
	$(GREP) Smoke-OK $@

clean:
	$(TMAKE) clean
	rm -f .bootstrap test-output test-errors
