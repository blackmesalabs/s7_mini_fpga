/* ****************************************************************************
-- Source file: mesa_core.v                
-- Date:        October 4, 2015 
-- Author:      khubbard
-- Description: Wrapper around a bunch of Mesa Bus Modules. This takes in the
--              binary nibble stream from mesa_phy and takes care of slot
--              enumeration and subslot bus decoding to local-bus.
--              SubSlot-0 is 32bit user localbus.
--              SubSlot-E is 32bit SPI PROM Interface localbus.
--              SubSlot-F is power management,etc.
-- Language:    Verilog-2001 and VHDL-1993
-- Simulation:  Mentor-Modelsim 
-- Synthesis:   Xilinst-XST 
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   10.04.15  khubbard Creation
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module mesa_core #
(
  parameter spi_prom_en = 1
)
(
  input  wire         clk,   
  input  wire         reset,

  output wire         lb_wr,
  output wire         lb_rd,
  output wire [31:0]  lb_addr,
  output wire [31:0]  lb_wr_d,
  input  wire [31:0]  lb_rd_d,
  input  wire         lb_rd_rdy,

  output wire         spi_sck,
  output wire         spi_cs_l,
  output wire         spi_mosi,
  input  wire         spi_miso,

  input  wire [3:0]   rx_in_d,
  input  wire         rx_in_rdy,
  input  wire         rx_in_flush,

  output reg  [7:0]   tx_byte_d,
  output reg          tx_byte_rdy,
  output reg          tx_done,
  input  wire         tx_busy,
  output wire [7:0]   tx_wo_byte,
  output wire         tx_wo_rdy,

  output wire [8:0]   subslot_ctrl,
  input  wire         reconfig_2nd_slot,
  output wire         reconfig_req,
  output wire [31:0]  reconfig_addr,
  output wire         bist_req
);// module mesa_core

  wire          rx_loc_rdy;
  wire          rx_loc_start;
  wire          rx_loc_stop;
  wire [7:0]    rx_loc_d;

  wire [7:0]    tx_spi_byte_d;
  wire          tx_spi_byte_rdy;
  wire          tx_spi_done;
  wire [7:0]    tx_lb_byte_d;
  wire          tx_lb_byte_rdy;
  wire          tx_lb_done;
  wire          tx_busy_loc;
  reg  [3:0]    tx_busy_sr;

  wire          prom_wr;
  wire          prom_rd;
  wire [31:0]   prom_addr;
  wire [31:0]   prom_wr_d;
  wire [31:0]   prom_rd_d;
  wire          prom_rd_rdy;
  reg           prom_cs_c;
  reg           prom_cs_d;

  wire [31:0]   slot_size;
  wire [31:0]   time_stamp_d;


//-----------------------------------------------------------------------------
// Decode the 2 PROM Addresses at 0x20 and 0x24 using combo logic
//-----------------------------------------------------------------------------
always @ ( * ) begin : proc_prom_decode
 begin
  if ( prom_addr[15:0] == 16'h0020 ) begin
    prom_cs_c <= prom_wr | prom_rd;
  end else begin
    prom_cs_c <= 0;
  end 
  if ( prom_addr[15:0] == 16'h0024 ) begin
    prom_cs_d <= prom_wr | prom_rd;
  end else begin
    prom_cs_d <= 0;
  end 
 end
end // proc_prom_decode


// ----------------------------------------------------------------------------
// Ro Mux : Mux between multiple byte sources for Ro readback path.
// Note: There is no arbitration - 1st come 1st service requires that only
// one device will send readback data ( polled requests ).
// ----------------------------------------------------------------------------
always @ ( posedge clk ) begin : proc_tx
  tx_busy_sr[0]   <= tx_lb_byte_rdy | tx_spi_byte_rdy | tx_busy;
  tx_busy_sr[3:1] <= tx_busy_sr[2:0];
  tx_byte_rdy     <= tx_lb_byte_rdy | tx_spi_byte_rdy;
  tx_done         <= tx_lb_done     | tx_spi_done ;// Sends LF

  if ( tx_lb_byte_rdy == 1 ) begin
    tx_byte_d <= tx_lb_byte_d[7:0];
  end else begin
    tx_byte_d <= tx_spi_byte_d[7:0];
  end 
end // proc_tx
  // Support pipeling Ro byte path by asserting busy for 4 clocks after a byte
  assign tx_busy_loc = ( tx_busy_sr != 4'b0000 ) ? 1 : 0;


//-----------------------------------------------------------------------------
// Decode Slot Addresses : Take in the Wi path as nibbles and generate the Wo
// paths for both internal and external devices.
//-----------------------------------------------------------------------------
mesa_decode u_mesa_decode
(
  .clk                              ( clk                            ),
  .reset                            ( reset                          ),
  .rx_in_flush                      ( rx_in_flush                    ),
  .rx_in_d                          ( rx_in_d[3:0]                   ),
  .rx_in_rdy                        ( rx_in_rdy                      ),
  .rx_out_d                         ( tx_wo_byte[7:0]                ),
  .rx_out_rdy                       ( tx_wo_rdy                      ),
  .rx_loc_d                         ( rx_loc_d[7:0]                  ),
  .rx_loc_rdy                       ( rx_loc_rdy                     ),
  .rx_loc_start                     ( rx_loc_start                   ),
  .rx_loc_stop                      ( rx_loc_stop                    )
);


//-----------------------------------------------------------------------------
// Convert Subslots 0x0 and 0xE to 32bit local bus for user logic and prom 
//-----------------------------------------------------------------------------
mesa2lb u_mesa2lb
(
  .clk                              ( clk                            ),
  .reset                            ( reset                          ),
  .mode_usb3                        ( 1'b0                           ),
  .rx_byte_d                        ( rx_loc_d[7:0]                  ),
  .rx_byte_rdy                      ( rx_loc_rdy                     ),
  .rx_byte_start                    ( rx_loc_start                   ),
  .rx_byte_stop                     ( rx_loc_stop                    ),
  .tx_byte_d                        ( tx_lb_byte_d[7:0]              ),
  .tx_byte_rdy                      ( tx_lb_byte_rdy                 ),
  .tx_done                          ( tx_lb_done                     ),
  .tx_busy                          ( tx_busy_loc                    ),
  .lb_wr                            ( lb_wr                          ),
  .lb_rd                            ( lb_rd                          ),
  .lb_wr_d                          ( lb_wr_d[31:0]                  ),
  .lb_addr                          ( lb_addr[31:0]                  ),
  .lb_rd_d                          ( lb_rd_d[31:0]                  ),
  .lb_rd_rdy                        ( lb_rd_rdy                      ),
  .prom_wr                          ( prom_wr                        ),
  .prom_rd                          ( prom_rd                        ),
  .prom_wr_d                        ( prom_wr_d[31:0]                ),
  .prom_addr                        ( prom_addr[31:0]                ),
  .prom_rd_d                        ( prom_rd_d[31:0]                ),
  .prom_rd_rdy                      ( prom_rd_rdy                    )
);


//-----------------------------------------------------------------------------
// Decode Subslot Nibble Controls : Used for Pin Reassigns,ReportID,ResetCore
//-----------------------------------------------------------------------------
mesa2ctrl u_mesa2ctrl
(
  .clk                              ( clk                            ),
  .reset                            ( reset                          ),
  .rx_byte_d                        ( rx_loc_d[7:0]                  ),
  .rx_byte_rdy                      ( rx_loc_rdy                     ),
  .rx_byte_start                    ( rx_loc_start                   ),
  .rx_byte_stop                     ( rx_loc_stop                    ),
  .subslot_ctrl                     ( subslot_ctrl[8:0]              )
);


endmodule // mesa_core
