DOCKER_COMPOSE = docker compose
EXEC_PHP = $(DOCKER_COMPOSE) exec -T -u www-data -e PHP_CS_FIXER_IGNORE_ENV=1 php
EXEC_YARN = $(DOCKER_COMPOSE) exec -T -u www-data php yarn --cache-folder=/home/app
EXEC_SYMFONY = $(DOCKER_COMPOSE) exec -T -u www-data php bin/console
EXEC_DB = $(DOCKER_COMPOSE) exec -T db sh -c
COMPOSER = $(EXEC_PHP) composer

.DEFAULT_GOAL := help

help: ## This help dialog.
	@echo "${GREEN}Skeleton${RESET}"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
		isTopic = match(lastLine, /^###/); \
	    if (isTopic) { printf "\n%s\n", $$1; } \
	} { lastLine = $$0 }' $(MAKEFILE_LIST)

docker-compose.override.yaml:
	@cp docker-compose.override.yaml.dist docker-compose.override.yaml

.PHONY: docker-compose.override.yaml

#################################
Docker:

pull: docker-compose.override.yaml
	@echo "\nPulling local images...\e[0m"
	@$(DOCKER_COMPOSE) pull --quiet

build: docker-compose.override.yaml pull ##Build docker
	@echo "\nBuilding local images...\e[0m"
	@$(DOCKER_COMPOSE) build

## Up environment
up: docker-compose.override.yaml ##Up docker
	@$(DOCKER_COMPOSE) up -d --remove-orphans

## Down environment
down: docker-compose.override.yaml ##Down docker
	@$(DOCKER_COMPOSE) kill
	@$(DOCKER_COMPOSE) down --remove-orphans

## View output from all containers
logs: docker-compose.override.yaml ##Logs from docker
	@${DOCKER_COMPOSE} logs -f --tail 0

.PHONY: pull build up down logs

#################################
Project:

## Up the project and load database
install: build up vendor node-modules assets-build db-load-fixtures

## Reset the project
reset: down install

## Start containers (unpause)
start: docker-compose.override.yaml
	@$(DOCKER_COMPOSE) unpause || true
	@$(DOCKER_COMPOSE) start || true

##Stop containers (pause)
stop: docker-compose.override.yaml
	@$(DOCKER_COMPOSE) pause || true

##Install composer
vendor: composer.lock
	@echo "\nInstalling composer packages...\e[0m"
	@$(COMPOSER) install

##Install yarn
node-modules: package.json
	@echo "\nInstalling yarn packages...\e[0m"
	@$(EXEC_YARN) install

## Update composer
composer-update: composer.json
	@echo "\nUpdating composer packages...\e[0m"
	@$(COMPOSER) update

## Clear symfony cache
cc:
	@echo "\nClearing cache...\e[0m"
	@$(EXEC_SYMFONY) c:c
	@$(EXEC_SYMFONY) cache:pool:clear cache.global_clearer

wait-db:
	@echo "\nWaiting for DB...\e[0m"
	@$(EXEC_PHP) php -r "set_time_limit(60);for(;;){if(@fsockopen('db',3306))die;echo \"\";sleep(1);}"

## Watch assets and do live reload
watch: node-modules
	@$(EXEC_YARN) encore dev --watch

## Build assets in dev env
assets-build:
	@$(EXEC_YARN) encore dev

.PHONY: install reset start stop vendor composer-update cc wait-db node-modules

#################################
Database:

## Load database from dump
db-load-fixtures: wait-db
	@echo "\nLoading fixtures from dump...\e[0m"
	@$(EXEC_DB) "mysql --user=root --password=root < /home/app/dump/skeleton.sql"

## Recreate database structure
db-reload-schema: wait-db db-drop db-create db-migrate

## Create database
db-create: wait-db
	@echo "\nCreating database...\e[0m"
	@$(EXEC_SYMFONY) doctrine:database:create --if-not-exists

