/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Tests                                                      ////
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
//// Copyright (C) 2000 Rudolf Usselmann                         ////
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
//  $Id: tests.v,v 1.1 2002-02-13 08:22:32 rudi Exp $
//
//  $Date: 2002-02-13 08:22:32 $
//  $Revision: 1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//                        


task show_errors;

begin

$display("\n");
$display("     +--------------------+");
$display("     |  Total ERRORS: %0d   |", error_cnt);
$display("     +--------------------+");

end
endtask


task basic1;

reg	[31:0]	data;
reg	[31:0]	data1;
reg	[31:0]	data2;
integer		size, frames, m;

begin
$display("\n\n");
$display("*****************************************************");
$display("*** Basic AC97 I/O Test & Reg Wr ...              ***");
$display("*****************************************************\n");


	wb_busy = 1;
	m0.wb_wr1(`INTM,4'hf, 32'h0000_0003);
	m0.wb_wr1(`OCC0,4'hf, 32'h7373_7373);
	m0.wb_wr1(`OCC1,4'hf, 32'h0000_7373);
	m0.wb_wr1(`ICC,4'hf, 32'h0073_7373);

	wb_busy = 0;
	oc0_dma_en = 1;
	oc1_dma_en = 1;
	oc2_dma_en = 1;
	oc3_dma_en = 1;
	oc4_dma_en = 1;
	oc5_dma_en = 1;
	ic0_dma_en = 1;
	ic1_dma_en = 1;
	ic2_dma_en = 1;

	for(n=0;n<256;n=n+1)
	   begin
		oc0_mem[n] = $random;
		oc1_mem[n] = $random;
		oc2_mem[n] = $random;
		oc3_mem[n] = $random;
		oc4_mem[n] = $random;
		oc5_mem[n] = $random;
		ic0_mem[n] = $random;
		ic1_mem[n] = $random;
		ic2_mem[n] = $random;
	   end

	u1.init(0);
	frames = 139;

