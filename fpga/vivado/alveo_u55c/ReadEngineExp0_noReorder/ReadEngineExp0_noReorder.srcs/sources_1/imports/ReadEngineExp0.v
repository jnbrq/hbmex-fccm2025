module mem_4096x64 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	R1_addr,
	R1_en,
	R1_clk,
	R1_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data,
	W0_mask
);
	input [11:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [63:0] R0_data;
	input [11:0] R1_addr;
	input R1_en;
	input R1_clk;
	output wire [63:0] R1_data;
	input [11:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [63:0] W0_data;
	input [7:0] W0_mask;
	reg [63:0] Memory [0:4095];
	reg _R0_en_d0;
	reg [11:0] _R0_addr_d0;
	always @(posedge R0_clk) begin
		_R0_en_d0 <= R0_en;
		_R0_addr_d0 <= R0_addr;
	end
	reg _R1_en_d0;
	reg [11:0] _R1_addr_d0;
	always @(posedge R1_clk) begin
		_R1_en_d0 <= R1_en;
		_R1_addr_d0 <= R1_addr;
	end
	always @(posedge W0_clk) begin
		if (W0_en & W0_mask[0])
			Memory[W0_addr][32'h00000000+:8] <= W0_data[7:0];
		if (W0_en & W0_mask[1])
			Memory[W0_addr][32'h00000008+:8] <= W0_data[15:8];
		if (W0_en & W0_mask[2])
			Memory[W0_addr][32'h00000010+:8] <= W0_data[23:16];
		if (W0_en & W0_mask[3])
			Memory[W0_addr][32'h00000018+:8] <= W0_data[31:24];
		if (W0_en & W0_mask[4])
			Memory[W0_addr][32'h00000020+:8] <= W0_data[39:32];
		if (W0_en & W0_mask[5])
			Memory[W0_addr][32'h00000028+:8] <= W0_data[47:40];
		if (W0_en & W0_mask[6])
			Memory[W0_addr][32'h00000030+:8] <= W0_data[55:48];
		if (W0_en & W0_mask[7])
			Memory[W0_addr][32'h00000038+:8] <= W0_data[63:56];
	end
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (_R0_en_d0 ? Memory[_R0_addr_d0] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
	assign R1_data = (_R1_en_d0 ? Memory[_R1_addr_d0] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module ChiselSimpleDualPortMem (
	clock,
	raw1_addr,
	raw1_dIn,
	raw1_dOut,
	raw1_wstrb,
	raw2_addr,
	raw2_dOut
);
	input clock;
	input [11:0] raw1_addr;
	input [63:0] raw1_dIn;
	output wire [63:0] raw1_dOut;
	input [7:0] raw1_wstrb;
	input [11:0] raw2_addr;
	output wire [63:0] raw2_dOut;
	wire [63:0] _mem_ext_R0_data;
	wire [63:0] _mem_ext_R1_data;
	reg [63:0] raw1_dOut_r;
	reg [63:0] raw2_dOut_r;
	always @(posedge clock) begin
		raw1_dOut_r <= _mem_ext_R1_data;
		raw2_dOut_r <= _mem_ext_R0_data;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:3];
	end
	mem_4096x64 mem_ext(
		.R0_addr(raw2_addr),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_mem_ext_R0_data),
		.R1_addr(raw1_addr),
		.R1_en(1'h1),
		.R1_clk(clock),
		.R1_data(_mem_ext_R1_data),
		.W0_addr(raw1_addr),
		.W0_en(1'h1),
		.W0_clk(clock),
		.W0_data(raw1_dIn),
		.W0_mask(raw1_wstrb)
	);
	assign raw1_dOut = raw1_dOut_r;
	assign raw2_dOut = raw2_dOut_r;
endmodule
module ram_2x64 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [63:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [63:0] W0_data;
	reg [63:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_UInt64 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x64 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Queue2_UInt0 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_deq_ready,
	io_deq_valid
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_deq_ready;
	output wire io_deq_valid;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_enq;
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			do_enq = ~full & io_enq_valid;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Counter (
	clock,
	reset,
	io_incEn,
	io_decEn,
	io_full
);
	input clock;
	input reset;
	input io_incEn;
	input io_decEn;
	output wire io_full;
	reg [2:0] rCounter;
	always @(posedge clock)
		if (reset)
			rCounter <= 3'h0;
		else if (~(io_incEn & io_decEn)) begin
			if (io_incEn)
				rCounter <= rCounter + 3'h1;
			else if (io_decEn)
				rCounter <= rCounter - 3'h1;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_full = rCounter == 3'h4;
endmodule
module Counter_1 (
	clock,
	reset,
	io_incEn,
	io_decEn,
	io_empty,
	io_full
);
	input clock;
	input reset;
	input io_incEn;
	input io_decEn;
	output wire io_empty;
	output wire io_full;
	reg [1:0] rCounter;
	always @(posedge clock)
		if (reset)
			rCounter <= 2'h0;
		else if (~(io_incEn & io_decEn)) begin
			if (io_incEn)
				rCounter <= rCounter + 2'h1;
			else if (io_decEn)
				rCounter <= rCounter - 2'h1;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_empty = rCounter == 2'h0;
	assign io_full = rCounter == 2'h2;
endmodule
module BasicReadWriteArbiter (
	clock,
	reset,
	rdReq,
	wrReq,
	chooseRd
);
	input clock;
	input reset;
	input rdReq;
	input wrReq;
	output wire chooseRd;
	reg state;
	reg [2:0] count;
	always @(posedge clock)
		if (reset) begin
			state <= 1'h0;
			count <= 3'h0;
		end
		else if (state) begin : sv2v_autoblock_1
			reg _GEN;
			_GEN = ~wrReq | &count;
			state <= ~_GEN & state;
			if (_GEN)
				count <= 3'h0;
			else
				count <= count + 3'h1;
		end
		else begin : sv2v_autoblock_2
			reg _GEN_0;
			_GEN_0 = ~rdReq | &count;
			state <= _GEN_0 | state;
			if (_GEN_0)
				count <= 3'h0;
			else
				count <= count + 3'h1;
		end
	initial begin : sv2v_autoblock_3
		reg [31:0] _RANDOM [0:0];
	end
	assign chooseRd = ~state;
endmodule
module ram_4x64 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [1:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [63:0] R0_data;
	input [1:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [63:0] W0_data;
	reg [63:0] Memory [0:3];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue4_UInt64 (
	clock,
	reset,
	io_enq_valid,
	io_enq_bits,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits
);
	input clock;
	input reset;
	input io_enq_valid;
	input [63:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits;
	wire io_enq_ready;
	wire [63:0] _ram_ext_R0_data;
	reg [1:0] enq_ptr_value;
	reg [1:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire io_deq_valid_0 = io_enq_valid | ~empty;
	wire do_deq = (~empty & io_deq_ready) & io_deq_valid_0;
	wire do_enq = (~(empty & io_deq_ready) & io_enq_ready) & io_enq_valid;
	assign io_enq_ready = io_deq_ready | ~(ptr_match & maybe_full);
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 2'h0;
			deq_ptr_value <= 2'h0;
			maybe_full <= 1'h0;
		end
		else begin
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 2'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 2'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	ram_4x64 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_deq_valid = io_deq_valid_0;
	assign io_deq_bits = (empty ? io_enq_bits : _ram_ext_R0_data);
endmodule
module ReadWriteToRawBridge (
	clock,
	reset,
	read_req_ready,
	read_req_valid,
	read_req_bits,
	read_resp_ready,
	read_resp_valid,
	read_resp_bits,
	write_req_ready,
	write_req_valid,
	write_req_bits_addr,
	write_req_bits_data,
	write_req_bits_strb,
	write_resp_ready,
	write_resp_valid,
	raw_addr,
	raw_dIn,
	raw_dOut,
	raw_wstrb
);
	input clock;
	input reset;
	output wire read_req_ready;
	input read_req_valid;
	input [11:0] read_req_bits;
	input read_resp_ready;
	output wire read_resp_valid;
	output wire [63:0] read_resp_bits;
	output wire write_req_ready;
	input write_req_valid;
	input [11:0] write_req_bits_addr;
	input [63:0] write_req_bits_data;
	input [7:0] write_req_bits_strb;
	input write_resp_ready;
	output wire write_resp_valid;
	output wire [11:0] raw_addr;
	output wire [63:0] raw_dIn;
	input [63:0] raw_dOut;
	output wire [7:0] raw_wstrb;
	wire _read_dataQueue_io_deq_valid;
	wire [63:0] _read_dataQueue_io_deq_bits;
	wire _arbiter_arbiter_chooseRd;
	wire _ctrWriteResp_io_empty;
	wire _ctrWrite_io_full;
	wire _ctrRead_io_full;
	wire _wrResp_sinkBuffer_io_enq_ready;
	wire _rdResp_sinkBuffer_io_enq_ready;
	wire read_req_ready_0 = _arbiter_arbiter_chooseRd & ~_ctrRead_io_full;
	wire write_req_ready_0 = ~_arbiter_arbiter_chooseRd & ~_ctrWrite_io_full;
	wire _read_T_1 = read_req_ready_0 & read_req_valid;
	wire _write_T_1 = write_req_ready_0 & write_req_valid;
	reg read_r;
	reg read_r_1;
	wire rdResp_valid = _rdResp_sinkBuffer_io_enq_ready & _read_dataQueue_io_deq_valid;
	reg write_r;
	wire wrResp_valid = _wrResp_sinkBuffer_io_enq_ready & ~_ctrWriteResp_io_empty;
	always @(posedge clock) begin
		read_r <= _read_T_1;
		read_r_1 <= read_r;
		write_r <= _write_T_1;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_UInt64 rdResp_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rdResp_sinkBuffer_io_enq_ready),
		.io_enq_valid(rdResp_valid),
		.io_enq_bits(_read_dataQueue_io_deq_bits),
		.io_deq_ready(read_resp_ready),
		.io_deq_valid(read_resp_valid),
		.io_deq_bits(read_resp_bits)
	);
	Queue2_UInt0 wrResp_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_wrResp_sinkBuffer_io_enq_ready),
		.io_enq_valid(wrResp_valid),
		.io_deq_ready(write_resp_ready),
		.io_deq_valid(write_resp_valid)
	);
	Counter ctrRead(
		.clock(clock),
		.reset(reset),
		.io_incEn(_read_T_1),
		.io_decEn(rdResp_valid),
		.io_full(_ctrRead_io_full)
	);
	Counter_1 ctrWrite(
		.clock(clock),
		.reset(reset),
		.io_incEn(_write_T_1),
		.io_decEn(wrResp_valid),
		.io_empty(),
		.io_full(_ctrWrite_io_full)
	);
	Counter_1 ctrWriteResp(
		.clock(clock),
		.reset(reset),
		.io_incEn(write_r),
		.io_decEn(wrResp_valid),
		.io_empty(_ctrWriteResp_io_empty),
		.io_full()
	);
	BasicReadWriteArbiter arbiter_arbiter(
		.clock(clock),
		.reset(reset),
		.rdReq(read_req_valid),
		.wrReq(write_req_valid),
		.chooseRd(_arbiter_arbiter_chooseRd)
	);
	Queue4_UInt64 read_dataQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_valid(read_r_1),
		.io_enq_bits(raw_dOut),
		.io_deq_ready(rdResp_valid),
		.io_deq_valid(_read_dataQueue_io_deq_valid),
		.io_deq_bits(_read_dataQueue_io_deq_bits)
	);
	assign read_req_ready = read_req_ready_0;
	assign write_req_ready = write_req_ready_0;
	assign raw_addr = (_write_T_1 ? write_req_bits_addr : read_req_bits);
	assign raw_dIn = write_req_bits_data;
	assign raw_wstrb = (_write_T_1 ? write_req_bits_strb : 8'h00);
endmodule
module ReadWriteToRawBridge_1 (
	clock,
	reset,
	read_req_ready,
	read_req_valid,
	read_req_bits,
	read_resp_ready,
	read_resp_valid,
	read_resp_bits,
	raw_addr,
	raw_dOut
);
	input clock;
	input reset;
	output wire read_req_ready;
	input read_req_valid;
	input [11:0] read_req_bits;
	input read_resp_ready;
	output wire read_resp_valid;
	output wire [63:0] read_resp_bits;
	output wire [11:0] raw_addr;
	input [63:0] raw_dOut;
	wire _read_dataQueue_io_deq_valid;
	wire [63:0] _read_dataQueue_io_deq_bits;
	wire _ctrRead_io_full;
	wire _rdResp_sinkBuffer_io_enq_ready;
	wire _read_T_1 = ~_ctrRead_io_full & read_req_valid;
	reg read_r;
	reg read_r_1;
	wire rdResp_valid = _rdResp_sinkBuffer_io_enq_ready & _read_dataQueue_io_deq_valid;
	always @(posedge clock) begin
		read_r <= _read_T_1;
		read_r_1 <= read_r;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_UInt64 rdResp_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rdResp_sinkBuffer_io_enq_ready),
		.io_enq_valid(rdResp_valid),
		.io_enq_bits(_read_dataQueue_io_deq_bits),
		.io_deq_ready(read_resp_ready),
		.io_deq_valid(read_resp_valid),
		.io_deq_bits(read_resp_bits)
	);
	Counter ctrRead(
		.clock(clock),
		.reset(reset),
		.io_incEn(_read_T_1),
		.io_decEn(rdResp_valid),
		.io_full(_ctrRead_io_full)
	);
	Queue4_UInt64 read_dataQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_valid(read_r_1),
		.io_enq_bits(raw_dOut),
		.io_deq_ready(rdResp_valid),
		.io_deq_valid(_read_dataQueue_io_deq_valid),
		.io_deq_bits(_read_dataQueue_io_deq_bits)
	);
	assign read_req_ready = ~_ctrRead_io_full;
	assign raw_addr = read_req_bits;
endmodule
module ChiselTrueDualPortRAM (
	clock,
	reset,
	read1_req_ready,
	read1_req_valid,
	read1_req_bits,
	read1_resp_ready,
	read1_resp_valid,
	read1_resp_bits,
	read2_req_ready,
	read2_req_valid,
	read2_req_bits,
	read2_resp_ready,
	read2_resp_valid,
	read2_resp_bits,
	write1_req_ready,
	write1_req_valid,
	write1_req_bits_addr,
	write1_req_bits_data,
	write1_req_bits_strb,
	write1_resp_ready,
	write1_resp_valid
);
	input clock;
	input reset;
	output wire read1_req_ready;
	input read1_req_valid;
	input [11:0] read1_req_bits;
	input read1_resp_ready;
	output wire read1_resp_valid;
	output wire [63:0] read1_resp_bits;
	output wire read2_req_ready;
	input read2_req_valid;
	input [11:0] read2_req_bits;
	input read2_resp_ready;
	output wire read2_resp_valid;
	output wire [63:0] read2_resp_bits;
	output wire write1_req_ready;
	input write1_req_valid;
	input [11:0] write1_req_bits_addr;
	input [63:0] write1_req_bits_data;
	input [7:0] write1_req_bits_strb;
	input write1_resp_ready;
	output wire write1_resp_valid;
	wire [11:0] _bridge2_raw_addr;
	wire [11:0] _bridge1_raw_addr;
	wire [63:0] _bridge1_raw_dIn;
	wire [7:0] _bridge1_raw_wstrb;
	wire [63:0] _rawMem_raw1_dOut;
	wire [63:0] _rawMem_raw2_dOut;
	ChiselSimpleDualPortMem rawMem(
		.clock(clock),
		.raw1_addr(_bridge1_raw_addr),
		.raw1_dIn(_bridge1_raw_dIn),
		.raw1_dOut(_rawMem_raw1_dOut),
		.raw1_wstrb(_bridge1_raw_wstrb),
		.raw2_addr(_bridge2_raw_addr),
		.raw2_dOut(_rawMem_raw2_dOut)
	);
	ReadWriteToRawBridge bridge1(
		.clock(clock),
		.reset(reset),
		.read_req_ready(read1_req_ready),
		.read_req_valid(read1_req_valid),
		.read_req_bits(read1_req_bits),
		.read_resp_ready(read1_resp_ready),
		.read_resp_valid(read1_resp_valid),
		.read_resp_bits(read1_resp_bits),
		.write_req_ready(write1_req_ready),
		.write_req_valid(write1_req_valid),
		.write_req_bits_addr(write1_req_bits_addr),
		.write_req_bits_data(write1_req_bits_data),
		.write_req_bits_strb(write1_req_bits_strb),
		.write_resp_ready(write1_resp_ready),
		.write_resp_valid(write1_resp_valid),
		.raw_addr(_bridge1_raw_addr),
		.raw_dIn(_bridge1_raw_dIn),
		.raw_dOut(_rawMem_raw1_dOut),
		.raw_wstrb(_bridge1_raw_wstrb)
	);
	ReadWriteToRawBridge_1 bridge2(
		.clock(clock),
		.reset(reset),
		.read_req_ready(read2_req_ready),
		.read_req_valid(read2_req_valid),
		.read_req_bits(read2_req_bits),
		.read_resp_ready(read2_resp_ready),
		.read_resp_valid(read2_resp_valid),
		.read_resp_bits(read2_resp_bits),
		.raw_addr(_bridge2_raw_addr),
		.raw_dOut(_rawMem_raw2_dOut)
	);
endmodule
module ram_2x28 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [27:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [27:0] W0_data;
	reg [27:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 28'bxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_AddrLenSizeBurstBundle (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [14:0] io_enq_bits_addr;
	input [7:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [14:0] io_deq_bits_addr;
	output wire [7:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [27:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x28 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[14:0];
	assign io_deq_bits_len = _ram_ext_R0_data[22:15];
	assign io_deq_bits_size = _ram_ext_R0_data[25:23];
	assign io_deq_bits_burst = _ram_ext_R0_data[27:26];
endmodule
module ram_2x18 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [17:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [17:0] W0_data;
	reg [17:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 18'bxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_AddrSizeLastBundle (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_size,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_size
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [14:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_size;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [14:0] io_deq_bits_addr;
	output wire [2:0] io_deq_bits_size;
	wire [17:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x18 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_size, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[14:0];
	assign io_deq_bits_size = _ram_ext_R0_data[17:15];
endmodule
module AddressGenerator (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits_addr,
	source_bits_len,
	source_bits_size,
	source_bits_burst,
	sink_ready,
	sink_valid,
	sink_bits_addr,
	sink_bits_size
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [14:0] source_bits_addr;
	input [7:0] source_bits_len;
	input [2:0] source_bits_size;
	input [1:0] source_bits_burst;
	input sink_ready;
	output wire sink_valid;
	output wire [14:0] sink_bits_addr;
	output wire [2:0] sink_bits_size;
	wire _sink__sinkBuffer_io_enq_ready;
	wire _source__sourceBuffer_io_deq_valid;
	wire [14:0] _source__sourceBuffer_io_deq_bits_addr;
	wire [7:0] _source__sourceBuffer_io_deq_bits_len;
	wire [2:0] _source__sourceBuffer_io_deq_bits_size;
	wire [1:0] _source__sourceBuffer_io_deq_bits_burst;
	reg [14:0] addr;
	reg [7:0] ctr;
	reg generating;
	wire sink__valid = _source__sourceBuffer_io_deq_valid & _sink__sinkBuffer_io_enq_ready;
	wire last = ctr == 8'h00;
	wire [21:0] _result_addr_T = {7'h00, addr} << _source__sourceBuffer_io_deq_bits_size;
	wire last_1 = _source__sourceBuffer_io_deq_bits_len == 8'h00;
	always @(posedge clock) begin
		if (sink__valid) begin
			if (generating) begin
				if (~last) begin
					if (_source__sourceBuffer_io_deq_bits_burst == 2'h1)
						addr <= addr + 15'h0001;
					else if (_source__sourceBuffer_io_deq_bits_burst == 2'h2)
						addr <= (addr & {7'h7f, ~_source__sourceBuffer_io_deq_bits_len}) | ((addr + 15'h0001) & {7'h00, _source__sourceBuffer_io_deq_bits_len});
					ctr <= ctr - 8'h01;
				end
			end
			else if (~last_1) begin
				addr <= (_source__sourceBuffer_io_deq_bits_addr >> _source__sourceBuffer_io_deq_bits_size) + 15'h0001;
				ctr <= _source__sourceBuffer_io_deq_bits_len - 8'h01;
			end
		end
		if (reset)
			generating <= 1'h0;
		else if (sink__valid) begin
			if (generating)
				generating <= ~last & generating;
			else
				generating <= ~last_1 | generating;
		end
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_AddrLenSizeBurstBundle source__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(source_ready),
		.io_enq_valid(source_valid),
		.io_enq_bits_addr(source_bits_addr),
		.io_enq_bits_len(source_bits_len),
		.io_enq_bits_size(source_bits_size),
		.io_enq_bits_burst(source_bits_burst),
		.io_deq_ready(sink__valid & (generating ? last : last_1)),
		.io_deq_valid(_source__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_source__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_len(_source__sourceBuffer_io_deq_bits_len),
		.io_deq_bits_size(_source__sourceBuffer_io_deq_bits_size),
		.io_deq_bits_burst(_source__sourceBuffer_io_deq_bits_burst)
	);
	Queue2_AddrSizeLastBundle sink__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sink__sinkBuffer_io_enq_ready),
		.io_enq_valid(sink__valid),
		.io_enq_bits_addr((~generating | (_source__sourceBuffer_io_deq_bits_burst == 2'h0) ? _source__sourceBuffer_io_deq_bits_addr : _result_addr_T[14:0])),
		.io_enq_bits_size(_source__sourceBuffer_io_deq_bits_size),
		.io_enq_bits_last((generating ? last : last_1)),
		.io_deq_ready(sink_ready),
		.io_deq_valid(sink_valid),
		.io_deq_bits_addr(sink_bits_addr),
		.io_deq_bits_size(sink_bits_size)
	);
endmodule
module ram_4x1 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [1:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire R0_data;
	input [1:0] W0_addr;
	input W0_en;
	input W0_clk;
	input W0_data;
	reg Memory [0:3];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 1'bx);
endmodule
module Queue4_IdLastBundle (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire io_deq_bits_last;
	reg [1:0] enq_ptr_value;
	reg [1:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 2'h0;
			deq_ptr_value <= 2'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 2'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 2'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_4x1 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits_last),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits_last)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module ram_2x1 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input W0_data;
	reg Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 1'bx);
endmodule
module Queue2_IdLastBundle (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire io_deq_bits_last;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x1 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits_last),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits_last)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module StrobeGenerator (
	source_ready,
	source_valid,
	source_bits_addr,
	source_bits_size,
	sink_ready,
	sink_valid,
	sink_bits_addr,
	sink_bits_strb
);
	output wire source_ready;
	input source_valid;
	input [14:0] source_bits_addr;
	input [2:0] source_bits_size;
	input sink_ready;
	output wire sink_valid;
	output wire [14:0] sink_bits_addr;
	output wire [7:0] sink_bits_strb;
	wire [9:0] _upperByteIndex_T_4 = ({7'h00, (source_bits_addr[2:0] >> source_bits_size) + 3'h1} << source_bits_size) - 10'h001;
	assign source_ready = sink_ready;
	assign sink_valid = source_valid;
	assign sink_bits_addr = source_bits_addr;
	assign sink_bits_strb = {_upperByteIndex_T_4 > 10'h006, (_upperByteIndex_T_4 > 10'h005) & (source_bits_addr[2:0] != 3'h7), (_upperByteIndex_T_4 > 10'h004) & (source_bits_addr[2:1] != 2'h3), |_upperByteIndex_T_4[9:2] & (source_bits_addr[2:0] < 3'h5), (_upperByteIndex_T_4 > 10'h002) & ~source_bits_addr[2], |_upperByteIndex_T_4[9:1] & (source_bits_addr[2:0] < 3'h3), |_upperByteIndex_T_4 & (source_bits_addr[2:0] < 3'h2), source_bits_addr[2:0] == 3'h0};
endmodule
module AddressStrobeGenerator (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits_addr,
	source_bits_len,
	source_bits_size,
	source_bits_burst,
	sink_ready,
	sink_valid,
	sink_bits_addr,
	sink_bits_strb
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [14:0] source_bits_addr;
	input [7:0] source_bits_len;
	input [2:0] source_bits_size;
	input [1:0] source_bits_burst;
	input sink_ready;
	output wire sink_valid;
	output wire [14:0] sink_bits_addr;
	output wire [7:0] sink_bits_strb;
	wire _strobeGenerator_source_ready;
	wire _addressGenerator_sink_valid;
	wire [14:0] _addressGenerator_sink_bits_addr;
	wire [2:0] _addressGenerator_sink_bits_size;
	AddressGenerator addressGenerator(
		.clock(clock),
		.reset(reset),
		.source_ready(source_ready),
		.source_valid(source_valid),
		.source_bits_addr(source_bits_addr),
		.source_bits_len(source_bits_len),
		.source_bits_size(source_bits_size),
		.source_bits_burst(source_bits_burst),
		.sink_ready(_strobeGenerator_source_ready),
		.sink_valid(_addressGenerator_sink_valid),
		.sink_bits_addr(_addressGenerator_sink_bits_addr),
		.sink_bits_size(_addressGenerator_sink_bits_size)
	);
	StrobeGenerator strobeGenerator(
		.source_ready(_strobeGenerator_source_ready),
		.source_valid(_addressGenerator_sink_valid),
		.source_bits_addr(_addressGenerator_sink_bits_addr),
		.source_bits_size(_addressGenerator_sink_bits_size),
		.sink_ready(sink_ready),
		.sink_valid(sink_valid),
		.sink_bits_addr(sink_bits_addr),
		.sink_bits_strb(sink_bits_strb)
	);
endmodule
module ram_2x2 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [1:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [1:0] W0_data;
	reg [1:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 2'bxx);
endmodule
module Queue2_WriteResponseChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_resp;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x2 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits_resp),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(2'h0)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Axi4FullToReadWriteBridge (
	clock,
	reset,
	s_axi_ar_ready,
	s_axi_ar_valid,
	s_axi_ar_bits_addr,
	s_axi_ar_bits_len,
	s_axi_ar_bits_size,
	s_axi_ar_bits_burst,
	s_axi_r_ready,
	s_axi_r_valid,
	s_axi_r_bits_data,
	s_axi_r_bits_last,
	s_axi_aw_ready,
	s_axi_aw_valid,
	s_axi_aw_bits_addr,
	s_axi_aw_bits_len,
	s_axi_aw_bits_size,
	s_axi_aw_bits_burst,
	s_axi_w_ready,
	s_axi_w_valid,
	s_axi_w_bits_data,
	s_axi_w_bits_strb,
	s_axi_b_ready,
	s_axi_b_valid,
	s_axi_b_bits_resp,
	read_req_ready,
	read_req_valid,
	read_req_bits,
	read_resp_ready,
	read_resp_valid,
	read_resp_bits,
	write_req_ready,
	write_req_valid,
	write_req_bits_addr,
	write_req_bits_data,
	write_req_bits_strb,
	write_resp_ready,
	write_resp_valid
);
	input clock;
	input reset;
	output wire s_axi_ar_ready;
	input s_axi_ar_valid;
	input [14:0] s_axi_ar_bits_addr;
	input [7:0] s_axi_ar_bits_len;
	input [2:0] s_axi_ar_bits_size;
	input [1:0] s_axi_ar_bits_burst;
	input s_axi_r_ready;
	output wire s_axi_r_valid;
	output wire [63:0] s_axi_r_bits_data;
	output wire s_axi_r_bits_last;
	output wire s_axi_aw_ready;
	input s_axi_aw_valid;
	input [14:0] s_axi_aw_bits_addr;
	input [7:0] s_axi_aw_bits_len;
	input [2:0] s_axi_aw_bits_size;
	input [1:0] s_axi_aw_bits_burst;
	output wire s_axi_w_ready;
	input s_axi_w_valid;
	input [63:0] s_axi_w_bits_data;
	input [7:0] s_axi_w_bits_strb;
	input s_axi_b_ready;
	output wire s_axi_b_valid;
	output wire [1:0] s_axi_b_bits_resp;
	input read_req_ready;
	output wire read_req_valid;
	output wire [11:0] read_req_bits;
	output wire read_resp_ready;
	input read_resp_valid;
	input [63:0] read_resp_bits;
	input write_req_ready;
	output wire write_req_valid;
	output wire [11:0] write_req_bits_addr;
	output wire [63:0] write_req_bits_data;
	output wire [7:0] write_req_bits_strb;
	output wire write_resp_ready;
	input write_resp_valid;
	wire write_idLastJoined_ready;
	wire _write_fork1_eagerFork_result_valid_T;
	wire [15:0] write_fork1_replicate1_idx;
	wire [8:0] _write_fork1_replicate1_len_T;
	wire _read_fork1_eagerFork_result_valid_T;
	wire [15:0] read_fork1_replicate1_idx;
	wire [8:0] _read_fork1_replicate1_len_T;
	wire _write_arrival1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _write_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid;
	wire _write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last;
	wire _write_fork1_replicate1_sinkBuffer_io_enq_ready;
	wire _write_fork1_replicate1_sinkBuffer_io_deq_valid;
	wire _write_fork1_replicate1_sinkBuffer_io_deq_bits_last;
	wire _write_addressStrobeGenerator_source_ready;
	wire _write_addressStrobeGenerator_sink_valid;
	wire [14:0] _write_addressStrobeGenerator_sink_bits_addr;
	wire [7:0] _write_addressStrobeGenerator_sink_bits_strb;
	wire _read_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid;
	wire _read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last;
	wire _read_fork1_replicate1_sinkBuffer_io_enq_ready;
	wire _read_fork1_replicate1_sinkBuffer_io_deq_valid;
	wire _read_addressGenerator_source_ready;
	wire [14:0] _read_addressGenerator_sink_bits_addr;
	reg read_fork1_replicate1_generating_;
	reg [15:0] read_fork1_replicate1_idx_;
	wire read_fork1_replicate1_last = read_fork1_replicate1_idx == ({7'h00, _read_fork1_replicate1_len_T} - 16'h0001);
	assign _read_fork1_replicate1_len_T = {1'h0, s_axi_ar_bits_len} + 9'h001;
	wire _read_fork1_replicate1_T = (s_axi_ar_valid & _read_fork1_eagerFork_result_valid_T) & _read_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _read_fork1_replicate1_T_2 = _read_fork1_replicate1_len_T == 9'h001;
	assign read_fork1_replicate1_idx = (read_fork1_replicate1_generating_ ? read_fork1_replicate1_idx_ : 16'h0000);
	reg read_fork1_eagerFork_regs_0;
	reg read_fork1_eagerFork_regs_1;
	assign _read_fork1_eagerFork_result_valid_T = ~read_fork1_eagerFork_regs_0;
	wire read_fork1_eagerFork_s_axi_ar_ready_qual1_0 = (_read_fork1_replicate1_T & (read_fork1_replicate1_generating_ ? read_fork1_replicate1_last : ~(|_read_fork1_replicate1_len_T) | _read_fork1_replicate1_T_2)) | read_fork1_eagerFork_regs_0;
	wire read_fork1_eagerFork_s_axi_ar_ready_qual1_1 = _read_addressGenerator_source_ready | read_fork1_eagerFork_regs_1;
	wire s_axi_ar_ready_0 = read_fork1_eagerFork_s_axi_ar_ready_qual1_0 & read_fork1_eagerFork_s_axi_ar_ready_qual1_1;
	wire s_axi_r_valid_0 = read_resp_valid & _read_fork1_replicate1_sinkBuffer_io_deq_valid;
	wire read_resp_ready_0 = s_axi_r_ready & s_axi_r_valid_0;
	reg write_fork1_replicate1_generating_;
	reg [15:0] write_fork1_replicate1_idx_;
	wire write_fork1_replicate1_last = write_fork1_replicate1_idx == ({7'h00, _write_fork1_replicate1_len_T} - 16'h0001);
	assign _write_fork1_replicate1_len_T = {1'h0, s_axi_aw_bits_len} + 9'h001;
	wire _write_fork1_replicate1_T = (s_axi_aw_valid & _write_fork1_eagerFork_result_valid_T) & _write_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _write_fork1_replicate1_T_2 = _write_fork1_replicate1_len_T == 9'h001;
	assign write_fork1_replicate1_idx = (write_fork1_replicate1_generating_ ? write_fork1_replicate1_idx_ : 16'h0000);
	reg write_fork1_eagerFork_regs_0;
	reg write_fork1_eagerFork_regs_1;
	assign _write_fork1_eagerFork_result_valid_T = ~write_fork1_eagerFork_regs_0;
	wire write_fork1_eagerFork_s_axi_aw_ready_qual1_0 = (_write_fork1_replicate1_T & (write_fork1_replicate1_generating_ ? write_fork1_replicate1_last : ~(|_write_fork1_replicate1_len_T) | _write_fork1_replicate1_T_2)) | write_fork1_eagerFork_regs_0;
	wire write_fork1_eagerFork_s_axi_aw_ready_qual1_1 = _write_addressStrobeGenerator_source_ready | write_fork1_eagerFork_regs_1;
	wire s_axi_aw_ready_0 = write_fork1_eagerFork_s_axi_aw_ready_qual1_0 & write_fork1_eagerFork_s_axi_aw_ready_qual1_1;
	wire write_req_valid_0 = _write_addressStrobeGenerator_sink_valid & s_axi_w_valid;
	wire s_axi_w_ready_0 = write_req_ready & write_req_valid_0;
	wire write_idLastJoined_valid = _write_fork1_replicate1_sinkBuffer_io_deq_valid & write_resp_valid;
	wire write_resp_ready_0 = write_idLastJoined_ready & write_idLastJoined_valid;
	assign write_idLastJoined_ready = _write_arrival1_sinkBuffered__sinkBuffer_io_enq_ready & write_idLastJoined_valid;
	always @(posedge clock)
		if (reset) begin
			read_fork1_replicate1_generating_ <= 1'h0;
			read_fork1_replicate1_idx_ <= 16'h0000;
			read_fork1_eagerFork_regs_0 <= 1'h0;
			read_fork1_eagerFork_regs_1 <= 1'h0;
			write_fork1_replicate1_generating_ <= 1'h0;
			write_fork1_replicate1_idx_ <= 16'h0000;
			write_fork1_eagerFork_regs_0 <= 1'h0;
			write_fork1_eagerFork_regs_1 <= 1'h0;
		end
		else begin
			if (_read_fork1_replicate1_T) begin
				if (read_fork1_replicate1_generating_) begin
					read_fork1_replicate1_generating_ <= ~read_fork1_replicate1_last & read_fork1_replicate1_generating_;
					read_fork1_replicate1_idx_ <= read_fork1_replicate1_idx_ + 16'h0001;
				end
				else begin : sv2v_autoblock_1
					reg _GEN;
					_GEN = ~(|_read_fork1_replicate1_len_T) | _read_fork1_replicate1_T_2;
					read_fork1_replicate1_generating_ <= ~_GEN | read_fork1_replicate1_generating_;
					if (~_GEN)
						read_fork1_replicate1_idx_ <= 16'h0001;
				end
			end
			read_fork1_eagerFork_regs_0 <= (read_fork1_eagerFork_s_axi_ar_ready_qual1_0 & s_axi_ar_valid) & ~s_axi_ar_ready_0;
			read_fork1_eagerFork_regs_1 <= (read_fork1_eagerFork_s_axi_ar_ready_qual1_1 & s_axi_ar_valid) & ~s_axi_ar_ready_0;
			if (_write_fork1_replicate1_T) begin
				if (write_fork1_replicate1_generating_) begin
					write_fork1_replicate1_generating_ <= ~write_fork1_replicate1_last & write_fork1_replicate1_generating_;
					write_fork1_replicate1_idx_ <= write_fork1_replicate1_idx_ + 16'h0001;
				end
				else begin : sv2v_autoblock_2
					reg _GEN_0;
					_GEN_0 = ~(|_write_fork1_replicate1_len_T) | _write_fork1_replicate1_T_2;
					write_fork1_replicate1_generating_ <= ~_GEN_0 | write_fork1_replicate1_generating_;
					if (~_GEN_0)
						write_fork1_replicate1_idx_ <= 16'h0001;
				end
			end
			write_fork1_eagerFork_regs_0 <= (write_fork1_eagerFork_s_axi_aw_ready_qual1_0 & s_axi_aw_valid) & ~s_axi_aw_ready_0;
			write_fork1_eagerFork_regs_1 <= (write_fork1_eagerFork_s_axi_aw_ready_qual1_1 & s_axi_aw_valid) & ~s_axi_aw_ready_0;
		end
	initial begin : sv2v_autoblock_3
		reg [31:0] _RANDOM [0:1];
	end
	AddressGenerator read_addressGenerator(
		.clock(clock),
		.reset(reset),
		.source_ready(_read_addressGenerator_source_ready),
		.source_valid(s_axi_ar_valid & ~read_fork1_eagerFork_regs_1),
		.source_bits_addr(s_axi_ar_bits_addr),
		.source_bits_len(s_axi_ar_bits_len),
		.source_bits_size(s_axi_ar_bits_size),
		.source_bits_burst(s_axi_ar_bits_burst),
		.sink_ready(read_req_ready),
		.sink_valid(read_req_valid),
		.sink_bits_addr(_read_addressGenerator_sink_bits_addr),
		.sink_bits_size()
	);
	Queue4_IdLastBundle read_fork1_replicate1_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_fork1_replicate1_sinkBuffer_io_enq_ready),
		.io_enq_valid(_read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_enq_bits_last(_read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last),
		.io_deq_ready(read_resp_ready_0),
		.io_deq_valid(_read_fork1_replicate1_sinkBuffer_io_deq_valid),
		.io_deq_bits_last(s_axi_r_bits_last)
	);
	Queue2_IdLastBundle read_fork1_replicate1_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_read_fork1_replicate1_T & (read_fork1_replicate1_generating_ | (|_read_fork1_replicate1_len_T))),
		.io_enq_bits_last(read_fork1_replicate1_last),
		.io_deq_ready(_read_fork1_replicate1_sinkBuffer_io_enq_ready),
		.io_deq_valid(_read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_last(_read_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last)
	);
	AddressStrobeGenerator write_addressStrobeGenerator(
		.clock(clock),
		.reset(reset),
		.source_ready(_write_addressStrobeGenerator_source_ready),
		.source_valid(s_axi_aw_valid & ~write_fork1_eagerFork_regs_1),
		.source_bits_addr(s_axi_aw_bits_addr),
		.source_bits_len(s_axi_aw_bits_len),
		.source_bits_size(s_axi_aw_bits_size),
		.source_bits_burst(s_axi_aw_bits_burst),
		.sink_ready(s_axi_w_ready_0),
		.sink_valid(_write_addressStrobeGenerator_sink_valid),
		.sink_bits_addr(_write_addressStrobeGenerator_sink_bits_addr),
		.sink_bits_strb(_write_addressStrobeGenerator_sink_bits_strb)
	);
	Queue4_IdLastBundle write_fork1_replicate1_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_fork1_replicate1_sinkBuffer_io_enq_ready),
		.io_enq_valid(_write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_enq_bits_last(_write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last),
		.io_deq_ready(write_resp_ready_0),
		.io_deq_valid(_write_fork1_replicate1_sinkBuffer_io_deq_valid),
		.io_deq_bits_last(_write_fork1_replicate1_sinkBuffer_io_deq_bits_last)
	);
	Queue2_IdLastBundle write_fork1_replicate1_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_fork1_replicate1_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_write_fork1_replicate1_T & (write_fork1_replicate1_generating_ | (|_write_fork1_replicate1_len_T))),
		.io_enq_bits_last(write_fork1_replicate1_last),
		.io_deq_ready(_write_fork1_replicate1_sinkBuffer_io_enq_ready),
		.io_deq_valid(_write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_last(_write_fork1_replicate1_sinkBuffered__sinkBuffer_io_deq_bits_last)
	);
	Queue2_WriteResponseChannel write_arrival1_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_arrival1_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(write_idLastJoined_ready & _write_fork1_replicate1_sinkBuffer_io_deq_bits_last),
		.io_deq_ready(s_axi_b_ready),
		.io_deq_valid(s_axi_b_valid),
		.io_deq_bits_resp(s_axi_b_bits_resp)
	);
	assign s_axi_ar_ready = s_axi_ar_ready_0;
	assign s_axi_r_valid = s_axi_r_valid_0;
	assign s_axi_r_bits_data = read_resp_bits;
	assign s_axi_aw_ready = s_axi_aw_ready_0;
	assign s_axi_w_ready = s_axi_w_ready_0;
	assign read_req_bits = _read_addressGenerator_sink_bits_addr[14:3];
	assign read_resp_ready = read_resp_ready_0;
	assign write_req_valid = write_req_valid_0;
	assign write_req_bits_addr = _write_addressStrobeGenerator_sink_bits_addr[14:3];
	assign write_req_bits_data = s_axi_w_bits_data;
	assign write_req_bits_strb = _write_addressStrobeGenerator_sink_bits_strb & s_axi_w_bits_strb;
	assign write_resp_ready = write_resp_ready_0;
endmodule
module ram_2x11 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [10:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [10:0] W0_data;
	reg [10:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 11'bxxxxxxxxxxx);
endmodule
module Queue2_AddressChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_prot,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_prot
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [7:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_prot;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [7:0] io_deq_bits_addr;
	output wire [2:0] io_deq_bits_prot;
	wire [10:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x11 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_prot, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[7:0];
	assign io_deq_bits_prot = _ram_ext_R0_data[10:8];
endmodule
module ram_2x34 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [33:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [33:0] W0_data;
	reg [33:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 34'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	wire [33:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x34 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_resp, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[31:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[33:32];
endmodule
module ram_2x36 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [35:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [35:0] W0_data;
	reg [35:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 36'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_WriteDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_strb,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_strb
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_data;
	input [3:0] io_enq_bits_strb;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_data;
	output wire [3:0] io_deq_bits_strb;
	wire [35:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x36 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_strb, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[31:0];
	assign io_deq_bits_strb = _ram_ext_R0_data[35:32];
endmodule
module Queue2_WriteResponseChannel_1 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_resp;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x2 ram_resp_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits_resp),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(2'h0)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Queue1_AddressChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_prot,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [7:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_prot;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [7:0] io_deq_bits_addr;
	reg [10:0] ram;
	reg full;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg do_enq;
		do_enq = ~full & io_enq_valid;
		if (do_enq)
			ram <= {io_enq_bits_prot, io_enq_bits_addr};
		if (reset)
			full <= 1'h0;
		else if (~(do_enq == (io_deq_ready & full)))
			full <= do_enq;
	end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	assign io_enq_ready = ~full;
	assign io_deq_valid = full;
	assign io_deq_bits_addr = ram[7:0];
endmodule
module Queue1_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_data;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	reg [33:0] ram;
	reg full;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg do_enq;
		do_enq = ~full & io_enq_valid;
		if (do_enq)
			ram <= {2'h0, io_enq_bits_data};
		if (reset)
			full <= 1'h0;
		else if (~(do_enq == (io_deq_ready & full)))
			full <= do_enq;
	end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:1];
	end
	assign io_enq_ready = ~full;
	assign io_deq_valid = full;
	assign io_deq_bits_data = ram[31:0];
	assign io_deq_bits_resp = ram[33:32];
endmodule
module Queue1_WriteDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_strb,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_strb
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_data;
	input [3:0] io_enq_bits_strb;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_data;
	output wire [3:0] io_deq_bits_strb;
	reg [35:0] ram;
	reg full;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg do_enq;
		do_enq = ~full & io_enq_valid;
		if (do_enq)
			ram <= {io_enq_bits_strb, io_enq_bits_data};
		if (reset)
			full <= 1'h0;
		else if (~(do_enq == (io_deq_ready & full)))
			full <= do_enq;
	end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:1];
	end
	assign io_enq_ready = ~full;
	assign io_deq_valid = full;
	assign io_deq_bits_data = ram[31:0];
	assign io_deq_bits_strb = ram[35:32];
endmodule
module Queue1_WriteResponseChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_deq_ready,
	io_deq_valid
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_deq_ready;
	output wire io_deq_valid;
	reg full;
	always @(posedge clock)
		if (reset)
			full <= 1'h0;
		else begin : sv2v_autoblock_1
			reg do_enq;
			do_enq = ~full & io_enq_valid;
			if (~(do_enq == (io_deq_ready & full)))
				full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	assign io_enq_ready = ~full;
	assign io_deq_valid = full;
endmodule
module Queue2_Desc (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_id,
	io_enq_bits_len,
	io_enq_bits_flags,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_id,
	io_deq_bits_len,
	io_deq_bits_flags
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [41:0] io_enq_bits_addr;
	input [11:0] io_enq_bits_id;
	input [7:0] io_enq_bits_len;
	input [1:0] io_enq_bits_flags;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [41:0] io_deq_bits_addr;
	output wire [11:0] io_deq_bits_id;
	output wire [7:0] io_deq_bits_len;
	output wire [1:0] io_deq_bits_flags;
	wire [63:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_2x64 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_flags, io_enq_bits_len, io_enq_bits_id, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[41:0];
	assign io_deq_bits_id = _ram_ext_R0_data[53:42];
	assign io_deq_bits_len = _ram_ext_R0_data[61:54];
	assign io_deq_bits_flags = _ram_ext_R0_data[63:62];
endmodule
module ReadEngine (
	clock,
	reset,
	s_axi_desc_ar_ready,
	s_axi_desc_ar_valid,
	s_axi_desc_ar_bits_addr,
	s_axi_desc_ar_bits_len,
	s_axi_desc_ar_bits_size,
	s_axi_desc_ar_bits_burst,
	s_axi_desc_r_ready,
	s_axi_desc_r_valid,
	s_axi_desc_r_bits_data,
	s_axi_desc_r_bits_last,
	s_axi_desc_aw_ready,
	s_axi_desc_aw_valid,
	s_axi_desc_aw_bits_addr,
	s_axi_desc_aw_bits_len,
	s_axi_desc_aw_bits_size,
	s_axi_desc_aw_bits_burst,
	s_axi_desc_w_ready,
	s_axi_desc_w_valid,
	s_axi_desc_w_bits_data,
	s_axi_desc_w_bits_strb,
	s_axi_desc_b_ready,
	s_axi_desc_b_valid,
	s_axi_desc_b_bits_resp,
	s_axi_ctrl_ar_ready,
	s_axi_ctrl_ar_valid,
	s_axi_ctrl_ar_bits_addr,
	s_axi_ctrl_ar_bits_prot,
	s_axi_ctrl_r_ready,
	s_axi_ctrl_r_valid,
	s_axi_ctrl_r_bits_data,
	s_axi_ctrl_r_bits_resp,
	s_axi_ctrl_aw_ready,
	s_axi_ctrl_aw_valid,
	s_axi_ctrl_aw_bits_addr,
	s_axi_ctrl_aw_bits_prot,
	s_axi_ctrl_w_ready,
	s_axi_ctrl_w_valid,
	s_axi_ctrl_w_bits_data,
	s_axi_ctrl_w_bits_strb,
	s_axi_ctrl_b_ready,
	s_axi_ctrl_b_valid,
	s_axi_ctrl_b_bits_resp,
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_id,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_last
);
	input clock;
	input reset;
	output wire s_axi_desc_ar_ready;
	input s_axi_desc_ar_valid;
	input [14:0] s_axi_desc_ar_bits_addr;
	input [7:0] s_axi_desc_ar_bits_len;
	input [2:0] s_axi_desc_ar_bits_size;
	input [1:0] s_axi_desc_ar_bits_burst;
	input s_axi_desc_r_ready;
	output wire s_axi_desc_r_valid;
	output wire [63:0] s_axi_desc_r_bits_data;
	output wire s_axi_desc_r_bits_last;
	output wire s_axi_desc_aw_ready;
	input s_axi_desc_aw_valid;
	input [14:0] s_axi_desc_aw_bits_addr;
	input [7:0] s_axi_desc_aw_bits_len;
	input [2:0] s_axi_desc_aw_bits_size;
	input [1:0] s_axi_desc_aw_bits_burst;
	output wire s_axi_desc_w_ready;
	input s_axi_desc_w_valid;
	input [63:0] s_axi_desc_w_bits_data;
	input [7:0] s_axi_desc_w_bits_strb;
	input s_axi_desc_b_ready;
	output wire s_axi_desc_b_valid;
	output wire [1:0] s_axi_desc_b_bits_resp;
	output wire s_axi_ctrl_ar_ready;
	input s_axi_ctrl_ar_valid;
	input [7:0] s_axi_ctrl_ar_bits_addr;
	input [2:0] s_axi_ctrl_ar_bits_prot;
	input s_axi_ctrl_r_ready;
	output wire s_axi_ctrl_r_valid;
	output wire [31:0] s_axi_ctrl_r_bits_data;
	output wire [1:0] s_axi_ctrl_r_bits_resp;
	output wire s_axi_ctrl_aw_ready;
	input s_axi_ctrl_aw_valid;
	input [7:0] s_axi_ctrl_aw_bits_addr;
	input [2:0] s_axi_ctrl_aw_bits_prot;
	output wire s_axi_ctrl_w_ready;
	input s_axi_ctrl_w_valid;
	input [31:0] s_axi_ctrl_w_bits_data;
	input [3:0] s_axi_ctrl_w_bits_strb;
	input s_axi_ctrl_b_ready;
	output wire s_axi_ctrl_b_valid;
	output wire [1:0] s_axi_ctrl_b_bits_resp;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [5:0] m_axi_ar_bits_id;
	output wire [33:0] m_axi_ar_bits_addr;
	output wire [3:0] m_axi_ar_bits_len;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input m_axi_r_bits_last;
	wire m_axi_ar_valid_0;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_deq_valid;
	wire [41:0] _sinkBuffered__sinkBuffer_io_deq_bits_addr;
	wire [11:0] _sinkBuffered__sinkBuffer_io_deq_bits_id;
	wire [7:0] _sinkBuffered__sinkBuffer_io_deq_bits_len;
	wire [1:0] _sinkBuffered__sinkBuffer_io_deq_bits_flags;
	wire _wrRespQueue__io_enq_ready;
	wire _wrRespQueue__io_deq_valid;
	wire _wrReqData__deq_q_io_enq_ready;
	wire _wrReqData__deq_q_io_deq_valid;
	wire [31:0] _wrReqData__deq_q_io_deq_bits_data;
	wire [3:0] _wrReqData__deq_q_io_deq_bits_strb;
	wire _wrReq__deq_q_io_enq_ready;
	wire _wrReq__deq_q_io_deq_valid;
	wire [7:0] _wrReq__deq_q_io_deq_bits_addr;
	wire _rdRespQueue__io_enq_ready;
	wire _rdRespQueue__io_deq_valid;
	wire [31:0] _rdRespQueue__io_deq_bits_data;
	wire [1:0] _rdRespQueue__io_deq_bits_resp;
	wire _rdReq__deq_q_io_enq_ready;
	wire _rdReq__deq_q_io_deq_valid;
	wire [7:0] _rdReq__deq_q_io_deq_bits_addr;
	wire _s_axil__sinkBuffer_1_io_enq_ready;
	wire _s_axil__sourceBuffer_2_io_deq_valid;
	wire [31:0] _s_axil__sourceBuffer_2_io_deq_bits_data;
	wire [3:0] _s_axil__sourceBuffer_2_io_deq_bits_strb;
	wire _s_axil__sourceBuffer_1_io_deq_valid;
	wire [7:0] _s_axil__sourceBuffer_1_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_1_io_deq_bits_prot;
	wire _s_axil__sinkBuffer_io_enq_ready;
	wire _s_axil__sourceBuffer_io_deq_valid;
	wire [7:0] _s_axil__sourceBuffer_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_io_deq_bits_prot;
	wire _descMem_bridge_read_req_valid;
	wire [11:0] _descMem_bridge_read_req_bits;
	wire _descMem_bridge_read_resp_ready;
	wire _descMem_bridge_write_req_valid;
	wire [11:0] _descMem_bridge_write_req_bits_addr;
	wire [63:0] _descMem_bridge_write_req_bits_data;
	wire [7:0] _descMem_bridge_write_req_bits_strb;
	wire _descMem_bridge_write_resp_ready;
	wire _descMem_mem_read1_req_ready;
	wire _descMem_mem_read1_resp_valid;
	wire [63:0] _descMem_mem_read1_resp_bits;
	wire _descMem_mem_read2_req_ready;
	wire _descMem_mem_read2_resp_valid;
	wire [63:0] _descMem_mem_read2_resp_bits;
	wire _descMem_mem_write1_req_ready;
	wire _descMem_mem_write1_resp_valid;
	reg regBusy;
	reg [63:0] regCounter;
	reg [31:0] regDescIndex;
	reg [31:0] regDescCount;
	wire rdReq = _rdReq__deq_q_io_deq_valid & _rdRespQueue__io_enq_ready;
	wire wrReq = (_wrReq__deq_q_io_deq_valid & _wrReqData__deq_q_io_deq_valid) & _wrRespQueue__io_enq_ready;
	reg [63:0] impl_count;
	reg [63:0] impl_stg1_count;
	reg [63:0] impl_stg1_idx;
	reg [63:0] impl_stg2_count;
	reg [47:0] impl_stg2_waitCycles;
	reg [31:0] impl_stg3_expected;
	reg [31:0] impl_stg3_received;
	wire _GEN = impl_stg1_count < impl_count;
	wire rdDesc_req_valid = regBusy & _GEN;
	wire impl_rvDesc_valid = regBusy & _sinkBuffered__sinkBuffer_io_deq_valid;
	wire _GEN_0 = _sinkBuffered__sinkBuffer_io_enq_ready & _descMem_mem_read2_resp_valid;
	wire [41:0] desc_addr = _descMem_mem_read2_resp_bits[41:0];
	wire [11:0] desc_id = _descMem_mem_read2_resp_bits[53:42];
	wire [7:0] desc_len = _descMem_mem_read2_resp_bits[61:54];
	wire [1:0] desc_flags = _descMem_mem_read2_resp_bits[63:62];
	wire _GEN_1 = impl_stg2_waitCycles == 48'h000000000000;
	wire _GEN_2 = desc_flags == 2'h1;
	wire _GEN_3 = _GEN_0 & _GEN_1;
	wire _GEN_4 = _sinkBuffered__sinkBuffer_io_deq_bits_flags == 2'h1;
	assign m_axi_ar_valid_0 = (regBusy & impl_rvDesc_valid) & _GEN_4;
	always @(posedge clock)
		if (reset) begin
			regBusy <= 1'h0;
			regCounter <= 64'h0000000000000000;
			regDescIndex <= 32'h00000000;
			regDescCount <= 32'h00000000;
			impl_count <= 64'h0000000000000000;
			impl_stg1_count <= 64'h0000000000000000;
			impl_stg1_idx <= 64'h0000000000000000;
			impl_stg2_count <= 64'h0000000000000000;
			impl_stg2_waitCycles <= 48'h000000000000;
			impl_stg3_expected <= 32'h00000000;
			impl_stg3_received <= 32'h00000000;
		end
		else begin : sv2v_autoblock_1
			reg axiStart;
			reg [63:0] _GEN_5;
			axiStart = wrReq & (_wrReq__deq_q_io_deq_bits_addr[7:2] == 6'h05);
			_GEN_5 = {32'h00000000, regDescCount};
			if (regBusy) begin
				regBusy <= ~((impl_stg2_count == 64'h0000000000000000) & (impl_stg3_expected == impl_stg3_received)) & regBusy;
				regCounter <= regCounter + 64'h0000000000000001;
				if ((_GEN & _descMem_mem_read2_req_ready) & rdDesc_req_valid) begin
					impl_stg1_count <= impl_stg1_count + 64'h0000000000000001;
					impl_stg1_idx <= impl_stg1_idx + 64'h0000000000000001;
				end
				if (_GEN_3)
					impl_stg2_count <= impl_stg2_count - 64'h0000000000000001;
				if (~_GEN_3 | _GEN_2) begin
					if (|impl_stg2_waitCycles)
						impl_stg2_waitCycles <= impl_stg2_waitCycles - 48'h000000000001;
				end
				else
					impl_stg2_waitCycles <= {6'h00, desc_addr};
				if ((_GEN_0 & _GEN_1) & _GEN_2)
					impl_stg3_expected <= impl_stg3_expected + 32'h00000001;
				if ((regBusy & m_axi_r_valid) & m_axi_r_bits_last)
					impl_stg3_received <= impl_stg3_received + 32'h00000001;
			end
			else if (axiStart) begin
				regBusy <= |regDescCount;
				regCounter <= 64'h0000000000000000;
				impl_stg1_count <= 64'h0000000000000000;
				impl_stg1_idx <= 64'h0000000000000000;
				impl_stg2_count <= _GEN_5;
				impl_stg2_waitCycles <= 48'h000000000000;
				impl_stg3_expected <= 32'h00000000;
				impl_stg3_received <= 32'h00000000;
			end
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[7:2] == 6'h03))
				regDescIndex <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : regDescIndex[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : regDescIndex[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : regDescIndex[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : regDescIndex[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[7:2] == 6'h04))
				regDescCount <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : regDescCount[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : regDescCount[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : regDescCount[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : regDescCount[7:0])};
			if (regBusy | ~axiStart)
				;
			else
				impl_count <= _GEN_5;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:15];
	end
	ChiselTrueDualPortRAM descMem_mem(
		.clock(clock),
		.reset(reset),
		.read1_req_ready(_descMem_mem_read1_req_ready),
		.read1_req_valid(_descMem_bridge_read_req_valid),
		.read1_req_bits(_descMem_bridge_read_req_bits),
		.read1_resp_ready(_descMem_bridge_read_resp_ready),
		.read1_resp_valid(_descMem_mem_read1_resp_valid),
		.read1_resp_bits(_descMem_mem_read1_resp_bits),
		.read2_req_ready(_descMem_mem_read2_req_ready),
		.read2_req_valid(rdDesc_req_valid),
		.read2_req_bits(impl_stg1_idx[11:0]),
		.read2_resp_ready((regBusy & _GEN_0) & _GEN_1),
		.read2_resp_valid(_descMem_mem_read2_resp_valid),
		.read2_resp_bits(_descMem_mem_read2_resp_bits),
		.write1_req_ready(_descMem_mem_write1_req_ready),
		.write1_req_valid(_descMem_bridge_write_req_valid),
		.write1_req_bits_addr(_descMem_bridge_write_req_bits_addr),
		.write1_req_bits_data(_descMem_bridge_write_req_bits_data),
		.write1_req_bits_strb(_descMem_bridge_write_req_bits_strb),
		.write1_resp_ready(_descMem_bridge_write_resp_ready),
		.write1_resp_valid(_descMem_mem_write1_resp_valid)
	);
	Axi4FullToReadWriteBridge descMem_bridge(
		.clock(clock),
		.reset(reset),
		.s_axi_ar_ready(s_axi_desc_ar_ready),
		.s_axi_ar_valid(s_axi_desc_ar_valid),
		.s_axi_ar_bits_addr(s_axi_desc_ar_bits_addr),
		.s_axi_ar_bits_len(s_axi_desc_ar_bits_len),
		.s_axi_ar_bits_size(s_axi_desc_ar_bits_size),
		.s_axi_ar_bits_burst(s_axi_desc_ar_bits_burst),
		.s_axi_r_ready(s_axi_desc_r_ready),
		.s_axi_r_valid(s_axi_desc_r_valid),
		.s_axi_r_bits_data(s_axi_desc_r_bits_data),
		.s_axi_r_bits_last(s_axi_desc_r_bits_last),
		.s_axi_aw_ready(s_axi_desc_aw_ready),
		.s_axi_aw_valid(s_axi_desc_aw_valid),
		.s_axi_aw_bits_addr(s_axi_desc_aw_bits_addr),
		.s_axi_aw_bits_len(s_axi_desc_aw_bits_len),
		.s_axi_aw_bits_size(s_axi_desc_aw_bits_size),
		.s_axi_aw_bits_burst(s_axi_desc_aw_bits_burst),
		.s_axi_w_ready(s_axi_desc_w_ready),
		.s_axi_w_valid(s_axi_desc_w_valid),
		.s_axi_w_bits_data(s_axi_desc_w_bits_data),
		.s_axi_w_bits_strb(s_axi_desc_w_bits_strb),
		.s_axi_b_ready(s_axi_desc_b_ready),
		.s_axi_b_valid(s_axi_desc_b_valid),
		.s_axi_b_bits_resp(s_axi_desc_b_bits_resp),
		.read_req_ready(_descMem_mem_read1_req_ready),
		.read_req_valid(_descMem_bridge_read_req_valid),
		.read_req_bits(_descMem_bridge_read_req_bits),
		.read_resp_ready(_descMem_bridge_read_resp_ready),
		.read_resp_valid(_descMem_mem_read1_resp_valid),
		.read_resp_bits(_descMem_mem_read1_resp_bits),
		.write_req_ready(_descMem_mem_write1_req_ready),
		.write_req_valid(_descMem_bridge_write_req_valid),
		.write_req_bits_addr(_descMem_bridge_write_req_bits_addr),
		.write_req_bits_data(_descMem_bridge_write_req_bits_data),
		.write_req_bits_strb(_descMem_bridge_write_req_bits_strb),
		.write_resp_ready(_descMem_bridge_write_resp_ready),
		.write_resp_valid(_descMem_mem_write1_resp_valid)
	);
	Queue2_AddressChannel s_axil__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_ctrl_ar_ready),
		.io_enq_valid(s_axi_ctrl_ar_valid),
		.io_enq_bits_addr(s_axi_ctrl_ar_bits_addr),
		.io_enq_bits_prot(s_axi_ctrl_ar_bits_prot),
		.io_deq_ready(_rdReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot)
	);
	Queue2_ReadDataChannel s_axil__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_enq_valid(_rdRespQueue__io_deq_valid),
		.io_enq_bits_data(_rdRespQueue__io_deq_bits_data),
		.io_enq_bits_resp(_rdRespQueue__io_deq_bits_resp),
		.io_deq_ready(s_axi_ctrl_r_ready),
		.io_deq_valid(s_axi_ctrl_r_valid),
		.io_deq_bits_data(s_axi_ctrl_r_bits_data),
		.io_deq_bits_resp(s_axi_ctrl_r_bits_resp)
	);
	Queue2_AddressChannel s_axil__sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_ctrl_aw_ready),
		.io_enq_valid(s_axi_ctrl_aw_valid),
		.io_enq_bits_addr(s_axi_ctrl_aw_bits_addr),
		.io_enq_bits_prot(s_axi_ctrl_aw_bits_prot),
		.io_deq_ready(_wrReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot)
	);
	Queue2_WriteDataChannel s_axil__sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_ctrl_w_ready),
		.io_enq_valid(s_axi_ctrl_w_valid),
		.io_enq_bits_data(s_axi_ctrl_w_bits_data),
		.io_enq_bits_strb(s_axi_ctrl_w_bits_strb),
		.io_deq_ready(_wrReqData__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb)
	);
	Queue2_WriteResponseChannel_1 s_axil__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_wrRespQueue__io_deq_valid),
		.io_deq_ready(s_axi_ctrl_b_ready),
		.io_deq_valid(s_axi_ctrl_b_valid),
		.io_deq_bits_resp(s_axi_ctrl_b_bits_resp)
	);
	Queue1_AddressChannel rdReq__deq_q(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rdReq__deq_q_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_enq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_enq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot),
		.io_deq_ready(rdReq),
		.io_deq_valid(_rdReq__deq_q_io_deq_valid),
		.io_deq_bits_addr(_rdReq__deq_q_io_deq_bits_addr)
	);
	Queue1_ReadDataChannel rdRespQueue_(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rdRespQueue__io_enq_ready),
		.io_enq_valid(rdReq),
		.io_enq_bits_data((_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h05 ? 32'h00000000 : (_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h04 ? regDescCount : (_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h03 ? regDescIndex : (_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h02 ? regCounter[63:32] : (_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h01 ? regCounter[31:0] : (_rdReq__deq_q_io_deq_bits_addr[7:2] == 6'h00 ? {31'h00000000, regBusy} : 32'hffffffff))))))),
		.io_deq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_deq_valid(_rdRespQueue__io_deq_valid),
		.io_deq_bits_data(_rdRespQueue__io_deq_bits_data),
		.io_deq_bits_resp(_rdRespQueue__io_deq_bits_resp)
	);
	Queue1_AddressChannel wrReq__deq_q(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_wrReq__deq_q_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_enq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_enq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot),
		.io_deq_ready(wrReq),
		.io_deq_valid(_wrReq__deq_q_io_deq_valid),
		.io_deq_bits_addr(_wrReq__deq_q_io_deq_bits_addr)
	);
	Queue1_WriteDataChannel wrReqData__deq_q(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_wrReqData__deq_q_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_enq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_enq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb),
		.io_deq_ready(wrReq),
		.io_deq_valid(_wrReqData__deq_q_io_deq_valid),
		.io_deq_bits_data(_wrReqData__deq_q_io_deq_bits_data),
		.io_deq_bits_strb(_wrReqData__deq_q_io_deq_bits_strb)
	);
	Queue1_WriteResponseChannel wrRespQueue_(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_wrRespQueue__io_enq_ready),
		.io_enq_valid(wrReq),
		.io_deq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_deq_valid(_wrRespQueue__io_deq_valid)
	);
	Queue2_Desc sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN_3 & _GEN_2),
		.io_enq_bits_addr(desc_addr),
		.io_enq_bits_id(desc_id),
		.io_enq_bits_len(desc_len),
		.io_enq_bits_flags(desc_flags),
		.io_deq_ready((((regBusy & impl_rvDesc_valid) & _GEN_4) & m_axi_ar_ready) & m_axi_ar_valid_0),
		.io_deq_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_addr(_sinkBuffered__sinkBuffer_io_deq_bits_addr),
		.io_deq_bits_id(_sinkBuffered__sinkBuffer_io_deq_bits_id),
		.io_deq_bits_len(_sinkBuffered__sinkBuffer_io_deq_bits_len),
		.io_deq_bits_flags(_sinkBuffered__sinkBuffer_io_deq_bits_flags)
	);
	assign m_axi_ar_valid = m_axi_ar_valid_0;
	assign m_axi_ar_bits_id = _sinkBuffered__sinkBuffer_io_deq_bits_id[5:0];
	assign m_axi_ar_bits_addr = _sinkBuffered__sinkBuffer_io_deq_bits_addr[33:0];
	assign m_axi_ar_bits_len = _sinkBuffered__sinkBuffer_io_deq_bits_len[3:0];
	assign m_axi_r_ready = regBusy;
endmodule
module ReadEngineExp0 (
	clock,
	reset,
	S_AXI_CONTROL_ARREADY,
	S_AXI_CONTROL_ARVALID,
	S_AXI_CONTROL_ARADDR,
	S_AXI_CONTROL_ARPROT,
	S_AXI_CONTROL_RREADY,
	S_AXI_CONTROL_RVALID,
	S_AXI_CONTROL_RDATA,
	S_AXI_CONTROL_RRESP,
	S_AXI_CONTROL_AWREADY,
	S_AXI_CONTROL_AWVALID,
	S_AXI_CONTROL_AWADDR,
	S_AXI_CONTROL_AWPROT,
	S_AXI_CONTROL_WREADY,
	S_AXI_CONTROL_WVALID,
	S_AXI_CONTROL_WDATA,
	S_AXI_CONTROL_WSTRB,
	S_AXI_CONTROL_BREADY,
	S_AXI_CONTROL_BVALID,
	S_AXI_CONTROL_BRESP,
	S_AXI_DESC_ARREADY,
	S_AXI_DESC_ARVALID,
	S_AXI_DESC_ARADDR,
	S_AXI_DESC_ARLEN,
	S_AXI_DESC_ARSIZE,
	S_AXI_DESC_ARBURST,
	S_AXI_DESC_ARLOCK,
	S_AXI_DESC_ARCACHE,
	S_AXI_DESC_ARPROT,
	S_AXI_DESC_ARQOS,
	S_AXI_DESC_ARREGION,
	S_AXI_DESC_RREADY,
	S_AXI_DESC_RVALID,
	S_AXI_DESC_RDATA,
	S_AXI_DESC_RRESP,
	S_AXI_DESC_RLAST,
	S_AXI_DESC_AWREADY,
	S_AXI_DESC_AWVALID,
	S_AXI_DESC_AWADDR,
	S_AXI_DESC_AWLEN,
	S_AXI_DESC_AWSIZE,
	S_AXI_DESC_AWBURST,
	S_AXI_DESC_AWLOCK,
	S_AXI_DESC_AWCACHE,
	S_AXI_DESC_AWPROT,
	S_AXI_DESC_AWQOS,
	S_AXI_DESC_AWREGION,
	S_AXI_DESC_WREADY,
	S_AXI_DESC_WVALID,
	S_AXI_DESC_WDATA,
	S_AXI_DESC_WSTRB,
	S_AXI_DESC_WLAST,
	S_AXI_DESC_BREADY,
	S_AXI_DESC_BVALID,
	S_AXI_DESC_BRESP,
	M_AXI_ARREADY,
	M_AXI_ARVALID,
	M_AXI_ARID,
	M_AXI_ARADDR,
	M_AXI_ARLEN,
	M_AXI_ARSIZE,
	M_AXI_ARBURST,
	M_AXI_RREADY,
	M_AXI_RVALID,
	M_AXI_RID,
	M_AXI_RDATA,
	M_AXI_RRESP,
	M_AXI_RLAST,
	M_AXI_AWREADY,
	M_AXI_AWVALID,
	M_AXI_AWID,
	M_AXI_AWADDR,
	M_AXI_AWLEN,
	M_AXI_AWSIZE,
	M_AXI_AWBURST,
	M_AXI_WREADY,
	M_AXI_WVALID,
	M_AXI_WDATA,
	M_AXI_WSTRB,
	M_AXI_WLAST,
	M_AXI_BREADY,
	M_AXI_BVALID,
	M_AXI_BID,
	M_AXI_BRESP
);
	input clock;
	input reset;
	output wire S_AXI_CONTROL_ARREADY;
	input S_AXI_CONTROL_ARVALID;
	input [7:0] S_AXI_CONTROL_ARADDR;
	input [2:0] S_AXI_CONTROL_ARPROT;
	input S_AXI_CONTROL_RREADY;
	output wire S_AXI_CONTROL_RVALID;
	output wire [31:0] S_AXI_CONTROL_RDATA;
	output wire [1:0] S_AXI_CONTROL_RRESP;
	output wire S_AXI_CONTROL_AWREADY;
	input S_AXI_CONTROL_AWVALID;
	input [7:0] S_AXI_CONTROL_AWADDR;
	input [2:0] S_AXI_CONTROL_AWPROT;
	output wire S_AXI_CONTROL_WREADY;
	input S_AXI_CONTROL_WVALID;
	input [31:0] S_AXI_CONTROL_WDATA;
	input [3:0] S_AXI_CONTROL_WSTRB;
	input S_AXI_CONTROL_BREADY;
	output wire S_AXI_CONTROL_BVALID;
	output wire [1:0] S_AXI_CONTROL_BRESP;
	output wire S_AXI_DESC_ARREADY;
	input S_AXI_DESC_ARVALID;
	input [14:0] S_AXI_DESC_ARADDR;
	input [7:0] S_AXI_DESC_ARLEN;
	input [2:0] S_AXI_DESC_ARSIZE;
	input [1:0] S_AXI_DESC_ARBURST;
	input S_AXI_DESC_ARLOCK;
	input [3:0] S_AXI_DESC_ARCACHE;
	input [2:0] S_AXI_DESC_ARPROT;
	input [3:0] S_AXI_DESC_ARQOS;
	input [3:0] S_AXI_DESC_ARREGION;
	input S_AXI_DESC_RREADY;
	output wire S_AXI_DESC_RVALID;
	output wire [63:0] S_AXI_DESC_RDATA;
	output wire [1:0] S_AXI_DESC_RRESP;
	output wire S_AXI_DESC_RLAST;
	output wire S_AXI_DESC_AWREADY;
	input S_AXI_DESC_AWVALID;
	input [14:0] S_AXI_DESC_AWADDR;
	input [7:0] S_AXI_DESC_AWLEN;
	input [2:0] S_AXI_DESC_AWSIZE;
	input [1:0] S_AXI_DESC_AWBURST;
	input S_AXI_DESC_AWLOCK;
	input [3:0] S_AXI_DESC_AWCACHE;
	input [2:0] S_AXI_DESC_AWPROT;
	input [3:0] S_AXI_DESC_AWQOS;
	input [3:0] S_AXI_DESC_AWREGION;
	output wire S_AXI_DESC_WREADY;
	input S_AXI_DESC_WVALID;
	input [63:0] S_AXI_DESC_WDATA;
	input [7:0] S_AXI_DESC_WSTRB;
	input S_AXI_DESC_WLAST;
	input S_AXI_DESC_BREADY;
	output wire S_AXI_DESC_BVALID;
	output wire [1:0] S_AXI_DESC_BRESP;
	input M_AXI_ARREADY;
	output wire M_AXI_ARVALID;
	output wire [5:0] M_AXI_ARID;
	output wire [33:0] M_AXI_ARADDR;
	output wire [3:0] M_AXI_ARLEN;
	output wire [2:0] M_AXI_ARSIZE;
	output wire [1:0] M_AXI_ARBURST;
	output wire M_AXI_RREADY;
	input M_AXI_RVALID;
	input [5:0] M_AXI_RID;
	input [255:0] M_AXI_RDATA;
	input [1:0] M_AXI_RRESP;
	input M_AXI_RLAST;
	input M_AXI_AWREADY;
	output wire M_AXI_AWVALID;
	output wire [5:0] M_AXI_AWID;
	output wire [33:0] M_AXI_AWADDR;
	output wire [3:0] M_AXI_AWLEN;
	output wire [2:0] M_AXI_AWSIZE;
	output wire [1:0] M_AXI_AWBURST;
	input M_AXI_WREADY;
	output wire M_AXI_WVALID;
	output wire [255:0] M_AXI_WDATA;
	output wire [31:0] M_AXI_WSTRB;
	output wire M_AXI_WLAST;
	output wire M_AXI_BREADY;
	input M_AXI_BVALID;
	input [5:0] M_AXI_BID;
	input [1:0] M_AXI_BRESP;
	ReadEngine readEngine0(
		.clock(clock),
		.reset(reset),
		.s_axi_desc_ar_ready(S_AXI_DESC_ARREADY),
		.s_axi_desc_ar_valid(S_AXI_DESC_ARVALID),
		.s_axi_desc_ar_bits_addr(S_AXI_DESC_ARADDR),
		.s_axi_desc_ar_bits_len(S_AXI_DESC_ARLEN),
		.s_axi_desc_ar_bits_size(S_AXI_DESC_ARSIZE),
		.s_axi_desc_ar_bits_burst(S_AXI_DESC_ARBURST),
		.s_axi_desc_r_ready(S_AXI_DESC_RREADY),
		.s_axi_desc_r_valid(S_AXI_DESC_RVALID),
		.s_axi_desc_r_bits_data(S_AXI_DESC_RDATA),
		.s_axi_desc_r_bits_last(S_AXI_DESC_RLAST),
		.s_axi_desc_aw_ready(S_AXI_DESC_AWREADY),
		.s_axi_desc_aw_valid(S_AXI_DESC_AWVALID),
		.s_axi_desc_aw_bits_addr(S_AXI_DESC_AWADDR),
		.s_axi_desc_aw_bits_len(S_AXI_DESC_AWLEN),
		.s_axi_desc_aw_bits_size(S_AXI_DESC_AWSIZE),
		.s_axi_desc_aw_bits_burst(S_AXI_DESC_AWBURST),
		.s_axi_desc_w_ready(S_AXI_DESC_WREADY),
		.s_axi_desc_w_valid(S_AXI_DESC_WVALID),
		.s_axi_desc_w_bits_data(S_AXI_DESC_WDATA),
		.s_axi_desc_w_bits_strb(S_AXI_DESC_WSTRB),
		.s_axi_desc_b_ready(S_AXI_DESC_BREADY),
		.s_axi_desc_b_valid(S_AXI_DESC_BVALID),
		.s_axi_desc_b_bits_resp(S_AXI_DESC_BRESP),
		.s_axi_ctrl_ar_ready(S_AXI_CONTROL_ARREADY),
		.s_axi_ctrl_ar_valid(S_AXI_CONTROL_ARVALID),
		.s_axi_ctrl_ar_bits_addr(S_AXI_CONTROL_ARADDR),
		.s_axi_ctrl_ar_bits_prot(S_AXI_CONTROL_ARPROT),
		.s_axi_ctrl_r_ready(S_AXI_CONTROL_RREADY),
		.s_axi_ctrl_r_valid(S_AXI_CONTROL_RVALID),
		.s_axi_ctrl_r_bits_data(S_AXI_CONTROL_RDATA),
		.s_axi_ctrl_r_bits_resp(S_AXI_CONTROL_RRESP),
		.s_axi_ctrl_aw_ready(S_AXI_CONTROL_AWREADY),
		.s_axi_ctrl_aw_valid(S_AXI_CONTROL_AWVALID),
		.s_axi_ctrl_aw_bits_addr(S_AXI_CONTROL_AWADDR),
		.s_axi_ctrl_aw_bits_prot(S_AXI_CONTROL_AWPROT),
		.s_axi_ctrl_w_ready(S_AXI_CONTROL_WREADY),
		.s_axi_ctrl_w_valid(S_AXI_CONTROL_WVALID),
		.s_axi_ctrl_w_bits_data(S_AXI_CONTROL_WDATA),
		.s_axi_ctrl_w_bits_strb(S_AXI_CONTROL_WSTRB),
		.s_axi_ctrl_b_ready(S_AXI_CONTROL_BREADY),
		.s_axi_ctrl_b_valid(S_AXI_CONTROL_BVALID),
		.s_axi_ctrl_b_bits_resp(S_AXI_CONTROL_BRESP),
		.m_axi_ar_ready(M_AXI_ARREADY),
		.m_axi_ar_valid(M_AXI_ARVALID),
		.m_axi_ar_bits_id(M_AXI_ARID),
		.m_axi_ar_bits_addr(M_AXI_ARADDR),
		.m_axi_ar_bits_len(M_AXI_ARLEN),
		.m_axi_r_ready(M_AXI_RREADY),
		.m_axi_r_valid(M_AXI_RVALID),
		.m_axi_r_bits_last(M_AXI_RLAST)
	);
	assign S_AXI_DESC_RRESP = 2'h0;
	assign M_AXI_ARSIZE = 3'h5;
	assign M_AXI_ARBURST = 2'h1;
	assign M_AXI_AWVALID = 1'h0;
	assign M_AXI_AWID = 6'h00;
	assign M_AXI_AWADDR = 34'h000000000;
	assign M_AXI_AWLEN = 4'h0;
	assign M_AXI_AWSIZE = 3'h0;
	assign M_AXI_AWBURST = 2'h0;
	assign M_AXI_WVALID = 1'h0;
	assign M_AXI_WDATA = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	assign M_AXI_WSTRB = 32'h00000000;
	assign M_AXI_WLAST = 1'h0;
	assign M_AXI_BREADY = 1'h0;
endmodule
