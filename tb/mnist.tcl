vlib work
vlog -sv +define+TESTBENCH +acc E:\\mnist\\src\\cov1.sv E:\\mnist\\src\\mac.sv E:\\mnist\\src\\mnist.sv E:\\mnist\\src\\data_seg.sv E:\\mnist\\tb\\mnist_tb.sv
vsim -voptargs=+acc work.mnist_tb           
add wave -r sim:/mnist_tb/*
run -all
