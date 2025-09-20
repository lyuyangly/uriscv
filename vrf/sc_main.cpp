#include <sys/stat.h>
#include <systemc.h>
#include <verilated.h>
#include <verilated_vcd_sc.h>
#include "Vtop.h"

int sc_main(int argc, char* argv[]) {
    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Set debug level, 0 is off, 9 is highest presently used
    Verilated::debug(0);

    // Randomization reset policy
    Verilated::randReset(2);

    // Before any evaluation, need to know to calculate those signals only used for tracing
    Verilated::traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // General logfile
    ios::sync_with_stdio();

    // Define clocks
    sc_clock clk{"clk", 10, SC_NS, 0.5, 3, SC_NS, true};

    // Define interconnect
    sc_signal<bool> rst_n;
    sc_signal<bool> intr_i;
    sc_signal<uint32_t> pio;

    // Construct the Verilated model, from inside Vtop.h
    Vtop *top{new Vtop{"top"}};

    // Attach Vtop's signals to this upper model
    top->clk(clk);
    top->rst_n(rst_n);
    top->intr_i(intr_i);
    top->pio(pio);

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
    sc_start(SC_ZERO_TIME);

    VerilatedVcdSc* tfp = nullptr;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0 == std::strcmp(flag, "+trace")) {
        std::cout << "Enabling waves into logs/wave.vcd...\n";
        tfp = new VerilatedVcdSc;
        top->trace(tfp, 99);  // Trace 99 levels of hierarchy
        Verilated::mkdir("logs");
        tfp->open("logs/wave.vcd");
    }

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
        // Flush the wave files each cycle so we can immediately see the output
        // Don't do this in "real" programs, do it in an abort() handler instead
        if (tfp) tfp->flush();

        // Apply inputs
        if (sc_time_stamp() > sc_time(0, SC_NS) && sc_time_stamp() < sc_time(100, SC_NS)) {
            rst_n = 0;  // Assert reset
            intr_i = 0;
        } else {
            rst_n = 1;  // Deassert reset
        }

        if (sc_time_stamp() >= sc_time(50, SC_US)) {
            sc_stop();
        }

        // Simulate 1ns
        sc_start(1, SC_NS);
    }

    // Final model cleanup
    top->final();

    // Close trace if opened
    if (tfp) {
        tfp->close();
        tfp = nullptr;
    }

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Return good completion status
    return 0;
}
