# SimulatedAnnealing

mini-project imitating algorithem from article:

2 different types of running

first is a simple run of the algorithem with input of input_net_path output_net_path and optional vizualization tcl script

second is a parameter scouting trying to find good parameters that will result with good clustering.

to run this:

gcc src/simulate_annealing_alg.c -o run_alg.o -lm

./run_alg.o <input_network_path.net> <output_network_path.net> [realpath_to_tcl_gui]

example:

./run_alg.o networks/HW2Net.net output/alg_results.net /home/cky800/git/simulating_annealing/simulatedannealing/src/vizualize_graph.tcl

to ru nthe parent version where parameter testing is beeing made
you may edit the loops values and run with any desired parameters

gcc test_params/parallel_simulating_annealing_parent.c -o master.o -lm

gcc test_params/simulating_annealing_alg_with_params.c -o child.o -lm

./master <realpath_to_child>

example:

./master /home/cky800/git/simulating_annealing/simulatedannealing/child_take_param.o
