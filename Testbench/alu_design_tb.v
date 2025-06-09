`include "alu_design.v"
`define num_of_testcase 74
module alu_vtb();
    parameter w = 8;
    parameter stimulusWidth = (23 + 4*w);
    parameter responseWidth = (stimulusWidth + 2*w + 6);
    parameter dataBits = (6 + 2*w);
    reg [stimulusWidth - 1:0] curr_test_case = 0;
    reg [stimulusWidth - 1:0] stimulus_mem[0:`num_of_testcase - 1];
    reg [responseWidth - 1:0] response_packet;
    integer i;
    reg clk,rst,CE;
    event fetch_stimulus;
    reg[w-1:0] OPA,OPB;
    reg[3:0] CMD;
    reg MODE,cin;
    reg[7:0] feature_ID;
    reg[2:0] comparison_egl;
    reg[(2*w-1):0] expected_RES;
    reg err,cout,ov;
    reg[1:0] INP_valid;
    wire [2*w-1:0] RES;
    wire ERR,ov_wire,cout_wire;
    wire [2:0] egl;
    wire [dataBits-1:0] expected_data;
    reg [dataBits-1:0] exact_data;
    task readStimulus();
        begin
            #10 $readmemb("stimulus.txt", stimulus_mem);
        end
    endtask
    alu_design #(.W(w)) dut (
        .clk(clk),
        .rst(rst),
        .ce(CE),
        .mode(MODE),
        .cin(cin),
        .inp_valid(INP_valid),
        .cmd(CMD),
        .opa(OPA),
        .opb(OPB),
        .err(ERR),
        .ov(ov_wire),
        .cout(cout_wire),
        .g(egl[1]),
        .l(egl[0]),
        .e(egl[2]),
        .res(RES)
    );
    integer stim_mem_ptr = 0;
    always @(fetch_stimulus) begin
        curr_test_case = stimulus_mem[stim_mem_ptr];
        $display("stimulus_mem data = %0b", stimulus_mem[stim_mem_ptr]);
        $display("packet data = %0b", curr_test_case);
        stim_mem_ptr = stim_mem_ptr + 1;
    end
    initial begin
        clk = 0;
        forever #60 clk = ~clk;
    end
    task driver();
        begin
            ->fetch_stimulus;
            @(posedge clk);
            feature_ID = curr_test_case[(stimulusWidth-1) -: 8];
            INP_valid = curr_test_case[(stimulusWidth-9) -: 2];
            OPA = curr_test_case[(stimulusWidth-11) -: w];
            OPB = curr_test_case[(stimulusWidth-19) -: w];
            CMD = curr_test_case[(stimulusWidth-27) -: 4];
            cin = curr_test_case[(stimulusWidth-31) -: 1];
            CE = curr_test_case[(stimulusWidth-32) -: 1];
            MODE = curr_test_case[(stimulusWidth-33) -: 1];
            expected_RES = curr_test_case[(stimulusWidth-34) -: (2*w)];
            cout = curr_test_case[(stimulusWidth-50) -: 1];
            comparison_egl = curr_test_case[(stimulusWidth-51) -: 3];
            ov = curr_test_case[(stimulusWidth-54) -: 1];
            err = curr_test_case[(stimulusWidth-55) -: 1];
            $display("Driver | [%0t] | FEATURE_ID : %8b | INP_VALID : %2b | OPA : %8b | OPB : %8b | CMD = %3b | CIN : %b | CE : %b | MODE : %b | EXPECTED_RESULT : %16b | COUT : %b | EGL = %3b | OV : %b | ERR = %b |\n",
                     $time, feature_ID, INP_valid, OPA, OPB, CMD, cin, CE, MODE, expected_RES, cout, comparison_egl, ov, err);
        end
    endtask
    task monitor();
        begin
            repeat(5) @(posedge clk);
            #5 response_packet[stimulusWidth-1:0] = curr_test_case;
            response_packet[stimulusWidth] = ERR;
            response_packet[stimulusWidth+1] = ov_wire;
            response_packet[stimulusWidth+4:stimulusWidth+2] = egl;
            response_packet[stimulusWidth+5] = cout_wire;
            response_packet[stimulusWidth+21:stimulusWidth+6] = RES;
            $display("Monitor | [%0t] | RES : %16b | COUT : %b | EGL : %3b | OV : %b | ERR : %b |",
                     $time, RES, cout_wire, egl, ov_wire, ERR);
            exact_data = {RES, cout_wire, egl, ov_wire, ERR};
        end
    endtask
    assign expected_data = {expected_RES, cout, comparison_egl, ov, err};
    reg [31:0] failed_count;
    task score_board();
        begin
            $display("SCOREBOARD | EXPECTED RESULT : %22b | RESPONSE DATA : %22b |", expected_data, exact_data);
            if (expected_data === exact_data)
                $display("PASSED");
            else begin
                $display("FAILED");
                failed_count = failed_count + 1;
            end
            $display("No of TestCases Failed = %0d\n", failed_count);
        end
    endtask
    initial begin
        rst = 1;
        CE = 1;
        curr_test_case = 0;
        response_packet = 0;
        stim_mem_ptr = 0;
        failed_count = 0;
        #10 rst = 0;
        #10 rst = 1;
        #10 rst = 0;
        readStimulus();
        for (i = 0; i < `num_of_testcase; i = i + 1) begin
            fork
                driver();
                monitor();
            join
            score_board();
        end
        #10 CE = 0;
        #10 CE = 1;
        #10 CE = 0;
        #300 $finish;
    end
endmodule
