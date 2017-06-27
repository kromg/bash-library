
test:
	cd t; \
	for t in *; do \
		/bin/bash $$t; \
	done

test-debug:
	cd t; \
	for t in *; do \
		/bin/bash -x $$t; \
	done

