/* ****************************************************************************
-- (C) Copyright 2018 Kevin Hubbard - All rights reserved.
-- Source file: core.v               
-- Date:        May 2018 
-- Author:      khubbard
-- Description: Example local bus core module
-- Language:    Verilog-2001
-- Simulation:  Mentor-Modelsim 
-- Synthesis:   Xilinst-Vivado
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
--
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   05.31.18  khubbard Creation
-- ***************************************************************************/
`timescale 1 ns/ 100 ps
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module core
(
  input  wire         reset,
  input  wire         clk_lb,
  input  wire         lb_wr,    
  input  wire         lb_rd,    
  input  wire [31:0]  lb_addr,
  input  wire [31:0]  lb_wr_d,
  output reg  [31:0]  lb_rd_d,
  output reg          lb_rd_rdy
);// module core 


  reg  [31:0]   lb_00_reg;
  reg  [31:0]   lb_04_reg;
  reg  [31:0]   lb_08_reg;
  reg  [31:0]   lb_0c_reg;


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
always @ ( posedge clk_lb or posedge reset ) begin : proc_lb
 if ( reset == 1 ) begin
   lb_rd_rdy <= 0;
   lb_rd_d   <= 32'd0;
   lb_00_reg <= 32'h12345678;
   lb_04_reg <= 32'h00000000;
   lb_08_reg <= 32'h00000000;
   lb_0c_reg <= 32'h00000000;
 end else begin
  if ( lb_wr == 1 ) begin 
    if ( lb_addr[7:0] == 8'h00 ) begin 
      lb_00_reg <= lb_wr_d[31:0];
    end 
    if ( lb_addr[7:0] == 8'h04 ) begin 
      lb_04_reg <= lb_wr_d[31:0];
    end 
    if ( lb_addr[7:0] == 8'h08 ) begin 
      lb_08_reg <= lb_wr_d[31:0];
    end 
    if ( lb_addr[7:0] == 8'h0c ) begin 
      lb_0c_reg <= lb_wr_d[31:0];
    end 
  end 

  lb_rd_rdy <= 0;
  lb_rd_d   <= 32'd0;
  if ( lb_rd == 1 ) begin 
    lb_rd_rdy <= 1;
    if ( lb_addr[7:0] == 8'h00 ) begin 
      lb_rd_d <= lb_00_reg[31:0];
    end 
    if ( lb_addr[7:0] == 8'h04 ) begin 
      lb_rd_d <= lb_04_reg[31:0];
    end 
    if ( lb_addr[7:0] == 8'h08 ) begin 
      lb_rd_d <= lb_08_reg[31:0];
    end 
    if ( lb_addr[7:0] == 8'h0c ) begin 
      lb_rd_d <= lb_0c_reg[31:0];
    end 
  end 
 end // reset
end // proc_lb


endmodule // core.v
`default_nettype wire // enable Verilog default for any 3rd party IP needing it
