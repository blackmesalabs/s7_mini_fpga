/* ****************************************************************************
-- (C) Copyright 2018 Kevin M. Hubbard - All rights reserved.
-- Source file: icap_ctrl.v
-- Date:        June 2018
-- Author:      khubbard
-- Description: Control block for Xilinx 7-Series ICAPE2 for reconfiguration.
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
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- --------------------------------------------------
-- 0.1   06.01.18  khubbard Creation
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared


module icap_ctrl 
(
  input  wire        reset,
  input  wire        clk,
  input  wire        prom_wr,      // MesaBus
  input  wire [31:0] prom_addr,  
  input  wire [31:0] prom_wr_d,  
  input  wire        reconfig_req, // from spi_prom.v
  input  wire [31:0] reconfig_addr
);


  reg  [3:0]  icap_fsm;
  reg         icap_cs_l;
  reg         icap_wr_l;
  reg  [31:0] icap_din;
  reg  [31:0] wb_start_addr;
  reg         reconfig_jk;


//-----------------------------------------------------------------------------
// State machine for driving 7-Series ICAP block to warmboot to an alt addr
// If jp1_l == 0, reconfigure FPGA with bitstream at SPI PROM addr 0x00200000
// Warning: Make sure and disable i_am_slot0 if building a bitfile for
// another slot ( or else the slot will just reconfigure again and again ).
// Note the 7bit address shift on START_ADDR. See Table 7-2 of document:
//   www.xilinx.com/support/documentation/user_guides/ug470_7Series_Config.pdf
// Seems like it should be 8bits, but 3bit shift is what actually works.
//-----------------------------------------------------------------------------
always @ ( posedge clk ) begin : proc_icap
  icap_cs_l <= 1;
  icap_wr_l <= 1;
  icap_din  <= 32'd0;

  case( icap_fsm[3:0] )
    4'd0    : icap_din <= 32'hFFFFFFFF;// Dummy
    4'd1    : icap_din <= 32'h5599aa66;// Sync Word : Bit Swapped
    4'd2    : icap_din <= 32'h04000000;// NOOP
    4'd3    : icap_din <= 32'h0c400080;// WB Start
    4'd4    : icap_din <= { 3'd0, wb_start_addr[31:3] };
    4'd5    : icap_din <= 32'h0c000180;// CMD_WR
    4'd6    : icap_din <= 32'h000000F0;// CMD_IPROG
    4'd7    : icap_din <= 32'h04000000;// NOOP
    default : icap_din <= 32'hFFFFFFFF;
  endcase

  if ( reset == 1 ) begin
    icap_fsm <= 4'd0;
  end else if ( reconfig_jk==1 ) begin
    // Count 0-7 and stop at 8 
    if ( icap_fsm != 4'd8 ) begin
      icap_fsm  <= icap_fsm + 1;
      icap_cs_l <= 0;
      icap_wr_l <= 0;
    end
  end

  // Support manually writing ICAP instructions via MesaBus PROM interface
  if ( prom_wr == 1 && prom_addr[7:0] == 8'h28 ) begin
    icap_cs_l <= 0;
    icap_wr_l <= 0;
    icap_din  <= prom_wr_d[31:0];
  end

  // spi_prom.v can request a boot to any address
  if ( reconfig_req == 1 ) begin
    wb_start_addr <= reconfig_addr[31:0];
    reconfig_jk   <= 1;
  end

  if ( reset == 1 ) begin
    reconfig_jk   <= 0;
  end

end // proc_icap


//-----------------------------------------------------------------------------
// 7-Series ICAPE2 block. Note max clock freq is 100 MHz for Spartan7
//-----------------------------------------------------------------------------
ICAPE2 #
(
  .ICAP_WIDTH              ( "X32"          )
)
u_icape2
(
  .CLK                     ( clk            ),
  .CSIB                    ( icap_cs_l      ),
  .RDWRB                   ( icap_wr_l      ),
  .I                       ( icap_din[31:0] ),
  .O                       (                )
);


endmodule // icap_ctrl
