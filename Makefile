.PHONY: rubocop spec brakeman docker-build docker-run docker-stop docker-remove
.DEFAULT_GOAL := pre-commit

MAKEFLAGS += --jobs=4

rubocop:
	bin/rubocop -A

spec:
	CI=1 bin/rspec

brakeman:
	bin/brakeman -q --no-pager

pre-commit: rubocop spec brakeman
	@echo "--------------------"
	@echo "✅ All checks passed!"
	@echo "--------------------"

cache-google-fonts:
	@GOOGLE_FONTS_API_KEY="op://Private/Google Fonts API Key/credential" op run -- \
		bundle exec rails r 'GoogleFontsService.build_static_source'
	
dev:
	@OPENAI_API_KEY="op://Employee/Brand Core OpenAI Developer Key/credential" op run --account nivoventures -- \
		bin/dev

update-trait-embeddings:
	@OPENAI_API_KEY="op://Employee/Brand Core OpenAI Developer Key/credential" op run --account nivoventures -- \
		bundle exec rake brand_color_palette:generate_trait_embeddings

docker-build:
	docker build -t brandcore .

docker-run:
	docker run -p 3000:3000 brandcore

docker-stop:
	docker stop brandcore

docker-remove:
	docker rm brandcore
