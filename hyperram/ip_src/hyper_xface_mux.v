/* ****************************************************************************
-- (C) Copyright 2018 Kevin Hubbard - All rights reserved.
-- Source file: hyper_xface_mux.v   
-- Date:        July 2018     
-- Author:      khubbard
-- Description: Mux to hyper_xface_pll.v for both DeepSump and LB access
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
-- Write Cycle Single and Burst:
-- In:
--   clk           _/ \_/ \_/ \_/ \_/ \_/ \_/ \
--   lb_wr         _____/  \________/      \___
--   lb_addr[31:0] -----<  >--------<  ><  >---
--   lb_wr_d[31:0] -----<  >--------<  ><  >---
--
-- Read Cycle Single Only Allowed. Bus is unavailable until cycle completed.
-- In:
--   clk           _/ \_/ \_/ \_/ \_/ \_/ \_/ \
--   lb_rd         _____/  \________/      \___
--   lb_addr[31:0] -----<  >--------<  >-------
-- Out:
--   lb_rd_d[31:0] -----------------<  >-------
--   lb_rd_rdy     _________________/  \_______
--                          |------| Variable Latency ( 1024 limit typically )
--
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   07.01.18  khubbard Creation
-- ***************************************************************************/
`timescale 1 ns/ 100 ps
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module hyper_xface_mux
(
  input  wire        reset,
  input  wire        clk,
  input  wire        lb_wr,
  input  wire        lb_rd,
  input  wire [31:0] lb_addr,
  input  wire [31:0] lb_wr_d,
  output reg  [31:0] lb_rd_d,
  output reg         lb_rd_rdy,
  output reg         ds_disable,

  input  wire        dsf_hr_rd_req,
  input  wire        dsf_hr_wr_req,
  input  wire        dsf_hr_mem_or_reg,
  input  wire [31:0] dsf_hr_addr,
  input  wire [5:0]  dsf_hr_rd_num_dwords,
  input  wire [31:0] dsf_hr_wr_d,
  output wire        dsf_hr_busy,
  output wire        dsf_hr_burst_wr_rdy,
  output wire [31:0] dsf_hr_rd_d,
  output wire        dsf_hr_rd_rdy,

  output wire        hr_rd_req,
  output wire        hr_wr_req,
  output wire        hr_mem_or_reg,
  output wire [31:0] hr_addr,
  output wire [5:0]  hr_rd_num_dwords,
  output wire [31:0] hr_wr_d,
  input  wire        hr_busy,
  input  wire        hr_burst_wr_rdy,
  input  wire [31:0] hr_rd_d,
  input  wire        hr_rd_rdy,
  input  wire [7:0]  hr_cycle_len
);// hyper_xface_mux


// Port Name Abbreviations:
//   dsf  = Deep Sump FIFO, signals to deep_sump_fifo.v
//   dram = IOB signals ( pins ) for the external HyperRAM
//   lb   = Local Bus

  reg           ds_enable;
  reg           loc_hr_rd_req;
  reg           loc_hr_wr_req;
  reg           loc_hr_mem_or_reg;
  reg  [31:0]   loc_hr_addr;
  reg  [5:0]    loc_hr_rd_num_dwords;
  reg  [31:0]   loc_hr_wr_d;
  wire [31:0]   loc_hr_rd_d;
  wire          loc_hr_rd_rdy;
  wire          loc_hr_busy;
  reg           loc_hr_busy_p1;
  wire          loc_hr_burst_wr_rdy;
  reg  [31:0]   hr_cfg_dword;
  wire [31:0]   hr_dflt_timing;

  reg  [31:0]   lb_0010_reg;
  reg  [31:0]   lb_0014_reg;
  reg  [31:0]   lb_0018_reg;
  reg  [31:0]   lb_001c_reg;
  reg  [14:0]   rst_cnt;
  reg           rst_done;
  reg           rst_done_p1;
  reg           cfg_busy;
  reg           cfg_now;
  reg           mux_sel_jk;
  wire          mux_sel_ord;


//-----------------------------------------------------------------------------
// This 32bit value is determined by both the HyperRAM clock rate (83-166 MHz)
// and prefence for variable 1x/2x latency, or fixed 2x always latency.
// See Section-3 of hyper_xface.pll doc for the 8 different valid 32bit values.
// Note: Testing at 90 MHz with 100 MHz variable latency resulted in about 1%
// of the writes being lost entirely ( never happening ). Slowing to 83 MHz
// made the HyperRAM 100% for Writes and Reads. This is on S7 Mini proto board.
//-----------------------------------------------------------------------------
//assign hr_dflt_timing = 32'h8ff40000; // 100 MHz Variable Latency
  assign hr_dflt_timing = 32'h8fe40000; //  83 MHz Variable Latency


//-----------------------------------------------------------------------------
// Mux HyperRAM access between DeepSump and LocalBus Regs and reset cfg fsm.
// There is no arbitration, the last to access has control. Assumption is
// both interfaces are never used at the same time.
//-----------------------------------------------------------------------------
always @( posedge clk )
begin
  if ( ds_enable == 1 && ( dsf_hr_rd_req == 1 || dsf_hr_wr_req == 1 ) ) begin
    mux_sel_jk <= 1;// DeepSumpFIFO has HyperRAM access
  end
  if ( loc_hr_rd_req == 1 || loc_hr_wr_req == 1 || reset == 1 ) begin
    mux_sel_jk <= 0;// LocalBus has HyperRAM access
  end
end


//-----------------------------------------------------------------------------
// Mux has to be combinatorial unfortunately as there is no advanced warning.
//-----------------------------------------------------------------------------
// Inputs to hyper_xface_pll.v
  assign mux_sel_ord = ( dsf_hr_rd_req | dsf_hr_wr_req ) & ds_enable;
  assign hr_addr = ( mux_sel_ord == 1 ) ? dsf_hr_addr[31:0] : loc_hr_addr[31:0];
  assign hr_rd_num_dwords = ( mux_sel_ord == 1 ) ? 
                      dsf_hr_rd_num_dwords[5:0] : loc_hr_rd_num_dwords[5:0];
  assign hr_wr_d = ( mux_sel_ord == 1 ) ? dsf_hr_wr_d[31:0] : loc_hr_wr_d[31:0];
  assign hr_rd_req     = ( dsf_hr_rd_req & ds_enable )     | loc_hr_rd_req;
  assign hr_wr_req     = ( dsf_hr_wr_req & ds_enable )     | loc_hr_wr_req;
  assign hr_mem_or_reg = ( dsf_hr_mem_or_reg & ds_enable ) | loc_hr_mem_or_reg;


// Outputs from hyper_xface_pll.v
//assign dsf_hr_busy         = hr_busy         & mux_sel_jk;
  assign dsf_hr_busy         = cfg_busy | ( hr_busy & mux_sel_jk );
  assign dsf_hr_burst_wr_rdy = hr_burst_wr_rdy & mux_sel_jk;
  assign dsf_hr_rd_rdy       = hr_rd_rdy       & mux_sel_jk;
  assign dsf_hr_rd_d         = hr_rd_d[31:0];// No muxing required

  assign loc_hr_busy          = hr_busy         & ~mux_sel_jk;
  assign loc_hr_burst_wr_rdy  = hr_burst_wr_rdy & ~mux_sel_jk;
  assign loc_hr_rd_rdy        = hr_rd_rdy       & ~mux_sel_jk;
  assign loc_hr_rd_d          = hr_rd_d[31:0];// No muxing required


//-----------------------------------------------------------------------------
// HyperRAM requires a 150uS delay from power on prior to configuration.  
// Delay 2^15 clocks from reset then issue the config cycle pulse cfg_now.
// This may optionally be used to automatically configure the HyperRAM speed.
//-----------------------------------------------------------------------------
always @( posedge clk )
begin
  rst_done_p1 <= rst_done;
  cfg_now     <= rst_done & ~rst_done_p1;// Rising Edge Detect

  if ( rst_cnt != 15'h7FFF ) begin
    rst_cnt  <= rst_cnt[14:0] + 1;
    rst_done <= 0;
    cfg_busy <= 1;
  end else begin
    rst_done <= 1;
    cfg_busy <= 0;
  end

  if ( reset == 1 ) begin
    rst_cnt  <= 15'd0;
    rst_done <= 0;
    cfg_busy <= 1;
  end
end // always


//-----------------------------------------------------------------------------
// This does two things:
//  1) 150uS after reset, issue a HyperRAM config write to set latency timing.
//  2) Provide 4 LocalBus registers that allow manual writing and reading DRAM.
//
// 0x0010 : Address
// 0x0014 : Data Buffer : DWORD0
// 0x0018 : Data Buffer : DWORD1
// 0x001C : Control   
//            1 : Write Single DWORD
//            2 : Read  Single DWORD
//            3 : Write Burst two DWORDs
//            4 : Read  Burst two DWORDs
//            5 : Write Configuration    
//            6 : Read  Configuration - Not Implemented
// 
// Cypress Values:
// D(23:20) = Initial Latency
//            0xF = 100 MHz 4-Clock
//            0xE =  83 MHz 3-Clock
//            0x1 = 166 MHz 6-Clock (Def)
//            0x0 = 133 MHz 5-Clock
// D(19)    = 0=Variable Latency, 1=Fixed 2x Latency (Def)
// D(18)    = Hybrid Burst Enable 0=Hybrid, 1=Legacy (Def)
// D(17:16) = Burst Length 00=128 Bytes, 11=32 Bytes (Def)
//-----------------------------------------------------------------------------
always @( posedge clk )
begin
  lb_rd_d           <= 32'd0;
  lb_rd_rdy         <= 0;
  loc_hr_busy_p1    <= loc_hr_busy;
  loc_hr_rd_req     <= 0;
  loc_hr_wr_req     <= 0;
  loc_hr_mem_or_reg <= 0;
  ds_disable        <= ~ ds_enable;

  if ( lb_wr == 1 ) begin
    if ( lb_addr[15:0] == 16'h0010 ) begin
      lb_0010_reg <= lb_wr_d[31:0];
    end
    if ( lb_addr[15:0] == 16'h0014 ) begin
      lb_0014_reg <= lb_wr_d[31:0];
    end
    if ( lb_addr[15:0] == 16'h0018 ) begin
      lb_0018_reg <= lb_wr_d[31:0];
    end
    if ( lb_addr[15:0] == 16'h001c ) begin
      lb_001c_reg <= lb_wr_d[31:0];
    end
  end 

  if ( lb_rd == 1 ) begin
    if ( lb_addr[15:0] == 16'h0010 ) begin
      lb_rd_d   <= lb_0010_reg[31:0];
      lb_rd_rdy <= 1;
    end 
    if ( lb_addr[15:0] == 16'h0014 ) begin
      lb_rd_d   <= lb_0014_reg[31:0];
      lb_rd_rdy <= 1;
    end 
    if ( lb_addr[15:0] == 16'h0018 ) begin
      lb_rd_d   <= lb_0018_reg[31:0];
      lb_rd_rdy <= 1;
    end 
    // Reading 0x1C tells you how many clock cycles the last HR access took
    if ( lb_addr[15:0] == 16'h001c ) begin
      lb_rd_d   <= { 24'd0, hr_cycle_len[7:0] };
      lb_rd_rdy <= 1;
    end 
  end 

  // Single DWORD Write
  if ( lb_001c_reg[2:0] == 3'd1 && loc_hr_busy == 0 ) begin
    loc_hr_addr       <= lb_0010_reg[31:0];
    loc_hr_wr_d       <= lb_0014_reg[31:0]; 
    loc_hr_wr_req     <= 1;
    loc_hr_mem_or_reg <= 0;// DRAM access
    lb_001c_reg   <= 32'd0; // Self Clearing
  end 


  // Single DWORD Read
  if ( lb_001c_reg[2:0] == 3'd2 && loc_hr_busy == 0 ) begin
    loc_hr_addr          <= lb_0010_reg[31:0];
    loc_hr_rd_req        <= 1;
    loc_hr_mem_or_reg    <= 0;// DRAM access
    loc_hr_rd_num_dwords <= 6'd1;
    lb_001c_reg      <= 32'd0; // Self Clearing
  end 


  // Burst Write of 2 DWORDs. 
  // 2nd DWORD must launch as soon loc_hr_burst_wr_rdy asserts
  if ( lb_001c_reg[2:0] == 3'd3 ) begin
    if ( loc_hr_busy == 0 ) begin
      loc_hr_addr       <= lb_0010_reg[31:0];
      loc_hr_wr_d       <= lb_0014_reg[31:0]; 
      loc_hr_wr_req     <= 1;
      loc_hr_mem_or_reg <= 0;// DRAM access
    end else if ( loc_hr_burst_wr_rdy == 1 ) begin 
      loc_hr_wr_d       <= lb_0018_reg[31:0]; 
      loc_hr_wr_req     <= 1;
      loc_hr_mem_or_reg <= 0;// DRAM access
      lb_001c_reg        <= 32'd0; // Self Clearing after 2nd DWORD
    end
  end


  // Burst Read of 2 DWORDs
  if ( lb_001c_reg[2:0] == 3'd4 ) begin
    if ( loc_hr_busy == 0 && loc_hr_busy_p1 == 0 ) begin
      loc_hr_addr          <= lb_0010_reg[31:0];
      loc_hr_rd_req        <= 1;
      loc_hr_mem_or_reg    <= 0;// DRAM access
      loc_hr_rd_num_dwords <= 6'd2;
    end else if ( loc_hr_busy == 1 ) begin
      if ( loc_hr_rd_rdy == 1 ) begin
        lb_0018_reg <= loc_hr_rd_d[31:0];
        lb_0014_reg <= lb_0018_reg[31:0];
      end
    end else if ( loc_hr_busy == 0 && loc_hr_busy_p1 == 1 ) begin
      lb_001c_reg   <= 32'd0; // Self Clearing after 2nd DWORD
    end
  end

  if ( lb_001c_reg[2:0] == 3'd7 ) begin
    ds_enable    <= 0;
  end
  if ( lb_001c_reg[2:0] == 3'd6 ) begin
    ds_enable    <= 1;
  end

  // Make sure pulses are only one clock wide for bursts
  if ( loc_hr_wr_req == 1 ) begin
    loc_hr_wr_req <= 0;
  end
  if ( loc_hr_rd_req == 1 ) begin
    loc_hr_rd_req <= 0;
  end


  // Configuration Write : Either via the 0x1C register of the 150uS Timer
  if ( ( cfg_now == 1 || lb_001c_reg[2:0] == 3'd5 ) && loc_hr_busy == 0 ) begin
    loc_hr_addr       <= 32'h00000800;
    loc_hr_wr_d       <= lb_0014_reg[31:0]; 
    hr_cfg_dword      <= lb_0014_reg[31:0]; 
    loc_hr_mem_or_reg <= 1;// Config Reg Write instead of DRAM Write
    loc_hr_wr_req     <= 1;
    lb_001c_reg       <= 32'd0; // Self Clearing
  end 

  if ( lb_001c_reg[2:0] == 3'd6 && loc_hr_busy == 0 ) begin
    lb_rd_d     <= hr_cfg_dword[31:0];
    lb_rd_rdy   <= 1;
    lb_001c_reg <= 32'd0; // Self Clearing
  end 


  if ( reset == 1 ) begin
    lb_0010_reg  <= 32'd0;
    lb_0018_reg  <= 32'd0;
    lb_001c_reg  <= 32'd0;
    lb_0014_reg  <= hr_dflt_timing[31:0];
    hr_cfg_dword <= hr_dflt_timing[31:0];
    ds_enable    <= 1;
  end

  ds_enable    <= 1;

end // always


endmodule // hyper_xface_mux.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it
