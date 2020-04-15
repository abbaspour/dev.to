
check:
	npm run embedme:check
	npm run prettier:check

prep:
	npm run embedme:write
	npm run prettier:write

.PHONY: check write
