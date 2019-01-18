# SimulatedAnnealing

mini-project imitating algorithem from article:

3 options to run the following code

option 1:

A simple run of the algorithem with input of input_net_path output_net_path and optional vizualization tcl script

the input net should have 136 nodes. for different value change N definition to desired quantity

to run this:

gcc src/simulate_annealing_alg.c -o run_alg.o -lm

./run_alg.o <input_network_path.net> <output_network_path.net> [realpath_to_tcl_gui]

example:

./run_alg.o networks/HW2Net.net output/alg_results.net /home/cky800/git/simulating_annealing/simulatedannealing/src/vizualize_graph.tcl


Option 2:

When starting the project I had to find the perfect parameters for it to work out and show me a clusterized graph as output so I built an automation to find optimal parameters by scouting. 

to run the parent version where parameter testing is beeing made
you may edit the loops values and run with any desired parameters

gcc test_params/parallel_simulating_annealing_parent.c -o master.o -lm

gcc test_params/simulating_annealing_alg_with_params.c -o child.o -lm

./master <realpath_to_child>

example:

./master /home/cky800/git/simulating_annealing/simulatedannealing/child_take_param.o

Option 3:

After running the automatic parameter search I had to manually choose which output cluster was good and which was useless

So by running:

cd test_params
./analyze_params.tcl

This will open and draw each of the created nets from Option 2 and we can click 'y' or 'n' to filter good and bad nets for later analasys to find optimal parameters.
 
after finishing to filter all created nets we run the analyzer

./analyze.tcl


