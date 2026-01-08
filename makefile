# -------- Cross-platform helpers --------
ifeq ($(OS),Windows_NT)
  define MKDIR_P
    powershell -NoProfile -Command "New-Item -ItemType Directory -Force '$(1)' | Out-Null"
  endef
  define RM_RF
    powershell -NoProfile -Command "if (Test-Path '$(1)') { Remove-Item -Recurse -Force '$(1)' }"
  endef
else
  define MKDIR_P
    mkdir -p '$(1)'
  endef
  define RM_RF
    rm -rf '$(1)'
  endef
endif
# ----------------------------------------

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
	$(call MKDIR_P,$(dir $@))
	typst compile $< $@

# 编译每个 HW
$(BUILD_DIR)/HW/%.pdf: HW/%/main.typ
	$(call MKDIR_P,$(dir $@))
	typst compile $< $@

# 编译每个 LAB
$(BUILD_DIR)/LAB/%.pdf: LAB/%/main.typ
	$(call MKDIR_P,$(dir $@))
	typst compile $< $@

clean:
	$(call RM_RF,$(BUILD_DIR))