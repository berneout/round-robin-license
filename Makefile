NPMBIN=node_modules/.bin
CFCM=$(NPMBIN)/commonform-commonmark
CFHTML=$(NPMBIN)/commonform-html
CFDOCX=$(NPMBIN)/commonform-docx
JSON=$(NPMBIN)/json

BUILD=build
TARGETS=$(addprefix $(BUILD)/,license.html license.docx license.pdf license.md)

all: $(TARGETS)

$(BUILD)/%.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse $< > $@

$(BUILD)/%.form: $(BUILD)/%.json | $(JSON)
	$(JSON) form < $< > $@

$(BUILD)/%.directions: $(BUILD)/%.json | $(BUILD) $(CFCM)
	$(JSON) directions < $< > $@

$(BUILD)/%.html: $(BUILD)/%.form $(BUILD)/%.directions $(BUILD)/%.values $(BUILD)/%.title $(BUILD)/%.edition | $(BUILD) $(CFHTML)
	$(CFHTML) \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--directions $(BUILD)/$*.directions \
		--values $(BUILD)/$*.values \
		--ids \
		--lists \
		--html5 \
		< $< > $@

$(BUILD)/%.docx: $(BUILD)/%.form $(BUILD)/%.directions $(BUILD)/%.values $(BUILD)/%.title $(BUILD)/%.edition styles.json | $(BUILD) $(CFDOCX)
	$(CFDOCX) \
		--number outline \
		--left-align-title \
		--indent-margins \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--directions $(BUILD)/$*.directions \
		--values $(BUILD)/$*.values \
		--styles styles.json \
		$< > $@

$(BUILD)/%.md: $(BUILD)/%.form $(BUILD)/%.title $(BUILD)/%.directions $(BUILD)/%.values $(BUILD)/%.edition styles.json | $(BUILD) $(CFCM)
	$(CFCM) stringify \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--directions $(BUILD)/$*.directions \
		--values $(BUILD)/$*.values \
		--ordered \
		< $< | \
		sed 's/^!!! \(.\+\)$$/***\1***/' | \
		sed 's!\\/!/!g' | \
		sed 's!\(https://.\+\).$$!<\1>.!g' | \
		fmt -u -w64 \
		> $@

$(BUILD)/%.title: $(BUILD)/%.json | $(JSON)
	$(JSON) frontMatter.title < $< > $@

$(BUILD)/%.edition: $(BUILD)/%.json | $(JSON)
	$(JSON) frontMatter.version < $< > $@

$(BUILD)/%.values: $(BUILD)/%.json
	node -e 'var value = require("./$(BUILD)/$*.json").frontMatter.version; console.log(JSON.stringify({ version: value === "Development Draft" ? "$$version" : value }))' > $@

$(BUILD)/%.pdf: $(BUILD)/%.docx
	unoconv $<

$(BUILD):
	mkdir -p $(BUILD)

$(NPMBIN) $(CFCM) $(CFHTML) $(CFDOCX) $(JSON):
	npm ci

.PHONY: clean

clean:
	rm -rf $(BUILD)
