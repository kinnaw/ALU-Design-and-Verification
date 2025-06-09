module alu_design #(parameter W = 8)(
    input clk, rst, mode, ce, cin,
    input [1:0] inp_valid,
    input [7:0] opa, opb,
    input [3:0] cmd,
    output reg err, ov, cout, g, l, e,
    output reg [15:0] res
);

parameter INV_INP = 2'b00, OPA_VALID = 2'b01, OPB_VALID = 2'b10, OPA_AND_OPB_VALID = 2'b11;

`define ADD 4'b0000
`define SUB 4'b0001
`define ADD_CIN 4'b0010
`define SUB_CIN 4'b0011
`define INC_A 4'b0100
`define DEC_A 4'b0101
`define INC_B 4'b0110
`define DEC_B 4'b0111
`define CMP 4'b1000
`define MULT_INC 4'b1001
`define MULT_SHIFT_A 4'b1010
`define S_ADD 4'b1011
`define S_SUB 4'b1100

`define AND 4'b0000
`define NAND 4'b0001
`define OR 4'b0010
`define NOR 4'b0011
`define XOR 4'b0100
`define XNOR 4'b0101
`define NOT_A 4'b0110
`define NOT_B 4'b0111
`define SHR1_A 4'b1000
`define SHL1_A 4'b1001
`define SHR1_B 4'b1010
`define SHL1_B 4'b1011
`define ROL_A_B 4'b1100
`define ROR_A_B 4'b1101

reg [7:0] opa_p, opb_p;
reg [3:0] cmd_p;
reg [1:0] valid_p;
reg mode_p, cin_p;
reg [15:0] res_p;
reg cout_p, ov_p, g_p, l_p, e_p, err_p;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        opa_p <= 0;
        opb_p <= 0;
        cmd_p <= 0;
        valid_p <= 0;
        cin_p <= 0;
        mode_p <= 0;
    end else if (ce) begin
        opa_p <= opa;
        opb_p <= opb;
        cmd_p <= cmd;
        valid_p <= inp_valid;
        cin_p <= cin;
        mode_p <= mode;
    end
end

always @(*) begin
    res_p = 0;
    err_p = 0;
    cout_p = 0;
    ov_p = 0;
    g_p = 0;
    l_p = 0;
    e_p = 0;

    if (ce) begin
        if (mode_p == 1) begin
            case (valid_p)
                INV_INP: begin
                    res_p = 0;
                    err_p = 1;
                end
                OPA_VALID: begin
                    case (cmd_p)
                        `INC_A: begin
                            res_p = opa_p + 1;
                            cout_p = res_p[8];
                        end
                        `DEC_A: begin
                            res_p = opa_p - 1;
                            ov_p = res_p[8];
                        end
                        default: err_p = 1;
                    endcase
                end
                OPB_VALID: begin
                    case (cmd_p)
                        `INC_B: begin
                            res_p = opb_p + 1;
                            cout_p = res_p[8];
                        end
                        `DEC_B: begin
                            res_p = opb_p - 1;
                            ov_p = res_p[8];
                        end
                        default: err_p = 1;
                    endcase
                end
                OPA_AND_OPB_VALID: begin
                    case (cmd_p)
                        `ADD: begin
                            res_p = opa_p + opb_p;
                            cout_p = res_p[8];
                        end
                        `SUB: begin
                            res_p = opa_p - opb_p;
                            ov_p = res_p[8];
                        end
                        `ADD_CIN: begin
                            res_p = opa_p + opb_p + cin_p;
                            cout_p = res_p[8];
                        end
                        `SUB_CIN: begin
                            res_p = opa_p - opb_p - cin_p;
                            ov_p = res_p[8];
                        end
                        `CMP: begin
                            g_p = (opa_p > opb_p);
                            l_p = (opa_p < opb_p);
                            e_p = (opa_p == opb_p);
                        end
                        `MULT_INC: begin
                            res_p = (opa_p + 1) * (opb_p + 1);
                        end
                        `MULT_SHIFT_A: begin
                            res_p = (opa_p << 1) * opb_p;
                        end
                        `S_ADD: begin
                            res_p = $signed(opa_p) + $signed(opb_p);
                            ov_p = (($signed(opa_p) > 0) && ($signed(opb_p) > 0) && ($signed(res_p[7:0]) < 0)) ||
                                   (($signed(opa_p) < 0) && ($signed(opb_p) < 0) && ($signed(res_p[7:0]) > 0));
                        end
                        `S_SUB: begin
                            res_p = $signed(opa_p) - $signed(opb_p);
                            ov_p = (($signed(opa_p) > 0) && ($signed(opb_p) < 0) && ($signed(res_p[7:0]) < 0)) ||
                                   (($signed(opa_p) < 0) && ($signed(opb_p) > 0) && ($signed(res_p[7:0]) > 0));
                        end
                        default: err_p = 1;
                    endcase
                end
                default: err_p = 1;
            endcase
        end else begin
            case (valid_p)
                INV_INP: begin
                    res_p = 0;
                    err_p = 1;
                end
                OPA_VALID: begin
                    case (cmd_p)
                        `NOT_A: res_p = ~opa_p;
                        `SHR1_A: res_p = opa_p >> 1;
                        `SHL1_A: res_p = opa_p << 1;
                        default: err_p = 1;
                    endcase
                end
                OPB_VALID: begin
                    case (cmd_p)
                        `NOT_B: res_p = ~opb_p;
                        `SHR1_B: res_p = opb_p >> 1;
                        `SHL1_B: res_p = opb_p << 1;
                        default: err_p = 1;
                    endcase
                end
                OPA_AND_OPB_VALID: begin
                    case (cmd_p)
                        `AND: res_p = opa_p & opb_p;
                        `OR: res_p = opa_p | opb_p;
                        `NAND: res_p = ~(opa_p & opb_p);
                        `NOR: res_p = ~(opa_p | opb_p);
                        `XOR: res_p = opa_p ^ opb_p;
                        `XNOR: res_p = ~(opa_p ^ opb_p);
                        `ROL_A_B: begin
                            if (|opb_p[7:4]) err_p = 1;
                            else res_p = (opa_p << opb_p[2:0]) | (opa_p >> (8 - opb_p[2:0]));
                        end
                        `ROR_A_B: begin
                            if (|opb_p[7:4]) err_p = 1;
                            else res_p = (opa_p >> opb_p[2:0]) | (opa_p << (8 - opb_p[2:0]));
                        end
                        default: err_p = 1;
                    endcase
                end
                default: err_p = 1;
            endcase
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        res <= 0;
        cout <= 0;
        ov <= 0;
        g <= 0;
        l <= 0;
        e <= 0;
        err <= 0;
    end else if (ce) begin
        res <= res_p;
        cout <= cout_p;
        ov <= ov_p;
        g <= g_p;
        l <= l_p;
        e <= e_p;
        err <= err_p;
    end
end

endmodule
