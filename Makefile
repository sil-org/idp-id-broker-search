zip: build
	mv main idp-id-broker-search
	zip idp-id-broker-search.zip idp-id-broker-search
	rm -f idp-id-broker-search

build:
	GOOS=linux go build main.go