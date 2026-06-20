# ============================================================
# build_project.tcl
#
# Master Vivado build script.
#
# Creates project, adds RTL/XDC by reference, creates IP,
# and optionally runs synthesis.
# ============================================================

# ------------------------------------------------------------
# Locate repo root from script location
# ------------------------------------------------------------

set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ".."]]

puts "script_dir = $script_dir"
puts "repo_root  = $repo_root"

# ------------------------------------------------------------
# User settings
# ------------------------------------------------------------

set proj_name "fa_ll_ip_test"

# Change this for your board/device.
set part_name "xczu7ev-ffvc1156-2-e"

# Disposable Vivado project location
set build_root [file normalize [file join $repo_root "build"]]
set proj_dir   [file normalize [file join $build_root $proj_name]]

# Source directories
set rtl_dir    [file normalize [file join $repo_root "rtl"]]
set xdc_dir    [file normalize [file join $repo_root "constraints"]]
set coe_dir    [file normalize [file join $repo_root "coe"]]
set ip_src_dir [file normalize [file join $repo_root "ip_src"]]

# Control whether to run synthesis after project/IP creation
set run_synth 1

# ------------------------------------------------------------
# Clean/create build area
# ------------------------------------------------------------

file mkdir $build_root

# Optional: force clean project every time.
# Be careful: this deletes the generated Vivado project.
if {[file exists $proj_dir]} {
    puts "Deleting existing project directory: $proj_dir"
    file delete -force $proj_dir
}

file mkdir $proj_dir

# ------------------------------------------------------------
# Create Vivado project
# ------------------------------------------------------------

puts "Creating Vivado project..."
puts "  Project = $proj_name"
puts "  Dir     = $proj_dir"
puts "  Part    = $part_name"

create_project $proj_name $proj_dir -part $part_name -force

set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]

# ------------------------------------------------------------
# Add RTL files by reference
# ------------------------------------------------------------

puts ""
puts "Adding RTL files from: $rtl_dir"

set rtl_files [glob -nocomplain \
    [file join $rtl_dir "*.vhd"] \
    [file join $rtl_dir "*.vhdl"] \
    [file join $rtl_dir "*.sv"] \
    [file join $rtl_dir "*.v"] \
]

if {[llength $rtl_files] == 0} {
    puts "WARNING: No RTL files found in $rtl_dir"
} else {
    foreach f $rtl_files {
        puts "  RTL: $f"
    }

    add_files -fileset sources_1 $rtl_files
}

# ------------------------------------------------------------
# Add constraints by reference
# ------------------------------------------------------------

puts ""
puts "Adding constraint files from: $xdc_dir"

set xdc_files [glob -nocomplain [file join $xdc_dir "*.xdc"]]

if {[llength $xdc_files] == 0} {
    puts "WARNING: No XDC files found in $xdc_dir"
} else {
    foreach f $xdc_files {
        puts "  XDC: $f"
    }

    add_files -fileset constrs_1 $xdc_files
}

# ------------------------------------------------------------
# Source existing IP creation script
# ------------------------------------------------------------

puts ""
puts "Running IP creation script..."

# These variables are intentionally available to create_ip.tcl
# if your IP script wants to use them.
set ::repo_root  $repo_root
set ::coe_dir    $coe_dir
set ::ip_src_dir $ip_src_dir
set ::rtl_dir    $rtl_dir
set ::xdc_dir    $xdc_dir

source [file join $script_dir "create_ip.tcl"]

# ------------------------------------------------------------
# Update compile order and save project
# ------------------------------------------------------------

puts ""
puts "Updating compile order..."

update_compile_order -fileset sources_1

save_project

puts ""
puts "Project creation and IP generation complete."

# ------------------------------------------------------------
# Optionally run synthesis
# ------------------------------------------------------------

if {$run_synth} {
    puts ""
    puts "Running synthesis script..."

    source [file join $script_dir "syn_design.tcl"]
} else {
    puts ""
    puts "Synthesis skipped. Open project manually if desired:"
    puts "  $proj_dir/$proj_name.xpr"
}