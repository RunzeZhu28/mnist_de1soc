vlib work
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_primitives.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\220model.v"
vlog "D:\\intelFPGA_lite\\22.1std\\quartus\\eda\\sim_lib\\altera_mf.v"
vlog -sv +define+TESTBENCH +acc E:\\mnist\\src\\fc.sv E:\\mnist\\src\\fc_mac.sv E:\\mnist\\src\\comparator.sv E:\\mnist\\src\\conv2_ram.sv  E:\\mnist\\src\\max_pooling.sv  E:\\mnist\\src\\pooling_ram.sv E:\\mnist\\src\\cov2.sv E:\\mnist\\src\\cov1.sv E:\\mnist\\src\\mac.sv E:\\mnist\\src\\mnist.sv E:\\mnist\\src\\data_seg.sv E:\\mnist\\tb\\mnist_tb.sv 
vsim -voptargs=+acc work.mnist_tb           
add wave -r sim:/mnist_tb/*
run -all
