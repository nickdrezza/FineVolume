.PHONY: build test package clean

build:
	swift build

test:
	swift run FineVolumeCoreChecks

package:
	./Scripts/package.sh

clean:
	swift package clean
	rm -rf dist
