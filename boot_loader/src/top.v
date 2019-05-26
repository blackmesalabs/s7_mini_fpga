/* ****************************************************************************
-- (C) Copyright 2018 Kevin Hubbard - All rights reserved.
-- Source file: top.v                
-- Date:        June 2018     
-- Author:      khubbard
-- Description: Spartan7 boot loader for bd_shell.exe 
-- Language:    Verilog-2001
-- Simulation:  Mentor-Modelsim 
-- Synthesis:   Xilinx-Vivado
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
--
-- [ FTDI Connector ]
--  1    : GND
--  2 C3 : CTS : ftdi[0] : ftdi_wo
--  3    : +5V   
--  4 B2 : TXD : ftdi[1] : ftdi_wi
--  5 B1   RXD : ftdi[2] : ftdi_ro
--  6 A3   RTS : ftdi[3] : ftdi_ri
--
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   06.01.18  khubbard Creation
-- ***************************************************************************/
`timescale 1 ns/ 100 ps
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module top #
(
  parameter i_am_slot0   = 0,  // 0 or 1
  parameter spi_prom_en  = 1   // 0 or 1
)
(
  // List of ports that all of my Spartan7 boards have
  input  wire         rst_l,
  input  wire         clk_100m,    
  inout  wire [3:0]   ftdi,
  output reg          led1,
  output reg          led2,
  input  wire         j1_l,
  input  wire         j2_l,
  output wire         spi_cs_l,
  output wire         spi_mosi,
  input  wire         spi_miso
);// module top


  wire          reset_loc;
  reg  [26:0]   led_cnt;
  wire          cfg_done;

  wire          lb_wr;
  wire          lb_rd;
  wire [31:0]   lb_addr;
  wire [31:0]   lb_wr_d;
  wire [31:0]   lb_rd_d;
  wire          lb_rd_rdy;

  wire          prom_wr;
  wire          prom_rd;
  wire [31:0]   prom_addr;
  wire [31:0]   prom_wr_d;
  wire [31:0]   prom_rd_d;
  wire          prom_rd_rdy;
  wire          lb_cs_prom_c;
  wire          lb_cs_prom_d;

  wire          ftdi_wi;
  wire          ftdi_ro;
  wire          ftdi_wo;
  wire          ftdi_ri;

  wire          spi_sck_loc;
  wire [31:0]   slot_size;
  wire          reconfig_2nd_slot;
  wire          reconfig_req;
  wire [31:0]   reconfig_addr;


  assign reset_loc = ~rst_l;// vs ~pll_lock or ~cfg_done


  assign ftdi[0] = 1'bz;
  assign ftdi_wi = ftdi[1];
  assign ftdi[2] = ftdi_ro;
  assign ftdi[3] = 1'bz;


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
always @ ( posedge clk_100m ) begin : proc_led_flops
  led_cnt <= led_cnt[26:0] + 1;
  led1    <=   led_cnt[25];
  led2    <= ~ led_cnt[25];
  if ( i_am_slot0 == 1 ) begin
    led1 <=   led_cnt[23];// Fast Blink for Slot-0 Bootloader
    led2 <= ~ led_cnt[23];
  end
end // proc_led_flops


//-----------------------------------------------------------------------------
// MesaBus interface to LocalBus
//-----------------------------------------------------------------------------
ft232_xface u_ft232_xface
(
  .reset       ( reset_loc   ),
  .clk_lb      ( clk_100m    ),
  .ftdi_wi     ( ftdi_wi     ),
  .ftdi_ro     ( ftdi_ro     ),
  .ftdi_wo     ( ftdi_wo     ),
  .ftdi_ri     ( ftdi_ri     ),

  .lb_wr       ( lb_wr       ),
  .lb_rd       ( lb_rd       ),
  .lb_addr     ( lb_addr     ),
  .lb_wr_d     ( lb_wr_d     ),
  .lb_rd_d     ( lb_rd_d     ),
  .lb_rd_rdy   ( lb_rd_rdy   ),

  .prom_wr     ( prom_wr     ),
  .prom_rd     ( prom_rd     ),
  .prom_addr   ( prom_addr   ),
  .prom_wr_d   ( prom_wr_d   ),
  .prom_rd_d   ( prom_rd_d   ),
  .prom_rd_rdy ( prom_rd_rdy )
);// module ft232_xface


//-----------------------------------------------------------------------------
// FPGA Reconfiguration Block
//-----------------------------------------------------------------------------
icap_ctrl u_icap_ctrl
(
//.reset                   ( reset_loc | ~cfg_done ),
  .reset                   ( reset_loc           ),   
  .clk                     ( clk_100m            ),
  .prom_wr                 ( prom_wr             ),
  .prom_addr               ( prom_addr[31:0]     ),
  .prom_wr_d               ( prom_wr_d[31:0]     ),
  .reconfig_req            ( reconfig_req        ),
  .reconfig_addr           ( reconfig_addr[31:0] )
);


//-----------------------------------------------------------------------------
// Special connection for SCK as dedicated Xilinx Config Pin
//-----------------------------------------------------------------------------
STARTUPE2 u_startupe2
(
  .CLK                     ( 1'b0        ),
  .GSR                     ( 1'b0        ),
  .GTS                     ( 1'b0        ),
  .KEYCLEARB               ( 1'b0        ),
  .PACK                    ( 1'b0        ),
  .USRCCLKO                ( spi_sck_loc ),
  .USRCCLKTS               ( 1'b0        ),
  .USRDONEO                ( 1'b1        ),
  .USRDONETS               ( 1'b1        ),
  .CFGCLK                  (             ),
  .CFGMCLK                 (             ),
  .EOS                     ( cfg_done    ),
  .PREQ                    (             )
);


//-----------------------------------------------------------------------------
// Interface to SPI PROM : Allow LB to program SPI PROM, request reconfig
// ck_divisor 10 is for ( 100M / 10 ) for 2x SPI Clock Rate of 5 MHz
//-----------------------------------------------------------------------------
generate
if ( spi_prom_en == 1 ) begin
spi_prom u_spi_prom
(
  .reset                            ( reset_loc                      ),
  .prom_is_32b                      ( 1'b0                           ),
  .ck_divisor                       ( 8'd10                          ),
  .slot_size                        ( slot_size[31:0]                ),
  .protect_1st_slot                 ( 1'b1                           ),
  .clk_lb                           ( clk_100m                       ),

  .lb_cs_prom_c                     ( lb_cs_prom_c                   ),
  .lb_cs_prom_d                     ( lb_cs_prom_d                   ),
  .lb_wr                            ( prom_wr                        ),
  .lb_rd                            ( prom_rd                        ),
  .lb_wr_d                          ( prom_wr_d[31:0]                ),
  .lb_rd_d                          ( prom_rd_d[31:0]                ),
  .lb_rd_rdy                        ( prom_rd_rdy                    ),

  .spi_sck                          ( spi_sck_loc                    ),
  .spi_cs_l                         ( spi_cs_l                       ),
  .spi_mosi                         ( spi_mosi                       ),
  .spi_miso                         ( spi_miso                       ),

  .flag_wip                         (                                ),
  .bist_req                         (                                ),
  .reconfig_2nd_slot                ( reconfig_2nd_slot              ),
  .reconfig_req                     ( reconfig_req                   ),
  .reconfig_addr                    ( reconfig_addr[31:0]            )
);// spi_prom
end else begin
  assign prom_rd_d   = 32'd0;
  assign prom_rd_rdy = 0;
end
endgenerate
  assign slot_size = 32'h00200000; // 16Mbit for 7S25
  assign lb_cs_prom_c = ( prom_addr[7:0] == 8'h20 ) ? 1 : 0;
  assign lb_cs_prom_d = ( prom_addr[7:0] == 8'h24 ) ? 1 : 0;
  assign reconfig_2nd_slot = i_am_slot0 & j1_l;// Jumper forces stay in Slot0


//-----------------------------------------------------------------------------
// Example Core. Just some Read and Writable 32bit registers on LocalBus
//-----------------------------------------------------------------------------
core u_core
(
  .reset       ( reset_loc        ),
  .clk_lb      ( clk_100m         ),
  .lb_wr       ( lb_wr            ),
  .lb_rd       ( lb_rd            ),
  .lb_addr     ( lb_addr          ),
  .lb_wr_d     ( lb_wr_d          ),
  .lb_rd_d     ( lb_rd_d          ),
  .lb_rd_rdy   ( lb_rd_rdy        )
);


endmodule // top.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it
