# Skeleton
![CI](https://github.com/tegbessou/skeleton/workflows/CI/badge.svg)
## Description
A skeleton of application, which can be used if you have to satrt a new project with Symfony, Ningx, PHP and Mysql.

## Purpose
This skeleton will be used on new and actual projects in our organization
In our skeleton we want a stack which is capable to run a Symfony application

## What is in Skeleton ?
### Docker
- Nginx: 1.19
- PHP: 7.4
- Mysql: 8.0
- QualityAssurance: 7.4
- Redis: 6.0
- Mailcatcher
- PhpMyAdmin

### Symfony
Version 5.1

### Functionnal Test
We use Behat. To run behat use:
<pre>
  make behat
</pre>

### Unit Test
We use PHPUnit. To run unit test use:
<pre>
  make unit-test
</pre>

### Makefile
To see all usefull command run:
<pre>
  make help
</pre>

## How to start with Skeleton ?
### First replace "skeleton" occurence with your project name
- Change all occurences of "skeleton" in Makefile
- Change host "skeleton.docker" in site.conf
- Change "skeleton" in .bashrc
- Change base url "https://skeleton.docker" in behat.yml.dist
- Change database name "skeleton" in .env
- Change dump name "skeleton.sql" in FixtureContext
- Change local domain "https://skeleton.docker" in ErrorHandlerContext.php
- Change urls which finish with "skeleton.docker" in docker-compose.override.yaml.dist
- Change urls which finish with "skeleton.docker" in docker-compose.yaml
- Rename "dump/skeleton.sql" by "dump/your-project.sql"

### Add host in your /etc/hosts
<pre>
  sudo vim /etc/hosts
</pre>

<pre>
  127.0.0.1 your-host.fr
  127.0.0.1 pma.your-host.fr
  127.0.0.1 mailcatcher.your-host.fr
</pre>

### Install the project
<pre>
  make install
</pre>

### Work with project
If you have already install the project and you want to switch to another project or stop for today,
just stop your project:
<pre>
  make stop
</pre>
And start when you need with:
<pre>
  make start
</pre>
## Database management
We used a dump to reload faster our database. To load your database use:
<pre>
  make db-load-fixtures
</pre>
### Update dump
If you add some migration or some fixtures, you have to update your dump with:
<pre>
   make db-reload-fixtures
</pre>
### PhpMyAdmin
To access PhpMyAdmin use: https://pma.your-host.fr

- Login: root
- Password: root

## Quality of our code
We have some quality tools and to run all this tools, you can use:
<pre>
  make code-quality
</pre>
In our quality tools you can find:
### Security checker of symfony
This tools check, if you have vulnerability in your dependencies
<pre>
  make security-checker
</pre>
### PHPmd
<pre>
  make phpmd
</pre>
### Composer unused
This tools allows you to check if you have unused dependencies
<pre>
  make composer-unused
</pre>
### Yaml Linter
<pre>
  make yaml-linter
</pre>
### Xliff Linter
<pre>
  make xliff-linter
</pre>
### Twig Linter
<pre>
  make twig-linter
</pre>
### Container Linter
<pre>
  make container-linter
</pre>
### PHPStan
<pre>
  make phpstan
</pre>
### CS Fixer
This tools check if you have error in your coding styles.

To show this error use:
<pre>
  make cs
</pre>

To fix this errors use:
<pre>
  make cs-fix
</pre>
### Validate database schema
This Symfony command check if your database schema is coherent with your entities annotation
<pre>
  make db-validate
</pre>

## Mailcatcher
If your local app send mail, your mail will be catched by the mailcatcher.
To see this mail go to: https://mailcatcher.your-host.fr

## Next step
If you want to help use, you can add some features like:
- A gitlab-ci.yaml example
- Add a docker image for S3 storage and some test
- Upgrade symfony version to 5.2
- Add Mac support

This are idea, but feel free to suggest any features you want!!
