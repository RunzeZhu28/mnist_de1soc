vlib work
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_primitives.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\220model.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_mf.v"
vlog -sv +define+TESTBENCH +acc E:\\mnist\\src\\cov1.sv E:\\mnist\\src\\mac.sv E:\\mnist\\src\\mnist.sv E:\\mnist\\src\\data_seg.sv E:\\mnist\\tb\\mnist_tb.sv
vsim -voptargs=+acc work.mnist_tb           
add wave -r sim:/mnist_tb/*
run -all
