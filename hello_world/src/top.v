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
  parameter i_am_slot0    = 0,  // 0 or 1
  parameter spi_prom_en   = 1,  // 0 or 1
  parameter ds_depth_len  = 1048576,
  parameter ds_depth_bits = 20

//parameter ds_depth_len  = 65536,
//parameter ds_depth_bits = 16

//parameter ds_depth_len  = 1024,
//parameter ds_depth_bits = 10
)
(
  // List of ports that all of my Spartan7 boards have
  input  wire         rst_l,
  input  wire         clk_100m_pin,    
  inout  wire [3:0]   ftdi,
  output reg          led1,
  output reg          led2,
  input  wire         j1_l,
  input  wire         j2_l,
  output wire         spi_cs_l,
  output wire         spi_mosi,
  input  wire         spi_miso,

  inout  wire [7:0]   port_a,
  inout  wire [7:0]   port_b,
  inout  wire [7:0]   port_c,
  inout  wire [7:0]   port_d,
  inout  wire [7:0]   port_e,
  inout  wire [7:0]   port_f,
  inout  wire [7:0]   port_g,
  inout  wire [7:0]   port_h,

  inout  wire [7:0]   hr_dq,
  inout  wire         hr_rwds,
  output wire         hr_ck,
  output wire         hr_rst_l,
  output wire         hr_cs_l
);// module top


  wire          reset_loc;
  wire          reset_200m;
  wire          reset_80m;
  wire          reset_hr;
  wire          pll_lock;
  reg  [26:0]   led_cnt;
  reg  [31:0]   test_cnt;
  reg  [31:0]   test_cnt_p1;
  reg  [7:0]    pulse_sr;
  reg  [7:0]    little_cnt;
  wire          cfg_done;

  wire          lb_wr;
  wire          lb_rd;
  wire [31:0]   lb_addr;
  wire [31:0]   lb_wr_d;
  reg  [31:0]   lb_rd_d;
  reg           lb_rd_rdy;

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
  reg  [31:0]   sump2_events;
  reg  [127:0]  dwords_3_0;
  reg  [31:0]   sump2_events_p1;
  reg  [31:0]   sump2_events_p2;
  reg  [31:0]   sump2_events_p3;
  wire [31:0]   hr_dbg_events;

  reg  [7:0]    port_a_loc;
  reg  [7:0]    port_b_loc;
  reg  [7:0]    port_c_loc;
  reg  [7:0]    port_d_loc;
  reg  [7:0]    port_e_loc;
  reg  [7:0]    port_f_loc;
  reg  [7:0]    port_g_loc;
  reg  [7:0]    port_h_loc;


  wire [31:0]   u0_lb_rd_d;
  wire          u0_lb_rd_rdy;
  wire [31:0]   u1_lb_rd_d;
  wire          u1_lb_rd_rdy;
  wire [31:0]   u2_lb_rd_d;
  wire          u2_lb_rd_rdy;

  wire          lb_cs_sump2_ctrl;
  wire          lb_cs_sump2_data;
  wire          sump_lb_wr;
  wire          sump_lb_rd;
  wire          pmod_ck;

  wire [7:0]    dram_dq_in;
  wire [7:0]    dram_dq_out;
  wire          dram_dq_oe_l;
  wire          dram_rwds_in;
  wire          dram_rwds_out;
  wire          dram_rwds_oe_l;
  wire          dram_ck;
  wire          dram_cs_l;
  wire          dram_rst_l;

  wire [31:0]   sump2_user_ctrl;
  reg  [31:0]   sump2_user_ctrl_p1;
  reg           mux0_sel;
  reg           mux1_sel;
  reg           mux2_sel;
  reg           mux3_sel;
  wire          ds_trigger;
  wire [31:0]   ds_events;
  wire [31:0]   ds_events_muxd;
  wire [31:0]   ds_user_ctrl;
  reg  [31:0]   ds_mux_sel;
  wire          ds_rle_pre_done;
  wire          ds_rle_post_done;

  wire [5:0]    ds_cmd_cap;
  wire [5:0]    ds_cmd_lb;
  wire          ds_rd_req;
  wire          ds_wr_req;
  wire [31:0]   ds_wr_d;
  wire [31:0]   ds_rd_d;
  wire          ds_rd_rdy;

  wire          dbg_fifo_pop;

  wire          clk_100m_in;
  wire          clk_40m_loc;
  wire          clk_40m;
  wire          clk_200m_loc;
  wire          clk_200m;
  wire          clk_80m_loc;
  wire          clk_80m;
  wire          clk_80m_90p_loc;
  wire          clk_80m_90p;

  wire          hr_rd_req;
  wire          hr_wr_req;
  wire          hr_mem_or_reg;
  wire [31:0]   hr_addr;
  wire [5:0]    hr_rd_num_dwords;
  wire [31:0]   hr_wr_d;
  wire [31:0]   hr_rd_d;
  wire          hr_rd_rdy;
  wire          hr_busy;
  wire          hr_burst_wr_rdy;

  wire          dsf_hr_rd_req;
  wire          dsf_hr_wr_req;
  wire          dsf_hr_mem_or_reg;
  wire [31:0]   dsf_hr_addr;
  wire [5:0]    dsf_hr_rd_num_dwords;
  wire [31:0]   dsf_hr_wr_d;
  wire          dsf_hr_busy;
  wire          dsf_hr_burst_wr_rdy;
  wire [31:0]   dsf_hr_rd_d;
  wire          dsf_hr_rd_rdy;

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

  wire                     a_we;
  wire                     a_overrun;
  wire                     a_empty;
  wire [63:0]              a_di;
  wire [ds_depth_bits-1:0] a_addr;
  wire [63:0]              b_do;
  wire [ds_depth_bits-1:0] b_addr;
  wire                     b_rd_req;

  wire [7:0]    vga_r;
  wire [7:0]    vga_g;
  wire [7:0]    vga_b;
  wire [23:0]   vga_rgb;
  wire          vga_de;
  wire          vga_hs;
  wire          vga_vs;
  wire [11:0]   rgb_ris;
  wire [11:0]   rgb_fal;
  wire          dvi_ck_p;
  wire          dvi_ck_n;
  wire [11:0]   dvi_rgb;

  assign reset_loc = ~rst_l;// vs ~pll_lock or ~cfg_done
  assign reset_hr = ~rst_l || ~ j2_l;


  assign ftdi[0] = 1'bz;
  assign ftdi_wi = ftdi[1];
  assign ftdi[2] = ftdi_ro;
  assign ftdi[3] = 1'bz;


