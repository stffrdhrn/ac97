/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE AC 97 Controller                                  ////
////  Output FIFO                                                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/ac97_ctrl/ ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Rudolf Usselmann                         ////
////                    rudi@asics.ws                            ////
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

//  CVS Log
//
//  $Id: ac97_in_fifo.v,v 1.2 2002-03-05 04:44:05 rudi Exp $
//
//  $Date: 2002-03-05 04:44:05 $
//  $Revision: 1.2 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.1  2001/08/03 06:54:50  rudi
//
//
//               - Changed to new directory structure
//
//               Revision 1.1.1.1  2001/05/19 02:29:14  rudi
//               Initial Checkin
//
//
//
//

`include "ac97_defines.v"

module ac97_in_fifo(clk, rst, en, mode, din, we, dout, re, status, full, empty);

input		clk, rst;
input		en;
input	[1:0]	mode;
input	[19:0]	din;
input		we;
output	[31:0]	dout;
input		re;
output	[1:0]	status;
output		full;
output		empty;


////////////////////////////////////////////////////////////////////
//
// Local Wires
//

reg	[31:0]	mem[0:3];
reg	[31:0]	dout;

reg	[3:0]	wp;
reg	[2:0]	rp;

wire	[3:0]	wp_p1;

reg	[1:0]	status;
reg	[15:0]	din_tmp1;
reg	[31:0]	din_tmp;
wire		m16b;
reg		full, empty;

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//

assign m16b = (mode == 2'h0);	// 16 Bit Mode

always @(posedge clk)
	if(!en)		wp <= #1 4'h0;
	else
	if(we)		wp <= #1 wp_p1;

assign wp_p1 = m16b ? (wp + 4'h1) : (wp + 4'h2);

always @(posedge clk)
	if(!en)		rp <= #1 3'h0;
	else
	if(re)		rp <= #1 rp + 3'h1;

always @(posedge clk)
	status <= #1 ((rp - wp[2:1]) - 2'h1);

always @(posedge clk)
	empty <= #1 (wp[3:1] == rp[2:0]) & (m16b ? !wp[0] : 1'b0);

always @(posedge clk)
	full  <= #1 (wp[2:1] == rp[1:0]) & (wp[3] != rp[2]);

// Fifo Output
always @(posedge clk)
	dout <= #1 mem[ rp[1:0] ];

// Fifo Input Half Word Latch
always @(posedge clk)
	if(we & !wp[0])	din_tmp1 <= #1 din[19:4];

always @(mode or din_tmp1 or din)
	case(mode)	// synopsys parallel_case full_case
	   0: din_tmp = {din[19:4], din_tmp1};		// 16 Bit Output
	   1: din_tmp = {13'h0, din[17:0]};		// 18 bit Output
	   2: din_tmp = {11'h0, din[19:0]};		// 20 Bit Output
	endcase

always @(posedge clk)
	if(we & (!m16b | (m16b & wp[0]) ) )	mem[ wp[2:1] ] <= #1 din_tmp;

endmodule
