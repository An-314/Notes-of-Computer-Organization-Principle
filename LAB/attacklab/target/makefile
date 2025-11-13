CTARGET := ./ctarget
RTARGET := ./rtarget
HEX2RAW := ./hex2raw
DISASC := ctarget.d
DISASR := rtarget.d
OUT := builds
SRC := src


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
	echo "41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 d6 89 80 00 00 00 00 00" > $(SRC)/ctarget01.txt
	$(HEX2RAW) < $(SRC)/ctarget01.txt > $(OUT)/level1-raw
	$(CTARGET) < $(OUT)/level1-raw


run_c:
	$(CTARGET)

run_r:
	$(RTARGET)

clean:
	rm -rf $(OUT)
