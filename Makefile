
check:
	npm run prettier:check

write:
	npm run embedme:write
	#npm run prettier:write

.phone: check write
