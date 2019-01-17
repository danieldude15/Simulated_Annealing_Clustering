#! /usr/bin/env tclsh

package require Tk
set e 2.718281828459045
set pi 3.141592653589793
set debug_intersection 0
set debug_intersection_start 0
set debug_intersection_cond 0
set debug_control_energy_calc 0

set net_file_name HW2Net.net
set log_file log_${net_file_name}.txt
set log 1
proc sleep {time} {
   after $time set end 1
   vwait end
}
# --------------------------
#   params
# --------------------------
# title
# canvas width & height
# delay between plots
# x = f(t)
# plot expression
# initial & final times
# accuracy
array set params {
    title     {HW2 vizualizer}
    screen_size 1000
    delay     1
	padd	  80
    x         {$t / 50.}
    plot      {sin($x)}
    t0        0
    #         {t1 < t0: non-stop scrolling}
    t1        -1
    accuracy  1.e-2
}
array set color {1 {red black} 2 {blue white} 3 {green black} 4 {white black} 5 {purple white} 6 {yellow black}}
set limit [expr $params(screen_size)/2]
# --------------------------
#   plotting
# --------------------------
# computed heights
set h $params(screen_size)
set h1 [expr {int($h * 0.5)}]  ;# canvas mid-height
set h2 [expr {$h1 + 1}]
set h3 [expr {int($h * 0.4)}]  ;# graph mid-height
# canvas & bindings
canvas .c -width $params(screen_size) -height $h -xscrollincrement 1 -bg beige
bind . <Destroy> { exit }
# plotting
wm title . $params(title)
pack .c
.c xview scroll $params(t0) unit
set t $params(t0)

proc draw_graph {} {
	puts "drawing graph"
	set screen_size $::params(screen_size)
	set text_color white
	set node_color red
	set delta 10
	if {[info exists ::canvas_e_id]} {
		foreach id [array names ::canvas_e_id] { foreach i $::canvas_e_id($id) {.c delete $i }}
	}
	if {[info exists ::canvas_v_id]} {
		foreach id [array names ::canvas_v_id] { .c delete $::canvas_v_id($id) }
	}
	foreach point_id [array names ::points] {
		lassign $::points($point_id) x0 y0
		set x0 [expr $x0*$screen_size]
		set y0 [expr $y0*$screen_size]
		#puts "p_id: $point_id (x,y) ($x0,$y0)"
		#draw point (node)
		#set ::canvas_v_id($point_id) [.c create oval [expr $x0-$delta] [expr $y0-$delta] [expr $x0+$delta] [expr $y0+$delta] -fill red]
		
		foreach connection $::connections($point_id) {
			#draw all connections to point (node)
			lassign $::points($connection) x1 y1
			set x1 [expr $x1*$screen_size]
			set y1 [expr $y1*$screen_size]
			#puts "connected to p_id: $connection (x,y) ($x0,$y0)"
			lappend ::canvas_e_id($point_id) [.c create line $x0 $y0 $x1 $y1 -fill gray]
		}
	}
	foreach point_id [array names ::points] {
		lassign $::points($point_id) x0 y0
		set x0 [expr $x0*$screen_size]
		set y0 [expr $y0*$screen_size]
		#puts "p_id: $point_id (x,y) ($x0,$y0)"
		#draw point (node)
		if {[info exists ::point_color($point_id)]} {
			lassign $::point_color($point_id) node_color text_color
		} else {
			puts "info does not exist in ::point_color($point_id) using $text_color on $node_color"
		}
		set ::canvas_v_id($point_id) [.c create oval [expr $x0-$delta] [expr $y0-$delta] [expr $x0+$delta] [expr $y0+$delta] -fill $node_color]
		set ::canvas_v_id($point_id,txt) [.c create text [expr $x0] [expr $y0] -fill $text_color -justify center -text "$point_id" -font {Helvetica -13}]
	}
	sleep 100
	return
}

proc lvarpop {ptr} {
	upvar $ptr p
	set ret [lindex $p 0]
	set p [lrange $p 1 end]
	return $ret
}

proc read_new_net_from_file {path} {
	set file [open $path r]
	set data [read $file]
	set delta 7
	set data [split $data "\n"]
	lassign [lvarpop data] - ::Vertices_count
	set r [expr $::params(screen_size)/2.0-$::params(padd)]
	set offset [expr $r+$::params(padd)]
	set alfa_change [expr (360.0/$::Vertices_count)]
	set conv_rad [expr $::pi/180]
	for {set i 0} {$i<$::Vertices_count} {incr i} {
		set alfa [expr 1.0*$i*$alfa_change]
		set x0 [expr 1.0*$r*cos($alfa*$conv_rad)+$offset]
		set y0 [expr 1.0*$r*sin($alfa*$conv_rad)+$offset]
		set ::points([expr $i+1]) [list $x0 $y0]
		set ::connections([expr $i+1]) [list]
	}
	lassign [lvarpop data] -
	foreach pair $data {
		lassign $pair index friend
		if {[string length $index]==0} {continue}
		lappend ::connections($index) $friend 
		lappend ::connections($friend) $index 
	}
	
	
	for {set i 1} {$i<=[expr $::Vertices_count-1]} {incr i} {
		for {set j [expr $i+1]} {$j<=$::Vertices_count} {incr j} {
			if {[lcontain $::connections($i) $j] || [lcontain $::connections($j) $i]} {
				set ::con_mat($i,$j) 1
			}
		}
	}
	return
}

