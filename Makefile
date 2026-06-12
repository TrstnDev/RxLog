SCHEME ?= RxLog
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro

.PHONY: build test clean lint

lint:
	swiftlint --fix
	swiftlint lint --strict

build: lint
	xcodebuild clean build \
	-scheme $(SCHEME) \
	-destination '$(DESTINATION)'

test: lint
	xcodebuild test \
	-scheme $(SCHEME) \
	-destination '$(DESTINATION)' \
	-parallel-testing-enabled YES \
	-parallel-testing-worker-count 12

clean:
	xcodebuild clean \
	-scheme $(SCHEME) \
	-destination '$(DESTINATION)'
