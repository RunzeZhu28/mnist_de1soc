vlib work

vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_primitives.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\220model.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_mf.v"

vlog -sv +define+TESTBENCH +acc E:\\mnist\\src\\cov1_ram.sv E:\\mnist\\tb\\cov1_ram_tb.sv E:\\mnist\\RAM_1.v
vsim -voptargs=+acc work.cov1_ram_tb           
add wave -r sim:/cov1_ram_tb/* 
run -all