//-----------------------------------------------------------------------------
// PLL for making 200M and two phases of 80M out of input 100M
//-----------------------------------------------------------------------------
pll_7series u_pll
(
  .reset        ( reset_loc       ),
  .pll_lock     ( pll_lock        ),
  .clk_ref      ( clk_100m_in     ),
  .clk0_out     ( clk_200m_loc    ),
  .clk1_out     ( clk_40m_loc    ),
  .clk2_out     ( clk_80m_loc     ),
  .clk3_out     ( clk_80m_90p_loc )
);
  assign clk_100m_in = clk_100m_pin; // Infer IBUF
  BUFGCE u0_bufg ( .I( clk_200m_loc    ), .O( clk_200m    ), .CE(1) );
  BUFGCE u1_bufg ( .I( clk_40m_loc     ), .O( clk_40m     ), .CE(1) );
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
  
  assign hr_ck    = dram_ck;
  assign hr_rst_l = dram_rst_l;
  assign hr_cs_l  = dram_cs_l;


//-----------------------------------------------------------------------------
// Flash the two LEDs at about 1 Hz because that is what FPGAs and uPs do best
//-----------------------------------------------------------------------------
always @ ( posedge clk_200m ) begin : proc_led_flops
  led_cnt <= led_cnt[26:0] + 1;
  led1    <=   led_cnt[26];
  led2    <= ~ led_cnt[26];

  if ( i_am_slot0 == 1 ) begin
    led1 <=   led_cnt[23];// Fast Blink if Slot-0 Bootloader design
    led2 <= ~ led_cnt[23];
  end
