vlib work
vlog -sv +define+TESTBENCH +acc E:\\mnist\\src\\cov1.sv E:\\mnist\\tb\\cov1_tb.sv
vsim -voptargs=+acc work.cov1_tb           
add wave -r sim:/cov1_tb/*
run -all
