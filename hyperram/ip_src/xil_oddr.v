/* ****************************************************************************
-- (C) Copyright 2018 Kevin M. Hubbard - All rights reserved.
-- Source file: xil_oddr.v 
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
-- Description: Xilinx 7-Series IDDR DDR input flop
-- Note: 100ns Power On Reset requirement until functional
-- Timing Diagram for SAME_EDGE_PIPELINED
--     |100ns|
-- clk ______/    \____/    \____/    \____/    \
-- din_ris  ---------< 0       >< 2      >----
-- din_fal  ---------< 1       >< 3      >----
-- dout     -----------< 0 >< 1 >< 2 >< 3 >----
-- ************************************************************************* */
`timescale 1 ns/ 100 ps
module xil_oddr
(
  input  wire  clk,
  input  wire  din_ris,
  input  wire  din_fal,
  output wire  dout
);// 


// ODDR: Output Double Data Rate Output Register with Set, Reset
// and Clock Enable.
// 7 Series Xilinx HDL Libraries Guide, version 2016.2
ODDR #
(
  .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
  .INIT(1'b0), // Initial value of Q: 1’b0 or 1’b1
  .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
) u_ODDR 
(
  .Q(  dout),     // 1-bit DDR output
  .C(  clk ),     // 1-bit clock input
  .CE( 1'b1),     // 1-bit clock enable input
  .D1( din_ris ), // 1-bit data input (positive edge)
  .D2( din_fal ), // 1-bit data input (negative edge)
  .R(  1'b0),     // 1-bit reset
  .S(  1'b0)      // 1-bit set
);
// End of ODDR_inst instantiation


endmodule