end // proc_led_flops


//-----------------------------------------------------------------------------
// MesaBus interface to LocalBus
//-----------------------------------------------------------------------------
ft232_xface u_ft232_xface
(
  .reset       ( reset_80m   ),
  .clk_lb      ( clk_80m     ),
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
// Mux between multiple Local Bus readback origins.
//-----------------------------------------------------------------------------
always @ ( posedge clk_80m ) begin : proc_lb_mux
  lb_rd_rdy <= 0;
  lb_rd_d   <= 32'd0;
  if ( u0_lb_rd_rdy == 1 ) begin
    lb_rd_rdy <= 1;
    lb_rd_d   <= u0_lb_rd_d[31:0];
  end
  if ( u1_lb_rd_rdy == 1 ) begin
    lb_rd_rdy <= 1;
    lb_rd_d   <= u1_lb_rd_d[31:0];
  end
  if ( u2_lb_rd_rdy == 1 ) begin
    lb_rd_rdy <= 1;
    lb_rd_d   <= u2_lb_rd_d[31:0];
  end
end


//-----------------------------------------------------------------------------
// FPGA Reconfiguration Block
//-----------------------------------------------------------------------------
icap_ctrl u_icap_ctrl
(
  .reset                   ( reset_80m           ),   
  .clk                     ( clk_80m             ),
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
  .reset                   ( reset_80m            ),
  .prom_is_32b             ( 1'b0                 ),
  .ck_divisor              ( 8'd10                ),
  .slot_size               ( slot_size[31:0]      ),
  .protect_1st_slot        ( 1'b1                 ),
  .clk_lb                  ( clk_80m              ),

  .lb_cs_prom_c            ( lb_cs_prom_c         ),
  .lb_cs_prom_d            ( lb_cs_prom_d         ),
  .lb_wr                   ( prom_wr              ),
  .lb_rd                   ( prom_rd              ),
  .lb_wr_d                 ( prom_wr_d[31:0]      ),
  .lb_rd_d                 ( prom_rd_d[31:0]      ),
  .lb_rd_rdy               ( prom_rd_rdy          ),

  .spi_sck                 ( spi_sck_loc          ),
  .spi_cs_l                ( spi_cs_l             ),
  .spi_mosi                ( spi_mosi             ),
  .spi_miso                ( spi_miso             ),

  .flag_wip                (                      ),
  .bist_req                (                      ),
  .reconfig_2nd_slot       ( reconfig_2nd_slot    ),
  .reconfig_req            ( reconfig_req         ),
  .reconfig_addr           ( reconfig_addr[31:0]  )
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
// test_cnt[31:0] and little_cnt[7:0] are example stimulus for SUMP2+DeepSump
// They generate bursty data at 200 MHz that won't overrun the HyperRAM DRAM.
//-----------------------------------------------------------------------------
always @ ( posedge clk_200m ) 
begin 
  test_cnt_p1 <= test_cnt[31:0];
  test_cnt    <= test_cnt[31:0] + 1;
  little_cnt <= little_cnt[7:0] + 1;
  if ( little_cnt == 8'd3 ) begin
    little_cnt <= 8'd1;// 3/4 Time 1,2,3,1,2,3,...
  end 

  pulse_sr[0]   <= test_cnt[19] & ~ test_cnt_p1[19];
  pulse_sr[7:1] <= pulse_sr[6:0];
  test_cnt[20]  <= pulse_sr[3];
  if ( pulse_sr[6:0] != 7'd0 ) begin
    test_cnt[21] <= 1;
  end else begin
    test_cnt[21] <= 0;
  end
  if ( pulse_sr[4:2] != 3'd0 ) begin
    test_cnt[22] <= 1;
  end else begin
    test_cnt[22] <= 0;
  end

  if ( reset_200m == 1 ) begin 
    little_cnt <= 8'd103;
    test_cnt   <= 32'd0;
  end 
end 


//-----------------------------------------------------------------------------
// Register the 64 input pins (Ports A-H) for better timing
//-----------------------------------------------------------------------------
always @ ( posedge clk_200m ) 
begin 
  port_a_loc <= port_a[7:0];
//port_b_loc <= port_b[7:0];
  port_c_loc <= port_c[7:0];
  port_d_loc <= port_d[7:0];
//port_e_loc <= port_e[7:0];
//port_f_loc <= port_f[7:0];
  port_f_loc[7:1] <= port_f[7:1];
//port_g_loc <= port_g[7:0];
//port_h_loc <= port_h[7:0];
end
  assign port_a[7:0] = 8'bzzzzzzzz;
//assign port_b[7:0] = 8'bzzzzzzzz;
  assign port_c[7:0] = 8'bzzzzzzzz;
  assign port_d[7:0] = 8'bzzzzzzzz;
//assign port_e[7:0] = 8'bzzzzzzzz;
//assign port_f[7:0] = 8'bzzzzzzzz;
  assign port_f[7:1] = 7'bzzzzzzz;
//assign port_g[7:0] = 8'bzzzzzzzz;
//assign port_h[7:0] = 8'bzzzzzzzz;

//-----------------------------------------------------------------------------
// B0-50-D11
// B4-51-D10
// B1-52-D9
// B5-53-D8
// B2-54-D7
// B6-55-D6
// B3-56-CK_N
// B7-57-CK_P
//
// F0-58-D5
// G0-5-VSYNC
// G4-4-HSYNC
// G1-2-DE
// G5-63-D0
// G2-62-D1
// G6-61-D2
// G3-60-D3
// G7-59-D4
//-----------------------------------------------------------------------------
  assign port_b[7:0] = { dvi_ck_p,  
                         dvi_rgb[6],
                         dvi_rgb[8],
                         dvi_rgb[10],
                         dvi_ck_n,  
                         dvi_rgb[7],
                         dvi_rgb[9],
                         dvi_rgb[11] };
  assign port_g[7:0] = { dvi_rgb[4],
                         dvi_rgb[2],
                         dvi_rgb[0],
                         vga_hs,     
                         dvi_rgb[3],
                         dvi_rgb[1],
                         vga_de,     
                         vga_vs      };

  assign port_f[0] =  dvi_rgb[5];

  assign port_h[7:0] = { vga_g[1],
                         vga_g[3],
                         vga_r[1],
                         vga_r[3],
                         vga_g[0],
                         vga_g[2],
                         vga_r[0],
                         vga_r[2]    };

  assign port_e[7:0] = { vga_hs  ,
                         vga_b[0],
                         pmod_ck,
                         vga_b[3],
                         vga_vs,
                         vga_de,
                         vga_b[1],
                         vga_b[2]    };

//-----------------------------------------------------------------------------
// This is the SUMP2 user_ctrl mux for muxing in different inputs.
// Setting sump_user_ctrl variable in sump2.ini will change this mux setting
// sump2_user_ctrl = 0x0 : Capture 100mil DIP pins A-H [3:0]
// sump2_user_ctrl = 0x1 : Capture 50mil pins on side A-D [7:0]
// sump2_user_ctrl = 0x2 : Capture 50mil pins on side E-H [7:0]
// sump2_user_ctrl = 0x3 : Internal Test Counters that don't overrun HyperRAM
//-----------------------------------------------------------------------------
always @ ( posedge clk_200m ) 
begin 
  sump2_user_ctrl_p1 <= sump2_user_ctrl[31:0];// Switch timing domains - static

  mux0_sel <= 0;
  mux1_sel <= 0;
  mux2_sel <= 0;
  mux3_sel <= 0;

  case( sump2_user_ctrl_p1[3:0] )
    4'd0    : mux0_sel <= 1;
    4'd1    : mux1_sel <= 1;
    4'd2    : mux2_sel <= 1;
    4'd3    : mux3_sel <= 1;
  endcase


  if ( mux0_sel == 1 ) begin 
    sump2_events <= { port_h_loc[3:0],
                      port_g_loc[3:0],
                      port_f_loc[3:0],
                      port_e_loc[3:0],
                      port_d_loc[3:0],
                      port_c_loc[3:0],
                      port_b_loc[3:0],
                      port_a_loc[3:0] };
  end

  if ( mux1_sel == 1 ) begin 
    sump2_events <= { port_d_loc[7:0],
                      port_c_loc[7:0],
                      port_b_loc[7:0],
                      port_a_loc[7:0] };
  end

  if ( mux2_sel == 1 ) begin 
    sump2_events <= { port_h_loc[7:0],
                      port_g_loc[7:0],
                      port_f_loc[7:0],
                      port_e_loc[7:0] };
  end

  if ( mux3_sel == 1 ) begin 
    if ( test_cnt[10:6] == 5'd0 ) begin
      sump2_events <= { test_cnt[31:6], little_cnt[5:0] };
    end else begin
      sump2_events <= { test_cnt[31:6], 6'd0 };
    end
    sump2_events[24] <= a_we;
    sump2_events[25] <= a_overrun;
    sump2_events[26] <= a_empty;
    sump2_events[27] <= dbg_fifo_pop;
    sump2_events[28] <= dsf_hr_wr_req;
    sump2_events[29] <= dsf_hr_busy;
    sump2_events[30] <= dsf_hr_burst_wr_rdy;
    sump2_events[31] <= 0;
  end
  sump2_events_p1 <= sump2_events[31:0];
  sump2_events_p2 <= sump2_events_p1[31:0];
  sump2_events_p3 <= sump2_events_p2[31:0];

  dwords_3_0[127:32] <= 96'd0;
  dwords_3_0[31:0  ] <= { port_h_loc[7:0],
                          port_g_loc[7:0],
                          port_f_loc[7:0],
                          port_e_loc[7:0] };

end // sump2 input mux


//-----------------------------------------------------------------------------
// SUMP2 OSH Logic Analyzer
// Note: For data_dwords = 4, reduce RAM from 8K/13 to 4K/12 to fit the 7S25
// Currently the design only samples 32bits at a time as sampling 64 bits at 
// once reduces the sample depth
//-----------------------------------------------------------------------------
sump2
#
(
  .depth_len        ( 8192                    ),
  .depth_bits       ( 13                      ),
//.depth_len        ( 4096                    ),
//.depth_bits       ( 12                      ),
//.depth_len        ( 1024                    ),
//.depth_bits       ( 10                      ),
  .event_bytes      ( 4                       ),
  .data_dwords      ( 0                       ),
//.data_dwords      ( 4                       ),
  .nonrle_en        ( 1                       ),
  .rle_en           ( 1                       ),
  .pattern_en       ( 0                       ),
  .deep_sump_en     ( 1                       ),
  .trigger_nth_en   ( 1                       ),
  .trigger_dly_en   ( 1                       ),
  .trigger_wd_en    ( 0                       ),
  .freq_mhz         ( 16'd200                 ),
  .freq_fracts      ( 16'h0000                )
)
u0_sump2
(
  .reset            ( 1'b0                    ),
  .clk_lb           ( clk_80m                 ),
  .clk_cap          ( clk_200m                ),
  .lb_cs_ctrl       ( lb_cs_sump2_ctrl        ),
  .lb_cs_data       ( lb_cs_sump2_data        ),
  .lb_wr            ( sump_lb_wr              ),
  .lb_rd            ( sump_lb_rd              ),
  .lb_wr_d          ( lb_wr_d[31:0]           ),
  .lb_rd_d          ( u0_lb_rd_d              ),
  .lb_rd_rdy        ( u0_lb_rd_rdy            ),
  .trigger_in       ( 1'b0                    ),
  .trigger_out      (                         ),
  .events_din       ( sump2_events_p3[31:0]   ),
  .active           (                         ),
  .dwords_3_0       ( dwords_3_0[127:0]       ),
  .dwords_7_4       ( 128'd0                  ),
  .dwords_11_8      ( 128'd0                  ),
  .dwords_15_12     ( 128'd0                  ),
  .user_ctrl        ( sump2_user_ctrl[31:0]   ),
  .user_pat0        (                         ),
  .user_pat1        (                         ),

  .ds_trigger       ( ds_trigger              ),
  .ds_events        ( ds_events[31:0]         ),
  .ds_user_ctrl     ( ds_user_ctrl[31:0]      ),
  .ds_rle_pre_done  ( ds_rle_pre_done         ),
  .ds_rle_post_done ( ds_rle_post_done        ),
  .ds_cmd_lb        ( ds_cmd_lb[5:0]          ),
  .ds_cmd_cap       ( ds_cmd_cap[5:0]         ),
  .ds_rd_req        ( ds_rd_req               ),
  .ds_wr_req        ( ds_wr_req               ),
  .ds_wr_d          ( ds_wr_d[31:0]           ),
  .ds_rd_d          ( ds_rd_d[31:0]           ),
  .ds_rd_rdy        ( ds_rd_rdy               )
); // u0_sump2
  assign lb_cs_sump2_ctrl = ( lb_addr[7:0] == 8'h90 ) ? 1 : 0;
  assign lb_cs_sump2_data = ( lb_addr[7:0] == 8'h94 ) ? 1 : 0;
  assign sump_lb_wr = lb_wr;
  assign sump_lb_rd = lb_rd;


//-----------------------------------------------------------------------------
// DeepSump connect on the side of sump2. Note, ds_depth_len and _bits MUST
// match those used for the external RAM.
// Examples:
//   ds_depth_len  = 65536
//   ds_depth_bits = 16
//-----------------------------------------------------------------------------
deep_sump
#
(
  .depth_len        ( ds_depth_len               ),
  .depth_bits       ( ds_depth_bits              )
)
u0_deep_sump
(
  .reset            ( 1'b0                       ),
  .clk_lb           ( clk_80m                    ),
  .clk_cap          ( clk_200m                   ),
  .ds_trigger       ( ds_trigger                 ),
//.ds_events        ( ds_events[31:0]            ),
//.ds_events        ( { 8'd0, ds_events[23:0] }  ),
  .ds_events        ( ds_events_muxd[31:0]       ),
  .ds_cmd_lb        ( ds_cmd_lb[5:0]             ),
  .ds_cmd_cap       ( ds_cmd_cap[5:0]            ),
  .ds_rd_req        ( ds_rd_req                  ),
  .ds_wr_req        ( ds_wr_req                  ),
  .ds_wr_d          ( ds_wr_d[31:0]              ),
  .ds_rd_d          ( ds_rd_d[31:0]              ),
  .ds_rd_rdy        ( ds_rd_rdy                  ),
  .ds_rle_pre_done  ( ds_rle_pre_done            ),
  .ds_rle_post_done ( ds_rle_post_done           ),
  .ds_user_cfg      (                            ),

  .a_di             ( a_di[63:0]                 ),
  .a_addr           ( a_addr[ds_depth_bits-1:0]  ),
  .a_we             ( a_we                       ),
  .a_overrun        ( a_overrun                  ),
  .b_do             ( b_do[63:0]                 ),
  .b_addr           ( b_addr[ds_depth_bits-1:0]  ),
  .b_rd_req         ( b_rd_req                   )
);
  assign ds_events_muxd[31:0] = ( mux3_sel == 1 ) ? 
                               { 8'd0,ds_events[23:0] } : { ds_events[31:0] };


//-----------------------------------------------------------------------------
// This example is to just infer a really big Block RAM ( or Ultra RAM ) that
// can write at full clk_cap rates. Typically this is better than external
// HyperRAM as data rate is so much higher.
//-----------------------------------------------------------------------------
//deep_sump_ram
//#
//(
//  .depth_len      ( ds_depth_len               ),
//  .depth_bits     ( ds_depth_bits              )
//)
//u0_deep_sump_ram
//(
//  .a_clk          ( clk_200m                   ),
//  .a_di           ( a_di[63:0]                 ),
//  .a_addr         ( a_addr[ds_depth_bits-1:0]  ),
//  .a_we           ( a_we                       ),
//  .a_overrun      ( a_overrun                  ),
//  .b_clk          ( clk_80m                    ),
//  .b_do           ( b_do[63:0]                 ),
//  .b_addr         ( b_addr[ds_depth_bits-1:0]  ),
//  .b_rd_req       ( b_rd_req                   )
//);


//-----------------------------------------------------------------------------
// Dual-Clock FIFO and FSM between the Deep Sump virtual SRAM interface and
// the hyper_xface_pll DRAM interface. Handles all the rate conversions.
// HyperRAM can only accept a DWORD every other clock plus there is the 
// overhead for Command+Address and the 1x and 2x Latency.
//-----------------------------------------------------------------------------
deep_sump_fifo 
#
(
  .depth_len          ( ds_depth_len               ),
  .depth_bits         ( ds_depth_bits              )
)
u_deep_sump_fifo
(
  .a_clk              ( clk_200m                   ),
  .a_di               ( a_di[63:0]                 ),
  .a_addr             ( a_addr[ds_depth_bits-1:0]  ),
  .a_we               ( a_we                       ),
  .a_overrun          ( a_overrun                  ),
  .a_empty            ( a_empty                    ),
  .dbg_fifo_pop       ( dbg_fifo_pop               ),
  .b_clk              ( clk_80m                    ),
  .b_do               ( b_do[63:0]                 ),
  .b_addr             ( b_addr[ds_depth_bits-1:0]  ),
  .b_rd_req           ( b_rd_req                   ),
  .hr_rd_req          ( dsf_hr_rd_req              ),
  .hr_wr_req          ( dsf_hr_wr_req              ),
  .hr_mem_or_reg      ( dsf_hr_mem_or_reg          ),
  .hr_addr            ( dsf_hr_addr[31:0]          ),
  .hr_rd_num_dwords   ( dsf_hr_rd_num_dwords[5:0]  ),
  .hr_wr_d            ( dsf_hr_wr_d[31:0]          ),
  .hr_rd_d            ( dsf_hr_rd_d[31:0]          ),
  .hr_rd_rdy          ( dsf_hr_rd_rdy              ),
  .hr_busy            ( dsf_hr_busy                ),
  .hr_burst_wr_rdy    ( dsf_hr_burst_wr_rdy        )
);
//assign dsf_hr_rd_req = 0;
//assign dsf_hr_wr_req = 0;
//assign dsf_hr_mem_or_reg = 0;


//-----------------------------------------------------------------------------
// Mux to the hyper_xface_pll:
//   1) Provides manual access to DRAM via LB for debug.
//   2) Takes care of 150uS post-Reset Latency Configuration.
//   3) Bolts onto deep_sump_fifo
// Note: Arbitration is simple 1st come 1st serve with no queuing.
//-----------------------------------------------------------------------------
hyper_xface_mux u_hyper_xface_mux 
(
  .reset                ( reset_80m                 ),
  .clk                  ( clk_80m                   ),
  .lb_wr                ( lb_wr                     ),
  .lb_rd                ( lb_rd                     ),
  .lb_addr              ( lb_addr[31:0]             ),
  .lb_wr_d              ( lb_wr_d[31:0]             ),
  .lb_rd_d              ( u2_lb_rd_d[31:0]          ),
  .lb_rd_rdy            ( u2_lb_rd_rdy              ),

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

  .dsf_hr_rd_req        ( dsf_hr_rd_req             ),
  .dsf_hr_wr_req        ( dsf_hr_wr_req             ),
  .dsf_hr_mem_or_reg    ( dsf_hr_mem_or_reg         ),
  .dsf_hr_addr          ( dsf_hr_addr[31:0]         ),
  .dsf_hr_rd_num_dwords ( dsf_hr_rd_num_dwords[5:0] ),
  .dsf_hr_wr_d          ( dsf_hr_wr_d[31:0]         ),
  .dsf_hr_rd_d          ( dsf_hr_rd_d[31:0]         ),
  .dsf_hr_rd_rdy        ( dsf_hr_rd_rdy             ),
  .dsf_hr_busy          ( dsf_hr_busy               ),
  .dsf_hr_burst_wr_rdy  ( dsf_hr_burst_wr_rdy       ),

  .dram_dq_in           ( dram_dq_in[7:0]           ),
  .dram_dq_out          ( dram_dq_out[7:0]          ),
  .dram_dq_oe_l         ( dram_dq_oe_l              ),
  .dram_rwds_in         ( dram_rwds_in              ),
  .dram_rwds_out        ( dram_rwds_out             ),
  .dram_rwds_oe_l       ( dram_rwds_oe_l            ),
  .dram_ck              ( dram_ck                   ),
  .dram_rst_l           ( dram_rst_l                ),
  .dram_cs_l            ( dram_cs_l                 )
);


//-----------------------------------------------------------------------------
// Bridge to an external HyperRAM DRAM chip. This module is not SUMP2 DeepSump
// specific. It is a generic HyperRAM xface for writing and reading DWORDs.
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
  .sump_dbg               ( hr_dbg_events[31:0]   ),
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


//-----------------------------------------------------------------------------
// Example Core. Just some Read and Writable 32bit registers on LocalBus
//-----------------------------------------------------------------------------
core u_core
(
  .reset       ( reset_80m        ),
  .clk_lb      ( clk_80m          ),
  .lb_wr       ( lb_wr            ),
  .lb_rd       ( lb_rd            ),
  .lb_addr     ( lb_addr          ),
  .lb_wr_d     ( lb_wr_d          ),
  .lb_rd_d     ( u1_lb_rd_d       ),
  .lb_rd_rdy   ( u1_lb_rd_rdy     )
);


// ----------------------------------------------------------------------------
// VGA Timing Generator
// ----------------------------------------------------------------------------
vga_core u0_vga_core
(
  .reset             ( 1'b0                ),
  .random_num        ( 32'd0               ),
  .color_3b          ( 1'b0                ),
  .mode_bit          ( 1'b0                ),
  .clk_dot           ( clk_40m             ),
  .vga_active        ( vga_de              ),
  .vga_hsync         ( vga_hs              ),
  .vga_vsync         ( vga_vs              ),
  .vga_pixel_rgb     ( vga_rgb[23:0]       )
);
  assign vga_r = vga_rgb[23:16];
  assign vga_g = vga_rgb[15:8];
  assign vga_b = vga_rgb[7:0];


//-----------------------------------------------------------------------------
// Reflop Data at IOBs using DDR Output Flops
// D[11:0] - Low  = { Green[3:0], Blue[7:0]  }
// D[11:0] - High = { Red[7:0],   Green[7:4] }
//-----------------------------------------------------------------------------
genvar i1;
generate
for ( i1=0; i1<=11; i1=i1+1 ) begin: gen_i1
 xil_oddr u_xil_oddr
  (
    .clk       ( clk_40m           ),
    .din_ris   ( rgb_ris[i1]       ),
    .din_fal   ( rgb_fal[i1]       ),
    .dout      ( dvi_rgb[i1]       )
  );
end
endgenerate
  assign rgb_fal = { vga_g[3:0], vga_b[7:0] };
  assign rgb_ris = { vga_r[7:0], vga_g[7:4] };


xil_oddr u0_xil_oddr
(
  .clk       ( clk_40m             ),
  .din_ris   ( 1'b1                ),
  .din_fal   ( 1'b0                ),
  .dout      ( dvi_ck_p            )
);

xil_oddr u1_xil_oddr
(
  .clk       ( clk_40m             ),
  .din_ris   ( 1'b0                ),
//.din_fal   ( 1'b1                ),
  .din_fal   ( 1'b0                ),
  .dout      ( dvi_ck_n            )
);

xil_oddr u2_xil_oddr
(
  .clk       ( clk_40m             ),
  .din_ris   ( 1'b1                ),
  .din_fal   ( 1'b0                ),
  .dout      ( pmod_ck             )
);


endmodule // top.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it
