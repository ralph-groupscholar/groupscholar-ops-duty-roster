PSQL ?= $(shell brew --prefix libpq)/bin/psql
PSQL_FLAGS = -v ON_ERROR_STOP=1

schema:
	$(PSQL) $(PSQL_FLAGS) -f schema.sql

seed:
	$(PSQL) $(PSQL_FLAGS) -f seed.sql

test:
	$(PSQL) $(PSQL_FLAGS) -f test.sql
