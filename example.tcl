#! /usr/bin/env tclsh

package require Tk

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
	set delta 7
	if {[info exists ::canvas_e_id]} {
		foreach id [array names ::canvas_e_id] { foreach i $::canvas_e_id($id) {.c delete $i }}
	}
	if {[info exists ::canvas_v_id]} {
		foreach id [array names ::canvas_v_id] { .c delete $::canvas_v_id($id) }
	}
	foreach point_id [array names ::points] {
		lassign $::points($point_id) x0 y0
		set x0 [expr $x0]
		set y0 [expr $y0]
		#puts "p_id: $point_id (x,y) ($x0,$y0)"
		#draw point (node)
		set ::canvas_v_id($point_id) [.c create oval [expr $x0-$delta] [expr $y0-$delta] [expr $x0+$delta] [expr $y0+$delta] -fill red]
		
		foreach connection $::connections($point_id) {
			#draw all connections to point (node)
			lassign $::points($connection) x1 y1
			set x1 [expr $x1]
			set y1 [expr $y1]
			#puts "connected to p_id: $connection (x,y) ($x0,$y0)"
			lappend ::canvas_e_id($point_id) [.c create line $x0 $y0 $x1 $y1 -fill gray]
		}
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

proc # args {}

proc lvarpop {ptr} {
	upvar $ptr p
	set ret [lindex $p 0]
	set p [lrange $p 1 end]
	return $ret
}

proc read_net_from_file {path} {
	set file [open $path r]
	set data [read $file]
	set delta 7
	set data [split $data "\n"]
	lassign [lvarpop data] - ::Vertices_count
	set r [expr $::params(screen_size)/2.0-$::params(padd)]
	set offset [expr $r+$::params(padd)]
	set alfa_change [expr (360.0/$::Vertices_count)]
	set pi [expr atan(1) * 4]
	set conv_rad [expr $pi/180]
	for {set i 0} {$i<$::Vertices_count} {incr i} {
		#set x0 [expr int(rand()*pow(10,[string size $::params(screen_size)]))%$::params(screen_size)]
		#set y0 [expr int(rand()*pow(10,[string size $::params(height)]))%$::params(height)]
		set alfa [expr 1.0*$i*$alfa_change]
		set x0 [expr 1.0*$r*cos($alfa*$conv_rad)+$offset]
		set y0 [expr 1.0*$r*sin($alfa*$conv_rad)+$offset]
		set ::points([expr $i+1]) [list $x0 $y0]
		set ::connections([expr $i+1]) [list]
	}
	lassign [lvarpop data] -
	foreach pair $data {
		lassign $pair index friend
		#puts "index: $index , coords: $coords shape: $shape_type"
		lappend ::connections($index) $friend ;#[list [expr $x0-$delta] [expr $y0-$delta] [expr $x0+$delta] [expr $y0+$delta]]
	}
	
	for {set i 1} {$i<=[expr $::Vertices_count-1]} {incr i} {
		for {set j $i} {$j<=$::Vertices_count} {incr j} {
			if {[lcontain $::connections($i) $j]} {
				set ::con_mat($i,$j) 1
				set ::con_mat($j,$i) 1
			} else {
				set ::con_mat($i,$j) 0
				set ::con_mat($j,$i) 0
			}
		}
	}
	for {set i 1} {$i <= $::Vertices_count} {incr i} {set ::con_mat($i,$i) 0}
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
	set T 50
	
	
	set ind 1
	while ( $T > $threshold ) {
		foreach node_id [array names ::points] {
			lassign $::points($node_id) old_x old_y
			set new_x [new_position $old_x]
			set new_y [new_position $old_y]
			set new_position [list $new_x $new_y]
			set old_position $::points($node_id)
			if { [energy_of_point $node_id $old_position] < [energy_of_point $node_id $new_position]} {
				if { [prob_calc $old_position $new_position]} {
					set ::points($node_id) $new_position
				}
			}
		}
		if {$ind%400==0} {
			draw_graph
			sleep 100
			set ind 1
		}
		incr ind
		incr threshold
	}
	
	return
}

proc new_position { p } {
	set pow_thresh 2
	set res [expr ($p+int(rand()*pow(10,$pow_thresh)))%$::params(screen_size)]
	return $res
}

proc energy_of_point { node_id position } {
	set c_1 1
	set c_2 1
	set c_3 1
	set c_4 1
	
	lassign [get_all_ns $node_id] n1 n2 n3 n4
	
	
	
}

proc get_all_ns {id} {
	set delta 0
	lassign $::poinst($id) x0 y0
	set node_id_l [set node_id_r [set node_id_t [set node_id_b 0]]]
	foreach node_id [array names ::points] {
		lassign $::points($node_id) x1 y1
		#getting n1
		set delta [expr $delta+sqrt(pow($x1-$x0,2)+pow($y1-$y0,2))]
		#getting n2
		lassign [distance_from_circle [list $x1 $y1]] l r t b
		set node_id_l [expr $node_id_l+$l]
		set node_id_r [expr $node_id_r+$r]
		set node_id_t [expr $node_id_t+$t]
		set node_id_b [expr $node_id_b+$b]
		#getting n3
		
	}
}

proc distance_from_circle {pos} {
	lassign $pos x y
	set r [expr $::params(screen_size)/2.0]
	set h [expr $r]
	#getting x points
	set c [expr 2*pow($h,2)-pow($r,2)+pow($y,2)-2*$y*$h]
	set precalc_sqrt [expr sqrt(pow($h,2)-$c)]
	set x_1 [expr $h + $precalc_sqrt]
	set x_2 [expr $h - $precalc_sqrt]
	#getting y points
	set c [expr 2*pow($h,2)-pow($r,2)+pow($x,2)-2*$x*$h]
	set precalc_sqrt [expr sqrt(pow($h,2)-$c)]
	set y_1 [expr $h + $precalc_sqrt]
	set y_2 [expr $h - $precalc_sqrt]
	return [list $x_1 $x_2 $y_1 $y_2]
}

proc prob_calc { position_old position_new } {
	#TODO get probability of change
	
}

proc cluster_points  {} {
	#set parameters like k for spring tention
	set max_movement 200
	set n 0
	set k 0.1
	while {$n<90} {
		for {set i 1} {$i <= $::Vertices_count} {incr i} {
			lassign $::points($i) x y
			set repulsion_vecs [set attract_vecs [list]]
			for {set j 1} {$j <= $::Vertices_count} {incr j} {
				lassign $::points($j) con_x con_y
				set dx [expr $con_x-$x]
				set dy [expr $con_y-$y]
				if {$::con_mat($i,$j) == 1} {
					lappend attract_vecs [list $dx $dy]
				} else {
					lappend repulsion_vecs [list $dx $dy]
				}
			}
			set att_vec_sum [get_vector_sum $attract_vecs]
			set rep_vec_sum [get_vector_sum $repulsion_vecs]
			
			lassign $att_vec_sum att_dx att_dy
			if {[expr abs($att_dx)] > $max_movement} {if {$att_dx>0} {set att_dx $max_movement} else {set att_dx -$max_movement}}
			if {[expr abs($att_dy)] > $max_movement} {if {$att_dy>0} {set att_dy $max_movement} else {set att_dy -$max_movement}}
			
			
			lassign $rep_vec_sum rep_dx rep_dy
			if {[expr abs($rep_dx)] > $max_movement} {if {$rep_dx>0} {set rep_dx $max_movement} else {set rep_dx -$max_movement}}
			if {[expr abs($rep_dy)] > $max_movement} {if {$rep_dy>0} {set rep_dy $max_movement} else {set rep_dy -$max_movement}}
			
			lassign [list [expr $att_dx-$rep_dx] [expr $att_dy-$rep_dy]] dx dy
			
			set new_x [expr int($x+$dx*$k)]
			set new_y [expr int($y+$dy*$k)]
			
			#making sure not leaving screen reagion
			if {$new_x>$::params(screen_size)} {
				set new_x $::params(screen_size)
			} elseif {$new_x<0} {
				set new_x 0
			}
			if {$new_y>$::params(screen_size)} {
				set new_y $::params(screen_size)
			} elseif {$new_y<0} {
				set new_y 0
			}
			
			set ::points($i) [list $new_x $new_y]
		}
		draw_graph
		#_pause
		#at this point we should normalize the canvas with the graph 
		#to make sure all verticses are spread on all width and height
		puts "finished iteration $n on [array size ::points] vertixes"
		incr n		
	}
		
		
	draw_graph
}

proc get_vector_sum {vectores} {
	set sum_x 0
	set sum_y 0
	foreach vec $vectores {
		lassign $vec x y 
		incr sum_x [expr int($x)]
		incr sum_y [expr int($y)]
	}
	return [list $sum_x $sum_y]
}

proc _pause {} {
	puts "paused: press n to exit:"
	gets stdin val
	if {$val eq "n"} {
		error "broke program by pressing \"n\""
	}
	return
}

read_net_from_file HW2Net.net

draw_graph



