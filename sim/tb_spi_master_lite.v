`timescale 1ns / 1ps

module tb_spi_master_lite;

    reg         clk;
    reg         rstn;
    reg         enable;
    reg         start;
    reg  [31:0] tx_data;
    wire [31:0] rx_data;
    reg  [2:0]  cs_select;
    reg  [15:0] prescaler;
    wire        busy;
    wire        done;
    wire        sclk;
    wire        mosi;
    wire        miso;
    wire [7:0]  cs_n;
    
    spi_master_lite #(
        .DATA_WIDTH(32),
        .CS_WIDTH(8),
        .CS_SEL_WIDTH(3)
    ) (
        .clk(clk),
        .rstn(rstn),
        .enable(enable),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .cs_select(cs_select),
        .prescaler(prescaler),
        .busy(busy),
        .done(done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );
    
    // 1. CS LOW oldugunda aktif olur
    // 2. SCLK dusen kenarinda MOSIden gelen biti shift registera kaydirir
    // 3. MISO'dan bilinen bir pattern gonderir - MSB first olarak
    reg [31:0] slave_rx = 32'd0;
    reg [31:0] slave_tx = 32'hA5A5A5A5;
    reg [5:0] slave_bit_idx = 6'd31;
    
    wire slave_cs = cs_n[0];
    
    assign miso = (slave_cs == 1'b0) ? slave_tx[slave_bit_idx] : 1'b0;
    
    always @(negedge sclk or posedge slave_cs) begin
        if (slave_cs) begin
            slave_bit_idx <= 6'd31;
        end
        else begin
            slave_rx[slave_bit_idx] <= mosi;
            if (slave_bit_idx > 0)
                slave_bit_idx <= slave_bit_idx - 1;
        end
    end
    
    // Clk

    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        rstn      = 1'b0;
        enable    = 1'b0;
        start     = 1'b0;
        tx_data   = 32'd0;
        cs_select = 3'd0;
        prescaler = 16'd4;
        
        #100;
        rstn = 1'b1;
        #50;
        
        enable = 1'b1;
        
        // Transfer 1: Internal reference on komutu (0x08000001)
 
        $display("Transfer 1: Internal REF on");
        tx_data   = 32'h08000001;
        cs_select = 3'd0;
        
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        wait (done == 1'b1);
        @(posedge clk);
        
        $display("Transfer 1 tamamlandi");
        $display("Slave aldigi veri: 0x%08h (beklenen: 0x08000001)", slave_rx);
        $display("DUT aldigi rx_data: 0x%08h (beklenen: 0xA5A5A5A5)", rx_data);
        
        #200;
        
        // Transfer 2: DAC Aya orta deger yazma

        $display("Transfer 2: DAC A ortaya yaz (0x0307FF00)");
        tx_data = 32'h0307FF00;
        
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        wait (done == 1'b1);
        @(posedge clk);
        
        $display("Transfer 2 tamamlandi");
        $display("Slave aldigi veri: 0x%08h (beklenen: 0x0307FF00)", slave_rx);
        $display("DUT aldigi rx_data: 0x%08h (beklenen: 0xA5A5A5A5)", rx_data);
        
        #500;
        $display("Simulasyon tamamlandi");
        $finish;
    end

endmodule

