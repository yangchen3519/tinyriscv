// bridge@core侧
// 1. 接收RIB侧请求，并组织为发送到 FPGA 的 6-byte 数据包
// 2. 接收 FPGA 返回的 4-byte 读数据，并拼接成 32-bit 返回给 RIB 侧

`include "../core/defines.v"

module bridge_core(

    input wire clk,
    input wire rst,

    // RIB side
    input wire req_i,
    input wire we_i,
    input wire[`MemAddrBus] addr_i,
    input wire[`MemBus] data_i,
    output reg[`MemBus] data_o,
    output reg ack_o,
    output wire hold_flag_o,

    // bridge@FPGA side
    output reg[7:0] tx_data_o,
    output reg tx_valid_o,
    input wire[7:0] rx_data_i

    );

    localparam [2:0] IDLE    = 3'd0;
    localparam [2:0] TX_CMD  = 3'd1;
    localparam [2:0] TX_ADDR = 3'd2;
    localparam [2:0] TX_DATA = 3'd3;
    localparam [2:0] RX_DATA = 3'd4;

    localparam [3:0] RAM_ADDR_TOP = 4'h1;

    reg[2:0] state;
    reg[1:0] byte_cnt;
    reg req_block;
    reg trans_we;
    reg trans_target;
    reg[`RomAddrBus] trans_addr;
    reg[`MEMBUS:0] trans_wdata;
    reg[`MEMBUS:0] trans_rdata;

    wire is_ram_req;
    wire start_req;
    wire[`RomAddrBus] phy_addr;
    wire[7:0] cmd_byte;

    assign is_ram_req = (addr_i[31:28] == RAM_ADDR_TOP);
    assign start_req = (req_i == `RIB_REQ) && (req_block == 1'b0);
    assign phy_addr = is_ram_req ? {4'h0, addr_i[5:2]} : addr_i[9:2];
    assign cmd_byte = {trans_we, trans_target, 6'b0};

    // 新请求启动以及事务进行期间都需要拉高hold
    assign hold_flag_o = (state != IDLE) || start_req;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= IDLE;
            byte_cnt <= 2'b00;
            req_block <= 1'b0;
            trans_we <= `WriteDisable;
            trans_target <= 1'b0;
            trans_addr <= 8'h0;
            trans_wdata <= `ZeroWord;
            trans_rdata <= `ZeroWord;
            data_o <= `ZeroWord;
            ack_o <= `RIB_NACK;
            tx_data_o <= 8'h0;
            tx_valid_o <= 1'b0;
        end else begin
            ack_o <= `RIB_NACK;
            tx_valid_o <= 1'b0;
            if (req_block == 1'b1) begin
                req_block <= 1'b0;
            end

            case (state)
                IDLE: begin
                    tx_data_o <= 8'h0;
                    if (start_req) begin
                        byte_cnt <= 2'b00;
                        trans_we <= we_i;
                        trans_target <= is_ram_req;
                        trans_addr <= phy_addr;
                        trans_wdata <= data_i;
                        state <= TX_CMD;
                    end
                end

                TX_CMD: begin
                    tx_valid_o <= 1'b1;
                    tx_data_o <= cmd_byte;
                    state <= TX_ADDR;
                end

                TX_ADDR: begin
                    tx_valid_o <= 1'b1;
                    tx_data_o <= trans_addr;
                    byte_cnt <= 2'b00;
                    if (trans_we == `WriteEnable) begin
                        state <= TX_DATA;
                    end else begin
                        state <= RX_DATA;
                    end
                end

                TX_DATA: begin
                    tx_valid_o <= 1'b1;
                    case (byte_cnt)
                        2'd0: tx_data_o <= trans_wdata[7:0];
                        2'd1: tx_data_o <= trans_wdata[15:8];
                        2'd2: tx_data_o <= trans_wdata[23:16];
                        default: tx_data_o <= trans_wdata[31:24];
                    endcase

                    if (byte_cnt == 2'd3) begin
                        byte_cnt <= 2'b00;
                        req_block <= 1'b1;
                        ack_o <= `RIB_ACK;
                        state <= IDLE;
                    end else begin
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                end

                RX_DATA: begin
                    case (byte_cnt)
                        2'd0: trans_rdata[7:0] <= rx_data_i;
                        2'd1: trans_rdata[15:8] <= rx_data_i;
                        2'd2: trans_rdata[23:16] <= rx_data_i;
                        default: trans_rdata[31:24] <= rx_data_i;
                    endcase

                    if (byte_cnt == 2'd3) begin
                        byte_cnt <= 2'b00;
                        req_block <= 1'b1;
                        data_o <= {rx_data_i, trans_rdata[23:0]};
                        ack_o <= `RIB_ACK;
                        state <= IDLE;
                    end else begin
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
