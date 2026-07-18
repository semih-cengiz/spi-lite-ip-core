
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_in1_0 }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk_in1_0 }];


set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { reset_rtl_0 }];


set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { uart_rtl_0_txd }];
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { uart_rtl_0_rxd }];

set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[0] }];

set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { mosi_0 }];

set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { sclk_0 }];

set_property -dict { PACKAGE_PIN F6   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[1] }];
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[2] }];
set_property -dict { PACKAGE_PIN G6   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[3] }];
set_property -dict { PACKAGE_PIN E7   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[4] }];
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[5] }];
set_property -dict { PACKAGE_PIN K1   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[6] }];
set_property -dict { PACKAGE_PIN E6   IOSTANDARD LVCMOS33 } [get_ports { cs_n_0[7] }];


