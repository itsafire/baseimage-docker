NAME = nawork/phusion-baseimage
VERSION = 0.9.15

.PHONY: all build build_jessie test tag_latest release ssh

all: build build_jessie

build_jessie:
	./dockerfeed -d image/Dockerfile.jessie image | docker build -t $(NAME)-jessie:$(VERSION) --rm -

build_stretch:
	./dockerfeed -d image/Dockerfile.stretch image | docker build -t $(NAME)-stretch:$(VERSION) --rm -

build:
	docker build -t $(NAME)-wheezy:$(VERSION) --rm image

test:
	env NAME=$(NAME) VERSION=$(VERSION) ./test/runner.sh

tag_latest:
	docker tag $(NAME)-wheezy:$(VERSION) $(NAME)-wheezy:latest 

tag_latest_jessie:
	docker tag $(NAME)-jessie:$(VERSION) $(NAME)-jessie:latest

tag_latest_stretch:
	docker tag $(NAME)-stretch:$(VERSION) $(NAME)-stretch:latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

ssh:
	chmod 600 image/insecure_key
	@ID=$$(docker ps | grep -F "$(NAME):$(VERSION)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		IP=$$(docker inspect $$ID | grep IPAddr | sed 's/.*: "//; s/".*//') && \
		echo "SSHing into $$IP" && \
		ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i image/insecure_key root@$$IP
