# TODO: Review docker artifacts: conainers, images, volumes

install:
	docker compose build
	make run-app rake db:prepare
	make run-app rake db:test:prepare

start:
	docker compose up

test:
	make run-app rspec $(filter-out $@, $(MAKECMDGOALS))

console: # quotes prevent recursion for 'console'
	make run-app 'rails console' 

shell:
	make run-app /bin/bash


# General

run-app:
	docker compose run --rm app $(filter-out $@, $(MAKECMDGOALS))


# Shortcuts

i: install
s: start
c: console
sh: shell
r:
	make run-app $(filter-out $@, $(MAKECMDGOALS))
t:
	make run-app rspec $(filter-out $@, $(MAKECMDGOALS))

# Prevent errors when passing arguments
%:
	@: