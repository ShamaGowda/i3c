.IGNORE:
	compile
	simulate

.SILENT:
	compile
	simulate
	usage

usage:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------------- Usage ---------------------------------";
	echo "";
	echo "make target <options> <variable>=<value>";
	echo "";
	echo "To compile use:"
	echo "make compile";
	echo "";
	echo "To simulate individual test:"
	echo "make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>";
	echo "";
	echo "Example:";
	echo "make simulate test=base_test uvm_verbosity=UVM_HIGH";
	echo "";
	echo "To provide seed number (default is random):";
	echo "make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL> seed=<value>";
	echo "";
	echo "To run regression:"
	echo "make regression testlist_name=<regression_testlist_name.list>";
	echo "";
	echo "To run regression with specific number of seeds (default=10):";
	echo "make regression testlist_name=<list> num_seeds=<N>";
	echo "";
	echo "Example:";
	echo "make regression testlist_name=i3c_standard_mode_regression.list num_seeds=20";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";

all:
	make clean; make compile; make simulate;

compile:
	make clean_compile;
	make clean_simulate;
	vlib work; 
	vlog -sv \
	+acc \
	+cover \
	+fcover \
	-l i3c_compile.log \
	-f ../i3c_compile.f 

	make compile_war_err


ifndef test
override test = i3cAllSeqTest
endif

ifndef seed
override seed = random 
endif

ifndef uvm_verbosity
override uvm_verbosity = UVM_MEDIUM
endif

ifndef test_folder
override test_folder = $(test)
endif

ifndef num_seeds
override num_seeds = 10
endif

simulate:
	mkdir -p $(test_folder)

	vsim -vopt \
	work.hvl_top \
	work.hdl_top \
	-voptargs=+acc=npr \
	-sv_seed $(seed) \
	-assertdebug \
	+UVM_TESTNAME=$(test) \
	+UVM_VERBOSITY=$(uvm_verbosity) \
	+define+$(i3c_type) \
	-l $(test_folder)/$(test).log \
	-sva \
	-coverage \
	-c -do "log -r /*; add wave -r /*; coverage save -onexit -assert -directive -cvg -codeAll -testname $(test)_seed$(seed) $(test_folder)/$(test)_coverage.ucdb; run -all; exit" \
	-wlf $(test_folder)/waveform.wlf

	make simulate_war_err

	vcover report -html $(test_folder)/$(test)_coverage.ucdb \
	              -htmldir $(test_folder)/html_cov_report \
	              -details

clean_simulate:
	rm -rf *_test* *_seed*

clean_compile:
	rm -rf work/ *_compile.log transcript waveform.wlf
	rm -rf merged_coverage.ucdb merged_cov_html_report

clean:
	make clean_compile
	make clean_simulate

regression:
	make compile
	python regression_handling.py $(testlist_name) $(num_seeds)
	make merge_cov_report

merge_cov_report:
	rm -rf merged_coverage.ucdb merged_cov_html_report
	
	vcover merge -testassociated merged_coverage.ucdb -64 *_seed*/*.ucdb
	vsim -c -do exclude_cov.do

	vcover report -html merged_coverage.ucdb \
	              -htmldir ./merged_cov_html_report \
	              -details

	echo "";
	echo "-----------------------------------------------------------------";
	echo "Coverage report: firefox merged_cov_html_report/index.html &"
	echo "-----------------------------------------------------------------";
	echo "";

compile_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------- Compilation Report --------------------------";
	echo "";
	grep "^** " i3c_compile.log;
	echo "";
	grep "^Error" i3c_compile.log;
	echo "";
	echo "Log file path: i3c_compile.log"
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";

simulate_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-------------------- Simulation Report --------------------------";
	echo "";
	echo "Simulator Errors";
	grep "Error" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Fatal";
	grep "UVM_FATAL" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Errors";
	grep "UVM_ERROR" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Warnings";
	grep "UVM_WARNING" $(test_folder)/$(test).log;
	echo "";
	echo "Testname: $(test)"
	echo "";
	echo "Log file path: $(test_folder)/$(test).log"
	echo "";
	echo "Waveform: vsim -view $(test_folder)/waveform.wlf &"
	echo "";
	echo "Coverage report: firefox $(test_folder)/html_cov_report/index.html &"
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";
