.PHONY: run-en
run-en:
	sml cookbook-en.sml solution.sml tests.sml < /dev/null

.PHONY: run-sl
run-sl:
	sml cookbook-sl.sml solution.sml tests.sml < /dev/null

A2PSFLAGS := -q1RBj

.INTERMEDIATE: instructions-en.ps
instructions-en.ps: cookbook-en.sml
	a2ps $(A2PSFLAGS) $^ -o $@

.INTERMEDIATE: instructions-sl.ps
instructions-sl.ps: cookbook-sl.sml
	a2ps $(A2PSFLAGS) $^ -o $@

instructions-en.pdf: instructions-en.ps
	ps2pdf $^ $@

instructions-sl.pdf: instructions-sl.ps
	ps2pdf $^ $@

.PHONY: instructions
instructions: instructions-en.pdf instructions-sl.pdf

.PHONY: clean
clean:
	rm -f instructions-en.pdf instructions-sl.pdf fpsem1.zip

fpsem1.zip: Makefile cookbook-en.sml cookbook-sl.sml tests.sml solution.sml instructions-en.pdf instructions-sl.pdf
	zip $@ $^

.PHONY: package
package: fpsem1.zip

.PHONY: all
all: package instructions
