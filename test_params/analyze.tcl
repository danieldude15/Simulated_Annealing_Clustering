#! /usr/bin/env tclsh

set f [open ../output/results.txt r]
set spl_data [split [set data [read $f]] "\n"]
close $f
foreach line $spl_data {
	if {[llength $line]!=4} {continue}
	lassign $line c1 c2 c3 c4
	set c1 [lindex [split $c1 "="] end]
	set c2 [lindex [split $c2 "="] end]
	set c3 [lindex [split $c3 "="] end]
	set c4 [lindex [split $c4 "="] end]
	if {[info exists c_1($c1)]} {incr c_1($c1)} else {set c_1($c1) 1}
	if {[info exists c_4($c4)]} {incr c_4($c4)} else {set c_4($c4) 1}
	if {[info exists c_3($c3)]} {incr c_3($c3)} else {set c_3($c3) 1}
	if {[info exists c_2($c2)]} {incr c_2($c2)} else {set c_2($c2) 1}
	if {[info exists c12([set r [expr $c1/$c2]])]} {incr c12($r)} else {set c12($r) 1}
	if {[info exists c13([set r [expr $c1/$c3]])]} {incr c13($r)} else {set c13($r) 1}
	if {[info exists c14([set r [expr $c1/$c4]])]} {incr c14($r)} else {set c14($r) 1}
	if {[info exists c23([set r [expr $c2/$c3]])]} {incr c23($r)} else {set c23($r) 1}
	if {[info exists c24([set r [expr $c2/$c4]])]} {incr c24($r)} else {set c24($r) 1}
	if {[info exists c34([set r [expr $c3/$c4]])]} {incr c34($r)} else {set c34($r) 1}
	
}

for {set i 1} {$i<4} {incr i} {
	for {set j [expr $i+1]} {$j<=4} {incr j} {
		puts "c${i}${j}: "
		foreach n [array names "c${i}${j}"] {
			set var "c${i}${j}"
			puts "${i}/$j $n : -> [subst $${var}($n)]"
		}
	}
}
puts "c_1: "
foreach n [lsort -real [array names c_1]] {
	puts "$n: -> $c_1($n)"
}
puts "c_2: "
foreach n [lsort -real [array names c_2]] {
	puts "$n: -> $c_2($n)"
}
puts "c_3: "
foreach n [lsort -real [array names c_3]] {
	puts "$n: -> $c_3($n)"
}
puts "c_4: "
foreach n [lsort -real [array names c_4]] {
	puts "$n: -> $c_4($n)"
}