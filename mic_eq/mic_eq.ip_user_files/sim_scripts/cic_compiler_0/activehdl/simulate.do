onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+cic_compiler_0  -L xbip_utils_v3_0_10 -L axi_utils_v2_0_6 -L cic_compiler_v4_0_16 -L xil_defaultlib -L secureip -O5 xil_defaultlib.cic_compiler_0

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {cic_compiler_0.udo}

run 1000ns

endsim

quit -force
