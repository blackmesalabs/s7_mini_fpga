/* ****************************************************************************
-- (C) Copyright 2018 Kevin M. Hubbard - All rights reserved.
-- Source file: cdc_reset.v
-- Date:        May 2018 
-- Author:      khubbard
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
-- Description: Xilinx 7-Series XPM inferred reset synchronizer. See UG974 
--
-- clk_dst     _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
-- reset       _______/              \______________________________________
-- dst_reset   _______/                             \_______________________
-- ************************************************************************* */
`timescale 1 ns/ 100 ps
module cdc_reset
(
  input  wire         reset,
  input  wire         clk_dst,
  output wire         dst_reset
);// module cdc_reset


xpm_cdc_async_rst #
(
  .DEST_SYNC_FF    ( 4 ), // integer; range: 2-10
  .RST_ACTIVE_HIGH ( 1 ), // integer; 0=Active Low Input, 1=Active High Input
  .INIT_SYNC_FF    ( 0 )  // integer; 0=Default, 1 EN Behavioral Init for Sims
) xpm_cdc_array_single_inst 
(
  .src_arst       ( reset     ),
  .dest_clk       ( clk_dst   ),
  .dest_arst      ( dst_reset )
);


endmodule
