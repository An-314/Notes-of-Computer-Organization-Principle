# 基本变量
BUILD_DIR := builds
MAIN_SRC := main.typ
MAIN_PDF := $(BUILD_DIR)/main.pdf
CHAPS := $(wildcard chap*.typ)

# HW 部分
HW_SRC := $(wildcard HW/*/main.typ)
HW_PDF := $(patsubst HW/%/main.typ,$(BUILD_DIR)/HW/%.pdf,$(HW_SRC))

# LAB 部分
LAB_SRC := $(wildcard LAB/*/main.typ)
LAB_PDF := $(patsubst LAB/%/main.typ,$(BUILD_DIR)/LAB/%.pdf,$(LAB_SRC))

.PHONY: all clean

all: $(MAIN_PDF) $(HW_PDF) $(LAB_PDF)

# 编译主文档
$(MAIN_PDF): $(MAIN_SRC) $(CHAPS)
	mkdir -p $(dir $@)
	typst compile $< $@

# 编译每个 HW
$(BUILD_DIR)/HW/%.pdf: HW/%/main.typ
	mkdir -p $(dir $@)
	typst compile $< $@

# 编译每个 LAB
$(BUILD_DIR)/LAB/%.pdf: LAB/%/main.typ
	mkdir -p $(dir $@)
	typst compile $< $@

clean:
	rm -rf $(BUILD_DIR)