## Drop database
db-drop: wait-db
	@echo "\nDropping database...\e[0m"
	@$(EXEC_SYMFONY) doctrine:database:drop --force --if-exists

## Generate migration by diff
db-diff: wait-db
	$(EXEC_SYMFONY) doctrine:migration:diff --formatted --allow-empty-diff

## Load migration
db-migrate: wait-db
	@echo "\nRunning migrations...\e[0m"
	@$(EXEC_SYMFONY) doctrine:migration:migrate --no-interaction --all-or-nothing

## Reload fixtures
db-reload-fixtures: wait-db db-reload-schema
	@echo "\nLoading fixtures from fixtures files...\e[0m"
	@$(EXEC_SYMFONY) hautelook:fixtures:load --no-interaction

	@echo "\nCreating dump...\e[0m"
	@$(EXEC_DB) "mysqldump --user=root --password=root --databases skeleton > /home/app/dump/skeleton.sql"

#################################
Test:

## Launch unit test
unit-test:
	@echo "\nLaunching unit tests\e[0m"
	@$(EXEC_PHP) bin/phpunit

## Launch behat
behat: vendor node-modules db-load-fixtures
	@echo "\nLaunching read-only behat tests...\e[0m"
	@$(EXEC_PHP) vendor/bin/behat --strict --format=progress --tags="@read-only"

	@echo "\nLaunching other behat tests...\e[0m"
	@$(EXEC_PHP) vendor/bin/behat --strict --format=progress --tags="~@read-only"

.PHONY: behat

#################################
Quality assurance:

## Launch all quality assurance step
code-quality: security-checker composer-unused yaml-linter xliff-linter twig-linter container-linter phpstan cs eslint db-validate

## Security check on dependencies
security-checker:
	@echo "\nRunning security checker...\e[0m"
	@$(EXEC_PHP) sh -c "local-php-security-checker"

## Phpmd
phpmd:
	@echo "\nRunning phpmd...\e[0m"
	@$(EXEC_PHP) vendor/bin/phpmd src/ text .phpmd.xml

## Check if you have unused dependencies
composer-unused:
	@echo "\nRunning composer unused...\e[0m"
	@$(EXEC_PHP) vendor/bin/composer-unused || true

## Linter yaml
yaml-linter:
	@echo "\nRunning yaml linter...\e[0m"
	@$(EXEC_SYMFONY) lint:yaml src/ config/ fixtures/ docker*

## Linter xliff
xliff-linter:
	@echo "\nRunning xliff linter...\e[0m"
	@$(EXEC_SYMFONY) lint:xliff translations/

## Linter twig
twig-linter:
	@echo "\nRunning twig linter...\e[0m"
	@$(EXEC_SYMFONY) lint:twig templates/

## Container yaml
container-linter:
	@echo "\nRunning container linter...\e[0m"
	@$(EXEC_SYMFONY) lint:container

## PHPStan with higher level
phpstan:
	@echo "\nRunning phpstan...\e[0m"
	@$(EXEC_PHP) vendor/bin/phpstan analyse src/ --level 8

## Show cs fixer error
cs:
	@echo "\nRunning cs fixer in dry run...\e[0m"
	@$(EXEC_PHP) vendor/bin/php-cs-fixer fix --dry-run --using-cache=no --verbose --diff --config=php-cs-fixer.dist.php

## Fix cs fixer error
cs-fix:
	@echo "\nRunning cs fixer...\e[0m"
	@$(EXEC_PHP) vendor/bin/php-cs-fixer fix --using-cache=no --verbose --diff --config=php-cs-fixer.dist.php

eslint: node-modules
	@echo "\nRunning eslint\e[0m"
	@$(EXEC_YARN) run eslint assets/

## Validate db schema
db-validate:
	@echo "\nRunning db validate...\e[0m"
	@$(EXEC_SYMFONY) doctrine:schema:validate

.PHONY: eslint