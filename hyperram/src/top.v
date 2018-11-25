/* ****************************************************************************
-- (C) Copyright 2018 Kevin Hubbard - All rights reserved.
-- Source file: top.v                
-- Date:        November 2018 
-- Author:      khubbard
-- Description: Spartan7 S7 Mini example design for HyperRAM DRAM interface.
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
-- 0.1   11.25.18  khubbard Creation
-- ***************************************************************************/
`timescale 1 ns/ 100 ps
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module top 
(
  input  wire         rst_l,
  input  wire         clk_100m_pin,    
  output reg          led1,
  output reg          led2,
  input  wire         j1_l,
  input  wire         j2_l,
  inout  wire [7:0]   hr_dq,
  inout  wire         hr_rwds,
  output wire         hr_ck,
  output wire         hr_rst_l,
  output wire         hr_cs_l
);// module top


  wire          reset_loc;
  wire          reset_200m;
  wire          reset_80m;
  wire          clk_100m_in;
  wire          clk_100m_loc;
  wire          clk_100m;
  wire          clk_200m_loc;
  wire          clk_200m;
  wire          clk_80m_loc;
  wire          clk_80m;
  wire          clk_80m_90p_loc;
  wire          clk_80m_90p;

  wire          pll_lock;
  reg  [26:0]   led_cnt;

  // Internal HyperRAM signals for the IOBs to outside
  wire [7:0]    dram_dq_in;
  wire [7:0]    dram_dq_out;
  wire          dram_dq_oe_l;
  wire          dram_rwds_in;
  wire          dram_rwds_out;
  wire          dram_rwds_oe_l;
  wire          dram_ck;
  wire          dram_cs_l;
  wire          dram_rst_l;

  // HyperRAM interface signals between the mux and xface components
  wire          hr_rd_req;
  wire          hr_wr_req;
  wire          hr_mem_or_reg;
  wire [31:0]   hr_addr;
  wire [5:0]    hr_rd_num_dwords;
  wire [31:0]   hr_wr_d;
  wire          hr_busy;
  wire          hr_burst_wr_rdy;
  wire [31:0]   hr_rd_d;
  wire          hr_rd_rdy;
  wire [7:0]    hr_cycle_len;

  // Unit Under Test access signals to HyperRAM via the mux component
  reg           uut_hr_rd_req;
  reg           uut_hr_wr_req;
  reg           uut_hr_mem_or_reg;
  reg  [31:0]   uut_hr_addr;
  reg  [5:0]    uut_hr_rd_num_dwords;
  reg  [31:0]   uut_hr_wr_d;
  wire          uut_hr_busy;
  wire          uut_hr_burst_wr_rdy;
  wire [31:0]   uut_hr_rd_d;
  wire          uut_hr_rd_rdy;
  reg  [31:0]   uut_test_dword;
  reg           uut_good;
  reg           uut_bad;


  assign reset_loc = ~rst_l;// Infer IBUF for reset pin and make active high


//-----------------------------------------------------------------------------
// PLL for making 200M and two phases of 80M out of input 100M
//-----------------------------------------------------------------------------
pll_7series u_pll
(
  .reset        ( reset_loc       ),
  .pll_lock     ( pll_lock        ),
  .clk_ref      ( clk_100m_in     ),
  .clk0_out     ( clk_200m_loc    ),
  .clk1_out     ( clk_100m_loc    ),
  .clk2_out     ( clk_80m_loc     ),
  .clk3_out     ( clk_80m_90p_loc )
);
  assign clk_100m_in = clk_100m_pin; // Infer IBUF
  BUFGCE u0_bufg ( .I( clk_200m_loc    ), .O( clk_200m    ), .CE(1) );
  BUFGCE u1_bufg ( .I( clk_100m_loc    ), .O( clk_100m    ), .CE(1) );
  BUFGCE u2_bufg ( .I( clk_80m_loc     ), .O( clk_80m     ), .CE(1) );
  BUFGCE u3_bufg ( .I( clk_80m_90p_loc ), .O( clk_80m_90p ), .CE(1) );


//-----------------------------------------------------------------------------
// XPMs for Async Reset Assert, Sync Reset De-Assert              
//-----------------------------------------------------------------------------
cdc_reset u0_cdc_reset
(
  .reset        ( ~pll_lock  ),
  .clk_dst      ( clk_200m   ),
  .dst_reset    ( reset_200m )
);// module cdc_reset

cdc_reset u1_cdc_reset
(
  .reset        ( ~pll_lock  ),
  .clk_dst      ( clk_80m    ),
  .dst_reset    ( reset_80m  )
);// module cdc_reset


//-----------------------------------------------------------------------------
// Instantiate BIDIs for the HyperRAM DQ[7:0] and RWDS pins
//-----------------------------------------------------------------------------
  iob_bidi u1_bidi(.IO(hr_rwds   ),.O(dram_rwds_in   ),.I(dram_rwds_out   ),
                                                       .T(dram_rwds_oe_l  ) );
  genvar j;
  generate
   for (j=0; j<=7; j=j+1 ) begin: gen_j
    iob_bidi u0_bidi(.IO(hr_dq[j]  ),.O(dram_dq_in[j] ),.I(dram_dq_out[j]  ),
                                                        .T(dram_dq_oe_l    ) );
   end 
  endgenerate
 
// Infer OBUFs 
  assign hr_ck    = dram_ck;
  assign hr_rst_l = dram_rst_l;
  assign hr_cs_l  = dram_cs_l;


//-----------------------------------------------------------------------------
// Flash the two LEDs at about 1 Hz because that is what FPGAs and uPs do best
//-----------------------------------------------------------------------------
always @ ( posedge clk_80m ) begin : proc_led_flops
  led_cnt <= led_cnt[26:0] + 1;
  led1    <=   led_cnt[25] & uut_good;// Flash LED1 if Good
//led2    <= ~ led_cnt[25];
  led2    <=                 uut_bad; // Solid LED2 on Bad
end // proc_led_flops


//-----------------------------------------------------------------------------
// A very simple HyperRAM test design.  Every 32 clocks, write a DWORD and 
// then read that same DWORD back. Light an LED if it doesn't match.
//             |----------------- 32 clocks -----------|
// clk    _/ \_/ \_/ \_/ \...._/ \_/ \_..../ \_/ \_/ \_/ \_/ \.....
// wr_req _____/   \______...._________....____________/   \__.....
// addr   -----<   >------....-<   >---....------------<   >--.....
// rd_req ________________...._/   \___....___________________.....
// rd_rdy ________________...._________..../   \______________.....
// wr_d   -----<   >------....---------....------------<   >--.....
// rd_d   ----------------....---------....<    >-------------.....
//-----------------------------------------------------------------------------
always @ ( posedge clk_80m ) begin : proc_uut
  uut_hr_rd_req     <= 0;
  uut_hr_wr_req     <= 0;
  uut_hr_addr       <= 32'd0;
  uut_hr_mem_or_reg <= 0; // Always DRAM, never control 
  
  // Every 16 clocks when DRAM is not busy
  if ( led_cnt[3:0] == 4'd0 && hr_busy == 0 ) begin
    // Write a DWORD 1st
    if ( led_cnt[4] == 0 ) begin
      uut_hr_wr_req     <= 1;
      uut_hr_addr[31:0] <= { 16'd0, led_cnt[23:8] };
      uut_hr_wr_d       <= { led_cnt[23:8], led_cnt[23:8] };
      uut_test_dword    <= { led_cnt[23:8], led_cnt[23:8] };// Remember it
    // Then 16 clocks later read the DWORD back 
    end else begin
      uut_hr_rd_req        <= 1;
      uut_hr_addr[31:0]    <= { 16'd0, led_cnt[23:8] };
      uut_hr_rd_num_dwords <= 6'd1; 
    end 
  end 
 
  // When read request comes back with data, compare with original write data 
  if ( uut_hr_rd_rdy == 1 ) begin
    if ( uut_hr_rd_d[31:0] == uut_test_dword[31:0] ) begin
      uut_good <= 1;
      uut_bad  <= 0;
    end else begin
      uut_good <= 0;
      uut_bad  <= 1;
    end
  end 
end // proc_uut


//-----------------------------------------------------------------------------
// Mux to the hyper_xface_pll:
//   1) Provides manual access to DRAM via LB for debug.
//   2) Takes care of 150uS post-Reset Latency Configuration.
//   Note: Arbitration is simple 1st come 1st serve with no queuing.
//-----------------------------------------------------------------------------
hyper_xface_mux u_hyper_xface_mux 
(
  .reset                ( reset_80m                 ),
  .clk                  ( clk_80m                   ),
  .lb_wr                ( 1'b0                      ),
  .lb_rd                ( 1'b0                      ),
  .lb_addr              ( 32'd0                     ),
  .lb_wr_d              ( 32'd0                     ),
  .lb_rd_d              (                           ),
  .lb_rd_rdy            (                           ),

  .hr_rd_req            ( hr_rd_req                 ),
  .hr_wr_req            ( hr_wr_req                 ),
  .hr_mem_or_reg        ( hr_mem_or_reg             ),
  .hr_addr              ( hr_addr[31:0]             ),
  .hr_rd_num_dwords     ( hr_rd_num_dwords[5:0]     ),
  .hr_wr_d              ( hr_wr_d[31:0]             ),
  .hr_rd_d              ( hr_rd_d[31:0]             ),
  .hr_rd_rdy            ( hr_rd_rdy                 ),
  .hr_busy              ( hr_busy                   ),
  .hr_burst_wr_rdy      ( hr_burst_wr_rdy           ),
  .hr_cycle_len         ( hr_cycle_len[7:0]         ),

  .dsf_hr_rd_req        ( uut_hr_rd_req             ),
  .dsf_hr_wr_req        ( uut_hr_wr_req             ),
  .dsf_hr_mem_or_reg    ( uut_hr_mem_or_reg         ),
  .dsf_hr_addr          ( uut_hr_addr[31:0]         ),
  .dsf_hr_rd_num_dwords ( uut_hr_rd_num_dwords[5:0] ),
  .dsf_hr_wr_d          ( uut_hr_wr_d[31:0]         ),
  .dsf_hr_rd_d          ( uut_hr_rd_d[31:0]         ),
  .dsf_hr_rd_rdy        ( uut_hr_rd_rdy             ),
  .dsf_hr_busy          ( uut_hr_busy               ),
  .dsf_hr_burst_wr_rdy  ( uut_hr_burst_wr_rdy       )
);


//-----------------------------------------------------------------------------
// Bridge to an external HyperRAM DRAM chip. This is a generic DWORD xface.
//-----------------------------------------------------------------------------
hyper_xface_pll u_hyper_xface_pll
(
  .simulation_en          ( 1'b0                  ),
  .reset                  ( reset_80m             ),
  .clk                    ( clk_80m               ),
  .clk_90p                ( clk_80m_90p           ),
  .rd_req                 ( hr_rd_req             ),
  .wr_req                 ( hr_wr_req             ),
  .mem_or_reg             ( hr_mem_or_reg         ),
  .addr                   ( hr_addr[31:0]         ),
  .rd_num_dwords          ( hr_rd_num_dwords[5:0] ),
  .wr_d                   ( hr_wr_d[31:0]         ),
  .rd_d                   ( hr_rd_d[31:0]         ),
  .rd_rdy                 ( hr_rd_rdy             ),
  .busy                   ( hr_busy               ),
  .burst_wr_rdy           ( hr_burst_wr_rdy       ),
  .lat_2x                 (                       ),
  .sump_dbg               (                       ),
  .cycle_len              ( hr_cycle_len[7:0]     ),

  .dram_dq_in             ( dram_dq_in[7:0]       ),
  .dram_dq_out            ( dram_dq_out[7:0]      ),
  .dram_dq_oe_l           ( dram_dq_oe_l          ),
  .dram_rwds_in           ( dram_rwds_in          ),
  .dram_rwds_out          ( dram_rwds_out         ),
  .dram_rwds_oe_l         ( dram_rwds_oe_l        ),
  .dram_ck                ( dram_ck               ),
  .dram_rst_l             ( dram_rst_l            ),
  .dram_cs_l              ( dram_cs_l             )
);// module hyper_xface_pll


endmodule // top.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it
