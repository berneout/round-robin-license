NPMBIN=node_modules/.bin
CFCM=$(NPMBIN)/commonform-commonmark
CFHTML=$(NPMBIN)/commonform-html
CFDOCX=$(NPMBIN)/commonform-docx
JSON=$(NPMBIN)/json

BUILD=build
TARGETS=$(addprefix $(BUILD)/,license.html license.docx license.pdf license.md)

all: $(TARGETS)

$(BUILD)/%.form.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse --only form $< > $@

$(BUILD)/%.html: $(BUILD)/%.form.json $(BUILD)/%.title $(BUILD)/%.edition | $(BUILD) $(CFHTML)
	$(CFHTML) \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--ids \
		--lists \
		--html5 \
		< $< > $@

$(BUILD)/%.docx: $(BUILD)/%.form.json $(BUILD)/%.title $(BUILD)/%.edition styles.json | $(BUILD) $(CFDOCX)
	$(CFDOCX) \
		--number outline \
		--left-align-title \
		--indent-margins \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--styles styles.json \
		$< > $@

$(BUILD)/%.md: $(BUILD)/%.form.json $(BUILD)/%.title $(BUILD)/%.edition styles.json | $(BUILD) $(CFCM)
	$(CFCM) stringify \
		--title "$(shell cat $(BUILD)/$*.title)" \
		--edition "$(shell cat $(BUILD)/$*.edition)" \
		--ordered \
		< $< | \
		sed 's/^!!! \(.\+\)$$/***\1***/' | \
		sed 's!\\/!/!g' | \
		sed 's!\(https://.\+\).$$!<\1>.!g' | \
		fmt -u -w64 \
		> $@

$(BUILD)/%.title: %.md | $(BUILD) $(CFCM) $(JSON)
	$(CFCM) parse < $< | $(JSON) frontMatter.title > $@

$(BUILD)/%.edition: %.md | $(BUILD) $(CFCM) $(JSON)
	$(CFCM) parse < $< | $(JSON) frontMatter.version > $@

$(BUILD)/%.pdf: $(BUILD)/%.docx
	unoconv $<

$(BUILD):
	mkdir -p $(BUILD)

$(NPMBIN) $(CFCM) $(CFHTML) $(CFDOCX) $(JSON):
	npm ci

.PHONY: clean

clean:
	rm -rf $(BUILD)
