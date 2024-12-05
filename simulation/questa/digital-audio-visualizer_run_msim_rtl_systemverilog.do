transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/bryan/Documents/school/ucla/ieee\ dav\ 2024/digital-audio-visualizer {C:/Users/bryan/Documents/school/ucla/ieee dav 2024/digital-audio-visualizer/butterfly_tb.sv}
vlog -sv -work work +incdir+C:/Users/bryan/Documents/school/ucla/ieee\ dav\ 2024/digital-audio-visualizer {C:/Users/bryan/Documents/school/ucla/ieee dav 2024/digital-audio-visualizer/butterfly_4.sv}

