.PHONY: rubocop spec brakeman docker-build docker-run docker-stop docker-remove
.DEFAULT_GOAL := pre-commit

MAKEFLAGS += --jobs=4

rubocop:
	bin/rubocop -A

spec:
	bundle exec rspec

brakeman:
	bin/brakeman -q --no-pager

pre-commit: rubocop spec brakeman
	@echo "--------------------"
	@echo "✅ All checks passed!"
	@echo "--------------------"

docker-build:
	docker build -t brandcore .

docker-run:
	docker run -p 3000:3000 brandcore

docker-stop:
	docker stop brandcore

docker-remove:
	docker rm brandcore
