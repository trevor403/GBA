
upload: GBA.bin
	tinyprog -p GBA.bin

GBA.blif: GBA.v
	yosys -ql GBA.log -p 'synth_ice40 -top top -blif GBA.blif' $^

GBA.asc: GBA.pcf GBA.blif
	arachne-pnr -d 8k -P cm81 -o GBA.asc -p GBA.pcf GBA.blif

GBA.bin: GBA.asc
	icetime -d lp8k -c 12 -mtr GBA.rpt GBA.asc
	icepack GBA.asc GBA.bin

clean:
	rm -f GBA.blif GBA.log GBA.asc GBA.rpt GBA.bin