fork
	u1.tx1(	frames,					// Number of frames to process
		0,					// How many frames before codec is ready
		10'b1111_1111_11,			// Output slots valid bits
		10'b1111_1111_11,			// Input slots valid bits
		20'b00_00_00_00_00_00_00_00_00_00,	// Output Slots intervals
		20'b00_00_00_00_00_00_00_00_00_00	// Input Slots intervals
		);

	begin	// Do a register Write
		repeat(2)	@(posedge sync);

		for(n=0;n<75;n=n+1)
		   begin
			@(negedge sync);
			repeat(230)	@(posedge bit_clk);

			repeat(n)	@(posedge bit_clk);

			while(wb_busy)	@(posedge clk);
			wb_busy = 1;
			m0.wb_wr1(`CRAC,4'hf, {9'h0, n[6:0], 16'h1234 + n[7:0]} );
			wb_busy = 0;

			while(!int)	@(posedge clk);
		   end
	end
join

repeat(300)	@(posedge bit_clk);

	for(n=0;n<75;n=n+1)
	   begin
			data2 = {9'h0, n[6:0], 16'h1234 + n[7:0]};
			tmp = u1.rs2_mem[n];
			data1[15:0] = tmp[19:4];

			tmp = u1.rs1_mem[n];
			data1[31:16] = {9'h0, tmp[18:12]};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Register Write Data %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end

	   end

	size = frames - 4;

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs3_mem[n];
		data = oc0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs4_mem[n];
		data = oc1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs6_mem[n];
		data = oc2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs7_mem[n];
		data = oc3_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH3 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs8_mem[n];
		data = oc4_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH4 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs9_mem[n];
		data = oc5_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH5 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is3_mem[n];
		data = ic0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is4_mem[n];
		data = ic1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is6_mem[n];
		data = ic2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

repeat(10)	@(posedge clk);

show_errors;
$display("*****************************************************");
$display("*** Test DONE ...                                 ***");
$display("*****************************************************\n\n");

end
endtask



task basic2;

reg	[31:0]	data;
reg	[31:0]	data1;
reg	[31:0]	data2;
integer		size, frames, m;

begin
$display("\n\n");
$display("*****************************************************");
$display("*** Basic AC97 I/O Test & Reg Rd ...              ***");
$display("*****************************************************\n");

	wb_busy = 1;
	m0.wb_wr1(`INTM,4'hf, 32'h0000_0003);
	m0.wb_wr1(`OCC0,4'hf, 32'h7373_7373);
	m0.wb_wr1(`OCC1,4'hf, 32'h0000_7373);
	m0.wb_wr1(`ICC,4'hf, 32'h0073_7373);

	wb_busy = 0;
	oc0_dma_en = 1;
	oc1_dma_en = 1;
	oc2_dma_en = 1;
	oc3_dma_en = 1;
	oc4_dma_en = 1;
	oc5_dma_en = 1;
	ic0_dma_en = 1;
	ic1_dma_en = 1;
	ic2_dma_en = 1;

	for(n=0;n<256;n=n+1)
	   begin
		oc0_mem[n] = $random;
		oc1_mem[n] = $random;
		oc2_mem[n] = $random;
		oc3_mem[n] = $random;
		oc4_mem[n] = $random;
		oc5_mem[n] = $random;
		ic0_mem[n] = $random;
		ic1_mem[n] = $random;
		ic2_mem[n] = $random;
	   end

	u1.init(0);
	frames = 139;

fork
	u1.tx1(	frames,					// Number of frames to process
		0,					// How many frames before codec is ready
		10'b1111_1111_11,			// Output slots valid bits
		10'b1111_1111_11,			// Input slots valid bits
		20'b00_00_00_00_00_00_00_00_00_00,	// Output Slots intervals
		20'b00_00_00_00_00_00_00_00_00_00	// Input Slots intervals
		);

	begin	// Do a register Write
		repeat(2)	@(posedge sync);

		for(n=0;n<75;n=n+1)
		   begin
			@(negedge sync);
			repeat(230)	@(posedge bit_clk);

			repeat(n)	@(posedge bit_clk);

			while(wb_busy)	@(posedge clk);
			wb_busy = 1;
			m0.wb_wr1(`CRAC,4'hf, {1'b1, 8'h0, n[6:0], 16'h1234 + n[7:0]} );
			wb_busy = 0;

			while(!int)	@(posedge clk);

			while(wb_busy)	@(posedge clk);
			wb_busy = 1;
			m0.wb_rd1(`CRAC,4'hf, reg_mem[n] );
			wb_busy = 0;

		   end
	end
join

repeat(300)	@(posedge bit_clk);

	for(n=0;n<75;n=n+1)
	   begin

			tmp = u1.is2_mem[n];
			data2 = {16'h0, tmp[19:4]};
			tmp = reg_mem[n];
			data1 = {16'h0, tmp[15:0]};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Register Read Data %0d Mismatch Expected: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end

	   end

	size = frames - 4;

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs3_mem[n];
		data = oc0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs4_mem[n];
		data = oc1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs6_mem[n];
		data = oc2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs7_mem[n];
		data = oc3_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH3 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs8_mem[n];
		data = oc4_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH4 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs9_mem[n];
		data = oc5_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH5 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is3_mem[n];
		data = ic0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is4_mem[n];
		data = ic1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is6_mem[n];
		data = ic2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

show_errors;
$display("*****************************************************");
$display("*** Test DONE ...                                 ***");
$display("*****************************************************\n\n");

end
endtask



task vsr1;

reg	[31:0]	data;
reg	[31:0]	data1;
reg	[31:0]	data2;
integer		size, frames, m;

begin
$display("\n\n");
$display("*****************************************************");
$display("*** VSR AC97 I/O Test ...                       ***");
$display("*****************************************************\n");

	wb_busy = 1;
	m0.wb_wr1(`OCC0,4'hf, 32'h7373_7373);
	m0.wb_wr1(`OCC1,4'hf, 32'h0000_7373);
	m0.wb_wr1(`ICC,4'hf, 32'h0073_7373);

	wb_busy = 0;
	oc0_dma_en = 1;
	oc1_dma_en = 1;
	oc2_dma_en = 1;
	oc3_dma_en = 1;
	oc4_dma_en = 1;
	oc5_dma_en = 1;
	ic0_dma_en = 1;
	ic1_dma_en = 1;
	ic2_dma_en = 1;

	for(n=0;n<256;n=n+1)
	   begin
		oc0_mem[n] = $random;
		oc1_mem[n] = $random;
		oc2_mem[n] = $random;
		oc3_mem[n] = $random;
		oc4_mem[n] = $random;
		oc5_mem[n] = $random;
		ic0_mem[n] = $random;
		ic1_mem[n] = $random;
		ic2_mem[n] = $random;
	   end

	u1.init(0);

	frames = 132;

	u1.tx1(	frames,					// Number of frames to process
		0,					// How many frames before codec is ready
		10'b1101_1110_00,			// Output slots valid bits
		10'b1101_0000_00,			// Input slots valid bits
		20'b01_01_00_01_01_01_01_00_00_00,	// Output Slots intervals
		20'b01_01_00_01_00_00_00_00_00_00	// Input Slots intervals
		);

	size = (frames - 4)/2;

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs3_mem[n];
		data = oc0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs4_mem[n];
		data = oc1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs6_mem[n];
		data = oc2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs7_mem[n];
		data = oc3_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH3 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs8_mem[n];
		data = oc4_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH4 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.rs9_mem[n];
		data = oc5_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: Out. CH5 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is3_mem[n];
		data = ic0_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH0 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is4_mem[n];
		data = ic1_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH1 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

	for(n=0;n<size;n=n+1)
	   begin
		data1 = u1.is6_mem[n];
		data = ic2_mem[n[8:1]];

		if(~n[0])	data2 = {12'h0, data[15:0], 4'h0};
		else		data2 = {12'h0, data[31:16], 4'h0};

		if(	(data1 !== data2) |
			(^data1 === 1'hx) |
			(^data2 === 1'hx)
			)
		   begin
			$display("ERROR: In. CH2 Sample %0d Mismatch Sent: %h Got: %h",
			n, data2, data1);
			error_cnt = error_cnt + 1;
		   end
	   end

repeat(10)	@(posedge clk);

show_errors;
$display("*****************************************************");
$display("*** Test DONE ...                                 ***");
$display("*****************************************************\n\n");

end
endtask


