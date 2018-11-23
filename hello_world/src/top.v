/* ****************************************************************************
-- (C) Copyright 2018 Kevin Hubbard - All rights reserved.
-- Source file: top.v                
-- Date:        November 2018 
-- Author:      khubbard
-- Description: Spartan7 S7 Mini example design for flashing LEDs
-- Language:    Verilog-2001
-- Simulation:  Xilinx-Vivado   
-- Synthesis:   Xilinx-Vivado
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
--
--                            --------------------------
--                        A0 |1    o  o  o  o  o  o   40| H0
--                        A1 |    GRN    FTDI    BLK    | H1
--                        A2 |       J1 J2              | H2
--                        A3 |  GND o o o               | H3
--                       GND |  5V0 o o o               | GND
--                        B0 |         HS2 JTAG         | G0
--                        B1 |     o  o  o  o  o  o     | G1
--                        B2 |     ----------------     | G2
--                        B3 |    |     Xilinx     |    | G3
--                       3V3 |    |    Spartan7    |    | 3V3
--                        C0 |    | xc7s25ftgb196-1|    | F0
--                        C1 |    |                |    | F1
--                        C2 |    |                |    | F2
--                        C3 |    |                |    | F3
--                       GND |     ----------------     | GND
--                        D0 |        -----------       | E0
--                        D1 |       | 64Mb DRAM |      | E1
--                        D2 |        -----------       | E2
--                        D3 |                          | E3
--                       5V0 |20                      21| 5V0
--                            --------------------------
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   11.22.18  khubbard Creation
-- ***************************************************************************/
`timescale 1 ns/ 100 ps
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module top 
(
  // List of just the main DIP-40 ports for the "S7 Mini"
  input  wire         rst_l,
  input  wire         clk_100m_pin,    
  output reg          led1,
  output reg          led2,
  input  wire         j1_l,
  input  wire         j2_l,

  inout  wire [3:0]   port_a,
  inout  wire [3:0]   port_b,
  inout  wire [3:0]   port_c,
  inout  wire [3:0]   port_d,
  inout  wire [3:0]   port_e,
  inout  wire [3:0]   port_f,
  inout  wire [3:0]   port_g,
  inout  wire [3:0]   port_h
);// module top


  wire          reset_loc;
  wire          clk_100m_loc;
  wire          clk_100m;
  wire          ck_tree_en;
  reg  [26:0]   led_cnt;

  reg  [3:0]    port_a_loc;
  reg  [3:0]    port_b_loc;
  reg  [3:0]    port_c_loc;
  reg  [3:0]    port_d_loc;
  reg  [3:0]    port_e_loc;
  reg  [3:0]    port_f_loc;
  reg  [3:0]    port_g_loc;
  reg  [3:0]    port_h_loc;

  assign reset_loc = ~rst_l;// Infer IBUF and make active high

//-----------------------------------------------------------------------------
// Single simple 100 MHz clock tree network.                      
//-----------------------------------------------------------------------------
  assign clk_100m_loc = clk_100m_pin; // Infer the IBUF
  assign ck_tree_en  = 1'b1;         // Super low power by connecting to 0
  BUFGCE u0_bufg ( .I( clk_100m_loc ), .O( clk_100m ), .CE( ck_tree_en ) );


//-----------------------------------------------------------------------------
// Drive all 8 nibble ports as outputs                            
//-----------------------------------------------------------------------------
  assign port_a = port_a_loc[3:0];
  assign port_b = port_b_loc[3:0];
  assign port_c = port_c_loc[3:0];
  assign port_d = port_d_loc[3:0];
  assign port_e = port_e_loc[3:0];
  assign port_f = port_f_loc[3:0];
  assign port_g = port_g_loc[3:0];
  assign port_h = port_h_loc[3:0];


//-----------------------------------------------------------------------------
// Flash the two LEDs at about 1 Hz because that is what FPGAs and uPs do best
//-----------------------------------------------------------------------------
always @ ( posedge clk_100m ) begin : proc_led_flops
  led_cnt    <=   led_cnt[26:0] + 1;
  // Flash faster if either jumper is in place
  if ( j1_l == 0 || j2_l == 0 ) begin
    led1 <=   led_cnt[24];
    led2 <= ~ led_cnt[24];
  end else begin
    led1 <=   led_cnt[26];
    led2 <= ~ led_cnt[26];
  end 

  port_a_loc <=   led_cnt[26:23];
  port_b_loc <=   led_cnt[22:19];
  port_c_loc <=   led_cnt[18:15];
  port_d_loc <=   led_cnt[14:11];
  port_e_loc <=   led_cnt[15:12];
  port_f_loc <=   led_cnt[11: 8];
  port_g_loc <=   led_cnt[7 : 4];
  port_h_loc <=   led_cnt[3 : 0];
  if ( reset_loc == 1 ) begin
    led_cnt <= 26'd0;
  end
end // proc_led_flops

endmodule // top.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it

