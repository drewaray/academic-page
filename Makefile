.PHONY: render check deploy clean size

DEPLOY_TARGET ?= ucsb-web:/home/grad/ortegaray/public_html/

render:
	quarto render --to html

check:
	./scripts/check-site.sh

deploy:
	./scripts/deploy-site.sh $(DEPLOY_TARGET)

clean:
	./scripts/clean-generated.sh --apply

size:
	./scripts/repo-size.sh
