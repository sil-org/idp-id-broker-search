zip: build
	mv main bootstrap
	zip idp-id-broker-search.zip bootstrap
	rm -f bootstrap

build:
	GOOS=linux go build main.go
