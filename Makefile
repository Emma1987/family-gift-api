# Misc
.DEFAULT_GOAL = help
.PHONY        : help build up down sh composer sf cc

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	docker compose build --pull --no-cache

up: ## Start the docker hub
	docker compose --env-file .env.local up

down: ## Stop the docker hub
	docker compose down --remove-orphans

sh: ## Connect to the PHP FPM container
	docker compose exec php bash

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	docker compose exec php composer $(c)

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	docker compose exec php bin/console $(c)

cc: c=c:c ## Clear the cache
cc: sf

## —— PHPUnit 🦎 ———————————————————————————————————————————————————————————————
load-fixtures: ## Load all fixtures in test database
	docker compose exec php bin/console doctrine:fixtures:load --env=test

run-test: ## Run PHPUnit test suite
	docker compose exec php bin/console doctrine:fixtures:load --env=test --quiet
	docker compose exec php bin/phpunit
