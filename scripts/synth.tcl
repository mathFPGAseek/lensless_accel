

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1 -jobs 1
wait_on_run synth_1

set status [get_property STATUS [get_runs synth_1]]
puts "synth_1 status = $status"

if {![string match -nocase "*complete*" $status]} {
    puts "synth_1 failed. Run dir:"
    puts [get_property DIRECTORY [get_runs synth_1]]
    error "Top-level synthesis failed"
}

open_run synth_1

set rpt_dir [file normalize [file join [get_property DIRECTORY [get_runs synth_1]] reports]]
file mkdir $rpt_dir

report_utilization -file [file join $rpt_dir top_synth_utilization.rpt]
report_utilization -hierarchical -hierarchical_depth 6 \
    -file [file join $rpt_dir top_synth_utilization_hierarchical.rpt]
report_timing_summary -file [file join $rpt_dir top_synth_timing_summary.rpt]
report_compile_order -fileset sources_1 \
    -file [file join $rpt_dir compile_order_sources_1.rpt]

write_checkpoint -force [file join $rpt_dir top_synth.dcp]

puts "============================================================"
puts "Top synthesis complete"
puts "Reports are in:"
puts $rpt_dir
puts "============================================================"