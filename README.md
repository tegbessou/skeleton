# Skeleton
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
- Adminer

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
### First replace "skeletton" occurence with your project name
- Change all occurences of "skeleton" in Makefile
- Change host "skeleton.fr" in site.conf
- Change "skeleton" in .bashrc
- Change base url "https://skeleton.fr" in behat.yml
- Change database name "skeleton" in .env
- Change dump name "skeleton.sql" in FixtureContext

### Add host in your /etc/hosts
<pre>
  sudo vim /etc/hosts
</pre>

<pre>
  127.0.0.1 your-host.fr
</pre>

### Run the project
<pre>
  make install
</pre>

## Database management
We used a dump to reload faster our database. To load your database use:
<pre>
  make db-load
</pre>
### Update dump
If you add some migration or some fixtures, you have to update your dump with:
<pre>
   make db-relaod-fixtures
</pre>

## Quality of our code
We have some quality tools and to run all this tools, you can use:
<pre>
  make quality-ci
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

## Next step
If you want to help use, you can add some features like:
- A gitlab-ci.yaml example
- Add a docker image for S3 storage and some test
- Upgrade symfony version to 5.2
- Add Mac support

This are idea, but feel free to suggest any features you want!!