proc read_net_from_file {path} {
	set file [open $path r]
	set data [read $file]
	close $file
	set data [split $data "\n"]
	set screen_size $::params(screen_size)
	lassign [lvarpop data] - ::Vertices_count
	set r [expr $::params(screen_size)/2.0-$::params(padd)]
	set offset [expr $r+$::params(padd)]
	set alfa_change [expr (360.0/$::Vertices_count)]
	set conv_rad [expr $::pi/180]
	foreach line $data {
		if {$line eq "*Edges"} {break}
		lassign $line i name x y z
		#~ set x [expr $x*$screen_size]
		#~ set y [expr $y*$screen_size]
		set ::points($i) [list $x $y]
		set ::connections($i) [list]
	}
	set flag 1;
	foreach line $data {
		if {$line ne "*Edges" && $flag} {continue}
		set flag 0
		lassign $line j i
		lappend ::connections($i) $j
		lappend ::connections($j) $i
	}
	if {[catch {
		set file [open ../networks/HW2Clust.clu r]
		set data [read $file]
		close $file
		set data [split $data "\n"]
		lvarpop data
		for {set i 1} {$i<=$::Vertices_count} {incr i} {
			set cluster [lvarpop data]
			set ::point_color($i) $::color($cluster)
			#puts "set ::point_color($i) $::color($cluster)"
		}
	} err]} {puts "DID NOT READ CLU FILE FOR CLUSTER COLORING BECAUSE: $err"}
	for {set i 1} {$i<=[expr $::Vertices_count-1]} {incr i} {
		for {set j [expr $i+1]} {$j<=$::Vertices_count} {incr j} {
			if {[lcontain $::connections($i) $j] || [lcontain $::connections($j) $i]} {
				set ::con_mat($i,$j) 1
			}
		}
	}
	return
}

proc lcontain {lst elem} {
	foreach e $lst {
		if {$e eq $elem} {return 1}
	}
	return 0
}

proc _pause {{msg "paused: "}} {
    set stty_settings [exec stty -g]
    exec stty raw -echo
    puts -nonewline $msg
    flush stdout
    read stdin 1
    exec stty $stty_settings
    puts ""
}

proc retransform_points_to_screen_size {} {
	global points
	set screen_size $::params(screen_size)
	set left [set top [list 99999999 0]]
	set bottom [set right [list 0 0]]
	foreach id [array names points] {
		lassign $points($id) x y
		if {[min [lindex $left 0] $x] == $x} {
			set left [list $x $id]
		}
		if {[min [lindex $top 0] $y] == $y} {
			set top [list $y $id]
		}
		if {[max [lindex $right 0] $x] == $x} {
			set right [list $x $id]
		}
		if {[max [lindex $bottom 0] $y] == $y} {
			set bottom [list $y $id]
		}
	}
	
	set box_width [expr [lindex $right 0]-[lindex $left 0]]
	set box_height [expr [lindex $bottom 0]-[lindex $top 0]]
	
	set ratio_x [expr 1.0*$screen_size/$box_width]
	set ratio_y [expr 1.0*$screen_size/$box_height]
	puts "left id top id right id bottom id box_width box_height ratio_x ratio_y"
	lassign $left l i1
	lassign $right r i2
	lassign $top t i3
	lassign $bottom b i4
	puts [format "%.2lf %d %.2lf %d %.2lf %d %.2lf %d %.2lf %.2lf %.2lf %.2lf" $l $i1 $t $i2 $r $i3 $b $i4 $box_width $box_height $ratio_x $ratio_y]
	#_pause
	foreach id [array names points] {
		lassign $points($id) x y
		set new_x [expr ($x-$l)*$ratio_x]
		set new_y [expr ($y-$t)*$ratio_y]
		if {$new_x>$screen_size} {set new_x $screen_size}
		if {$new_x<0} {set new_x 0}
		if {$new_y>$screen_size} {set new_y $screen_size}
		if {$new_y<0} {set new_y 0}
		set points($id) [list $new_x $new_y]
	}
	
}
proc min {a b} {return [expr $a > $b ? $b : $a] }
proc max {a b} {return [expr $a > $b ? $a : $b] }

lassign $argv path title
catch {.c create text [expr $params(screen_size)/2] 15 -fill black -justify center -text "$title" -font {Helvetica -15}} err
expr srand(int(rand()*1000))
read_net_from_file $path
draw_graph
#puts [get_all_ns points]
#cluster_points_simulating_annealing
