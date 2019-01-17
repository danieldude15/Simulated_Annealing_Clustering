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
set comment {
	array set points {
		0	{100 400}
		1	{400 500}
		2	{100 100}
		3	{100 500}
		4	{200 400}
		5	{200 700}
		6	{300 600}
	}

	array set connections {
		0	{1 2 3}
		1	{3 5 6}
		2	{5 1}
		3	{0 5 1}
		4	{0 4}
		5	{2 4}
		6	{}
	}
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
		set file [open HW2Clust.clu r]
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

proc cluster_points_simulating_annealing {} {
	
	set threshold 0
	set T 5000
	#set c [list 10 0.001 0.000001 0.001]
	# c_1 is responsible for energy reultion from eachother to make sure everyone are not ending up right next to eachother
	# c_2 is responsible to create a circular barior so nodes dont go far away from the midle of the screen
	# c_3 is mesuring the length of all edges and tries to shorten them
	# c_4 is counting the number of edges intersecting with each other
	set c [list 10000 1 0.000001 1]
	set ind 1
	puts "### Calculating initial energy ###"
	set e_info [initial_energy ::points $c] 
	lassign $e_info energy n1 n2 n3 n4
	puts "### initial energy is $energy ###"
	while { $T > $threshold } {
		puts "########################### T = $T #############################"
		foreach node_id [lsort -integer [array names ::points]] {
			lassign $::points($node_id) old_x old_y
			lassign [new_energy_of_points ::points $node_id $c $e_info] old_e_info new_e_info
			lassign $new_e_info new_e
			lassign $old_e_info old_e
			if { $old_e  < $new_e} {
				if { [prob_calc $old_e $new_e $T]} {
					set ::points($node_id) [list $old_x $old_y]
					#if {[expr $node_id%5]==0} {draw_graph}
				} else {
					lassign e_info $new_e_info
					#draw_graph
					#sleep 100
				}
			} else {
				set e_info $new_e_info
				#draw_graph
				#sleep 100
			}
			if {$::debug_control_energy_calc} {
				if {$energy eq $new_e} {
					puts "######DEBUG control#########\nnew_energy_calculated: $new_e\n\t\tvs\nrecalculation of new energy [initial_energy ::points $c]\n######DEBUG control#########"
				}
			}
			if {[expr $node_id%10]==0} {draw_graph}
			#draw_graph
			#_pause
		}
		#retransform_points_to_screen_size
		#draw_graph
		#set energy [initial_energy ::points $c]
		set T [expr $T*0.95]
	}
	
	return
}

proc new_position { id } {
	global points
	upvar 2 T T
	#~ set vec_sum_x 0.0
	#~ set vec_sum_y 0.0
	#~ lassign $points($id) x0 y0
	#~ foreach con $::connections($id) {
		#~ lassign $points($con) x1 y1
		#~ set vec_sum_x [expr $vec_sum_x + $x1-$x0]
		#~ set vec_sum_y [expr $vec_sum_y + $y1-$y0]
	#~ }
	#~ set vec_size [expr sqrt(pow($vec_sum_x,2)+pow($vec_sum_y,2))]
	#~ set x_norm [expr $vec_sum_x/$vec_size]
	#~ set y_norm [expr $vec_sum_y/$vec_size]
	
	#~ set dx [expr int($x_norm*2*rand()*$T/8)]
	#~ set dy [expr int($y_norm*2*rand()*$T/8)]
	set dir_x [expr rand() > 0.5 ? 1 : -1]
	set dir_y [expr rand() > 0.5 ? 1 : -1]
	set dx [expr $dir_x*(int(rand()*10*$T/8)%($::params(screen_size)/2))]
	set dy [expr $dir_y*(int(rand()*10*$T/8)%($::params(screen_size)/2))]
	lassign [list [expr $x0+$dx] [expr $y0+$dy]] new_x new_y
	set screen_size $::params(screen_size)
	if {$new_x>$screen_size} {set new_x $screen_size; set dx [expr $screen_size-$x0]}
	if {$new_x<0} {set new_x 0; set dx -$x0}
	if {$new_y>$screen_size} {set new_y $screen_size; set dy [expr $screen_size-$y0]}
	if {$new_y<0} {set new_y 0; set dy -$y0}
	
	set table_size 88
	set title "Movement Table"
	puts [format "|%s%s%s|" [string repeat "-" [expr $table_size/2-[string length $title]]] $title [string repeat "-" [expr $table_size/2]]]
	puts [format "|%s|" [string repeat "-" $table_size]]
	set before [list "(" [expr int($x0)] "," [expr int($y0)] ")"]
	set after [list "(" [expr int($x0+$dx)] "," [expr int($y0+$dy)] ")"]
	if {$dy>0} {
		set direction "S"
	} else {
		set direction "N"
	} 
	if {$dx<0} {
		set direction [string cat $direction "W"]
	} else {
		set direction [string cat $direction "E"]
	}
	puts [format "|%-11s %-15s %-12s %-15s %-12s %-18s|" "Node#" "before" "after" "dx" "dy" "direction"]
	puts [format "|%-8s %-15s %-15s %-15s %-15s %-15s|" $id $before $after [expr int($dx)] [expr int($dy)] $direction]
	puts [format "|%s|" [string repeat "-" $table_size]]
	#puts "vec: ($vec_sum_x , $vec_sum_y)/$vec_size = ($x_norm , $y_norm)"
	
	
	
	
	return [list $new_x $new_y]
}


proc initial_energy { points_ptr c } {
	upvar $points_ptr points
	lassign $c c_1 c_2 c_3 c_4 
	lassign [get_all_ns $points_ptr] n1 n2 n3 n4
	puts "n1: $n1 n2: $n2 n3: $n3 n4: $n4"
	return [list [expr $c_1*$n1+$c_2*$n2+$c_3*$n3+$c_4*$n4] $n1 $n2 $n3 $n4]
}

proc new_energy_of_points { points_ptr id c e_info } {
	upvar $points_ptr points
	lassign $e_info old_e n(1) n(2) n(3) n(4)
	lassign $points($id) x0 y0
	lassign $c c_1 c_2 c_3 c_4 
	lassign $c c_(1) c_(2) c_(3) c_(4)
	### getting new energy by reducing the node's energy contribution and later on adding its new positioned contribution
	set size $::Vertices_count
	set red_n(1) [set red_n(3) [set red_n(4) 0]]
	#reduction of n1
	for {set j 1} {$j<$size} {incr j} {
		lassign $points($j) x1 y1
		if {$j eq $id} {continue}
		if {[expr $x1-$x0] == 0 && [expr $y1-$y0] == 0} {set x0 $x1+0.0001}
		set red_n(1) [expr $red_n(1) + 1.0/(pow($x1-$x0,2)+pow($y1-$y0,2))]
	}
	#reduction of n2
	set red_n(2) [distance_from_circle [list $x0 $y0]]
	
	set ::debug_intersection_start 1
	#reduction of n4
	if {$::debug_intersection} {
		puts "about to go over all connections to $id -> $::connections($id)"
	}
	foreach con $::connections($id) {
		#here con and id are 2 node that represent an edge
		#going over all existing edges and counting those that intersect with con-id
		if {$::debug_intersection} {
			puts "checking [array size ::con_mat] options on ($con $id)"
			_pause
		}
		foreach pair [array names ::con_mat] {
			lassign [split $pair ,] u v
			if {$u eq $id || $v eq $con || $u eq $con || $v eq $id } {continue}
			if {$::debug_intersection && $::debug_intersection_cond} {
				foreach canvas_id [array names ::temp_ids] { .c delete $::temp_ids($canvas_id) ; sleep 10}
				puts "testing intersection between edges ($u $v) ($con $id) -> edges_intersect $u $v $con $id"
				foreach edge [list [list $u $v] [list $con $id]] {
					lassign $edge uuu vvv
					#draw all connections to point (node)
					lassign $::points($vvv) x0 y0
					lassign $::points($uuu) x1 y1
					#puts "connected to p_id: $connection (x,y) ($x0,$y0)"
					lappend ::temp_ids($edge) [.c create line $x0 $y0 $x1 $y1 -fill red]
					sleep 10
				}
			}
			if {[set intersect [edges_intersect $u $v $con $id]]} {
				incr red_n(4)
				if {$::debug_intersection && $::debug_intersection_cond} {_pause}
			}
			if {$::debug_intersection && $::debug_intersection_cond} {
				puts "edges intersect result: $intersect"
			}
		}
		#reduction of n3
		lassign $points($con) x1 y1
		set red_n(3) [expr $red_n(3) + pow($x1-$x0,2) + pow($y1-$y0,2)]
	}

	set diff_reduction [expr $c_1*$red_n(1) + $c_2*$red_n(2) + $c_3*$red_n(3) + $c_4*$red_n(4)]
	set energy_without_id_node [expr $old_e - $diff_reduction]
	#here energy_without_id_node holds the energy without the energy of the node_id
	#now we will add its new locations energy
	set new_n(1) [set new_n(3) [set new_n(4) 0]]
	set table_size 118
	set title "###############NODE: $id#################"
	puts [format "|%s|" [string repeat "-" $table_size]]
	puts [format "|%s%s%s|" [string repeat "-" [expr $table_size/2-[string length $title]/2]] $title [string repeat "-" [expr $table_size/2-[string length $title]/2-1]]]
	lassign $points($id) old_x old_y
	lassign [new_position $id] new_x new_y
	set points($id) [list $new_x $new_y]
	lassign $points($id) x0 y0
	#addition of new n1
	for {set j 1} {$j<$size} {incr j} {
		lassign $points($j) x1 y1
		if {$j eq $id} {continue}
		if {[expr $x1-$x0] == 0 && [expr $y1-$y0] == 0} {set x0 $x1+0.0001}
		set new_n(1) [expr $new_n(1) + 1.0/(pow($x1-$x0,2)+pow($y1-$y0,2))]
	}
	#addition of new n2
	set new_n(2) [distance_from_circle $points($id)]
	
	#addition of new n4
	foreach con $::connections($id) {
		foreach pair [array names ::con_mat] {
			lassign [split $pair ,] u v
			if {$u eq $id || $v eq $con || $u eq $con || $v eq $id } {continue}
			if {[set intersect [edges_intersect $u $v $con $id]]} {incr new_n(4)}
		}
		#addition of new n3
		lassign $points($con) x1 y1
		set new_n(3) [expr $new_n(3) + pow($x1-$x0,2) + pow($y1-$y0,2)]
	}
	set updated_n(1) [expr $n(1)-$red_n(1)+$new_n(1)]
	set updated_n(2) [expr $n(2)-$red_n(2)+$new_n(2)]
	set updated_n(3) [expr $n(3)-$red_n(3)+$new_n(3)]
	set updated_n(4) [expr $n(4)-$red_n(4)+$new_n(4)]
	#puts "new(1,2,3,4) ($new_n1 , $new_n2 , $new_n3 , $new_n4)"
	set diff_addition [expr $c_1*$new_n(1) + $c_2*$new_n(2) + $c_3*$new_n(3) + $c_4*$new_n(4)]
	set new_e [expr $energy_without_id_node + $diff_addition]
	set total_diff [expr $new_e-$old_e]
	if {$total_diff>0} {set indicator "(X)"} else { set indicator "(O)"}
	set title "Energy Table"
	puts [format "|%s%s%s|" [string repeat "-" [expr $table_size/2-[string length $title]]] $title [string repeat "-" [expr $table_size/2]]]
	puts [format "|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-15s|" "Var" "Before" "New" "reduced(n)" "reduced(n*c)" "added(n)" "added(n*c)" "diff(n*c)"]
	for {set i 1} {$i<=4} {incr i} {
		puts [format "|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-15s|" "n$i" [format "%.2lf" $n($i)] [format "%.2lf" $updated_n($i)] [format "%.2lf" $red_n($i)] [format "%.2lf" [expr $c_($i)*$red_n($i)]] [format "%.2lf" $new_n($i)] [format "%.2lf" [expr $c_($i)*$new_n($i)]] [format "%.2lf" [expr $c_($i)*($new_n($i)-$red_n($i))]]]
		if {$::log && $indicator eq "(O)"} {
			eval set f [open ${::log_file}_n${i}.log a]
			puts $f "[clock clicks] $updated_n($i)"
			close $f
		}
	}
	#~ puts [format "|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-12s|" "n2" [format "%.4lf" $n2] [format "%.4lf" $updated_n2] [format "%.4lf" $red_n2] [format "%.4lf" [expr $c_2*$red_n2]] [format "%.4lf" $new_n2] [format "%.4lf" [expr $c_2*$new_n2]] [format "%.4lf" [expr $c_2*($new_n2-$red_n2)]]]
	#~ puts [format "|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-12s|" "n3" [format "%.4lf" $n3] [format "%.4lf" $updated_n3] [format "%.4lf" $red_n3] [format "%.4lf" [expr $c_3*$red_n3]] [format "%.4lf" $new_n3] [format "%.4lf" [expr $c_3*$new_n3]] [format "%.4lf" [expr $c_3*($new_n3-$red_n3)]]]
	#~ puts [format "|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-12s|" "n4" [format "%.4lf" $n4] [format "%.4lf" $updated_n4] [format "%.4lf" $red_n4] [format "%.4lf" [expr $c_4*$red_n4]] [format "%.4lf" $new_n4] [format "%.4lf" [expr $c_4*$new_n4]] [format "%.4lf" [expr $c_4*($new_n4-$red_n4)]]]
	puts [format "|%s|" [string repeat "-" $table_size]]
	puts [format "|%-8s %-15s %-15s %-15s %-15s %-15s|" "Energy" "before" "diff_reduction" "diff_addition" "after" "total_diff"]
	puts [format "|%-8s %-15s %-15s %-15s %-15s %-15s|" "Energy" [format "%.4lf" $old_e] [format "%.4lf" $diff_reduction] [format "%.4lf" $diff_addition] [format "%.4lf" $new_e] [format "%.4lf %s" $total_diff $indicator]]
	puts [format "|%s|" [string repeat "-" 88]]
	set new_e_info [list $new_e $updated_n(1) $updated_n(2) $updated_n(3) $updated_n(4)]
	return [list $e_info $new_e_info [list $new_x $new_y]]
	
}

proc get_all_ns {points_ptr} {
	upvar $points_ptr points
	set n1 [set n2 [set n3 [set n4 0]]]
	set size [array size points]
	for {set i 1} {$i<[expr $size-1]} {incr i} {
		lassign $points($i) x0 y0
		#getting n2
		set n2 [expr $n2 + [distance_from_circle [list $x0 $y0]]]
		for {set j [expr $i+1]} {$j<$size} {incr j} {
			lassign $points($j) x1 y1
			#getting n1
			set n1 [expr $n1 + 1.0/(pow($x1-$x0,2)+pow($y1-$y0,2))]
			if {![info exists ::con_mat($i,$j)]} {continue}
			#getting n4
			foreach con [array names ::con_mat] {
				lassign [split $con ,] u v
				if {$u eq $i && $v eq $j} {continue}
				if {[edges_intersect $u $v $i $j]} {
					set key [lsort [list [list $u $v] [list $i $j]]]
					if {![info exists done($key)]} {
						incr n4
						set done($key) 1
					}
				}
			}
			array unset done
		}
	}
	#getting n3
	foreach con [array names ::con_mat] {
		lassign [split $con ,] u v
		lassign $points($u) x0 y0
		lassign $points($v) x1 y1
		set n3 [expr $n3 + pow($x1-$x0,2) + pow($y1-$y0,2)]
		#puts "from $con u-$u v-$v -> incr n3 [expr $n3 + pow($x1-$x0,2) + pow($y1-$y0,2)] -> pow($x1-$x0,2) = [expr pow($x1-$x0,2)]"
		
	}
	
	return [list $n1 $n2 $n3 $n4]
}

proc edges_intersect {first_u first_v second_u second_v} {
	global points
	#lassign $e1 u1 v1
	#lassign $e2 u2 v2
	set p1 $points($first_u) 
	set q1 $points($first_v) 
	set p2 $points($second_u) 
	set q2 $points($second_v) 
	
	set o1 [orientation $p1 $q1 $p2] 
    set o2 [orientation $p1 $q1 $q2]
    set o3 [orientation $p2 $q2 $p1] 
    set o4 [orientation $p2 $q2 $q1] 
	
	#~ if {$::debug_intersection_start && $::debug_intersection && $::debug_intersection_cond} {
		#~ puts "first edge: $first_u $first_v --> seond enge: $second_u $second_v o1: $o1 o2: $o2 o3: $o3 o4: $o4"
		#~ puts "$o1 && onSegment $p1 $p2 $q1 [onSegment $p1 $p2 $q1]"
		#~ puts "$o2 && onSegment $p1 $q2 $q1 [onSegment $p1 $q2 $q1]"
		#~ puts "$o3 && onSegment $p1 $q2 $q1 [onSegment $p1 $q2 $q1]"
		#~ puts "$o4 && onSegment $p1 $q2 $q1 [onSegment $p1 $q2 $q1]"
	#~ }
	
    # General case 
    if {$o1 ne $o2 && $o3 ne $o4} { return 1 }
	
    # Special Cases 
    # p1, q1 and p2 are colinear and p2 lies on segment p1q1 
    if {$o1 == "colinear" && [onSegment $p1 $p2 $q1]} { return 1 } 
  
    # p1, q1 and q2 are colinear and q2 lies on segment p1q1 
    if {$o2 == "colinear" && [onSegment $p1 $q2 $q1]} { return 1 } 
  
    # p2, q2 and p1 are colinear and p1 lies on segment p2q2 
    if {$o3 == "colinear" && [onSegment $p2 $p1 $q2]} { return 1 } 
  
    # p2, q2 and q1 are colinear and q1 lies on segment p2q2 
    if {$o4 == "colinear" && [onSegment $p2 $q1 $q2]} { return 1 } 
    
    return 0; # Doesn't fall in any of the above cases 
}

proc onSegment { p1 q1 r } { 
	
	lassign $p1 p_x p_y
	lassign $q1 q_x q_y
	lassign $r r_x r_y
    if {$q_x <= [max $p_x $r_x] && $q_x >= [min $p_x $r_x] && 
        $q_y <= [max $p_y $r_y] && $q_y >= [min $p_y $r_y]} { return 1 }
    return 0 
} 
  
# To find orientation of ordered triplet (p, q, r). 
# The function returns following values 
# 0 --> p, q and r are colinear 
# 1 --> Clockwise 
# 2 --> Counterclockwise 
proc orientation {p1 q1 r} { 
	lassign $p1 p_x p_y
	lassign $q1 q_x q_y
	lassign $r r_x r_y
    set val [expr ($q_y - $p_y) * ($r_x - $q_x) - ($q_x - $p_x) * ($r_y - $q_y)]
    if {$val == 0} {return "colinear"}  ;# colinear 
    if {[expr ($val > 0)]} {return "clock"} else {return "counterclock"} ;# clock or counterclock wise 
} 


proc distance_from_circle {pos} {
	lassign $pos x y
	set circle_center 0.5
	#getting x points
	return sqrt(pow($x-$circle_center,2)+pow($y-$circle_center,2))
}

proc prob_calc { old_e new_e T } {
	set p [expr 1 - pow($::e,($old_e-$new_e)/$T)]
	set rand [expr rand()]
	if {$rand<$p} {set big_small ">" ;set move_happend "(X)"} else {set big_small "<" ; set move_happend "(O)"}
	set table_size 88
	set title "Probability Table"
	puts [format "|%s%s%s|" [string repeat "-" [expr $table_size/2-[string length $title]]] $title [string repeat "-" [expr $table_size/2]]]
	puts [format "|%s|" [string repeat "-" $table_size]]
	puts [format "|    %sU(old)-U(cur)%s%-10s%49s" [string repeat " " 6] [string repeat " " 7] [format "%.5lf" [expr $old_e-$new_e]] "|"]
	puts [format "|    %s%s%s%s%48s" [string repeat " " 6] [string repeat "-" 11] [string repeat " " 9] [string repeat "-" 11] "|"]
	puts [format "|    %sT%s%s%51s" [string repeat " " 10] [string repeat " " 20] $T "|"]
	puts [format "|    1 - e%s= 1 - e%s= P = %.4lf %s %.4lf = random number%9s" [string repeat " " 17] [string repeat " " 10] $p $big_small $rand "$move_happend|"]
	puts [format "|%s|" [string repeat "-" 88]]
	if {$rand<$p} {return 1}
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

#~ proc _pause {} {
	#~ set redraw 1
	#~ puts "paused: press n to exit:"
	#~ gets stdin val
	#~ if {$val eq "n"} {
		#~ error "broke program by pressing \"n\""
	#~ }
	#~ set redraw 0
	#~ return
#~ }
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
