/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant Watchdog timer                   ////
////                                                             ////
////                                                             ////
////  Author: Marko Mlinar                                       ////
////          markom@opencores.org                               ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Marko Mlinar                             ////
////                    markom@opencores.org                     ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

/*
  Watchdog time functionality
  ===========================

  Watchdog timer has only one wishbone address, holding current counter
  value. Countdown timer decreases its contents by 1 each wishbone clock.
  When 0 is reached, interrupt is asserted. Interrupt is deasserted upon
  next read/write to watchdog timer register.
  If contents of the watchdog timer are -1 (e.g. 32'hffff_ffff), counter is
  stopped.
  Timer can start counting at wisbone reset, if `WDT_INITIAL != -1.

  For typical watchdog timer configuration wb_int_o signal should cause
  system reset.
*/


`include "timescale.v"
`include "watchdog_defines.v"

module watchdog(
	wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o,
        wb_int_o);

parameter Tp = 1;

// wishbone signals
input         wb_clk_i;     // master clock input
input         wb_rst_i;     // synchronous active high reset
input  [`WDT_WIDTH - 1:0] wb_dat_i;     // databus input
output [`WDT_WIDTH - 1:0] wb_dat_o;     // databus output
reg    [`WDT_WIDTH - 1:0] wb_dat_o;
input         wb_we_i;      // write enable input
input         wb_stb_i;     // stobe/core select signal
input         wb_cyc_i;     // valid bus cycle input
output        wb_ack_o;     // bus cycle acknowledge output
output        wb_int_o;     // interrupt request signal output
reg           wb_int_o;     // interrupt request signal output

reg           stb;
reg           we;
reg    [`WDT_WIDTH - 1:0] dat_ir;

assign        wb_ack_o = stb;

/* sample input signals */
always @(posedge wb_rst_i or posedge wb_clk_i)
  if (wb_rst_i) begin
    stb <= #Tp 1'b0;
    we <= #Tp 1'b0;
    dat_ir <= #Tp `WDT_WIDTH'h0;
  end else begin
    stb <= #Tp wb_stb_i && wb_cyc_i;
    we <= #Tp wb_we_i;
    dat_ir <= #Tp wb_dat_i;
  end

/* Counter */
always @(posedge wb_rst_i or posedge wb_clk_i)
  if (wb_rst_i) wb_dat_o <= #Tp `WDT_INITIAL;
  else if (stb && we) wb_dat_o <= #Tp dat_ir;
  else if (~&wb_dat_o) wb_dat_o <= #Tp wb_dat_o - `WDT_WIDTH'h1;

/* Interrupt */
always @(posedge wb_rst_i or posedge wb_clk_i)
  if (wb_rst_i) wb_int_o <= #Tp 1'b0;
  else if (stb) wb_int_o <= #Tp 1'b0;
  else if (~|wb_dat_o) wb_int_o <= #Tp 1'b1;

endmodule

