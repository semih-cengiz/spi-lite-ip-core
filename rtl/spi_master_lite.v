`timescale 1ns / 1ps

module spi_master_lite #(
parameter DATA_WIDTH   = 32,
parameter CS_WIDTH     = 8,
parameter CS_SEL_WIDTH = 3
)(

input  wire                      clk,
input  wire                       rstn,
// Ax? protokolu ile haberlesme
input  wire                      enable,// SPI ip core'u aktif et
input  wire                      start,// Transfer baslat 
input  wire [DATA_WIDTH-1:0]     tx_data,// Gönderilecek veri
output reg  [DATA_WIDTH-1:0]     rx_data,// Alinan veri
input  wire [CS_SEL_WIDTH-1:0]   cs_select,// 8 CS 
input  wire [15:0]               prescaler,// SCLK bölücü 
output reg                       busy,// Transfer devam ediyor
output reg                       done,// Transfer bitti
// Dis baglantilar
output reg                       sclk,
output reg                       mosi,
input  wire                      miso,
output reg  [CS_WIDTH-1:0]       cs_n
);

// FSM durum tanimlari
localparam [2:0] S_IDLE     = 3'b000;
localparam [2:0] S_PREPARE  = 3'b001;
localparam [2:0] S_TRANSFER = 3'b010;
localparam [2:0] S_FINISH   = 3'b011;

reg [2:0] state, next_state;

// Clock prescaler
reg [15:0] presc_counter;   
reg        sclk_tick;

// Shift register ve bit sayaci
reg [DATA_WIDTH-1:0] tx_shift_reg;// MOSI'ya gönderilecek veri
reg [DATA_WIDTH-1:0] rx_shift_reg;// MISO'dan gelen veri
reg [5:0]            bit_counter;// 0-32 arasi sayar, 6-bit yeter

// PREPARE ve FINISH bekleme sayaçlari
reg [2:0] prep_counter;
reg [2:0] finish_counter;
localparam PREP_DELAY   = 3'd2;//20 ns
localparam FINISH_DELAY = 3'd2;

// Prescaler always blogu (sclk_tick uretimi)
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        presc_counter <= 16'd0;
        sclk_tick     <= 1'b0;
    end
    else if (state == S_TRANSFER) begin
        // Sadece bu durumda sayac aktif cpol=0 mant?g?
        if (presc_counter >= (prescaler - 1)) begin
            presc_counter <= 16'd0;
            sclk_tick     <= 1'b1;    
        end
        else begin
            presc_counter <= presc_counter + 16'd1;
            sclk_tick     <= 1'b0;
        end
    end
    else begin
        presc_counter <= 16'd0;
        sclk_tick     <= 1'b0;
    end
end

// FSM 
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        state <= S_IDLE;
    else
        state <= next_state;
end

// FSM - Next state logic
always @(*) begin
    next_state = state;
    
    case (state)
        S_IDLE: begin
            if (enable && start)
                next_state = S_PREPARE;
        end
        
        S_PREPARE: begin
            if (prep_counter >= PREP_DELAY)
                next_state = S_TRANSFER;
        end
        
        S_TRANSFER: begin
            if (bit_counter >= DATA_WIDTH && sclk == 1'b0)
                next_state = S_FINISH;
        end
        
        S_FINISH: begin
            if (finish_counter >= FINISH_DELAY)
                next_state = S_IDLE;
        end
        
        default: next_state = S_IDLE;
    endcase
end

// FSM 
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sclk           <= 1'b0;
        mosi           <= 1'b0;
        cs_n           <= {CS_WIDTH{1'b1}};
        tx_shift_reg   <= {DATA_WIDTH{1'b0}};
        rx_shift_reg   <= {DATA_WIDTH{1'b0}};
        rx_data        <= {DATA_WIDTH{1'b0}};
        bit_counter    <= 6'd0;
        prep_counter   <= 3'd0;
        finish_counter <= 3'd0;
        busy           <= 1'b0;
        done           <= 1'b0;
    end
    else begin
        done <= 1'b0;
        
        case (state)
            S_IDLE: begin
                sclk           <= 1'b0;
                mosi           <= 1'b0;
                cs_n           <= {CS_WIDTH{1'b1}};
                bit_counter    <= 6'd0;
                prep_counter   <= 3'd0;
                finish_counter <= 3'd0;
                busy           <= 1'b0;
                
                if (enable && start) begin
                    tx_shift_reg <= tx_data;
                    rx_shift_reg <= {DATA_WIDTH{1'b0}};
                    busy         <= 1'b1;
                end
            end
            
            S_PREPARE: begin
                cs_n            <= {CS_WIDTH{1'b1}};
                cs_n[cs_select] <= 1'b0;
                mosi            <= tx_shift_reg[DATA_WIDTH-1];
                sclk            <= 1'b0;
                prep_counter    <= prep_counter + 3'd1;
            end
            
            S_TRANSFER: begin
                cs_n            <= {CS_WIDTH{1'b1}};
                cs_n[cs_select] <= 1'b0;
                
                if (sclk_tick) begin
                    sclk <= ~sclk;
                    
                    if (sclk == 1'b0) begin
                        if (bit_counter < DATA_WIDTH) begin
                            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0}; // MOSI'ya c?kar
                            mosi         <= tx_shift_reg[DATA_WIDTH-1];
                            bit_counter  <= bit_counter + 6'd1;
                        end
                    end
                    else begin
                        // MISO'yu yakala
                        rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], miso};
                    end
                end
            end
            
            S_FINISH: begin
                cs_n           <= {CS_WIDTH{1'b1}};
                sclk           <= 1'b0;
                rx_data        <= rx_shift_reg;
                finish_counter <= finish_counter + 3'd1;
                
                if (finish_counter >= FINISH_DELAY) begin
                    done <= 1'b1;
                    busy <= 1'b0;
                end
            end
            
            default: begin
            end
        endcase
    end
end

endmodule