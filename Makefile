DOCKER_COMPOSE = docker-compose
EXEC_PHP = $(DOCKER_COMPOSE) exec -T -u www-data php
EXEC_SYMFONY = $(DOCKER_COMPOSE) exec -T -u www-data php bin/console
EXEC_DB = $(DOCKER_COMPOSE) exec -T db sh -c
QUALITY_ASSURANCE = $(DOCKER_COMPOSE) run --rm quality-assurance
COMPOSER = $(EXEC_PHP) composer

.DEFAULT_GOAL := help

help: ##Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

docker-compose.override.yaml:
	@cp docker-compose.override.yaml.dist docker-compose.override.yaml

.PHONY: docker-compose.override.yaml

##Docker
pull: docker-compose.override.yaml
	@echo "\nPulling local images...\e[0m"
	@$(DOCKER_COMPOSE) pull --quiet

build: docker-compose.override.yaml pull ##Build docker
	@echo "\nBuilding local images...\e[0m"
	@$(DOCKER_COMPOSE) build

up: docker-compose.override.yaml ##Up docker
	@$(DOCKER_COMPOSE) up -d --remove-orphans

down: docker-compose.override.yaml ##Down docker
	@$(DOCKER_COMPOSE) kill
	@$(DOCKER_COMPOSE) down --remove-orphans

logs: docker-compose.override.yaml ##Logs from docker
	@${DOCKER_COMPOSE} logs -f --tail 0

.PHONY: pull build up down logs

##Project
install: build up vendor db-load-fixtures ##Up the project and load database

reset: down build up db-load-fixtures ##Reset the project

start: docker-compose.override.yaml ## Start containers (unpause)
	@$(DOCKER_COMPOSE) unpause || true
	@$(DOCKER_COMPOSE) start || true

stop: docker-compose.override.yaml ##Stop containers (pause)
	@$(DOCKER_COMPOSE) pause || true

vendor: composer.lock ##Install composer
	@echo "\nInstalling composer packages...\e[0m"
	@$(COMPOSER) install

composer-update: composer.json ##Update composer
	@echo "\nUpdating composer packages...\e[0m"
	@$(COMPOSER) update

cc: ##Clear symfony cache
	@echo "\nClearing cache...\e[0m"
	@$(EXEC_SYMFONY) c:c
	@$(EXEC_SYMFONY) cache:pool:clear cache.global_clearer

wait-db:
	@echo "\nWaiting for DB...\e[0m"
	@$(EXEC_PHP) php -r "set_time_limit(60);for(;;){if(@fsockopen('db',3306))die;echo \"\";sleep(1);}"

.PHONY: install reset start stop vendor composer-update cc wait-db

##Database
db-load-fixtures: wait-db ##Load database from dump
	@echo "\nLoading fixtures from dump...\e[0m"
	@$(EXEC_DB) "mysql --user=root --password=root < /home/app/dump/skeleton.sql"

db-reload-schema: wait-db db-drop db-create db-migrate ##Recreate database structure

db-create: wait-db ##Create database
	@echo "\nCreating database...\e[0m"
	@$(EXEC_SYMFONY) doctrine:database:create --if-not-exists

db-drop: wait-db ##Drop database
	@echo "\nDropping database...\e[0m"
	@$(EXEC_SYMFONY) doctrine:database:drop --force --if-exists

db-diff: wait-db ##Generate migration by diff
	$(EXEC_SYMFONY) doctrine:migration:diff --formatted --allow-empty-diff

db-migrate: wait-db ##Load migration
	@echo "\nRunning migrations...\e[0m"
	@$(EXEC_SYMFONY) doctrine:migration:migrate --no-interaction --all-or-nothing

db-reload-fixtures: wait-db db-reload-schema ##Reload fixtures
	@echo "\nLoading fixtures from fixtures files...\e[0m"
	@$(EXEC_SYMFONY) hautelook:fixtures:load --no-interaction

	@echo "\nCreating dump...\e[0m"
	@$(EXEC_DB) "mysqldump --user=root --password=root --databases skeleton > /home/app/dump/skeleton.sql"

##Behat
behat: db-load-fixtures ##Launch behat
	@echo "\nLaunching read-only behat tests...\e[0m"
	@$(EXEC_PHP) vendor/bin/behat --strict --format=progress --tags="@read-only"

	@echo "\nLaunching other behat tests...\e[0m"
	@$(EXEC_PHP) vendor/bin/behat --strict --format=progress --tags="~@read-only"

##Quality assurance
code-quality: security-checker phpmd composer-unused yaml-linter phpstan cs db-validate ##Launch all quality assurance step
security-checker: ##Security check on dependencies
	@echo "\nRunning security checker...\e[0m"
	@$(QUALITY_ASSURANCE) sh -c "security-checker security:check"

phpmd: ##Phpmd
	@echo "\nRunning phpmd...\e[0m"
	@$(QUALITY_ASSURANCE) phpmd src/ text .phpmd.xml

composer-unused: ##Check if you have unused dependencies
	@echo "\nRunning composer unused...\e[0m"
	@$(QUALITY_ASSURANCE) composer-unused

yaml-linter: ##Linter yaml
	@echo "\nRunning yaml linter...\e[0m"
	@$(QUALITY_ASSURANCE) yaml-linter . --format=json

phpstan: ##PHPStan with higher level
	@echo "\nRunning phpstan...\e[0m"
	@$(QUALITY_ASSURANCE) phpstan analyse src/ --level 8

cs: ##Show cs fixer error
	@echo "\nRunning cs fixer in dry run...\e[0m"
	@$(QUALITY_ASSURANCE) php-cs-fixer fix --dry-run --using-cache=no --verbose --diff

cs-fix: ##Fix cs fixer error
	@echo "\nRunning cs fixer...\e[0m"
	@$(QUALITY_ASSURANCE) php-cs-fixer fix --using-cache=no --verbose --diff

db-validate: ##Validate db schema
	@echo "\nRunning db validate...\e[0m"
	@$(EXEC_SYMFONY) doctrine:schema:validate

.PHONY: behat