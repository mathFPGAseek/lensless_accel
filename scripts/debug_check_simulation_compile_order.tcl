# Check Simulation COmpile Order
puts "============================================================"
puts "Simulation compile order"
puts "============================================================"

foreach f [get_files -compile_order sources -used_in simulation] {
    puts $f
}