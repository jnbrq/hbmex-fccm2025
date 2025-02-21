module ram_16x64 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [63:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [63:0] W0_data;
	reg [63:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue16_UInt64 (
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
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x64 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module ram_2x128 (
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
	output wire [127:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [127:0] W0_data;
	reg [127:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [127:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 128'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadStreamTask (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_address,
	io_enq_bits_length,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_address,
	io_deq_bits_length
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits_address;
	input [63:0] io_enq_bits_length;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_address;
	output wire [63:0] io_deq_bits_length;
	wire [127:0] _ram_ext_R0_data;
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
	ram_2x128 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_length, io_enq_bits_address})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_address = _ram_ext_R0_data[63:0];
	assign io_deq_bits_length = _ram_ext_R0_data[127:64];
endmodule
module ram_2x73 (
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
	output wire [72:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [72:0] W0_data;
	reg [72:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [95:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 73'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadAddressChannel (
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
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [72:0] _ram_ext_R0_data;
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
	ram_2x73 ram_ext(
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
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[67:64];
	assign io_deq_bits_size = _ram_ext_R0_data[70:68];
	assign io_deq_bits_burst = _ram_ext_R0_data[72:71];
endmodule
module ReadStream (
	clock,
	reset,
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_ar_bits_size,
	m_axi_ar_bits_burst,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_data,
	sourceTask_ready,
	sourceTask_valid,
	sourceTask_bits_address,
	sourceTask_bits_length,
	sinkData_ready,
	sinkData_valid,
	sinkData_bits
);
	input clock;
	input reset;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [63:0] m_axi_ar_bits_addr;
	output wire [3:0] m_axi_ar_bits_len;
	output wire [2:0] m_axi_ar_bits_size;
	output wire [1:0] m_axi_ar_bits_burst;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input [255:0] m_axi_r_bits_data;
	output wire sourceTask_ready;
	input sourceTask_valid;
	input [63:0] sourceTask_bits_address;
	input [63:0] sourceTask_bits_length;
	input sinkData_ready;
	output wire sinkData_valid;
	output wire [255:0] sinkData_bits;
	wire _addressPhase_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid;
	wire [63:0] _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address;
	wire [63:0] _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length;
	wire sourceTask_ready_0 = _filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready & sourceTask_valid;
	reg addressPhase_rGenerating;
	reg [63:0] addressPhase_rRemaining;
	reg [63:0] addressPhase_rAddress;
	wire _addressPhase_T = _addressPhase_sinkBuffered__sinkBuffer_io_enq_ready & _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid;
	wire _addressPhase_T_1 = addressPhase_rRemaining < 64'h0000000000000011;
	wire _addressPhase_T_2 = _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length < 64'h0000000000000011;
	always @(posedge clock)
		if (reset) begin
			addressPhase_rGenerating <= 1'h0;
			addressPhase_rRemaining <= 64'h0000000000000000;
			addressPhase_rAddress <= 64'h0000000000000000;
		end
		else if (_addressPhase_T) begin
			if (addressPhase_rGenerating) begin
				addressPhase_rGenerating <= ~_addressPhase_T_1;
				if (_addressPhase_T_1) begin
					addressPhase_rRemaining <= 64'h0000000000000000;
					addressPhase_rAddress <= 64'h0000000000000000;
				end
				else begin
					addressPhase_rRemaining <= addressPhase_rRemaining - 64'h0000000000000010;
					addressPhase_rAddress <= addressPhase_rAddress + 64'h0000000000000200;
				end
			end
			else begin
				addressPhase_rGenerating <= ~_addressPhase_T_2;
				addressPhase_rRemaining <= (_addressPhase_T_2 ? 64'h0000000000000000 : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length - 64'h0000000000000010);
				addressPhase_rAddress <= (_addressPhase_T_2 ? 64'h0000000000000000 : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address + 64'h0000000000000200);
			end
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:4];
	end
	Queue2_ReadStreamTask filtering_arrival_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceTask_ready_0 & |sourceTask_bits_length),
		.io_enq_bits_address(sourceTask_bits_address),
		.io_enq_bits_length(sourceTask_bits_length),
		.io_deq_ready(_addressPhase_T & (addressPhase_rGenerating ? _addressPhase_T_1 : _addressPhase_T_2)),
		.io_deq_valid(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_address(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address),
		.io_deq_bits_length(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length)
	);
	Queue2_ReadAddressChannel addressPhase_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_addressPhase_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_addressPhase_T),
		.io_enq_bits_addr((addressPhase_rGenerating ? addressPhase_rAddress : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address)),
		.io_enq_bits_len((addressPhase_rGenerating ? (_addressPhase_T_1 ? addressPhase_rRemaining[3:0] - 4'h1 : 4'hf) : (_addressPhase_T_2 ? _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length[3:0] - 4'h1 : 4'hf))),
		.io_enq_bits_size(3'h5),
		.io_enq_bits_burst(2'h1),
		.io_deq_ready(m_axi_ar_ready),
		.io_deq_valid(m_axi_ar_valid),
		.io_deq_bits_addr(m_axi_ar_bits_addr),
		.io_deq_bits_len(m_axi_ar_bits_len),
		.io_deq_bits_size(m_axi_ar_bits_size),
		.io_deq_bits_burst(m_axi_ar_bits_burst)
	);
	assign m_axi_r_ready = sinkData_ready;
	assign sourceTask_ready = sourceTask_ready_0;
	assign sinkData_valid = m_axi_r_valid;
	assign sinkData_bits = m_axi_r_bits_data;
endmodule
module ram_8x64 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [2:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [63:0] R0_data;
	input [2:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [63:0] W0_data;
	reg [63:0] Memory [0:7];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 64'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue8_UInt64 (
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
	reg [2:0] enq_ptr_value;
	reg [2:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 3'h0;
			deq_ptr_value <= 3'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 3'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 3'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_8x64 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module ram_2x257 (
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
	output wire [256:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [256:0] W0_data;
	reg [256:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 257'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_DataLast (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire io_deq_bits_last;
	wire [256:0] _ram_ext_R0_data;
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
	ram_2x257 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_last = _ram_ext_R0_data[256];
endmodule
module ReadStreamWithLast (
	clock,
	reset,
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_ar_bits_size,
	m_axi_ar_bits_burst,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_data,
	sourceTask_ready,
	sourceTask_valid,
	sourceTask_bits_address,
	sourceTask_bits_length,
	sinkData_ready,
	sinkData_valid,
	sinkData_bits_data,
	sinkData_bits_last
);
	input clock;
	input reset;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [63:0] m_axi_ar_bits_addr;
	output wire [3:0] m_axi_ar_bits_len;
	output wire [2:0] m_axi_ar_bits_size;
	output wire [1:0] m_axi_ar_bits_burst;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input [255:0] m_axi_r_bits_data;
	output wire sourceTask_ready;
	input sourceTask_valid;
	input [63:0] sourceTask_bits_address;
	input [63:0] sourceTask_bits_length;
	input sinkData_ready;
	output wire sinkData_valid;
	output wire [255:0] sinkData_bits_data;
	output wire sinkData_bits_last;
	wire _fork0_eagerFork_result_valid_T_2;
	wire _dataPhase_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _addressPhase_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid;
	wire [63:0] _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address;
	wire [63:0] _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length;
	wire _qLength_io_enq_ready;
	wire _qLength_io_deq_valid;
	wire [63:0] _qLength_io_deq_bits;
	wire sourceTask_ready_0 = _filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready & sourceTask_valid;
	reg addressPhase_rGenerating;
	reg [63:0] addressPhase_rRemaining;
	reg [63:0] addressPhase_rAddress;
	wire _addressPhase_T = (_addressPhase_sinkBuffered__sinkBuffer_io_enq_ready & _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid) & _fork0_eagerFork_result_valid_T_2;
	wire _addressPhase_T_1 = addressPhase_rRemaining < 64'h0000000000000011;
	wire _addressPhase_T_2 = _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length < 64'h0000000000000011;
	reg fork0_eagerFork_regs_0;
	reg fork0_eagerFork_regs_1;
	assign _fork0_eagerFork_result_valid_T_2 = ~fork0_eagerFork_regs_1;
	wire fork0_eagerFork_rvTask0_ready_qual1_0 = _qLength_io_enq_ready | fork0_eagerFork_regs_0;
	wire fork0_eagerFork_rvTask0_ready_qual1_1 = (_addressPhase_T & (addressPhase_rGenerating ? _addressPhase_T_1 : _addressPhase_T_2)) | fork0_eagerFork_regs_1;
	wire rvTask0_ready = fork0_eagerFork_rvTask0_ready_qual1_0 & fork0_eagerFork_rvTask0_ready_qual1_1;
	reg [63:0] dataPhase_rReceived;
	wire _dataPhase_T = _dataPhase_sinkBuffered__sinkBuffer_io_enq_ready & m_axi_r_valid;
	wire _dataPhase_T_3 = dataPhase_rReceived == (_qLength_io_deq_bits - 64'h0000000000000001);
	wire _GEN = _dataPhase_T & _qLength_io_deq_valid;
	wire m_axi_r_ready_0 = _dataPhase_T & _qLength_io_deq_valid;
	always @(posedge clock)
		if (reset) begin
			addressPhase_rGenerating <= 1'h0;
			addressPhase_rRemaining <= 64'h0000000000000000;
			addressPhase_rAddress <= 64'h0000000000000000;
			fork0_eagerFork_regs_0 <= 1'h0;
			fork0_eagerFork_regs_1 <= 1'h0;
			dataPhase_rReceived <= 64'h0000000000000000;
		end
		else begin
			if (_addressPhase_T) begin
				if (addressPhase_rGenerating) begin
					addressPhase_rGenerating <= ~_addressPhase_T_1;
					if (_addressPhase_T_1) begin
						addressPhase_rRemaining <= 64'h0000000000000000;
						addressPhase_rAddress <= 64'h0000000000000000;
					end
					else begin
						addressPhase_rRemaining <= addressPhase_rRemaining - 64'h0000000000000010;
						addressPhase_rAddress <= addressPhase_rAddress + 64'h0000000000000200;
					end
				end
				else begin
					addressPhase_rGenerating <= ~_addressPhase_T_2;
					addressPhase_rRemaining <= (_addressPhase_T_2 ? 64'h0000000000000000 : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length - 64'h0000000000000010);
					addressPhase_rAddress <= (_addressPhase_T_2 ? 64'h0000000000000000 : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address + 64'h0000000000000200);
				end
			end
			fork0_eagerFork_regs_0 <= (fork0_eagerFork_rvTask0_ready_qual1_0 & _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask0_ready;
			fork0_eagerFork_regs_1 <= (fork0_eagerFork_rvTask0_ready_qual1_1 & _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask0_ready;
			if (_GEN) begin
				if (_dataPhase_T_3)
					dataPhase_rReceived <= 64'h0000000000000000;
				else
					dataPhase_rReceived <= dataPhase_rReceived + 64'h0000000000000001;
			end
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:6];
	end
	Queue8_UInt64 qLength(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_qLength_io_enq_ready),
		.io_enq_valid(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid & ~fork0_eagerFork_regs_0),
		.io_enq_bits(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length),
		.io_deq_ready(_GEN & _dataPhase_T_3),
		.io_deq_valid(_qLength_io_deq_valid),
		.io_deq_bits(_qLength_io_deq_bits)
	);
	Queue2_ReadStreamTask filtering_arrival_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_filtering_arrival_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceTask_ready_0 & |sourceTask_bits_length),
		.io_enq_bits_address(sourceTask_bits_address),
		.io_enq_bits_length(sourceTask_bits_length),
		.io_deq_ready(rvTask0_ready),
		.io_deq_valid(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_address(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address),
		.io_deq_bits_length(_filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length)
	);
	Queue2_ReadAddressChannel addressPhase_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_addressPhase_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_addressPhase_T),
		.io_enq_bits_addr((addressPhase_rGenerating ? addressPhase_rAddress : _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_address)),
		.io_enq_bits_len((addressPhase_rGenerating ? (_addressPhase_T_1 ? addressPhase_rRemaining[3:0] - 4'h1 : 4'hf) : (_addressPhase_T_2 ? _filtering_arrival_sinkBuffered__sinkBuffer_io_deq_bits_length[3:0] - 4'h1 : 4'hf))),
		.io_enq_bits_size(3'h5),
		.io_enq_bits_burst(2'h1),
		.io_deq_ready(m_axi_ar_ready),
		.io_deq_valid(m_axi_ar_valid),
		.io_deq_bits_addr(m_axi_ar_bits_addr),
		.io_deq_bits_len(m_axi_ar_bits_len),
		.io_deq_bits_size(m_axi_ar_bits_size),
		.io_deq_bits_burst(m_axi_ar_bits_burst)
	);
	Queue2_DataLast dataPhase_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_dataPhase_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(m_axi_r_ready_0),
		.io_enq_bits_data(m_axi_r_bits_data),
		.io_enq_bits_last(_dataPhase_T_3),
		.io_deq_ready(sinkData_ready),
		.io_deq_valid(sinkData_valid),
		.io_deq_bits_data(sinkData_bits_data),
		.io_deq_bits_last(sinkData_bits_last)
	);
	assign m_axi_r_ready = m_axi_r_ready_0;
	assign sourceTask_ready = sourceTask_ready_0;
endmodule
module ram_16x4 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [3:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [3:0] W0_data;
	reg [3:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 4'bxxxx);
endmodule
module Queue16_UInt4 (
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
	input [3:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [3:0] io_deq_bits;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x4 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Queue2_WriteStreamTask (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_address,
	io_enq_bits_length,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_address,
	io_deq_bits_length
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits_address;
	input [63:0] io_enq_bits_length;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_address;
	output wire [63:0] io_deq_bits_length;
	wire [127:0] _ram_ext_R0_data;
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
	ram_2x128 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_length, io_enq_bits_address})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_address = _ram_ext_R0_data[63:0];
	assign io_deq_bits_length = _ram_ext_R0_data[127:64];
endmodule
module Queue2_WriteAddressChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_len,
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
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [72:0] _ram_ext_R0_data;
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
	ram_2x73 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({5'h0d, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[67:64];
	assign io_deq_bits_size = _ram_ext_R0_data[70:68];
	assign io_deq_bits_burst = _ram_ext_R0_data[72:71];
endmodule
module ram_2x289 (
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
	output wire [288:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [288:0] W0_data;
	reg [288:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [319:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 289'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_WriteDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_strb,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_strb,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [31:0] io_enq_bits_strb;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [31:0] io_deq_bits_strb;
	output wire io_deq_bits_last;
	wire [288:0] _ram_ext_R0_data;
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
	ram_2x289 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_strb, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_strb = _ram_ext_R0_data[287:256];
	assign io_deq_bits_last = _ram_ext_R0_data[288];
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
module WriteStream (
	clock,
	reset,
	m_axi_aw_ready,
	m_axi_aw_valid,
	m_axi_aw_bits_addr,
	m_axi_aw_bits_len,
	m_axi_aw_bits_size,
	m_axi_aw_bits_burst,
	m_axi_w_ready,
	m_axi_w_valid,
	m_axi_w_bits_data,
	m_axi_w_bits_strb,
	m_axi_w_bits_last,
	m_axi_b_ready,
	m_axi_b_valid,
	m_axi_b_bits_resp,
	sourceTask_ready,
	sourceTask_valid,
	sourceTask_bits_address,
	sourceTask_bits_length,
	sinkDone_ready,
	sinkDone_valid,
	sourceData_ready,
	sourceData_valid,
	sourceData_bits
);
	input clock;
	input reset;
	input m_axi_aw_ready;
	output wire m_axi_aw_valid;
	output wire [63:0] m_axi_aw_bits_addr;
	output wire [3:0] m_axi_aw_bits_len;
	output wire [2:0] m_axi_aw_bits_size;
	output wire [1:0] m_axi_aw_bits_burst;
	input m_axi_w_ready;
	output wire m_axi_w_valid;
	output wire [255:0] m_axi_w_bits_data;
	output wire [31:0] m_axi_w_bits_strb;
	output wire m_axi_w_bits_last;
	output wire m_axi_b_ready;
	input m_axi_b_valid;
	input [1:0] m_axi_b_bits_resp;
	output wire sourceTask_ready;
	input sourceTask_valid;
	input [63:0] sourceTask_bits_address;
	input [63:0] sourceTask_bits_length;
	input sinkDone_ready;
	output wire sinkDone_valid;
	output wire sourceData_ready;
	input sourceData_valid;
	input [255:0] sourceData_bits;
	wire _responsePhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _dataPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _addressPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_valid;
	wire [63:0] _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_address;
	wire [63:0] _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length;
	wire _qLengthW_io_enq_ready;
	wire _qLengthW_io_deq_valid;
	wire [3:0] _qLengthW_io_deq_bits;
	wire _qLengthB_io_enq_ready;
	wire _qLengthB_io_deq_valid;
	wire [63:0] _qLengthB_io_deq_bits;
	wire sourceTask_ready_0 = _filtering_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & sourceTask_valid;
	reg addressPhase_rGenerating;
	reg [63:0] addressPhase_rRemaining;
	reg [63:0] addressPhase_rAddress;
	wire _addressPhase_arrival0_T = _addressPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_valid;
	wire _addressPhase_arrival0_T_1 = _qLengthB_io_enq_ready & _qLengthW_io_enq_ready;
	wire _addressPhase_arrival0_T_2 = addressPhase_rRemaining < 64'h0000000000000011;
	wire _addressPhase_arrival0_T_3 = _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length < 64'h0000000000000011;
	wire _GEN = _addressPhase_arrival0_T & _addressPhase_arrival0_T_1;
	wire [3:0] _GEN_0 = (_addressPhase_arrival0_T_1 ? (addressPhase_rGenerating ? (_addressPhase_arrival0_T_2 ? addressPhase_rRemaining[3:0] - 4'h1 : 4'hf) : (_addressPhase_arrival0_T_3 ? _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length[3:0] - 4'h1 : 4'hf)) : 4'h0);
	wire [63:0] _addressPhase_arrival0_T_4 = _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length + 64'h000000000000000f;
	wire _GEN_1 = _addressPhase_arrival0_T & _addressPhase_arrival0_T_1;
	reg [3:0] dataPhase_rReceived;
	wire _dataPhase_arrival0_T = _dataPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & sourceData_valid;
	wire _dataPhase_arrival0_sinkBuffer_io_enq_bits_last_T = dataPhase_rReceived == _qLengthW_io_deq_bits;
	wire _GEN_2 = _dataPhase_arrival0_T & _qLengthW_io_deq_valid;
	wire sourceData_ready_0 = _dataPhase_arrival0_T & _qLengthW_io_deq_valid;
	reg [63:0] responsePhase_rReceived;
	wire _responsePhase_arrival0_T = _responsePhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & m_axi_b_valid;
	wire _responsePhase_arrival0_T_1 = responsePhase_rReceived == _qLengthB_io_deq_bits;
	wire _GEN_3 = _responsePhase_arrival0_T & _qLengthB_io_deq_valid;
	wire _GEN_4 = _GEN_3 & _responsePhase_arrival0_T_1;
	always @(posedge clock)
		if (reset) begin
			addressPhase_rGenerating <= 1'h0;
			addressPhase_rRemaining <= 64'h0000000000000000;
			addressPhase_rAddress <= 64'h0000000000000000;
			dataPhase_rReceived <= 4'h0;
			responsePhase_rReceived <= 64'h0000000000000000;
		end
		else begin
			if (_GEN) begin
				if (addressPhase_rGenerating) begin
					addressPhase_rGenerating <= ~_addressPhase_arrival0_T_2;
					if (_addressPhase_arrival0_T_2) begin
						addressPhase_rRemaining <= 64'h0000000000000000;
						addressPhase_rAddress <= 64'h0000000000000000;
					end
					else begin
						addressPhase_rRemaining <= addressPhase_rRemaining - 64'h0000000000000010;
						addressPhase_rAddress <= addressPhase_rAddress + 64'h0000000000000200;
					end
				end
				else begin
					addressPhase_rGenerating <= ~_addressPhase_arrival0_T_3;
					if (~_addressPhase_arrival0_T_3)
						addressPhase_rRemaining <= _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length - 64'h0000000000000010;
					addressPhase_rAddress <= (_addressPhase_arrival0_T_3 ? 64'h0000000000000000 : _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_address + 64'h0000000000000200);
				end
			end
			if (_GEN_2) begin
				if (_dataPhase_arrival0_sinkBuffer_io_enq_bits_last_T)
					dataPhase_rReceived <= 4'h0;
				else
					dataPhase_rReceived <= dataPhase_rReceived + 4'h1;
			end
			if (_GEN_3) begin
				if (_responsePhase_arrival0_T_1)
					responsePhase_rReceived <= 64'h0000000000000000;
				else
					responsePhase_rReceived <= responsePhase_rReceived + 64'h0000000000000001;
			end
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:6];
	end
	Queue16_UInt64 qLengthB(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_qLengthB_io_enq_ready),
		.io_enq_valid(_GEN & ~addressPhase_rGenerating),
		.io_enq_bits({4'h0, _addressPhase_arrival0_T_4[63:4] - 60'h000000000000001}),
		.io_deq_ready(_GEN_4),
		.io_deq_valid(_qLengthB_io_deq_valid),
		.io_deq_bits(_qLengthB_io_deq_bits)
	);
	Queue16_UInt4 qLengthW(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_qLengthW_io_enq_ready),
		.io_enq_valid(_GEN_1),
		.io_enq_bits(_GEN_0),
		.io_deq_ready(_GEN_2 & _dataPhase_arrival0_sinkBuffer_io_enq_bits_last_T),
		.io_deq_valid(_qLengthW_io_deq_valid),
		.io_deq_bits(_qLengthW_io_deq_bits)
	);
	Queue2_WriteStreamTask filtering_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_filtering_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceTask_ready_0 & |sourceTask_bits_length),
		.io_enq_bits_address(sourceTask_bits_address),
		.io_enq_bits_length(sourceTask_bits_length),
		.io_deq_ready(_GEN & (addressPhase_rGenerating ? _addressPhase_arrival0_T_2 : _addressPhase_arrival0_T_3)),
		.io_deq_valid(_filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_address(_filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_address),
		.io_deq_bits_length(_filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_length)
	);
	Queue2_WriteAddressChannel addressPhase_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_addressPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN_1),
		.io_enq_bits_addr((_addressPhase_arrival0_T_1 ? (addressPhase_rGenerating ? addressPhase_rAddress : _filtering_arrival0_sinkBuffered__sinkBuffer_io_deq_bits_address) : 64'h0000000000000000)),
		.io_enq_bits_len(_GEN_0),
		.io_deq_ready(m_axi_aw_ready),
		.io_deq_valid(m_axi_aw_valid),
		.io_deq_bits_addr(m_axi_aw_bits_addr),
		.io_deq_bits_len(m_axi_aw_bits_len),
		.io_deq_bits_size(m_axi_aw_bits_size),
		.io_deq_bits_burst(m_axi_aw_bits_burst)
	);
	Queue2_WriteDataChannel dataPhase_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_dataPhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceData_ready_0),
		.io_enq_bits_data(sourceData_bits),
		.io_enq_bits_strb(32'hffffffff),
		.io_enq_bits_last(_dataPhase_arrival0_sinkBuffer_io_enq_bits_last_T),
		.io_deq_ready(m_axi_w_ready),
		.io_deq_valid(m_axi_w_valid),
		.io_deq_bits_data(m_axi_w_bits_data),
		.io_deq_bits_strb(m_axi_w_bits_strb),
		.io_deq_bits_last(m_axi_w_bits_last)
	);
	Queue2_UInt0 responsePhase_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_responsePhase_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN_4),
		.io_deq_ready(sinkDone_ready),
		.io_deq_valid(sinkDone_valid)
	);
	assign m_axi_b_ready = _responsePhase_arrival0_T & _qLengthB_io_deq_valid;
	assign sourceTask_ready = sourceTask_ready_0;
	assign sourceData_ready = sourceData_ready_0;
endmodule
module CounterEx (
	clock,
	reset,
	io_up,
	io_down,
	io_left
);
	input clock;
	input reset;
	input [5:0] io_up;
	input [5:0] io_down;
	output wire [5:0] io_left;
	reg [5:0] rLeft;
	always @(posedge clock)
		if (reset)
			rLeft <= 6'h20;
		else if (io_up > io_down)
			rLeft <= rLeft - (io_up - io_down);
		else
			rLeft <= (rLeft + io_down) - io_up;
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_left = rLeft;
endmodule
module ram_32x259 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [4:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [258:0] R0_data;
	input [4:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [258:0] W0_data;
	reg [258:0] Memory [0:31];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 259'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue32_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	output wire io_deq_bits_last;
	wire [258:0] _ram_ext_R0_data;
	reg [4:0] enq_ptr_value;
	reg [4:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 5'h00;
			deq_ptr_value <= 5'h00;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 5'h01;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 5'h01;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_32x259 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_resp, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[257:256];
	assign io_deq_bits_last = _ram_ext_R0_data[258];
endmodule
module ram_2x259 (
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
	output wire [258:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [258:0] W0_data;
	reg [258:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 259'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	output wire io_deq_bits_last;
	wire [258:0] _ram_ext_R0_data;
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
	ram_2x259 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_resp, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[257:256];
	assign io_deq_bits_last = _ram_ext_R0_data[258];
endmodule
module ResponseBuffer (
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
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_ar_bits_size,
	m_axi_ar_bits_burst,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_data,
	m_axi_r_bits_resp,
	m_axi_r_bits_last
);
	input clock;
	input reset;
	output wire s_axi_ar_ready;
	input s_axi_ar_valid;
	input [63:0] s_axi_ar_bits_addr;
	input [3:0] s_axi_ar_bits_len;
	input [2:0] s_axi_ar_bits_size;
	input [1:0] s_axi_ar_bits_burst;
	input s_axi_r_ready;
	output wire s_axi_r_valid;
	output wire [255:0] s_axi_r_bits_data;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [63:0] m_axi_ar_bits_addr;
	output wire [3:0] m_axi_ar_bits_len;
	output wire [2:0] m_axi_ar_bits_size;
	output wire [1:0] m_axi_ar_bits_burst;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input [255:0] m_axi_r_bits_data;
	input [1:0] m_axi_r_bits_resp;
	input m_axi_r_bits_last;
	wire _read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _read_arrival1_sourceBuffer_io_deq_valid;
	wire [255:0] _read_arrival1_sourceBuffer_io_deq_bits_data;
	wire [1:0] _read_arrival1_sourceBuffer_io_deq_bits_resp;
	wire _read_arrival1_sourceBuffer_io_deq_bits_last;
	wire _read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire [5:0] _read_ctrR_io_left;
	wire _read_arrival0_T = _read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & s_axi_ar_valid;
	wire [5:0] _GEN = {1'h0, {1'h0, s_axi_ar_bits_len} + 5'h01};
	wire _read_arrival0_T_1 = _read_ctrR_io_left >= _GEN;
	wire s_axi_ar_ready_0 = _read_arrival0_T & _read_arrival0_T_1;
	wire read_arrival1_result_ready = _read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready & _read_arrival1_sourceBuffer_io_deq_valid;
	CounterEx read_ctrR(
		.clock(clock),
		.reset(reset),
		.io_up((_read_arrival0_T & _read_arrival0_T_1 ? _GEN : 6'h00)),
		.io_down({5'h00, read_arrival1_result_ready}),
		.io_left(_read_ctrR_io_left)
	);
	Queue2_ReadAddressChannel read_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(s_axi_ar_ready_0),
		.io_enq_bits_addr(s_axi_ar_bits_addr),
		.io_enq_bits_len(s_axi_ar_bits_len),
		.io_enq_bits_size(s_axi_ar_bits_size),
		.io_enq_bits_burst(s_axi_ar_bits_burst),
		.io_deq_ready(m_axi_ar_ready),
		.io_deq_valid(m_axi_ar_valid),
		.io_deq_bits_addr(m_axi_ar_bits_addr),
		.io_deq_bits_len(m_axi_ar_bits_len),
		.io_deq_bits_size(m_axi_ar_bits_size),
		.io_deq_bits_burst(m_axi_ar_bits_burst)
	);
	Queue32_ReadDataChannel read_arrival1_sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(m_axi_r_ready),
		.io_enq_valid(m_axi_r_valid),
		.io_enq_bits_data(m_axi_r_bits_data),
		.io_enq_bits_resp(m_axi_r_bits_resp),
		.io_enq_bits_last(m_axi_r_bits_last),
		.io_deq_ready(read_arrival1_result_ready),
		.io_deq_valid(_read_arrival1_sourceBuffer_io_deq_valid),
		.io_deq_bits_data(_read_arrival1_sourceBuffer_io_deq_bits_data),
		.io_deq_bits_resp(_read_arrival1_sourceBuffer_io_deq_bits_resp),
		.io_deq_bits_last(_read_arrival1_sourceBuffer_io_deq_bits_last)
	);
	Queue2_ReadDataChannel read_arrival1_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(read_arrival1_result_ready),
		.io_enq_bits_data(_read_arrival1_sourceBuffer_io_deq_bits_data),
		.io_enq_bits_resp(_read_arrival1_sourceBuffer_io_deq_bits_resp),
		.io_enq_bits_last(_read_arrival1_sourceBuffer_io_deq_bits_last),
		.io_deq_ready(s_axi_r_ready),
		.io_deq_valid(s_axi_r_valid),
		.io_deq_bits_data(s_axi_r_bits_data),
		.io_deq_bits_resp(),
		.io_deq_bits_last()
	);
	assign s_axi_ar_ready = s_axi_ar_ready_0;
endmodule
module ram_16x73 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [72:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [72:0] W0_data;
	reg [72:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [95:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 73'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue16_ReadAddressChannel (
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
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [72:0] _ram_ext_R0_data;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_deq == do_enq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x73 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[67:64];
	assign io_deq_bits_size = _ram_ext_R0_data[70:68];
	assign io_deq_bits_burst = _ram_ext_R0_data[72:71];
endmodule
module ram_16x259 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [258:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [258:0] W0_data;
	reg [258:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 259'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue16_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	output wire io_deq_bits_last;
	wire [258:0] _ram_ext_R0_data;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x259 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_resp, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[257:256];
	assign io_deq_bits_last = _ram_ext_R0_data[258];
endmodule
module Queue16_WriteAddressChannel (
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
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [72:0] _ram_ext_R0_data;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_deq == do_enq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x73 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[67:64];
	assign io_deq_bits_size = _ram_ext_R0_data[70:68];
	assign io_deq_bits_burst = _ram_ext_R0_data[72:71];
endmodule
module ram_16x289 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [288:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [288:0] W0_data;
	reg [288:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [319:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 289'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue16_WriteDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_strb,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_strb,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [31:0] io_enq_bits_strb;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [31:0] io_deq_bits_strb;
	output wire io_deq_bits_last;
	wire [288:0] _ram_ext_R0_data;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_deq == do_enq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x289 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_strb, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_strb = _ram_ext_R0_data[287:256];
	assign io_deq_bits_last = _ram_ext_R0_data[288];
endmodule
module ram_16x2 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [1:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [1:0] W0_data;
	reg [1:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 2'bxx);
endmodule
module Queue16_WriteResponseChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_resp,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_resp;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_resp;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x2 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits_resp),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits_resp)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module ram_2x75 (
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
	output wire [74:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [74:0] W0_data;
	reg [74:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [95:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 75'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadAddressChannel_6 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_id,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_id,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_id;
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_id;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [74:0] _ram_ext_R0_data;
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
	ram_2x75 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr, io_enq_bits_id})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_id = _ram_ext_R0_data[1:0];
	assign io_deq_bits_addr = _ram_ext_R0_data[65:2];
	assign io_deq_bits_len = _ram_ext_R0_data[69:66];
	assign io_deq_bits_size = _ram_ext_R0_data[72:70];
	assign io_deq_bits_burst = _ram_ext_R0_data[74:73];
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
module Queue2_UInt2 (
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
	input [1:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits;
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
		.R0_data(io_deq_bits),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module elasticBasicArbiter (
	clock,
	reset,
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits_addr,
	io_sources_0_bits_len,
	io_sources_0_bits_size,
	io_sources_0_bits_burst,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits_addr,
	io_sources_1_bits_len,
	io_sources_1_bits_size,
	io_sources_1_bits_burst,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits_addr,
	io_sources_2_bits_len,
	io_sources_2_bits_size,
	io_sources_2_bits_burst,
	io_sources_3_ready,
	io_sources_3_valid,
	io_sources_3_bits_addr,
	io_sources_3_bits_len,
	io_sources_3_bits_size,
	io_sources_3_bits_burst,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits_id,
	io_sink_bits_addr,
	io_sink_bits_len,
	io_sink_bits_size,
	io_sink_bits_burst
);
	input clock;
	input reset;
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [63:0] io_sources_0_bits_addr;
	input [3:0] io_sources_0_bits_len;
	input [2:0] io_sources_0_bits_size;
	input [1:0] io_sources_0_bits_burst;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [63:0] io_sources_1_bits_addr;
	input [3:0] io_sources_1_bits_len;
	input [2:0] io_sources_1_bits_size;
	input [1:0] io_sources_1_bits_burst;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [63:0] io_sources_2_bits_addr;
	input [3:0] io_sources_2_bits_len;
	input [2:0] io_sources_2_bits_size;
	input [1:0] io_sources_2_bits_burst;
	output wire io_sources_3_ready;
	input io_sources_3_valid;
	input [63:0] io_sources_3_bits_addr;
	input [3:0] io_sources_3_bits_len;
	input [2:0] io_sources_3_bits_size;
	input [1:0] io_sources_3_bits_burst;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [1:0] io_sink_bits_id;
	output wire [63:0] io_sink_bits_addr;
	output wire [3:0] io_sink_bits_len;
	output wire [2:0] io_sink_bits_size;
	output wire [1:0] io_sink_bits_burst;
	wire _select_sinkBuffer_io_enq_ready;
	wire _sink_sinkBuffer_io_enq_ready;
	wire [7:0] _GEN = 8'he4;
	reg [1:0] chooser_lastChoice;
	wire _chooser_rrChoice_T_4 = (chooser_lastChoice == 2'h0) & io_sources_1_valid;
	wire [1:0] _chooser_rrChoice_T_9 = {1'h1, ~(~chooser_lastChoice[1] & io_sources_2_valid)};
	wire [1:0] chooser_rrChoice = (&chooser_lastChoice ? 2'h0 : (_chooser_rrChoice_T_4 ? 2'h1 : _chooser_rrChoice_T_9));
	wire [1:0] chooser_priorityChoice = (io_sources_0_valid ? 2'h0 : (io_sources_1_valid ? 2'h1 : {1'h1, ~io_sources_2_valid}));
	wire [3:0] _GEN_0 = {io_sources_3_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [1:0] choice = (_GEN_0[chooser_rrChoice] ? chooser_rrChoice : chooser_priorityChoice);
	wire [255:0] _GEN_1 = {io_sources_3_bits_addr, io_sources_2_bits_addr, io_sources_1_bits_addr, io_sources_0_bits_addr};
	wire [15:0] _GEN_2 = {io_sources_3_bits_len, io_sources_2_bits_len, io_sources_1_bits_len, io_sources_0_bits_len};
	wire [11:0] _GEN_3 = {io_sources_3_bits_size, io_sources_2_bits_size, io_sources_1_bits_size, io_sources_0_bits_size};
	wire [7:0] _GEN_4 = {io_sources_3_bits_burst, io_sources_2_bits_burst, io_sources_1_bits_burst, io_sources_0_bits_burst};
	wire fire = (_GEN_0[choice] & _sink_sinkBuffer_io_enq_ready) & _select_sinkBuffer_io_enq_ready;
	always @(posedge clock)
		if (reset)
			chooser_lastChoice <= 2'h0;
		else if (fire) begin
			if (_GEN_0[chooser_rrChoice]) begin
				if (&chooser_lastChoice)
					chooser_lastChoice <= 2'h0;
				else if (_chooser_rrChoice_T_4)
					chooser_lastChoice <= 2'h1;
				else
					chooser_lastChoice <= _chooser_rrChoice_T_9;
			end
			else
				chooser_lastChoice <= chooser_priorityChoice;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_ReadAddressChannel_6 sink_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sink_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits_id(_GEN[choice * 2+:2]),
		.io_enq_bits_addr(_GEN_1[choice * 64+:64]),
		.io_enq_bits_len(_GEN_2[choice * 4+:4]),
		.io_enq_bits_size(_GEN_3[choice * 3+:3]),
		.io_enq_bits_burst(_GEN_4[choice * 2+:2]),
		.io_deq_ready(io_sink_ready),
		.io_deq_valid(io_sink_valid),
		.io_deq_bits_id(io_sink_bits_id),
		.io_deq_bits_addr(io_sink_bits_addr),
		.io_deq_bits_len(io_sink_bits_len),
		.io_deq_bits_size(io_sink_bits_size),
		.io_deq_bits_burst(io_sink_bits_burst)
	);
	Queue2_UInt2 select_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_select_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits(choice),
		.io_deq_ready(1'h1),
		.io_deq_valid(),
		.io_deq_bits()
	);
	assign io_sources_0_ready = fire & (choice == 2'h0);
	assign io_sources_1_ready = fire & (choice == 2'h1);
	assign io_sources_2_ready = fire & (choice == 2'h2);
	assign io_sources_3_ready = fire & (&choice);
endmodule
module elasticDemux (
	io_source_ready,
	io_source_valid,
	io_source_bits_data,
	io_source_bits_resp,
	io_source_bits_last,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits_data,
	io_sinks_0_bits_resp,
	io_sinks_0_bits_last,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits_data,
	io_sinks_1_bits_resp,
	io_sinks_1_bits_last,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits_data,
	io_sinks_2_bits_resp,
	io_sinks_2_bits_last,
	io_sinks_3_ready,
	io_sinks_3_valid,
	io_sinks_3_bits_data,
	io_sinks_3_bits_resp,
	io_sinks_3_bits_last,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [255:0] io_source_bits_data;
	input [1:0] io_source_bits_resp;
	input io_source_bits_last;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [255:0] io_sinks_0_bits_data;
	output wire [1:0] io_sinks_0_bits_resp;
	output wire io_sinks_0_bits_last;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [255:0] io_sinks_1_bits_data;
	output wire [1:0] io_sinks_1_bits_resp;
	output wire io_sinks_1_bits_last;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [255:0] io_sinks_2_bits_data;
	output wire [1:0] io_sinks_2_bits_resp;
	output wire io_sinks_2_bits_last;
	input io_sinks_3_ready;
	output wire io_sinks_3_valid;
	output wire [255:0] io_sinks_3_bits_data;
	output wire [1:0] io_sinks_3_bits_resp;
	output wire io_sinks_3_bits_last;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire [3:0] _GEN = {io_sinks_3_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & (io_select_bits == 2'h0);
	assign io_sinks_0_bits_data = io_source_bits_data;
	assign io_sinks_0_bits_resp = io_source_bits_resp;
	assign io_sinks_0_bits_last = io_source_bits_last;
	assign io_sinks_1_valid = valid & (io_select_bits == 2'h1);
	assign io_sinks_1_bits_data = io_source_bits_data;
	assign io_sinks_1_bits_resp = io_source_bits_resp;
	assign io_sinks_1_bits_last = io_source_bits_last;
	assign io_sinks_2_valid = valid & (io_select_bits == 2'h2);
	assign io_sinks_2_bits_data = io_source_bits_data;
	assign io_sinks_2_bits_resp = io_source_bits_resp;
	assign io_sinks_2_bits_last = io_source_bits_last;
	assign io_sinks_3_valid = valid & (&io_select_bits);
	assign io_sinks_3_bits_data = io_source_bits_data;
	assign io_sinks_3_bits_resp = io_source_bits_resp;
	assign io_sinks_3_bits_last = io_source_bits_last;
	assign io_select_ready = fire;
endmodule
module ram_32x2 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [4:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [1:0] R0_data;
	input [4:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [1:0] W0_data;
	reg [1:0] Memory [0:31];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 2'bxx);
endmodule
module Queue32_UInt2 (
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
	input [1:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits;
	wire io_enq_ready_0;
	wire [1:0] _ram_ext_R0_data;
	reg [4:0] enq_ptr_value;
	reg [4:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire io_deq_valid_0 = io_enq_valid | ~empty;
	wire do_deq = (~empty & io_deq_ready) & io_deq_valid_0;
	wire do_enq = (~(empty & io_deq_ready) & io_enq_ready_0) & io_enq_valid;
	assign io_enq_ready_0 = io_deq_ready | ~(ptr_match & maybe_full);
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 5'h00;
			deq_ptr_value <= 5'h00;
			maybe_full <= 1'h0;
		end
		else begin
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 5'h01;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 5'h01;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	ram_32x2 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = io_enq_ready_0;
	assign io_deq_valid = io_deq_valid_0;
	assign io_deq_bits = (empty ? io_enq_bits : _ram_ext_R0_data);
endmodule
module Queue2_WriteAddressChannel_1 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_id,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_id,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_id;
	input [63:0] io_enq_bits_addr;
	input [3:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_id;
	output wire [63:0] io_deq_bits_addr;
	output wire [3:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	wire [74:0] _ram_ext_R0_data;
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
	ram_2x75 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr, io_enq_bits_id})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_id = _ram_ext_R0_data[1:0];
	assign io_deq_bits_addr = _ram_ext_R0_data[65:2];
	assign io_deq_bits_len = _ram_ext_R0_data[69:66];
	assign io_deq_bits_size = _ram_ext_R0_data[72:70];
	assign io_deq_bits_burst = _ram_ext_R0_data[74:73];
endmodule
module elasticBasicArbiter_1 (
	clock,
	reset,
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits_addr,
	io_sources_0_bits_len,
	io_sources_0_bits_size,
	io_sources_0_bits_burst,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits_addr,
	io_sources_1_bits_len,
	io_sources_1_bits_size,
	io_sources_1_bits_burst,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits_addr,
	io_sources_2_bits_len,
	io_sources_2_bits_size,
	io_sources_2_bits_burst,
	io_sources_3_ready,
	io_sources_3_valid,
	io_sources_3_bits_addr,
	io_sources_3_bits_len,
	io_sources_3_bits_size,
	io_sources_3_bits_burst,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits_id,
	io_sink_bits_addr,
	io_sink_bits_len,
	io_sink_bits_size,
	io_sink_bits_burst,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	input clock;
	input reset;
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [63:0] io_sources_0_bits_addr;
	input [3:0] io_sources_0_bits_len;
	input [2:0] io_sources_0_bits_size;
	input [1:0] io_sources_0_bits_burst;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [63:0] io_sources_1_bits_addr;
	input [3:0] io_sources_1_bits_len;
	input [2:0] io_sources_1_bits_size;
	input [1:0] io_sources_1_bits_burst;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [63:0] io_sources_2_bits_addr;
	input [3:0] io_sources_2_bits_len;
	input [2:0] io_sources_2_bits_size;
	input [1:0] io_sources_2_bits_burst;
	output wire io_sources_3_ready;
	input io_sources_3_valid;
	input [63:0] io_sources_3_bits_addr;
	input [3:0] io_sources_3_bits_len;
	input [2:0] io_sources_3_bits_size;
	input [1:0] io_sources_3_bits_burst;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [1:0] io_sink_bits_id;
	output wire [63:0] io_sink_bits_addr;
	output wire [3:0] io_sink_bits_len;
	output wire [2:0] io_sink_bits_size;
	output wire [1:0] io_sink_bits_burst;
	input io_select_ready;
	output wire io_select_valid;
	output wire [1:0] io_select_bits;
	wire _select_sinkBuffer_io_enq_ready;
	wire _sink_sinkBuffer_io_enq_ready;
	wire [7:0] _GEN = 8'he4;
	reg [1:0] chooser_lastChoice;
	wire _chooser_rrChoice_T_4 = (chooser_lastChoice == 2'h0) & io_sources_1_valid;
	wire [1:0] _chooser_rrChoice_T_9 = {1'h1, ~(~chooser_lastChoice[1] & io_sources_2_valid)};
	wire [1:0] chooser_rrChoice = (&chooser_lastChoice ? 2'h0 : (_chooser_rrChoice_T_4 ? 2'h1 : _chooser_rrChoice_T_9));
	wire [1:0] chooser_priorityChoice = (io_sources_0_valid ? 2'h0 : (io_sources_1_valid ? 2'h1 : {1'h1, ~io_sources_2_valid}));
	wire [3:0] _GEN_0 = {io_sources_3_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [1:0] choice = (_GEN_0[chooser_rrChoice] ? chooser_rrChoice : chooser_priorityChoice);
	wire [255:0] _GEN_1 = {io_sources_3_bits_addr, io_sources_2_bits_addr, io_sources_1_bits_addr, io_sources_0_bits_addr};
	wire [15:0] _GEN_2 = {io_sources_3_bits_len, io_sources_2_bits_len, io_sources_1_bits_len, io_sources_0_bits_len};
	wire [11:0] _GEN_3 = {io_sources_3_bits_size, io_sources_2_bits_size, io_sources_1_bits_size, io_sources_0_bits_size};
	wire [7:0] _GEN_4 = {io_sources_3_bits_burst, io_sources_2_bits_burst, io_sources_1_bits_burst, io_sources_0_bits_burst};
	wire fire = (_GEN_0[choice] & _sink_sinkBuffer_io_enq_ready) & _select_sinkBuffer_io_enq_ready;
	always @(posedge clock)
		if (reset)
			chooser_lastChoice <= 2'h0;
		else if (fire) begin
			if (_GEN_0[chooser_rrChoice]) begin
				if (&chooser_lastChoice)
					chooser_lastChoice <= 2'h0;
				else if (_chooser_rrChoice_T_4)
					chooser_lastChoice <= 2'h1;
				else
					chooser_lastChoice <= _chooser_rrChoice_T_9;
			end
			else
				chooser_lastChoice <= chooser_priorityChoice;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_WriteAddressChannel_1 sink_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sink_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits_id(_GEN[choice * 2+:2]),
		.io_enq_bits_addr(_GEN_1[choice * 64+:64]),
		.io_enq_bits_len(_GEN_2[choice * 4+:4]),
		.io_enq_bits_size(_GEN_3[choice * 3+:3]),
		.io_enq_bits_burst(_GEN_4[choice * 2+:2]),
		.io_deq_ready(io_sink_ready),
		.io_deq_valid(io_sink_valid),
		.io_deq_bits_id(io_sink_bits_id),
		.io_deq_bits_addr(io_sink_bits_addr),
		.io_deq_bits_len(io_sink_bits_len),
		.io_deq_bits_size(io_sink_bits_size),
		.io_deq_bits_burst(io_sink_bits_burst)
	);
	Queue2_UInt2 select_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_select_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits(choice),
		.io_deq_ready(io_select_ready),
		.io_deq_valid(io_select_valid),
		.io_deq_bits(io_select_bits)
	);
	assign io_sources_0_ready = fire & (choice == 2'h0);
	assign io_sources_1_ready = fire & (choice == 2'h1);
	assign io_sources_2_ready = fire & (choice == 2'h2);
	assign io_sources_3_ready = fire & (&choice);
endmodule
module elasticMux (
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits_data,
	io_sources_0_bits_strb,
	io_sources_0_bits_last,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits_data,
	io_sources_1_bits_strb,
	io_sources_1_bits_last,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits_data,
	io_sources_2_bits_strb,
	io_sources_2_bits_last,
	io_sources_3_ready,
	io_sources_3_valid,
	io_sources_3_bits_data,
	io_sources_3_bits_strb,
	io_sources_3_bits_last,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits_data,
	io_sink_bits_strb,
	io_sink_bits_last,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [255:0] io_sources_0_bits_data;
	input [31:0] io_sources_0_bits_strb;
	input io_sources_0_bits_last;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [255:0] io_sources_1_bits_data;
	input [31:0] io_sources_1_bits_strb;
	input io_sources_1_bits_last;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [255:0] io_sources_2_bits_data;
	input [31:0] io_sources_2_bits_strb;
	input io_sources_2_bits_last;
	output wire io_sources_3_ready;
	input io_sources_3_valid;
	input [255:0] io_sources_3_bits_data;
	input [31:0] io_sources_3_bits_strb;
	input io_sources_3_bits_last;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [255:0] io_sink_bits_data;
	output wire [31:0] io_sink_bits_strb;
	output wire io_sink_bits_last;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire [3:0] _GEN = {io_sources_3_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [1023:0] _GEN_0 = {io_sources_3_bits_data, io_sources_2_bits_data, io_sources_1_bits_data, io_sources_0_bits_data};
	wire [127:0] _GEN_1 = {io_sources_3_bits_strb, io_sources_2_bits_strb, io_sources_1_bits_strb, io_sources_0_bits_strb};
	wire [3:0] _GEN_2 = {io_sources_3_bits_last, io_sources_2_bits_last, io_sources_1_bits_last, io_sources_0_bits_last};
	wire valid = io_select_valid & _GEN[io_select_bits];
	wire fire = valid & io_sink_ready;
	assign io_sources_0_ready = fire & (io_select_bits == 2'h0);
	assign io_sources_1_ready = fire & (io_select_bits == 2'h1);
	assign io_sources_2_ready = fire & (io_select_bits == 2'h2);
	assign io_sources_3_ready = fire & (&io_select_bits);
	assign io_sink_valid = valid;
	assign io_sink_bits_data = _GEN_0[io_select_bits * 256+:256];
	assign io_sink_bits_strb = _GEN_1[io_select_bits * 32+:32];
	assign io_sink_bits_last = _GEN_2[io_select_bits];
	assign io_select_ready = fire & _GEN_2[io_select_bits];
endmodule
module elasticDemux_1 (
	io_source_ready,
	io_source_valid,
	io_source_bits_resp,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits_resp,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits_resp,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits_resp,
	io_sinks_3_ready,
	io_sinks_3_valid,
	io_sinks_3_bits_resp,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [1:0] io_source_bits_resp;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [1:0] io_sinks_0_bits_resp;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [1:0] io_sinks_1_bits_resp;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [1:0] io_sinks_2_bits_resp;
	input io_sinks_3_ready;
	output wire io_sinks_3_valid;
	output wire [1:0] io_sinks_3_bits_resp;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire [3:0] _GEN = {io_sinks_3_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & (io_select_bits == 2'h0);
	assign io_sinks_0_bits_resp = io_source_bits_resp;
	assign io_sinks_1_valid = valid & (io_select_bits == 2'h1);
	assign io_sinks_1_bits_resp = io_source_bits_resp;
	assign io_sinks_2_valid = valid & (io_select_bits == 2'h2);
	assign io_sinks_2_bits_resp = io_source_bits_resp;
	assign io_sinks_3_valid = valid & (&io_select_bits);
	assign io_sinks_3_bits_resp = io_source_bits_resp;
	assign io_select_ready = fire;
endmodule
module Mux (
	clock,
	reset,
	s_axi_0_ar_ready,
	s_axi_0_ar_valid,
	s_axi_0_ar_bits_addr,
	s_axi_0_ar_bits_len,
	s_axi_0_ar_bits_size,
	s_axi_0_ar_bits_burst,
	s_axi_0_r_ready,
	s_axi_0_r_valid,
	s_axi_0_r_bits_data,
	s_axi_0_r_bits_resp,
	s_axi_0_r_bits_last,
	s_axi_1_ar_ready,
	s_axi_1_ar_valid,
	s_axi_1_ar_bits_addr,
	s_axi_1_ar_bits_len,
	s_axi_1_ar_bits_size,
	s_axi_1_ar_bits_burst,
	s_axi_1_r_ready,
	s_axi_1_r_valid,
	s_axi_1_r_bits_data,
	s_axi_1_r_bits_resp,
	s_axi_1_r_bits_last,
	s_axi_2_ar_ready,
	s_axi_2_ar_valid,
	s_axi_2_ar_bits_addr,
	s_axi_2_ar_bits_len,
	s_axi_2_ar_bits_size,
	s_axi_2_ar_bits_burst,
	s_axi_2_r_ready,
	s_axi_2_r_valid,
	s_axi_2_r_bits_data,
	s_axi_2_r_bits_resp,
	s_axi_2_r_bits_last,
	s_axi_3_aw_ready,
	s_axi_3_aw_valid,
	s_axi_3_aw_bits_addr,
	s_axi_3_aw_bits_len,
	s_axi_3_aw_bits_size,
	s_axi_3_aw_bits_burst,
	s_axi_3_w_ready,
	s_axi_3_w_valid,
	s_axi_3_w_bits_data,
	s_axi_3_w_bits_strb,
	s_axi_3_w_bits_last,
	s_axi_3_b_ready,
	s_axi_3_b_valid,
	s_axi_3_b_bits_resp,
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_id,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_ar_bits_size,
	m_axi_ar_bits_burst,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_id,
	m_axi_r_bits_data,
	m_axi_r_bits_resp,
	m_axi_r_bits_last,
	m_axi_aw_ready,
	m_axi_aw_valid,
	m_axi_aw_bits_id,
	m_axi_aw_bits_addr,
	m_axi_aw_bits_len,
	m_axi_aw_bits_size,
	m_axi_aw_bits_burst,
	m_axi_w_ready,
	m_axi_w_valid,
	m_axi_w_bits_data,
	m_axi_w_bits_strb,
	m_axi_w_bits_last,
	m_axi_b_ready,
	m_axi_b_valid,
	m_axi_b_bits_id,
	m_axi_b_bits_resp
);
	input clock;
	input reset;
	output wire s_axi_0_ar_ready;
	input s_axi_0_ar_valid;
	input [63:0] s_axi_0_ar_bits_addr;
	input [3:0] s_axi_0_ar_bits_len;
	input [2:0] s_axi_0_ar_bits_size;
	input [1:0] s_axi_0_ar_bits_burst;
	input s_axi_0_r_ready;
	output wire s_axi_0_r_valid;
	output wire [255:0] s_axi_0_r_bits_data;
	output wire [1:0] s_axi_0_r_bits_resp;
	output wire s_axi_0_r_bits_last;
	output wire s_axi_1_ar_ready;
	input s_axi_1_ar_valid;
	input [63:0] s_axi_1_ar_bits_addr;
	input [3:0] s_axi_1_ar_bits_len;
	input [2:0] s_axi_1_ar_bits_size;
	input [1:0] s_axi_1_ar_bits_burst;
	input s_axi_1_r_ready;
	output wire s_axi_1_r_valid;
	output wire [255:0] s_axi_1_r_bits_data;
	output wire [1:0] s_axi_1_r_bits_resp;
	output wire s_axi_1_r_bits_last;
	output wire s_axi_2_ar_ready;
	input s_axi_2_ar_valid;
	input [63:0] s_axi_2_ar_bits_addr;
	input [3:0] s_axi_2_ar_bits_len;
	input [2:0] s_axi_2_ar_bits_size;
	input [1:0] s_axi_2_ar_bits_burst;
	input s_axi_2_r_ready;
	output wire s_axi_2_r_valid;
	output wire [255:0] s_axi_2_r_bits_data;
	output wire [1:0] s_axi_2_r_bits_resp;
	output wire s_axi_2_r_bits_last;
	output wire s_axi_3_aw_ready;
	input s_axi_3_aw_valid;
	input [63:0] s_axi_3_aw_bits_addr;
	input [3:0] s_axi_3_aw_bits_len;
	input [2:0] s_axi_3_aw_bits_size;
	input [1:0] s_axi_3_aw_bits_burst;
	output wire s_axi_3_w_ready;
	input s_axi_3_w_valid;
	input [255:0] s_axi_3_w_bits_data;
	input [31:0] s_axi_3_w_bits_strb;
	input s_axi_3_w_bits_last;
	input s_axi_3_b_ready;
	output wire s_axi_3_b_valid;
	output wire [1:0] s_axi_3_b_bits_resp;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [1:0] m_axi_ar_bits_id;
	output wire [63:0] m_axi_ar_bits_addr;
	output wire [3:0] m_axi_ar_bits_len;
	output wire [2:0] m_axi_ar_bits_size;
	output wire [1:0] m_axi_ar_bits_burst;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input [1:0] m_axi_r_bits_id;
	input [255:0] m_axi_r_bits_data;
	input [1:0] m_axi_r_bits_resp;
	input m_axi_r_bits_last;
	input m_axi_aw_ready;
	output wire m_axi_aw_valid;
	output wire [1:0] m_axi_aw_bits_id;
	output wire [63:0] m_axi_aw_bits_addr;
	output wire [3:0] m_axi_aw_bits_len;
	output wire [2:0] m_axi_aw_bits_size;
	output wire [1:0] m_axi_aw_bits_burst;
	input m_axi_w_ready;
	output wire m_axi_w_valid;
	output wire [255:0] m_axi_w_bits_data;
	output wire [31:0] m_axi_w_bits_strb;
	output wire m_axi_w_bits_last;
	output wire m_axi_b_ready;
	input m_axi_b_valid;
	input [1:0] m_axi_b_bits_id;
	input [1:0] m_axi_b_bits_resp;
	wire _write_demux_io_source_ready;
	wire _write_demux_io_sinks_0_valid;
	wire [1:0] _write_demux_io_sinks_0_bits_resp;
	wire _write_demux_io_sinks_1_valid;
	wire [1:0] _write_demux_io_sinks_1_bits_resp;
	wire _write_demux_io_sinks_2_valid;
	wire [1:0] _write_demux_io_sinks_2_bits_resp;
	wire _write_demux_io_sinks_3_valid;
	wire [1:0] _write_demux_io_sinks_3_bits_resp;
	wire _write_demux_io_select_ready;
	wire _write_mux_io_sources_0_ready;
	wire _write_mux_io_sources_1_ready;
	wire _write_mux_io_sources_2_ready;
	wire _write_mux_io_sources_3_ready;
	wire _write_mux_io_select_ready;
	wire _write_arbiter_io_sources_0_ready;
	wire _write_arbiter_io_sources_1_ready;
	wire _write_arbiter_io_sources_2_ready;
	wire _write_arbiter_io_sources_3_ready;
	wire _write_arbiter_io_select_valid;
	wire [1:0] _write_arbiter_io_select_bits;
	wire _write_portQueue_io_enq_ready;
	wire _write_portQueue_io_deq_valid;
	wire [1:0] _write_portQueue_io_deq_bits;
	wire _read_demux_io_source_ready;
	wire _read_demux_io_sinks_0_valid;
	wire [255:0] _read_demux_io_sinks_0_bits_data;
	wire [1:0] _read_demux_io_sinks_0_bits_resp;
	wire _read_demux_io_sinks_0_bits_last;
	wire _read_demux_io_sinks_1_valid;
	wire [255:0] _read_demux_io_sinks_1_bits_data;
	wire [1:0] _read_demux_io_sinks_1_bits_resp;
	wire _read_demux_io_sinks_1_bits_last;
	wire _read_demux_io_sinks_2_valid;
	wire [255:0] _read_demux_io_sinks_2_bits_data;
	wire [1:0] _read_demux_io_sinks_2_bits_resp;
	wire _read_demux_io_sinks_2_bits_last;
	wire _read_demux_io_sinks_3_valid;
	wire [255:0] _read_demux_io_sinks_3_bits_data;
	wire [1:0] _read_demux_io_sinks_3_bits_resp;
	wire _read_demux_io_sinks_3_bits_last;
	wire _read_demux_io_select_ready;
	wire _read_arbiter_io_sources_0_ready;
	wire _read_arbiter_io_sources_1_ready;
	wire _read_arbiter_io_sources_2_ready;
	wire _read_arbiter_io_sources_3_ready;
	wire _s_axi__buffered_sinkBuffer_7_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_11_io_deq_valid;
	wire [255:0] _s_axi__buffered_sourceBuffer_11_io_deq_bits_data;
	wire [31:0] _s_axi__buffered_sourceBuffer_11_io_deq_bits_strb;
	wire _s_axi__buffered_sourceBuffer_11_io_deq_bits_last;
	wire _s_axi__buffered_sourceBuffer_10_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_10_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_10_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_10_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_10_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_6_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_9_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_9_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_9_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_9_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_9_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_5_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_8_io_deq_valid;
	wire [255:0] _s_axi__buffered_sourceBuffer_8_io_deq_bits_data;
	wire [31:0] _s_axi__buffered_sourceBuffer_8_io_deq_bits_strb;
	wire _s_axi__buffered_sourceBuffer_8_io_deq_bits_last;
	wire _s_axi__buffered_sourceBuffer_7_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_7_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_7_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_7_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_7_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_4_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_6_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_6_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_6_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_6_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_6_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_3_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_5_io_deq_valid;
	wire [255:0] _s_axi__buffered_sourceBuffer_5_io_deq_bits_data;
	wire [31:0] _s_axi__buffered_sourceBuffer_5_io_deq_bits_strb;
	wire _s_axi__buffered_sourceBuffer_5_io_deq_bits_last;
	wire _s_axi__buffered_sourceBuffer_4_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_4_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_4_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_4_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_4_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_2_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_3_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_3_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_3_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_3_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_3_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_1_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_2_io_deq_valid;
	wire [255:0] _s_axi__buffered_sourceBuffer_2_io_deq_bits_data;
	wire [31:0] _s_axi__buffered_sourceBuffer_2_io_deq_bits_strb;
	wire _s_axi__buffered_sourceBuffer_2_io_deq_bits_last;
	wire _s_axi__buffered_sourceBuffer_1_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_1_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_1_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_1_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_1_io_deq_bits_burst;
	wire _s_axi__buffered_sinkBuffer_io_enq_ready;
	wire _s_axi__buffered_sourceBuffer_io_deq_valid;
	wire [63:0] _s_axi__buffered_sourceBuffer_io_deq_bits_addr;
	wire [3:0] _s_axi__buffered_sourceBuffer_io_deq_bits_len;
	wire [2:0] _s_axi__buffered_sourceBuffer_io_deq_bits_size;
	wire [1:0] _s_axi__buffered_sourceBuffer_io_deq_bits_burst;
	reg read_eagerFork_regs_0;
	reg read_eagerFork_regs_1;
	wire read_eagerFork_m_axi__r_ready_qual1_0 = _read_demux_io_source_ready | read_eagerFork_regs_0;
	wire read_eagerFork_m_axi__r_ready_qual1_1 = _read_demux_io_select_ready | read_eagerFork_regs_1;
	wire m_axi__r_ready = read_eagerFork_m_axi__r_ready_qual1_0 & read_eagerFork_m_axi__r_ready_qual1_1;
	reg write_eagerFork_regs_0;
	reg write_eagerFork_regs_1;
	wire write_eagerFork_m_axi__b_ready_qual1_0 = _write_demux_io_source_ready | write_eagerFork_regs_0;
	wire write_eagerFork_m_axi__b_ready_qual1_1 = _write_demux_io_select_ready | write_eagerFork_regs_1;
	wire m_axi__b_ready = write_eagerFork_m_axi__b_ready_qual1_0 & write_eagerFork_m_axi__b_ready_qual1_1;
	always @(posedge clock)
		if (reset) begin
			read_eagerFork_regs_0 <= 1'h0;
			read_eagerFork_regs_1 <= 1'h0;
			write_eagerFork_regs_0 <= 1'h0;
			write_eagerFork_regs_1 <= 1'h0;
		end
		else begin
			read_eagerFork_regs_0 <= (read_eagerFork_m_axi__r_ready_qual1_0 & m_axi_r_valid) & ~m_axi__r_ready;
			read_eagerFork_regs_1 <= (read_eagerFork_m_axi__r_ready_qual1_1 & m_axi_r_valid) & ~m_axi__r_ready;
			write_eagerFork_regs_0 <= (write_eagerFork_m_axi__b_ready_qual1_0 & m_axi_b_valid) & ~m_axi__b_ready;
			write_eagerFork_regs_1 <= (write_eagerFork_m_axi__b_ready_qual1_1 & m_axi_b_valid) & ~m_axi__b_ready;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue16_ReadAddressChannel s_axi__buffered_sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_0_ar_ready),
		.io_enq_valid(s_axi_0_ar_valid),
		.io_enq_bits_addr(s_axi_0_ar_bits_addr),
		.io_enq_bits_len(s_axi_0_ar_bits_len),
		.io_enq_bits_size(s_axi_0_ar_bits_size),
		.io_enq_bits_burst(s_axi_0_ar_bits_burst),
		.io_deq_ready(_read_arbiter_io_sources_0_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_io_deq_bits_burst)
	);
	Queue16_ReadDataChannel s_axi__buffered_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_io_enq_ready),
		.io_enq_valid(_read_demux_io_sinks_0_valid),
		.io_enq_bits_data(_read_demux_io_sinks_0_bits_data),
		.io_enq_bits_resp(_read_demux_io_sinks_0_bits_resp),
		.io_enq_bits_last(_read_demux_io_sinks_0_bits_last),
		.io_deq_ready(s_axi_0_r_ready),
		.io_deq_valid(s_axi_0_r_valid),
		.io_deq_bits_data(s_axi_0_r_bits_data),
		.io_deq_bits_resp(s_axi_0_r_bits_resp),
		.io_deq_bits_last(s_axi_0_r_bits_last)
	);
	Queue16_WriteAddressChannel s_axi__buffered_sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_addr(64'h0000000000000000),
		.io_enq_bits_len(4'h0),
		.io_enq_bits_size(3'h0),
		.io_enq_bits_burst(2'h0),
		.io_deq_ready(_write_arbiter_io_sources_0_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_1_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_1_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_1_io_deq_bits_burst)
	);
	Queue16_WriteDataChannel s_axi__buffered_sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_data(256'h0000000000000000000000000000000000000000000000000000000000000000),
		.io_enq_bits_strb(32'h00000000),
		.io_enq_bits_last(1'h0),
		.io_deq_ready(_write_mux_io_sources_0_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axi__buffered_sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axi__buffered_sourceBuffer_2_io_deq_bits_strb),
		.io_deq_bits_last(_s_axi__buffered_sourceBuffer_2_io_deq_bits_last)
	);
	Queue16_WriteResponseChannel s_axi__buffered_sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_write_demux_io_sinks_0_valid),
		.io_enq_bits_resp(_write_demux_io_sinks_0_bits_resp),
		.io_deq_ready(1'h0),
		.io_deq_valid(),
		.io_deq_bits_resp()
	);
	Queue16_ReadAddressChannel s_axi__buffered_sourceBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_1_ar_ready),
		.io_enq_valid(s_axi_1_ar_valid),
		.io_enq_bits_addr(s_axi_1_ar_bits_addr),
		.io_enq_bits_len(s_axi_1_ar_bits_len),
		.io_enq_bits_size(s_axi_1_ar_bits_size),
		.io_enq_bits_burst(s_axi_1_ar_bits_burst),
		.io_deq_ready(_read_arbiter_io_sources_1_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_3_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_3_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_3_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_3_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_3_io_deq_bits_burst)
	);
	Queue16_ReadDataChannel s_axi__buffered_sinkBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_2_io_enq_ready),
		.io_enq_valid(_read_demux_io_sinks_1_valid),
		.io_enq_bits_data(_read_demux_io_sinks_1_bits_data),
		.io_enq_bits_resp(_read_demux_io_sinks_1_bits_resp),
		.io_enq_bits_last(_read_demux_io_sinks_1_bits_last),
		.io_deq_ready(s_axi_1_r_ready),
		.io_deq_valid(s_axi_1_r_valid),
		.io_deq_bits_data(s_axi_1_r_bits_data),
		.io_deq_bits_resp(s_axi_1_r_bits_resp),
		.io_deq_bits_last(s_axi_1_r_bits_last)
	);
	Queue16_WriteAddressChannel s_axi__buffered_sourceBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_addr(64'h0000000000000000),
		.io_enq_bits_len(4'h0),
		.io_enq_bits_size(3'h0),
		.io_enq_bits_burst(2'h0),
		.io_deq_ready(_write_arbiter_io_sources_1_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_4_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_4_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_4_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_4_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_4_io_deq_bits_burst)
	);
	Queue16_WriteDataChannel s_axi__buffered_sourceBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_data(256'h0000000000000000000000000000000000000000000000000000000000000000),
		.io_enq_bits_strb(32'h00000000),
		.io_enq_bits_last(1'h0),
		.io_deq_ready(_write_mux_io_sources_1_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_5_io_deq_valid),
		.io_deq_bits_data(_s_axi__buffered_sourceBuffer_5_io_deq_bits_data),
		.io_deq_bits_strb(_s_axi__buffered_sourceBuffer_5_io_deq_bits_strb),
		.io_deq_bits_last(_s_axi__buffered_sourceBuffer_5_io_deq_bits_last)
	);
	Queue16_WriteResponseChannel s_axi__buffered_sinkBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_3_io_enq_ready),
		.io_enq_valid(_write_demux_io_sinks_1_valid),
		.io_enq_bits_resp(_write_demux_io_sinks_1_bits_resp),
		.io_deq_ready(1'h0),
		.io_deq_valid(),
		.io_deq_bits_resp()
	);
	Queue16_ReadAddressChannel s_axi__buffered_sourceBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_2_ar_ready),
		.io_enq_valid(s_axi_2_ar_valid),
		.io_enq_bits_addr(s_axi_2_ar_bits_addr),
		.io_enq_bits_len(s_axi_2_ar_bits_len),
		.io_enq_bits_size(s_axi_2_ar_bits_size),
		.io_enq_bits_burst(s_axi_2_ar_bits_burst),
		.io_deq_ready(_read_arbiter_io_sources_2_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_6_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_6_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_6_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_6_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_6_io_deq_bits_burst)
	);
	Queue16_ReadDataChannel s_axi__buffered_sinkBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_4_io_enq_ready),
		.io_enq_valid(_read_demux_io_sinks_2_valid),
		.io_enq_bits_data(_read_demux_io_sinks_2_bits_data),
		.io_enq_bits_resp(_read_demux_io_sinks_2_bits_resp),
		.io_enq_bits_last(_read_demux_io_sinks_2_bits_last),
		.io_deq_ready(s_axi_2_r_ready),
		.io_deq_valid(s_axi_2_r_valid),
		.io_deq_bits_data(s_axi_2_r_bits_data),
		.io_deq_bits_resp(s_axi_2_r_bits_resp),
		.io_deq_bits_last(s_axi_2_r_bits_last)
	);
	Queue16_WriteAddressChannel s_axi__buffered_sourceBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_addr(64'h0000000000000000),
		.io_enq_bits_len(4'h0),
		.io_enq_bits_size(3'h0),
		.io_enq_bits_burst(2'h0),
		.io_deq_ready(_write_arbiter_io_sources_2_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_7_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_7_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_7_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_7_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_7_io_deq_bits_burst)
	);
	Queue16_WriteDataChannel s_axi__buffered_sourceBuffer_8(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_data(256'h0000000000000000000000000000000000000000000000000000000000000000),
		.io_enq_bits_strb(32'h00000000),
		.io_enq_bits_last(1'h0),
		.io_deq_ready(_write_mux_io_sources_2_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_8_io_deq_valid),
		.io_deq_bits_data(_s_axi__buffered_sourceBuffer_8_io_deq_bits_data),
		.io_deq_bits_strb(_s_axi__buffered_sourceBuffer_8_io_deq_bits_strb),
		.io_deq_bits_last(_s_axi__buffered_sourceBuffer_8_io_deq_bits_last)
	);
	Queue16_WriteResponseChannel s_axi__buffered_sinkBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_5_io_enq_ready),
		.io_enq_valid(_write_demux_io_sinks_2_valid),
		.io_enq_bits_resp(_write_demux_io_sinks_2_bits_resp),
		.io_deq_ready(1'h0),
		.io_deq_valid(),
		.io_deq_bits_resp()
	);
	Queue16_ReadAddressChannel s_axi__buffered_sourceBuffer_9(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_addr(64'h0000000000000000),
		.io_enq_bits_len(4'h0),
		.io_enq_bits_size(3'h0),
		.io_enq_bits_burst(2'h0),
		.io_deq_ready(_read_arbiter_io_sources_3_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_9_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_9_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_9_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_9_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_9_io_deq_bits_burst)
	);
	Queue16_ReadDataChannel s_axi__buffered_sinkBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_6_io_enq_ready),
		.io_enq_valid(_read_demux_io_sinks_3_valid),
		.io_enq_bits_data(_read_demux_io_sinks_3_bits_data),
		.io_enq_bits_resp(_read_demux_io_sinks_3_bits_resp),
		.io_enq_bits_last(_read_demux_io_sinks_3_bits_last),
		.io_deq_ready(1'h0),
		.io_deq_valid(),
		.io_deq_bits_data(),
		.io_deq_bits_resp(),
		.io_deq_bits_last()
	);
	Queue16_WriteAddressChannel s_axi__buffered_sourceBuffer_10(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_3_aw_ready),
		.io_enq_valid(s_axi_3_aw_valid),
		.io_enq_bits_addr(s_axi_3_aw_bits_addr),
		.io_enq_bits_len(s_axi_3_aw_bits_len),
		.io_enq_bits_size(s_axi_3_aw_bits_size),
		.io_enq_bits_burst(s_axi_3_aw_bits_burst),
		.io_deq_ready(_write_arbiter_io_sources_3_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_10_io_deq_valid),
		.io_deq_bits_addr(_s_axi__buffered_sourceBuffer_10_io_deq_bits_addr),
		.io_deq_bits_len(_s_axi__buffered_sourceBuffer_10_io_deq_bits_len),
		.io_deq_bits_size(_s_axi__buffered_sourceBuffer_10_io_deq_bits_size),
		.io_deq_bits_burst(_s_axi__buffered_sourceBuffer_10_io_deq_bits_burst)
	);
	Queue16_WriteDataChannel s_axi__buffered_sourceBuffer_11(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axi_3_w_ready),
		.io_enq_valid(s_axi_3_w_valid),
		.io_enq_bits_data(s_axi_3_w_bits_data),
		.io_enq_bits_strb(s_axi_3_w_bits_strb),
		.io_enq_bits_last(s_axi_3_w_bits_last),
		.io_deq_ready(_write_mux_io_sources_3_ready),
		.io_deq_valid(_s_axi__buffered_sourceBuffer_11_io_deq_valid),
		.io_deq_bits_data(_s_axi__buffered_sourceBuffer_11_io_deq_bits_data),
		.io_deq_bits_strb(_s_axi__buffered_sourceBuffer_11_io_deq_bits_strb),
		.io_deq_bits_last(_s_axi__buffered_sourceBuffer_11_io_deq_bits_last)
	);
	Queue16_WriteResponseChannel s_axi__buffered_sinkBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axi__buffered_sinkBuffer_7_io_enq_ready),
		.io_enq_valid(_write_demux_io_sinks_3_valid),
		.io_enq_bits_resp(_write_demux_io_sinks_3_bits_resp),
		.io_deq_ready(s_axi_3_b_ready),
		.io_deq_valid(s_axi_3_b_valid),
		.io_deq_bits_resp(s_axi_3_b_bits_resp)
	);
	elasticBasicArbiter read_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_read_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_s_axi__buffered_sourceBuffer_io_deq_valid),
		.io_sources_0_bits_addr(_s_axi__buffered_sourceBuffer_io_deq_bits_addr),
		.io_sources_0_bits_len(_s_axi__buffered_sourceBuffer_io_deq_bits_len),
		.io_sources_0_bits_size(_s_axi__buffered_sourceBuffer_io_deq_bits_size),
		.io_sources_0_bits_burst(_s_axi__buffered_sourceBuffer_io_deq_bits_burst),
		.io_sources_1_ready(_read_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_s_axi__buffered_sourceBuffer_3_io_deq_valid),
		.io_sources_1_bits_addr(_s_axi__buffered_sourceBuffer_3_io_deq_bits_addr),
		.io_sources_1_bits_len(_s_axi__buffered_sourceBuffer_3_io_deq_bits_len),
		.io_sources_1_bits_size(_s_axi__buffered_sourceBuffer_3_io_deq_bits_size),
		.io_sources_1_bits_burst(_s_axi__buffered_sourceBuffer_3_io_deq_bits_burst),
		.io_sources_2_ready(_read_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_s_axi__buffered_sourceBuffer_6_io_deq_valid),
		.io_sources_2_bits_addr(_s_axi__buffered_sourceBuffer_6_io_deq_bits_addr),
		.io_sources_2_bits_len(_s_axi__buffered_sourceBuffer_6_io_deq_bits_len),
		.io_sources_2_bits_size(_s_axi__buffered_sourceBuffer_6_io_deq_bits_size),
		.io_sources_2_bits_burst(_s_axi__buffered_sourceBuffer_6_io_deq_bits_burst),
		.io_sources_3_ready(_read_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_s_axi__buffered_sourceBuffer_9_io_deq_valid),
		.io_sources_3_bits_addr(_s_axi__buffered_sourceBuffer_9_io_deq_bits_addr),
		.io_sources_3_bits_len(_s_axi__buffered_sourceBuffer_9_io_deq_bits_len),
		.io_sources_3_bits_size(_s_axi__buffered_sourceBuffer_9_io_deq_bits_size),
		.io_sources_3_bits_burst(_s_axi__buffered_sourceBuffer_9_io_deq_bits_burst),
		.io_sink_ready(m_axi_ar_ready),
		.io_sink_valid(m_axi_ar_valid),
		.io_sink_bits_id(m_axi_ar_bits_id),
		.io_sink_bits_addr(m_axi_ar_bits_addr),
		.io_sink_bits_len(m_axi_ar_bits_len),
		.io_sink_bits_size(m_axi_ar_bits_size),
		.io_sink_bits_burst(m_axi_ar_bits_burst)
	);
	elasticDemux read_demux(
		.io_source_ready(_read_demux_io_source_ready),
		.io_source_valid(m_axi_r_valid & ~read_eagerFork_regs_0),
		.io_source_bits_data(m_axi_r_bits_data),
		.io_source_bits_resp(m_axi_r_bits_resp),
		.io_source_bits_last(m_axi_r_bits_last),
		.io_sinks_0_ready(_s_axi__buffered_sinkBuffer_io_enq_ready),
		.io_sinks_0_valid(_read_demux_io_sinks_0_valid),
		.io_sinks_0_bits_data(_read_demux_io_sinks_0_bits_data),
		.io_sinks_0_bits_resp(_read_demux_io_sinks_0_bits_resp),
		.io_sinks_0_bits_last(_read_demux_io_sinks_0_bits_last),
		.io_sinks_1_ready(_s_axi__buffered_sinkBuffer_2_io_enq_ready),
		.io_sinks_1_valid(_read_demux_io_sinks_1_valid),
		.io_sinks_1_bits_data(_read_demux_io_sinks_1_bits_data),
		.io_sinks_1_bits_resp(_read_demux_io_sinks_1_bits_resp),
		.io_sinks_1_bits_last(_read_demux_io_sinks_1_bits_last),
		.io_sinks_2_ready(_s_axi__buffered_sinkBuffer_4_io_enq_ready),
		.io_sinks_2_valid(_read_demux_io_sinks_2_valid),
		.io_sinks_2_bits_data(_read_demux_io_sinks_2_bits_data),
		.io_sinks_2_bits_resp(_read_demux_io_sinks_2_bits_resp),
		.io_sinks_2_bits_last(_read_demux_io_sinks_2_bits_last),
		.io_sinks_3_ready(_s_axi__buffered_sinkBuffer_6_io_enq_ready),
		.io_sinks_3_valid(_read_demux_io_sinks_3_valid),
		.io_sinks_3_bits_data(_read_demux_io_sinks_3_bits_data),
		.io_sinks_3_bits_resp(_read_demux_io_sinks_3_bits_resp),
		.io_sinks_3_bits_last(_read_demux_io_sinks_3_bits_last),
		.io_select_ready(_read_demux_io_select_ready),
		.io_select_valid(m_axi_r_valid & ~read_eagerFork_regs_1),
		.io_select_bits(m_axi_r_bits_id)
	);
	Queue32_UInt2 write_portQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_portQueue_io_enq_ready),
		.io_enq_valid(_write_arbiter_io_select_valid),
		.io_enq_bits(_write_arbiter_io_select_bits),
		.io_deq_ready(_write_mux_io_select_ready),
		.io_deq_valid(_write_portQueue_io_deq_valid),
		.io_deq_bits(_write_portQueue_io_deq_bits)
	);
	elasticBasicArbiter_1 write_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_write_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_s_axi__buffered_sourceBuffer_1_io_deq_valid),
		.io_sources_0_bits_addr(_s_axi__buffered_sourceBuffer_1_io_deq_bits_addr),
		.io_sources_0_bits_len(_s_axi__buffered_sourceBuffer_1_io_deq_bits_len),
		.io_sources_0_bits_size(_s_axi__buffered_sourceBuffer_1_io_deq_bits_size),
		.io_sources_0_bits_burst(_s_axi__buffered_sourceBuffer_1_io_deq_bits_burst),
		.io_sources_1_ready(_write_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_s_axi__buffered_sourceBuffer_4_io_deq_valid),
		.io_sources_1_bits_addr(_s_axi__buffered_sourceBuffer_4_io_deq_bits_addr),
		.io_sources_1_bits_len(_s_axi__buffered_sourceBuffer_4_io_deq_bits_len),
		.io_sources_1_bits_size(_s_axi__buffered_sourceBuffer_4_io_deq_bits_size),
		.io_sources_1_bits_burst(_s_axi__buffered_sourceBuffer_4_io_deq_bits_burst),
		.io_sources_2_ready(_write_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_s_axi__buffered_sourceBuffer_7_io_deq_valid),
		.io_sources_2_bits_addr(_s_axi__buffered_sourceBuffer_7_io_deq_bits_addr),
		.io_sources_2_bits_len(_s_axi__buffered_sourceBuffer_7_io_deq_bits_len),
		.io_sources_2_bits_size(_s_axi__buffered_sourceBuffer_7_io_deq_bits_size),
		.io_sources_2_bits_burst(_s_axi__buffered_sourceBuffer_7_io_deq_bits_burst),
		.io_sources_3_ready(_write_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_s_axi__buffered_sourceBuffer_10_io_deq_valid),
		.io_sources_3_bits_addr(_s_axi__buffered_sourceBuffer_10_io_deq_bits_addr),
		.io_sources_3_bits_len(_s_axi__buffered_sourceBuffer_10_io_deq_bits_len),
		.io_sources_3_bits_size(_s_axi__buffered_sourceBuffer_10_io_deq_bits_size),
		.io_sources_3_bits_burst(_s_axi__buffered_sourceBuffer_10_io_deq_bits_burst),
		.io_sink_ready(m_axi_aw_ready),
		.io_sink_valid(m_axi_aw_valid),
		.io_sink_bits_id(m_axi_aw_bits_id),
		.io_sink_bits_addr(m_axi_aw_bits_addr),
		.io_sink_bits_len(m_axi_aw_bits_len),
		.io_sink_bits_size(m_axi_aw_bits_size),
		.io_sink_bits_burst(m_axi_aw_bits_burst),
		.io_select_ready(_write_portQueue_io_enq_ready),
		.io_select_valid(_write_arbiter_io_select_valid),
		.io_select_bits(_write_arbiter_io_select_bits)
	);
	elasticMux write_mux(
		.io_sources_0_ready(_write_mux_io_sources_0_ready),
		.io_sources_0_valid(_s_axi__buffered_sourceBuffer_2_io_deq_valid),
		.io_sources_0_bits_data(_s_axi__buffered_sourceBuffer_2_io_deq_bits_data),
		.io_sources_0_bits_strb(_s_axi__buffered_sourceBuffer_2_io_deq_bits_strb),
		.io_sources_0_bits_last(_s_axi__buffered_sourceBuffer_2_io_deq_bits_last),
		.io_sources_1_ready(_write_mux_io_sources_1_ready),
		.io_sources_1_valid(_s_axi__buffered_sourceBuffer_5_io_deq_valid),
		.io_sources_1_bits_data(_s_axi__buffered_sourceBuffer_5_io_deq_bits_data),
		.io_sources_1_bits_strb(_s_axi__buffered_sourceBuffer_5_io_deq_bits_strb),
		.io_sources_1_bits_last(_s_axi__buffered_sourceBuffer_5_io_deq_bits_last),
		.io_sources_2_ready(_write_mux_io_sources_2_ready),
		.io_sources_2_valid(_s_axi__buffered_sourceBuffer_8_io_deq_valid),
		.io_sources_2_bits_data(_s_axi__buffered_sourceBuffer_8_io_deq_bits_data),
		.io_sources_2_bits_strb(_s_axi__buffered_sourceBuffer_8_io_deq_bits_strb),
		.io_sources_2_bits_last(_s_axi__buffered_sourceBuffer_8_io_deq_bits_last),
		.io_sources_3_ready(_write_mux_io_sources_3_ready),
		.io_sources_3_valid(_s_axi__buffered_sourceBuffer_11_io_deq_valid),
		.io_sources_3_bits_data(_s_axi__buffered_sourceBuffer_11_io_deq_bits_data),
		.io_sources_3_bits_strb(_s_axi__buffered_sourceBuffer_11_io_deq_bits_strb),
		.io_sources_3_bits_last(_s_axi__buffered_sourceBuffer_11_io_deq_bits_last),
		.io_sink_ready(m_axi_w_ready),
		.io_sink_valid(m_axi_w_valid),
		.io_sink_bits_data(m_axi_w_bits_data),
		.io_sink_bits_strb(m_axi_w_bits_strb),
		.io_sink_bits_last(m_axi_w_bits_last),
		.io_select_ready(_write_mux_io_select_ready),
		.io_select_valid(_write_portQueue_io_deq_valid),
		.io_select_bits(_write_portQueue_io_deq_bits)
	);
	elasticDemux_1 write_demux(
		.io_source_ready(_write_demux_io_source_ready),
		.io_source_valid(m_axi_b_valid & ~write_eagerFork_regs_0),
		.io_source_bits_resp(m_axi_b_bits_resp),
		.io_sinks_0_ready(_s_axi__buffered_sinkBuffer_1_io_enq_ready),
		.io_sinks_0_valid(_write_demux_io_sinks_0_valid),
		.io_sinks_0_bits_resp(_write_demux_io_sinks_0_bits_resp),
		.io_sinks_1_ready(_s_axi__buffered_sinkBuffer_3_io_enq_ready),
		.io_sinks_1_valid(_write_demux_io_sinks_1_valid),
		.io_sinks_1_bits_resp(_write_demux_io_sinks_1_bits_resp),
		.io_sinks_2_ready(_s_axi__buffered_sinkBuffer_5_io_enq_ready),
		.io_sinks_2_valid(_write_demux_io_sinks_2_valid),
		.io_sinks_2_bits_resp(_write_demux_io_sinks_2_bits_resp),
		.io_sinks_3_ready(_s_axi__buffered_sinkBuffer_7_io_enq_ready),
		.io_sinks_3_valid(_write_demux_io_sinks_3_valid),
		.io_sinks_3_bits_resp(_write_demux_io_sinks_3_bits_resp),
		.io_select_ready(_write_demux_io_select_ready),
		.io_select_valid(m_axi_b_valid & ~write_eagerFork_regs_1),
		.io_select_bits(m_axi_b_bits_id)
	);
	assign m_axi_r_ready = m_axi__r_ready;
	assign m_axi_b_ready = m_axi__b_ready;
endmodule
module SteerRight (
	dataIn,
	offsetIn,
	dataOut
);
	input [255:0] dataIn;
	input [2:0] offsetIn;
	output wire [31:0] dataOut;
	wire [255:0] _GEN = {dataIn[255:224], dataIn[223:192], dataIn[191:160], dataIn[159:128], dataIn[127:96], dataIn[95:64], dataIn[63:32], dataIn[31:0]};
	assign dataOut = _GEN[offsetIn * 32+:32];
endmodule
module ram_2x32 (
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
	output wire [31:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [31:0] W0_data;
	reg [31:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_UInt32 (
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
	input [31:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits;
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
	ram_2x32 ram_ext(
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
module Downsize (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits,
	sink_ready,
	sink_valid,
	sink_bits
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [255:0] source_bits;
	input sink_ready;
	output wire sink_valid;
	output wire [31:0] sink_bits;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire [31:0] _steerRight_dataOut;
	reg [2:0] offset;
	wire [2:0] _nextOffset_T = offset + 3'h1;
	wire _GEN = _sinkBuffered__sinkBuffer_io_enq_ready & source_valid;
	always @(posedge clock)
		if (reset)
			offset <= 3'h0;
		else if (_GEN)
			offset <= _nextOffset_T;
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	SteerRight steerRight(
		.dataIn(source_bits),
		.offsetIn(offset),
		.dataOut(_steerRight_dataOut)
	);
	Queue2_UInt32 sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN),
		.io_enq_bits(_steerRight_dataOut),
		.io_deq_ready(sink_ready),
		.io_deq_valid(sink_valid),
		.io_deq_bits(sink_bits)
	);
	assign source_ready = _GEN & (_nextOffset_T == 3'h0);
endmodule
module ram_2x33 (
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
	output wire [32:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [32:0] W0_data;
	reg [32:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 33'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_DataLast_1 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_data;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_data;
	output wire io_deq_bits_last;
	wire [32:0] _ram_ext_R0_data;
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
	ram_2x33 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[31:0];
	assign io_deq_bits_last = _ram_ext_R0_data[32];
endmodule
module DownsizeWithLast (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits_data,
	source_bits_last,
	sink_ready,
	sink_valid,
	sink_bits_data,
	sink_bits_last
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [255:0] source_bits_data;
	input source_bits_last;
	input sink_ready;
	output wire sink_valid;
	output wire [31:0] sink_bits_data;
	output wire sink_bits_last;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire [31:0] _steerRight_dataOut;
	reg [2:0] offset;
	wire [2:0] _nextOffset_T = offset + 3'h1;
	wire _GEN = _sinkBuffered__sinkBuffer_io_enq_ready & source_valid;
	always @(posedge clock)
		if (reset)
			offset <= 3'h0;
		else if (_GEN)
			offset <= _nextOffset_T;
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	SteerRight steerRight(
		.dataIn(source_bits_data),
		.offsetIn(offset),
		.dataOut(_steerRight_dataOut)
	);
	Queue2_DataLast_1 sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN),
		.io_enq_bits_data(_steerRight_dataOut),
		.io_enq_bits_last(source_bits_last & ~(|_nextOffset_T)),
		.io_deq_ready(sink_ready),
		.io_deq_valid(sink_valid),
		.io_deq_bits_data(sink_bits_data),
		.io_deq_bits_last(sink_bits_last)
	);
	assign source_ready = _GEN & ~(|_nextOffset_T);
endmodule
module ram_2x448 (
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
	output wire [447:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [447:0] W0_data;
	reg [447:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [447:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 448'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_SpmvTask (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_ptrValues,
	io_enq_bits_ptrColumnIndices,
	io_enq_bits_ptrRowLengths,
	io_enq_bits_ptrInputVector,
	io_enq_bits_ptrOutputVector,
	io_enq_bits_numValues,
	io_enq_bits_numRows,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_ptrValues,
	io_deq_bits_ptrColumnIndices,
	io_deq_bits_ptrRowLengths,
	io_deq_bits_ptrInputVector,
	io_deq_bits_ptrOutputVector,
	io_deq_bits_numValues,
	io_deq_bits_numRows
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits_ptrValues;
	input [63:0] io_enq_bits_ptrColumnIndices;
	input [63:0] io_enq_bits_ptrRowLengths;
	input [63:0] io_enq_bits_ptrInputVector;
	input [63:0] io_enq_bits_ptrOutputVector;
	input [63:0] io_enq_bits_numValues;
	input [63:0] io_enq_bits_numRows;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_ptrValues;
	output wire [63:0] io_deq_bits_ptrColumnIndices;
	output wire [63:0] io_deq_bits_ptrRowLengths;
	output wire [63:0] io_deq_bits_ptrInputVector;
	output wire [63:0] io_deq_bits_ptrOutputVector;
	output wire [63:0] io_deq_bits_numValues;
	output wire [63:0] io_deq_bits_numRows;
	wire [447:0] _ram_ext_R0_data;
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
	ram_2x448 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_numRows, io_enq_bits_numValues, io_enq_bits_ptrOutputVector, io_enq_bits_ptrInputVector, io_enq_bits_ptrRowLengths, io_enq_bits_ptrColumnIndices, io_enq_bits_ptrValues})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_ptrValues = _ram_ext_R0_data[63:0];
	assign io_deq_bits_ptrColumnIndices = _ram_ext_R0_data[127:64];
	assign io_deq_bits_ptrRowLengths = _ram_ext_R0_data[191:128];
	assign io_deq_bits_ptrInputVector = _ram_ext_R0_data[255:192];
	assign io_deq_bits_ptrOutputVector = _ram_ext_R0_data[319:256];
	assign io_deq_bits_numValues = _ram_ext_R0_data[383:320];
	assign io_deq_bits_numRows = _ram_ext_R0_data[447:384];
endmodule
module ram_2x93 (
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
	output wire [92:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [92:0] W0_data;
	reg [92:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [95:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 93'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadAddressChannel_7 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_enq_bits_lock,
	io_enq_bits_cache,
	io_enq_bits_prot,
	io_enq_bits_qos,
	io_enq_bits_region,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst,
	io_deq_bits_lock,
	io_deq_bits_cache,
	io_deq_bits_prot,
	io_deq_bits_qos,
	io_deq_bits_region
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits_addr;
	input [7:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_enq_bits_lock;
	input [3:0] io_enq_bits_cache;
	input [2:0] io_enq_bits_prot;
	input [3:0] io_enq_bits_qos;
	input [3:0] io_enq_bits_region;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [7:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	output wire io_deq_bits_lock;
	output wire [3:0] io_deq_bits_cache;
	output wire [2:0] io_deq_bits_prot;
	output wire [3:0] io_deq_bits_qos;
	output wire [3:0] io_deq_bits_region;
	wire [92:0] _ram_ext_R0_data;
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
	ram_2x93 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_region, io_enq_bits_qos, io_enq_bits_prot, io_enq_bits_cache, io_enq_bits_lock, io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[71:64];
	assign io_deq_bits_size = _ram_ext_R0_data[74:72];
	assign io_deq_bits_burst = _ram_ext_R0_data[76:75];
	assign io_deq_bits_lock = _ram_ext_R0_data[77];
	assign io_deq_bits_cache = _ram_ext_R0_data[81:78];
	assign io_deq_bits_prot = _ram_ext_R0_data[84:82];
	assign io_deq_bits_qos = _ram_ext_R0_data[88:85];
	assign io_deq_bits_region = _ram_ext_R0_data[92:89];
endmodule
module MulFullRawFN (
	io_a_isNaN,
	io_a_isInf,
	io_a_isZero,
	io_a_sign,
	io_a_sExp,
	io_a_sig,
	io_b_isNaN,
	io_b_isInf,
	io_b_isZero,
	io_b_sign,
	io_b_sExp,
	io_b_sig,
	io_invalidExc,
	io_rawOut_isNaN,
	io_rawOut_isInf,
	io_rawOut_isZero,
	io_rawOut_sign,
	io_rawOut_sExp,
	io_rawOut_sig
);
	input io_a_isNaN;
	input io_a_isInf;
	input io_a_isZero;
	input io_a_sign;
	input [9:0] io_a_sExp;
	input [24:0] io_a_sig;
	input io_b_isNaN;
	input io_b_isInf;
	input io_b_isZero;
	input io_b_sign;
	input [9:0] io_b_sExp;
	input [24:0] io_b_sig;
	output wire io_invalidExc;
	output wire io_rawOut_isNaN;
	output wire io_rawOut_isInf;
	output wire io_rawOut_isZero;
	output wire io_rawOut_sign;
	output wire [9:0] io_rawOut_sExp;
	output wire [47:0] io_rawOut_sig;
	assign io_invalidExc = (((io_a_isNaN & ~io_a_sig[22]) | (io_b_isNaN & ~io_b_sig[22])) | (io_a_isInf & io_b_isZero)) | (io_a_isZero & io_b_isInf);
	assign io_rawOut_isNaN = io_a_isNaN | io_b_isNaN;
	assign io_rawOut_isInf = io_a_isInf | io_b_isInf;
	assign io_rawOut_isZero = io_a_isZero | io_b_isZero;
	assign io_rawOut_sign = io_a_sign ^ io_b_sign;
	assign io_rawOut_sExp = (io_a_sExp + io_b_sExp) - 10'h100;
	assign io_rawOut_sig = {23'h000000, io_a_sig} * {23'h000000, io_b_sig};
endmodule
module MulRawFN (
	io_a_isNaN,
	io_a_isInf,
	io_a_isZero,
	io_a_sign,
	io_a_sExp,
	io_a_sig,
	io_b_isNaN,
	io_b_isInf,
	io_b_isZero,
	io_b_sign,
	io_b_sExp,
	io_b_sig,
	io_invalidExc,
	io_rawOut_isNaN,
	io_rawOut_isInf,
	io_rawOut_isZero,
	io_rawOut_sign,
	io_rawOut_sExp,
	io_rawOut_sig
);
	input io_a_isNaN;
	input io_a_isInf;
	input io_a_isZero;
	input io_a_sign;
	input [9:0] io_a_sExp;
	input [24:0] io_a_sig;
	input io_b_isNaN;
	input io_b_isInf;
	input io_b_isZero;
	input io_b_sign;
	input [9:0] io_b_sExp;
	input [24:0] io_b_sig;
	output wire io_invalidExc;
	output wire io_rawOut_isNaN;
	output wire io_rawOut_isInf;
	output wire io_rawOut_isZero;
	output wire io_rawOut_sign;
	output wire [9:0] io_rawOut_sExp;
	output wire [26:0] io_rawOut_sig;
	wire [47:0] _mulFullRaw_io_rawOut_sig;
	MulFullRawFN mulFullRaw(
		.io_a_isNaN(io_a_isNaN),
		.io_a_isInf(io_a_isInf),
		.io_a_isZero(io_a_isZero),
		.io_a_sign(io_a_sign),
		.io_a_sExp(io_a_sExp),
		.io_a_sig(io_a_sig),
		.io_b_isNaN(io_b_isNaN),
		.io_b_isInf(io_b_isInf),
		.io_b_isZero(io_b_isZero),
		.io_b_sign(io_b_sign),
		.io_b_sExp(io_b_sExp),
		.io_b_sig(io_b_sig),
		.io_invalidExc(io_invalidExc),
		.io_rawOut_isNaN(io_rawOut_isNaN),
		.io_rawOut_isInf(io_rawOut_isInf),
		.io_rawOut_isZero(io_rawOut_isZero),
		.io_rawOut_sign(io_rawOut_sign),
		.io_rawOut_sExp(io_rawOut_sExp),
		.io_rawOut_sig(_mulFullRaw_io_rawOut_sig)
	);
	assign io_rawOut_sig = {_mulFullRaw_io_rawOut_sig[47:22], |_mulFullRaw_io_rawOut_sig[21:0]};
endmodule
module RoundAnyRawFNToRecFN_ie8_is26_oe8_os24 (
	io_invalidExc,
	io_in_isNaN,
	io_in_isInf,
	io_in_isZero,
	io_in_sign,
	io_in_sExp,
	io_in_sig,
	io_out
);
	input io_invalidExc;
	input io_in_isNaN;
	input io_in_isInf;
	input io_in_isZero;
	input io_in_sign;
	input [9:0] io_in_sExp;
	input [26:0] io_in_sig;
	output wire [32:0] io_out;
	wire [8:0] _roundMask_T_1 = ~io_in_sExp[8:0];
	wire [64:0] _GEN = {59'h000000000000000, _roundMask_T_1[5:0]};
	wire [64:0] roundMask_shift = $signed(65'sh10000000000000000 >>> _GEN);
	wire [64:0] roundMask_shift_1 = $signed(65'sh10000000000000000 >>> _GEN);
	wire [24:0] _roundMask_T_73 = (_roundMask_T_1[8] ? (_roundMask_T_1[7] ? {~(_roundMask_T_1[6] ? 22'h000000 : ~{roundMask_shift[42], roundMask_shift[43], roundMask_shift[44], roundMask_shift[45], roundMask_shift[46], {{roundMask_shift[47:46], roundMask_shift[49]} & 3'h5, 1'h0} | ({roundMask_shift[49:48], roundMask_shift[51:50]} & 4'h5), roundMask_shift[51], roundMask_shift[52], roundMask_shift[53], roundMask_shift[54], roundMask_shift[55], roundMask_shift[56], roundMask_shift[57], roundMask_shift[58], roundMask_shift[59], roundMask_shift[60], roundMask_shift[61], roundMask_shift[62], roundMask_shift[63]}), 3'h7} : {22'h000000, (_roundMask_T_1[6] ? {roundMask_shift_1[0], roundMask_shift_1[1], roundMask_shift_1[2]} : 3'h0)}) : 25'h0000000);
	wire _GEN_0 = _roundMask_T_73[0] | io_in_sig[26];
	wire [25:0] _GEN_1 = {_roundMask_T_73[24:1], _GEN_0, 1'h1};
	wire [25:0] _roundPosBit_T = (io_in_sig[26:1] & {1'h1, ~_roundMask_T_73[24:1], ~_GEN_0}) & _GEN_1;
	wire [25:0] roundedSig = (|_roundPosBit_T ? ({1'h0, io_in_sig[26:2] | {_roundMask_T_73[24:1], _GEN_0}} + 26'h0000001) & ~(|_roundPosBit_T & ((io_in_sig[25:0] & _GEN_1) == 26'h0000000) ? {_roundMask_T_73[24:1], _GEN_0, 1'h1} : 26'h0000000) : {1'h0, io_in_sig[26:2] & {~_roundMask_T_73[24:1], ~_GEN_0}});
	wire [10:0] sRoundedExp = {io_in_sExp[9], io_in_sExp} + {9'h000, roundedSig[25:24]};
	wire common_totalUnderflow = $signed(sRoundedExp) < 11'sh06b;
	wire isNaNOut = io_invalidExc | io_in_isNaN;
	wire notNaN_isInfOut = io_in_isInf | (((~isNaNOut & ~io_in_isInf) & ~io_in_isZero) & ($signed(sRoundedExp[10:7]) > 4'sh2));
	assign io_out = {~isNaNOut & io_in_sign, (((sRoundedExp[8:0] & ~(io_in_isZero | common_totalUnderflow ? 9'h1c0 : 9'h000)) & {2'h3, ~notNaN_isInfOut, 6'h3f}) | (notNaN_isInfOut ? 9'h180 : 9'h000)) | (isNaNOut ? 9'h1c0 : 9'h000), ((isNaNOut | io_in_isZero) | common_totalUnderflow ? {isNaNOut, 22'h000000} : (io_in_sig[26] ? roundedSig[23:1] : roundedSig[22:0]))};
endmodule
module RoundRawFNToRecFN_e8_s24 (
	io_invalidExc,
	io_in_isNaN,
	io_in_isInf,
	io_in_isZero,
	io_in_sign,
	io_in_sExp,
	io_in_sig,
	io_out
);
	input io_invalidExc;
	input io_in_isNaN;
	input io_in_isInf;
	input io_in_isZero;
	input io_in_sign;
	input [9:0] io_in_sExp;
	input [26:0] io_in_sig;
	output wire [32:0] io_out;
	RoundAnyRawFNToRecFN_ie8_is26_oe8_os24 roundAnyRawFNToRecFN(
		.io_invalidExc(io_invalidExc),
		.io_in_isNaN(io_in_isNaN),
		.io_in_isInf(io_in_isInf),
		.io_in_isZero(io_in_isZero),
		.io_in_sign(io_in_sign),
		.io_in_sExp(io_in_sExp),
		.io_in_sig(io_in_sig),
		.io_out(io_out)
	);
endmodule
module MulRecFN_Pipelined_8_24 (
	clock,
	io_a,
	io_b,
	io_out
);
	input clock;
	input [32:0] io_a;
	input [32:0] io_b;
	output wire [32:0] io_out;
	wire [32:0] _roundRawFNToRecFN_io_out;
	wire _mulRawFN_io_invalidExc;
	wire _mulRawFN_io_rawOut_isNaN;
	wire _mulRawFN_io_rawOut_isInf;
	wire _mulRawFN_io_rawOut_isZero;
	wire _mulRawFN_io_rawOut_sign;
	wire [9:0] _mulRawFN_io_rawOut_sExp;
	wire [26:0] _mulRawFN_io_rawOut_sig;
	reg [32:0] mulRawFN_io_a_stage1_a;
	reg [32:0] mulRawFN_io_b_stage1_b;
	reg roundRawFNToRecFN_io_invalidExc_stage2_mulRawFn_invalidExc;
	reg roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isNaN;
	reg roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isInf;
	reg roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isZero;
	reg roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sign;
	reg [9:0] roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sExp;
	reg [26:0] roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sig;
	reg [32:0] io_out_stage3_roundRawFNToRecFN_out;
	always @(posedge clock) begin
		mulRawFN_io_a_stage1_a <= io_a;
		mulRawFN_io_b_stage1_b <= io_b;
		roundRawFNToRecFN_io_invalidExc_stage2_mulRawFn_invalidExc <= _mulRawFN_io_invalidExc;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isNaN <= _mulRawFN_io_rawOut_isNaN;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isInf <= _mulRawFN_io_rawOut_isInf;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isZero <= _mulRawFN_io_rawOut_isZero;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sign <= _mulRawFN_io_rawOut_sign;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sExp <= _mulRawFN_io_rawOut_sExp;
		roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sig <= _mulRawFN_io_rawOut_sig;
		io_out_stage3_roundRawFNToRecFN_out <= _roundRawFNToRecFN_io_out;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:4];
	end
	MulRawFN mulRawFN(
		.io_a_isNaN(&mulRawFN_io_a_stage1_a[31:30] & mulRawFN_io_a_stage1_a[29]),
		.io_a_isInf(&mulRawFN_io_a_stage1_a[31:30] & ~mulRawFN_io_a_stage1_a[29]),
		.io_a_isZero(~(|mulRawFN_io_a_stage1_a[31:29])),
		.io_a_sign(mulRawFN_io_a_stage1_a[32]),
		.io_a_sExp({1'h0, mulRawFN_io_a_stage1_a[31:23]}),
		.io_a_sig({1'h0, |mulRawFN_io_a_stage1_a[31:29], mulRawFN_io_a_stage1_a[22:0]}),
		.io_b_isNaN(&mulRawFN_io_b_stage1_b[31:30] & mulRawFN_io_b_stage1_b[29]),
		.io_b_isInf(&mulRawFN_io_b_stage1_b[31:30] & ~mulRawFN_io_b_stage1_b[29]),
		.io_b_isZero(~(|mulRawFN_io_b_stage1_b[31:29])),
		.io_b_sign(mulRawFN_io_b_stage1_b[32]),
		.io_b_sExp({1'h0, mulRawFN_io_b_stage1_b[31:23]}),
		.io_b_sig({1'h0, |mulRawFN_io_b_stage1_b[31:29], mulRawFN_io_b_stage1_b[22:0]}),
		.io_invalidExc(_mulRawFN_io_invalidExc),
		.io_rawOut_isNaN(_mulRawFN_io_rawOut_isNaN),
		.io_rawOut_isInf(_mulRawFN_io_rawOut_isInf),
		.io_rawOut_isZero(_mulRawFN_io_rawOut_isZero),
		.io_rawOut_sign(_mulRawFN_io_rawOut_sign),
		.io_rawOut_sExp(_mulRawFN_io_rawOut_sExp),
		.io_rawOut_sig(_mulRawFN_io_rawOut_sig)
	);
	RoundRawFNToRecFN_e8_s24 roundRawFNToRecFN(
		.io_invalidExc(roundRawFNToRecFN_io_invalidExc_stage2_mulRawFn_invalidExc),
		.io_in_isNaN(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isNaN),
		.io_in_isInf(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isInf),
		.io_in_isZero(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_isZero),
		.io_in_sign(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sign),
		.io_in_sExp(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sExp),
		.io_in_sig(roundRawFNToRecFN_io_in_stage2_mulRawFn_rawOut_sig),
		.io_out(_roundRawFNToRecFN_io_out)
	);
	assign io_out = io_out_stage3_roundRawFNToRecFN_out;
endmodule
module MulFp_Pipelined_8_23 (
	clock,
	io_in_a_sign,
	io_in_a_exponent,
	io_in_a_mantissa,
	io_in_b_sign,
	io_in_b_exponent,
	io_in_b_mantissa,
	io_out_sign,
	io_out_exponent,
	io_out_mantissa
);
	input clock;
	input io_in_a_sign;
	input [7:0] io_in_a_exponent;
	input [22:0] io_in_a_mantissa;
	input io_in_b_sign;
	input [7:0] io_in_b_exponent;
	input [22:0] io_in_b_mantissa;
	output wire io_out_sign;
	output wire [7:0] io_out_exponent;
	output wire [22:0] io_out_mantissa;
	wire [32:0] _mulRecFn_io_out;
	wire mulRecFn_io_a_rawIn_isZeroExpIn = io_in_a_exponent == 8'h00;
	wire [4:0] mulRecFn_io_a_rawIn_normDist = (io_in_a_mantissa[22] ? 5'h00 : (io_in_a_mantissa[21] ? 5'h01 : (io_in_a_mantissa[20] ? 5'h02 : (io_in_a_mantissa[19] ? 5'h03 : (io_in_a_mantissa[18] ? 5'h04 : (io_in_a_mantissa[17] ? 5'h05 : (io_in_a_mantissa[16] ? 5'h06 : (io_in_a_mantissa[15] ? 5'h07 : (io_in_a_mantissa[14] ? 5'h08 : (io_in_a_mantissa[13] ? 5'h09 : (io_in_a_mantissa[12] ? 5'h0a : (io_in_a_mantissa[11] ? 5'h0b : (io_in_a_mantissa[10] ? 5'h0c : (io_in_a_mantissa[9] ? 5'h0d : (io_in_a_mantissa[8] ? 5'h0e : (io_in_a_mantissa[7] ? 5'h0f : (io_in_a_mantissa[6] ? 5'h10 : (io_in_a_mantissa[5] ? 5'h11 : (io_in_a_mantissa[4] ? 5'h12 : (io_in_a_mantissa[3] ? 5'h13 : (io_in_a_mantissa[2] ? 5'h14 : (io_in_a_mantissa[1] ? 5'h15 : 5'h16))))))))))))))))))))));
	wire [53:0] _mulRecFn_io_a_rawIn_subnormFract_T = {31'h00000000, io_in_a_mantissa} << mulRecFn_io_a_rawIn_normDist;
	wire [8:0] _mulRecFn_io_a_rawIn_adjustedExp_T_4 = (mulRecFn_io_a_rawIn_isZeroExpIn ? {4'hf, ~mulRecFn_io_a_rawIn_normDist} : {1'h0, io_in_a_exponent}) + {7'h20, (mulRecFn_io_a_rawIn_isZeroExpIn ? 2'h2 : 2'h1)};
	wire [2:0] _mulRecFn_io_a_T_2 = (mulRecFn_io_a_rawIn_isZeroExpIn & ~(|io_in_a_mantissa) ? 3'h0 : _mulRecFn_io_a_rawIn_adjustedExp_T_4[8:6]);
	wire mulRecFn_io_b_rawIn_isZeroExpIn = io_in_b_exponent == 8'h00;
	wire [4:0] mulRecFn_io_b_rawIn_normDist = (io_in_b_mantissa[22] ? 5'h00 : (io_in_b_mantissa[21] ? 5'h01 : (io_in_b_mantissa[20] ? 5'h02 : (io_in_b_mantissa[19] ? 5'h03 : (io_in_b_mantissa[18] ? 5'h04 : (io_in_b_mantissa[17] ? 5'h05 : (io_in_b_mantissa[16] ? 5'h06 : (io_in_b_mantissa[15] ? 5'h07 : (io_in_b_mantissa[14] ? 5'h08 : (io_in_b_mantissa[13] ? 5'h09 : (io_in_b_mantissa[12] ? 5'h0a : (io_in_b_mantissa[11] ? 5'h0b : (io_in_b_mantissa[10] ? 5'h0c : (io_in_b_mantissa[9] ? 5'h0d : (io_in_b_mantissa[8] ? 5'h0e : (io_in_b_mantissa[7] ? 5'h0f : (io_in_b_mantissa[6] ? 5'h10 : (io_in_b_mantissa[5] ? 5'h11 : (io_in_b_mantissa[4] ? 5'h12 : (io_in_b_mantissa[3] ? 5'h13 : (io_in_b_mantissa[2] ? 5'h14 : (io_in_b_mantissa[1] ? 5'h15 : 5'h16))))))))))))))))))))));
	wire [53:0] _mulRecFn_io_b_rawIn_subnormFract_T = {31'h00000000, io_in_b_mantissa} << mulRecFn_io_b_rawIn_normDist;
	wire [8:0] _mulRecFn_io_b_rawIn_adjustedExp_T_4 = (mulRecFn_io_b_rawIn_isZeroExpIn ? {4'hf, ~mulRecFn_io_b_rawIn_normDist} : {1'h0, io_in_b_exponent}) + {7'h20, (mulRecFn_io_b_rawIn_isZeroExpIn ? 2'h2 : 2'h1)};
	wire [2:0] _mulRecFn_io_b_T_2 = (mulRecFn_io_b_rawIn_isZeroExpIn & ~(|io_in_b_mantissa) ? 3'h0 : _mulRecFn_io_b_rawIn_adjustedExp_T_4[8:6]);
	wire io_out_rawIn_isInf = &_mulRecFn_io_out[31:30] & ~_mulRecFn_io_out[29];
	wire io_out_isSubnormal = $signed({1'h0, _mulRecFn_io_out[31:23]}) < 10'sh082;
	wire [23:0] _io_out_denormFract_T_1 = {1'h0, |_mulRecFn_io_out[31:29], _mulRecFn_io_out[22:1]} >> (5'h01 - _mulRecFn_io_out[27:23]);
	MulRecFN_Pipelined_8_24 mulRecFn(
		.clock(clock),
		.io_a({io_in_a_sign, _mulRecFn_io_a_T_2[2:1], _mulRecFn_io_a_T_2[0] | (&_mulRecFn_io_a_rawIn_adjustedExp_T_4[8:7] & |io_in_a_mantissa), _mulRecFn_io_a_rawIn_adjustedExp_T_4[5:0], (mulRecFn_io_a_rawIn_isZeroExpIn ? {_mulRecFn_io_a_rawIn_subnormFract_T[21:0], 1'h0} : io_in_a_mantissa)}),
		.io_b({io_in_b_sign, _mulRecFn_io_b_T_2[2:1], _mulRecFn_io_b_T_2[0] | (&_mulRecFn_io_b_rawIn_adjustedExp_T_4[8:7] & |io_in_b_mantissa), _mulRecFn_io_b_rawIn_adjustedExp_T_4[5:0], (mulRecFn_io_b_rawIn_isZeroExpIn ? {_mulRecFn_io_b_rawIn_subnormFract_T[21:0], 1'h0} : io_in_b_mantissa)}),
		.io_out(_mulRecFn_io_out)
	);
	assign io_out_sign = _mulRecFn_io_out[32];
	assign io_out_exponent = (io_out_isSubnormal ? 8'h00 : _mulRecFn_io_out[30:23] + 8'h7f) | {8 {(&_mulRecFn_io_out[31:30] & _mulRecFn_io_out[29]) | io_out_rawIn_isInf}};
	assign io_out_mantissa = (io_out_isSubnormal ? _io_out_denormFract_T_1[22:0] : (io_out_rawIn_isInf ? 23'h000000 : _mulRecFn_io_out[22:0]));
endmodule
module OpMultiply (
	clock,
	io_in_a_sign,
	io_in_a_exponent,
	io_in_a_mantissa,
	io_in_b_sign,
	io_in_b_exponent,
	io_in_b_mantissa,
	io_out_sign,
	io_out_exponent,
	io_out_mantissa
);
	input clock;
	input io_in_a_sign;
	input [7:0] io_in_a_exponent;
	input [22:0] io_in_a_mantissa;
	input io_in_b_sign;
	input [7:0] io_in_b_exponent;
	input [22:0] io_in_b_mantissa;
	output wire io_out_sign;
	output wire [7:0] io_out_exponent;
	output wire [22:0] io_out_mantissa;
	wire _module_io_out_sign;
	wire [7:0] _module_io_out_exponent;
	wire [22:0] _module_io_out_mantissa;
	wire [31:0] in_a__ = {io_in_a_sign, io_in_a_exponent, io_in_a_mantissa};
	wire [31:0] in_b__ = {io_in_b_sign, io_in_b_exponent, io_in_b_mantissa};
	wire [31:0] out__ = {_module_io_out_sign, _module_io_out_exponent, _module_io_out_mantissa};
	MulFp_Pipelined_8_23 module_0(
		.clock(clock),
		.io_in_a_sign(io_in_a_sign),
		.io_in_a_exponent(io_in_a_exponent),
		.io_in_a_mantissa(io_in_a_mantissa),
		.io_in_b_sign(io_in_b_sign),
		.io_in_b_exponent(io_in_b_exponent),
		.io_in_b_mantissa(io_in_b_mantissa),
		.io_out_sign(_module_io_out_sign),
		.io_out_exponent(_module_io_out_exponent),
		.io_out_mantissa(_module_io_out_mantissa)
	);
	assign io_out_sign = _module_io_out_sign;
	assign io_out_exponent = _module_io_out_exponent;
	assign io_out_mantissa = _module_io_out_mantissa;
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
module ram_4x256 (
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
	output wire [255:0] R0_data;
	input [1:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [255:0] W0_data;
	reg [255:0] Memory [0:3];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [255:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 256'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue4_UInt256 (
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
	input [255:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits;
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
	ram_4x256 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module Wrapper (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits__1,
	source_bits__2,
	sink_ready,
	sink_valid,
	sink_bits,
	moduleIn__1,
	moduleIn__2,
	moduleOut
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [31:0] source_bits__1;
	input [255:0] source_bits__2;
	input sink_ready;
	output wire sink_valid;
	output wire [255:0] sink_bits;
	output wire [31:0] moduleIn__1;
	output wire [255:0] moduleIn__2;
	input [255:0] moduleOut;
	wire _qOutput_io_deq_valid;
	wire _ctr_io_full;
	wire source_ready_0 = ~_ctr_io_full & source_valid;
	wire _qOutput_io_enq_valid_T = source_ready_0 & source_valid;
	reg qOutput_io_enq_valid_r;
	reg qOutput_io_enq_valid_r_1;
	reg qOutput_io_enq_valid_r_2;
	always @(posedge clock) begin
		qOutput_io_enq_valid_r <= _qOutput_io_enq_valid_T;
		qOutput_io_enq_valid_r_1 <= qOutput_io_enq_valid_r;
		qOutput_io_enq_valid_r_2 <= qOutput_io_enq_valid_r_1;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Counter ctr(
		.clock(clock),
		.reset(reset),
		.io_incEn(_qOutput_io_enq_valid_T),
		.io_decEn(sink_ready & _qOutput_io_deq_valid),
		.io_full(_ctr_io_full)
	);
	Queue4_UInt256 qOutput(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(qOutput_io_enq_valid_r_2),
		.io_enq_bits(moduleOut),
		.io_deq_ready(sink_ready),
		.io_deq_valid(_qOutput_io_deq_valid),
		.io_deq_bits(sink_bits)
	);
	assign source_ready = source_ready_0;
	assign sink_valid = _qOutput_io_deq_valid;
	assign moduleIn__1 = source_bits__1;
	assign moduleIn__2 = source_bits__2;
endmodule
module BatchMultiply (
	clock,
	reset,
	sourceInA_ready,
	sourceInA_valid,
	sourceInA_bits,
	sourceInB_ready,
	sourceInB_valid,
	sourceInB_bits,
	sinkOut_ready,
	sinkOut_valid,
	sinkOut_bits
);
	input clock;
	input reset;
	output wire sourceInA_ready;
	input sourceInA_valid;
	input [31:0] sourceInA_bits;
	output wire sourceInB_ready;
	input sourceInB_valid;
	input [255:0] sourceInB_bits;
	input sinkOut_ready;
	output wire sinkOut_valid;
	output wire [255:0] sinkOut_bits;
	wire _wrapper_source_ready;
	wire [31:0] _wrapper_moduleIn__1;
	wire [255:0] _wrapper_moduleIn__2;
	wire _multiply7_io_out_sign;
	wire [7:0] _multiply7_io_out_exponent;
	wire [22:0] _multiply7_io_out_mantissa;
	wire _multiply6_io_out_sign;
	wire [7:0] _multiply6_io_out_exponent;
	wire [22:0] _multiply6_io_out_mantissa;
	wire _multiply5_io_out_sign;
	wire [7:0] _multiply5_io_out_exponent;
	wire [22:0] _multiply5_io_out_mantissa;
	wire _multiply4_io_out_sign;
	wire [7:0] _multiply4_io_out_exponent;
	wire [22:0] _multiply4_io_out_mantissa;
	wire _multiply3_io_out_sign;
	wire [7:0] _multiply3_io_out_exponent;
	wire [22:0] _multiply3_io_out_mantissa;
	wire _multiply2_io_out_sign;
	wire [7:0] _multiply2_io_out_exponent;
	wire [22:0] _multiply2_io_out_mantissa;
	wire _multiply1_io_out_sign;
	wire [7:0] _multiply1_io_out_exponent;
	wire [22:0] _multiply1_io_out_mantissa;
	wire _multiply0_io_out_sign;
	wire [7:0] _multiply0_io_out_exponent;
	wire [22:0] _multiply0_io_out_mantissa;
	wire join0_mkJoin_allValid = sourceInA_valid & sourceInB_valid;
	wire sourceInB_ready_0 = _wrapper_source_ready & join0_mkJoin_allValid;
	OpMultiply multiply0(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[31]),
		.io_in_b_exponent(_wrapper_moduleIn__2[30:23]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[22:0]),
		.io_out_sign(_multiply0_io_out_sign),
		.io_out_exponent(_multiply0_io_out_exponent),
		.io_out_mantissa(_multiply0_io_out_mantissa)
	);
	OpMultiply multiply1(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[63]),
		.io_in_b_exponent(_wrapper_moduleIn__2[62:55]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[54:32]),
		.io_out_sign(_multiply1_io_out_sign),
		.io_out_exponent(_multiply1_io_out_exponent),
		.io_out_mantissa(_multiply1_io_out_mantissa)
	);
	OpMultiply multiply2(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[95]),
		.io_in_b_exponent(_wrapper_moduleIn__2[94:87]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[86:64]),
		.io_out_sign(_multiply2_io_out_sign),
		.io_out_exponent(_multiply2_io_out_exponent),
		.io_out_mantissa(_multiply2_io_out_mantissa)
	);
	OpMultiply multiply3(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[127]),
		.io_in_b_exponent(_wrapper_moduleIn__2[126:119]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[118:96]),
		.io_out_sign(_multiply3_io_out_sign),
		.io_out_exponent(_multiply3_io_out_exponent),
		.io_out_mantissa(_multiply3_io_out_mantissa)
	);
	OpMultiply multiply4(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[159]),
		.io_in_b_exponent(_wrapper_moduleIn__2[158:151]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[150:128]),
		.io_out_sign(_multiply4_io_out_sign),
		.io_out_exponent(_multiply4_io_out_exponent),
		.io_out_mantissa(_multiply4_io_out_mantissa)
	);
	OpMultiply multiply5(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[191]),
		.io_in_b_exponent(_wrapper_moduleIn__2[190:183]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[182:160]),
		.io_out_sign(_multiply5_io_out_sign),
		.io_out_exponent(_multiply5_io_out_exponent),
		.io_out_mantissa(_multiply5_io_out_mantissa)
	);
	OpMultiply multiply6(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[223]),
		.io_in_b_exponent(_wrapper_moduleIn__2[222:215]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[214:192]),
		.io_out_sign(_multiply6_io_out_sign),
		.io_out_exponent(_multiply6_io_out_exponent),
		.io_out_mantissa(_multiply6_io_out_mantissa)
	);
	OpMultiply multiply7(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[255]),
		.io_in_b_exponent(_wrapper_moduleIn__2[254:247]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[246:224]),
		.io_out_sign(_multiply7_io_out_sign),
		.io_out_exponent(_multiply7_io_out_exponent),
		.io_out_mantissa(_multiply7_io_out_mantissa)
	);
	Wrapper wrapper(
		.clock(clock),
		.reset(reset),
		.source_ready(_wrapper_source_ready),
		.source_valid(join0_mkJoin_allValid),
		.source_bits__1(sourceInA_bits),
		.source_bits__2(sourceInB_bits),
		.sink_ready(sinkOut_ready),
		.sink_valid(sinkOut_valid),
		.sink_bits(sinkOut_bits),
		.moduleIn__1(_wrapper_moduleIn__1),
		.moduleIn__2(_wrapper_moduleIn__2),
		.moduleOut({_multiply7_io_out_sign, _multiply7_io_out_exponent, _multiply7_io_out_mantissa, _multiply6_io_out_sign, _multiply6_io_out_exponent, _multiply6_io_out_mantissa, _multiply5_io_out_sign, _multiply5_io_out_exponent, _multiply5_io_out_mantissa, _multiply4_io_out_sign, _multiply4_io_out_exponent, _multiply4_io_out_mantissa, _multiply3_io_out_sign, _multiply3_io_out_exponent, _multiply3_io_out_mantissa, _multiply2_io_out_sign, _multiply2_io_out_exponent, _multiply2_io_out_mantissa, _multiply1_io_out_sign, _multiply1_io_out_exponent, _multiply1_io_out_mantissa, _multiply0_io_out_sign, _multiply0_io_out_exponent, _multiply0_io_out_mantissa})
	);
	assign sourceInA_ready = sourceInB_ready_0;
	assign sourceInB_ready = sourceInB_ready_0;
endmodule
module ram_2x256 (
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
	output wire [255:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [255:0] W0_data;
	reg [255:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [255:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 256'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_UInt256 (
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
	input [255:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits;
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
	ram_2x256 ram_ext(
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
module ram_2x512 (
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
	output wire [511:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [511:0] W0_data;
	reg [511:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [511:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 512'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_Bundle2 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits__1,
	io_enq_bits__2,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits__1,
	io_deq_bits__2
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits__1;
	input [255:0] io_enq_bits__2;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits__1;
	output wire [255:0] io_deq_bits__2;
	wire [511:0] _ram_ext_R0_data;
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
	ram_2x512 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits__2, io_enq_bits__1})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits__1 = _ram_ext_R0_data[255:0];
	assign io_deq_bits__2 = _ram_ext_R0_data[511:256];
endmodule
module RequestResponseGuard (
	clock,
	reset,
	sourceReq_ready,
	sourceReq_valid,
	sourceReq_bits__1,
	sourceReq_bits__2,
	sinkResp_ready,
	sinkResp_valid,
	sinkResp_bits,
	sinkReq_ready,
	sinkReq_valid,
	sinkReq_bits__1,
	sinkReq_bits__2,
	sourceResp_ready,
	sourceResp_valid,
	sourceResp_bits
);
	input clock;
	input reset;
	output wire sourceReq_ready;
	input sourceReq_valid;
	input [255:0] sourceReq_bits__1;
	input [255:0] sourceReq_bits__2;
	input sinkResp_ready;
	output wire sinkResp_valid;
	output wire [255:0] sinkResp_bits;
	input sinkReq_ready;
	output wire sinkReq_valid;
	output wire [255:0] sinkReq_bits__1;
	output wire [255:0] sinkReq_bits__2;
	output wire sourceResp_ready;
	input sourceResp_valid;
	input [255:0] sourceResp_bits;
	wire _sinkBuffered__sinkBuffer_1_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire _respQueue_io_deq_valid;
	wire [255:0] _respQueue_io_deq_bits;
	wire _ctr_io_full;
	wire sourceReq_ready_0 = (_sinkBuffered__sinkBuffer_io_enq_ready & sourceReq_valid) & ~_ctr_io_full;
	wire _GEN = _sinkBuffered__sinkBuffer_1_io_enq_ready & _respQueue_io_deq_valid;
	Counter ctr(
		.clock(clock),
		.reset(reset),
		.io_incEn(sourceReq_ready_0),
		.io_decEn(_GEN),
		.io_full(_ctr_io_full)
	);
	Queue4_UInt256 respQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(sourceResp_ready),
		.io_enq_valid(sourceResp_valid),
		.io_enq_bits(sourceResp_bits),
		.io_deq_ready(_GEN),
		.io_deq_valid(_respQueue_io_deq_valid),
		.io_deq_bits(_respQueue_io_deq_bits)
	);
	Queue2_Bundle2 sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceReq_ready_0),
		.io_enq_bits__1(sourceReq_bits__1),
		.io_enq_bits__2(sourceReq_bits__2),
		.io_deq_ready(sinkReq_ready),
		.io_deq_valid(sinkReq_valid),
		.io_deq_bits__1(sinkReq_bits__1),
		.io_deq_bits__2(sinkReq_bits__2)
	);
	Queue2_UInt256 sinkBuffered__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_GEN),
		.io_enq_bits(_respQueue_io_deq_bits),
		.io_deq_ready(sinkResp_ready),
		.io_deq_valid(sinkResp_valid),
		.io_deq_bits(sinkResp_bits)
	);
	assign sourceReq_ready = sourceReq_ready_0;
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
module Queue2_Bool (
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
	input io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire io_deq_bits;
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
		.R0_data(io_deq_bits),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module elasticMux_1 (
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [255:0] io_sources_1_bits;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [255:0] io_sink_bits;
	output wire io_select_ready;
	input io_select_valid;
	input io_select_bits;
	wire valid = io_select_valid & (~io_select_bits | io_sources_1_valid);
	wire fire = valid & io_sink_ready;
	assign io_sources_1_ready = fire & io_select_bits;
	assign io_sink_valid = valid;
	assign io_sink_bits = (io_select_bits ? io_sources_1_bits : 256'h0000000000000000000000000000000000000000000000000000000000000000);
	assign io_select_ready = fire;
endmodule
module elasticDemux_2 (
	io_source_ready,
	io_source_valid,
	io_source_bits,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [255:0] io_source_bits;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [255:0] io_sinks_0_bits;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [255:0] io_sinks_1_bits;
	output wire io_select_ready;
	input io_select_valid;
	input io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire fire = valid & (io_select_bits ? io_sinks_1_ready : io_sinks_0_ready);
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & ~io_select_bits;
	assign io_sinks_0_bits = io_source_bits;
	assign io_sinks_1_valid = valid & io_select_bits;
	assign io_sinks_1_bits = io_source_bits;
	assign io_select_ready = fire;
endmodule
module RowReduceSingle (
	clock,
	reset,
	sourceElem_ready,
	sourceElem_valid,
	sourceElem_bits_data,
	sourceElem_bits_last,
	sinkResult_ready,
	sinkResult_valid,
	sinkResult_bits,
	batchAddReq_ready,
	batchAddReq_valid,
	batchAddReq_bits__1,
	batchAddReq_bits__2,
	batchAddResp_ready,
	batchAddResp_valid,
	batchAddResp_bits
);
	input clock;
	input reset;
	output wire sourceElem_ready;
	input sourceElem_valid;
	input [255:0] sourceElem_bits_data;
	input sourceElem_bits_last;
	input sinkResult_ready;
	output wire sinkResult_valid;
	output wire [255:0] sinkResult_bits;
	input batchAddReq_ready;
	output wire batchAddReq_valid;
	output wire [255:0] batchAddReq_bits__1;
	output wire [255:0] batchAddReq_bits__2;
	output wire batchAddResp_ready;
	input batchAddResp_valid;
	input [255:0] batchAddResp_bits;
	wire rvLast0_ready;
	wire _demux_io_source_ready;
	wire _demux_io_sinks_0_valid;
	wire [255:0] _demux_io_sinks_0_bits;
	wire _demux_io_select_ready;
	wire _mux_io_sources_1_ready;
	wire _mux_io_sink_valid;
	wire [255:0] _mux_io_sink_bits;
	wire _mux_io_select_ready;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_deq_valid;
	wire _sinkBuffered__sinkBuffer_io_deq_bits;
	wire _sinkBuffer_1_io_enq_ready;
	wire _sinkBuffer_1_io_deq_valid;
	wire _sinkBuffer_1_io_deq_bits;
	wire _sinkBuffer_io_enq_ready;
	wire _sinkBuffer_io_deq_valid;
	wire [255:0] _sinkBuffer_io_deq_bits;
	wire _requestResponseGuard_sourceReq_ready;
	wire _requestResponseGuard_sinkResp_valid;
	wire [255:0] _requestResponseGuard_sinkResp_bits;
	wire mkJoin_allValid = _mux_io_sink_valid & _sinkBuffer_io_deq_valid;
	wire mkJoin_fire = _requestResponseGuard_sourceReq_ready & mkJoin_allValid;
	reg eagerFork_regs_0;
	reg eagerFork_regs_1;
	reg eagerFork_regs_2;
	wire eagerFork_sourceElem_ready_qual1_0 = _sinkBuffer_io_enq_ready | eagerFork_regs_0;
	wire eagerFork_sourceElem_ready_qual1_1 = rvLast0_ready | eagerFork_regs_1;
	wire eagerFork_sourceElem_ready_qual1_2 = _sinkBuffer_1_io_enq_ready | eagerFork_regs_2;
	wire sourceElem_ready_0 = (eagerFork_sourceElem_ready_qual1_0 & eagerFork_sourceElem_ready_qual1_1) & eagerFork_sourceElem_ready_qual1_2;
	reg rIsNextFirst;
	assign rvLast0_ready = (_sinkBuffered__sinkBuffer_io_enq_ready & sourceElem_valid) & ~eagerFork_regs_1;
	always @(posedge clock)
		if (reset) begin
			eagerFork_regs_0 <= 1'h0;
			eagerFork_regs_1 <= 1'h0;
			eagerFork_regs_2 <= 1'h0;
			rIsNextFirst <= 1'h1;
		end
		else begin
			eagerFork_regs_0 <= (eagerFork_sourceElem_ready_qual1_0 & sourceElem_valid) & ~sourceElem_ready_0;
			eagerFork_regs_1 <= (eagerFork_sourceElem_ready_qual1_1 & sourceElem_valid) & ~sourceElem_ready_0;
			eagerFork_regs_2 <= (eagerFork_sourceElem_ready_qual1_2 & sourceElem_valid) & ~sourceElem_ready_0;
			if (rvLast0_ready)
				rIsNextFirst <= sourceElem_bits_last;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	RequestResponseGuard requestResponseGuard(
		.clock(clock),
		.reset(reset),
		.sourceReq_ready(_requestResponseGuard_sourceReq_ready),
		.sourceReq_valid(mkJoin_allValid),
		.sourceReq_bits__1(_mux_io_sink_bits),
		.sourceReq_bits__2(_sinkBuffer_io_deq_bits),
		.sinkResp_ready(_demux_io_source_ready),
		.sinkResp_valid(_requestResponseGuard_sinkResp_valid),
		.sinkResp_bits(_requestResponseGuard_sinkResp_bits),
		.sinkReq_ready(batchAddReq_ready),
		.sinkReq_valid(batchAddReq_valid),
		.sinkReq_bits__1(batchAddReq_bits__1),
		.sinkReq_bits__2(batchAddReq_bits__2),
		.sourceResp_ready(batchAddResp_ready),
		.sourceResp_valid(batchAddResp_valid),
		.sourceResp_bits(batchAddResp_bits)
	);
	Queue2_UInt256 sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceElem_valid & ~eagerFork_regs_0),
		.io_enq_bits(sourceElem_bits_data),
		.io_deq_ready(mkJoin_fire),
		.io_deq_valid(_sinkBuffer_io_deq_valid),
		.io_deq_bits(_sinkBuffer_io_deq_bits)
	);
	Queue2_Bool sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_1_io_enq_ready),
		.io_enq_valid(sourceElem_valid & ~eagerFork_regs_2),
		.io_enq_bits(sourceElem_bits_last),
		.io_deq_ready(_demux_io_select_ready),
		.io_deq_valid(_sinkBuffer_1_io_deq_valid),
		.io_deq_bits(_sinkBuffer_1_io_deq_bits)
	);
	Queue2_Bool sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(rvLast0_ready),
		.io_enq_bits(rIsNextFirst),
		.io_deq_ready(_mux_io_select_ready),
		.io_deq_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits(_sinkBuffered__sinkBuffer_io_deq_bits)
	);
	elasticMux_1 mux(
		.io_sources_1_ready(_mux_io_sources_1_ready),
		.io_sources_1_valid(_demux_io_sinks_0_valid),
		.io_sources_1_bits(_demux_io_sinks_0_bits),
		.io_sink_ready(mkJoin_fire),
		.io_sink_valid(_mux_io_sink_valid),
		.io_sink_bits(_mux_io_sink_bits),
		.io_select_ready(_mux_io_select_ready),
		.io_select_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_select_bits(~_sinkBuffered__sinkBuffer_io_deq_bits)
	);
	elasticDemux_2 demux(
		.io_source_ready(_demux_io_source_ready),
		.io_source_valid(_requestResponseGuard_sinkResp_valid),
		.io_source_bits(_requestResponseGuard_sinkResp_bits),
		.io_sinks_0_ready(_mux_io_sources_1_ready),
		.io_sinks_0_valid(_demux_io_sinks_0_valid),
		.io_sinks_0_bits(_demux_io_sinks_0_bits),
		.io_sinks_1_ready(sinkResult_ready),
		.io_sinks_1_valid(sinkResult_valid),
		.io_sinks_1_bits(sinkResult_bits),
		.io_select_ready(_demux_io_select_ready),
		.io_select_valid(_sinkBuffer_1_io_deq_valid),
		.io_select_bits(_sinkBuffer_1_io_deq_bits)
	);
	assign sourceElem_ready = sourceElem_ready_0;
endmodule
module AddRawFN_Pipelined_8_24 (
	clock,
	io_a_isNaN,
	io_a_isInf,
	io_a_isZero,
	io_a_sign,
	io_a_sExp,
	io_a_sig,
	io_b_isNaN,
	io_b_isInf,
	io_b_isZero,
	io_b_sign,
	io_b_sExp,
	io_b_sig,
	io_invalidExc,
	io_rawOut_isNaN,
	io_rawOut_isInf,
	io_rawOut_isZero,
	io_rawOut_sign,
	io_rawOut_sExp,
	io_rawOut_sig
);
	input clock;
	input io_a_isNaN;
	input io_a_isInf;
	input io_a_isZero;
	input io_a_sign;
	input [9:0] io_a_sExp;
	input [24:0] io_a_sig;
	input io_b_isNaN;
	input io_b_isInf;
	input io_b_isZero;
	input io_b_sign;
	input [9:0] io_b_sExp;
	input [24:0] io_b_sig;
	output wire io_invalidExc;
	output wire io_rawOut_isNaN;
	output wire io_rawOut_isInf;
	output wire io_rawOut_isZero;
	output wire io_rawOut_sign;
	output wire [9:0] io_rawOut_sExp;
	output wire [26:0] io_rawOut_sig;
	reg [12:0] stage1_close_reduced2SigSum;
	wire [3:0] stage1_close_normDistReduced2 = (stage1_close_reduced2SigSum[12] ? 4'h0 : (stage1_close_reduced2SigSum[11] ? 4'h1 : (stage1_close_reduced2SigSum[10] ? 4'h2 : (stage1_close_reduced2SigSum[9] ? 4'h3 : (stage1_close_reduced2SigSum[8] ? 4'h4 : (stage1_close_reduced2SigSum[7] ? 4'h5 : (stage1_close_reduced2SigSum[6] ? 4'h6 : (stage1_close_reduced2SigSum[5] ? 4'h7 : (stage1_close_reduced2SigSum[4] ? 4'h8 : (stage1_close_reduced2SigSum[3] ? 4'h9 : (stage1_close_reduced2SigSum[2] ? 4'ha : (stage1_close_reduced2SigSum[1] ? 4'hb : 4'hc))))))))))));
	reg [25:0] stage1_close_sigSum;
	wire [56:0] _GEN = {31'h00000000, stage1_close_sigSum} << {52'h0000000000000, stage1_close_normDistReduced2, 1'h0};
	reg stage1_a_isNaN;
	reg stage1_a_isInf;
	reg stage1_a_sign;
	reg [9:0] stage1_a_sExp;
	reg [24:0] stage1_a_sig;
	reg [26:0] stage1_close_sSigSum;
	reg [4:0] stage1_alignDist;
	wire [8:0] shift = $signed(9'sh100 >>> stage1_alignDist[4:2]);
	reg [28:0] stage1_far_mainAlignedSigSmaller;
	reg [6:0] stage1_far_reduced4SigSmaller;
	wire _GEN_0 = |stage1_far_mainAlignedSigSmaller[2:0] | (|(stage1_far_reduced4SigSmaller & {shift[1], shift[2], shift[3], shift[4], shift[5], shift[6], shift[7]}));
	reg stage1_eqSigns;
	reg [23:0] stage1_far_sigLarger;
	wire [27:0] stage1_far_sigSum = ({1'h0, stage1_far_sigLarger, 3'h0} + (stage1_eqSigns ? {1'h0, stage1_far_mainAlignedSigSmaller[28:3], _GEN_0} : {1'h1, ~{stage1_far_mainAlignedSigSmaller[28:3], _GEN_0}})) + {27'h0000000, ~stage1_eqSigns};
	reg stage1_addZeros;
	reg stage1_notNaN_isInfOut;
	reg stage1_closeSubMags;
	wire io_rawOut_isZero_0 = stage1_addZeros | ((~stage1_notNaN_isInfOut & stage1_closeSubMags) & ~(|_GEN[25:24]));
	reg stage1_b_isNaN;
	reg stage1_b_isInf;
	reg [9:0] stage1_b_sExp;
	reg [24:0] stage1_b_sig;
	reg stage1_effSignB;
	reg stage1_notEqSigns_signZero;
	reg stage1_notNaN_specialCase;
	reg stage1_far_signOut;
	reg [9:0] stage1_sDiffExps;
	reg io_invalidExc_stage1_notSigNaN_invalidExc;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg stage0_eqSigns;
		reg [9:0] _GEN_1;
		reg _GEN_2;
		reg [4:0] stage0_modNatAlignDist;
		reg stage0_isMaxAlign;
		reg [4:0] stage0_alignDist;
		reg stage0_notNaN_isInfOut;
		reg stage0_addZeros;
		reg _GEN_3;
		reg [26:0] _GEN_4;
		reg [25:0] _GEN_5;
		reg [26:0] _GEN_6;
		reg [25:0] stage0_close_sigSum;
		reg [23:0] stage0_far_sigSmaller;
		stage0_eqSigns = io_a_sign == io_b_sign;
		_GEN_1 = io_a_sExp - io_b_sExp;
		_GEN_2 = $signed(_GEN_1) < 10'sh000;
		stage0_modNatAlignDist = (_GEN_2 ? io_b_sExp[4:0] - io_a_sExp[4:0] : _GEN_1[4:0]);
		stage0_isMaxAlign = |_GEN_1[9:5] & ((_GEN_1[9:5] != 5'h1f) | (_GEN_1[4:0] == 5'h00));
		stage0_alignDist = (stage0_isMaxAlign ? 5'h1f : stage0_modNatAlignDist);
		stage0_notNaN_isInfOut = io_a_isInf | io_b_isInf;
		stage0_addZeros = io_a_isZero & io_b_isZero;
		_GEN_3 = $signed(_GEN_1) > -10'sh001;
		_GEN_4 = (_GEN_3 & _GEN_1[0] ? {io_a_sig, 2'h0} : 27'h0000000);
		_GEN_5 = _GEN_4[25:0] | (_GEN_3 & ~_GEN_1[0] ? {io_a_sig, 1'h0} : 26'h0000000);
		_GEN_6 = {_GEN_4[26], _GEN_5[25], _GEN_5[24:0] | (_GEN_2 ? io_a_sig : 25'h0000000)} - {io_b_sig[24], io_b_sig, 1'h0};
		stage0_close_sigSum = ($signed(_GEN_6) < 27'sh0000000 ? 26'h0000000 - _GEN_6[25:0] : _GEN_6[25:0]);
		stage0_far_sigSmaller = (_GEN_2 ? io_a_sig[23:0] : io_b_sig[23:0]);
		stage1_close_reduced2SigSum <= {|stage0_close_sigSum[25:24], |stage0_close_sigSum[23:22], |stage0_close_sigSum[21:20], |stage0_close_sigSum[19:18], |stage0_close_sigSum[17:16], |stage0_close_sigSum[15:14], |stage0_close_sigSum[13:12], |stage0_close_sigSum[11:10], |stage0_close_sigSum[9:8], |stage0_close_sigSum[7:6], |stage0_close_sigSum[5:4], |stage0_close_sigSum[3:2], |stage0_close_sigSum[1:0]};
		stage1_close_sigSum <= stage0_close_sigSum;
		stage1_a_isNaN <= io_a_isNaN;
		stage1_a_isInf <= io_a_isInf;
		stage1_a_sign <= io_a_sign;
		stage1_a_sExp <= io_a_sExp;
		stage1_a_sig <= io_a_sig;
		stage1_close_sSigSum <= _GEN_6;
		stage1_alignDist <= stage0_alignDist;
		stage1_far_mainAlignedSigSmaller <= {stage0_far_sigSmaller, 5'h00} >> stage0_alignDist;
		stage1_far_reduced4SigSmaller <= {|stage0_far_sigSmaller[23:22], |stage0_far_sigSmaller[21:18], |stage0_far_sigSmaller[17:14], |stage0_far_sigSmaller[13:10], |stage0_far_sigSmaller[9:6], |stage0_far_sigSmaller[5:2], |stage0_far_sigSmaller[1:0]};
		stage1_eqSigns <= stage0_eqSigns;
		stage1_far_sigLarger <= (_GEN_2 ? io_b_sig[23:0] : io_a_sig[23:0]);
		stage1_addZeros <= stage0_addZeros;
		stage1_notNaN_isInfOut <= stage0_notNaN_isInfOut;
		stage1_closeSubMags <= (~stage0_eqSigns & ~stage0_isMaxAlign) & (stage0_modNatAlignDist < 5'h02);
		stage1_b_isNaN <= io_b_isNaN;
		stage1_b_isInf <= io_b_isInf;
		stage1_b_sExp <= io_b_sExp;
		stage1_b_sig <= io_b_sig;
		stage1_effSignB <= io_b_sign;
		stage1_notEqSigns_signZero <= 1'h0;
		stage1_notNaN_specialCase <= stage0_notNaN_isInfOut | stage0_addZeros;
		stage1_far_signOut <= (_GEN_2 ? io_b_sign : io_a_sign);
		stage1_sDiffExps <= _GEN_1;
		io_invalidExc_stage1_notSigNaN_invalidExc <= (io_a_isInf & io_b_isInf) & ~stage0_eqSigns;
	end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:7];
	end
	assign io_invalidExc = ((stage1_a_isNaN & ~stage1_a_sig[22]) | (stage1_b_isNaN & ~stage1_b_sig[22])) | io_invalidExc_stage1_notSigNaN_invalidExc;
	assign io_rawOut_isNaN = stage1_a_isNaN | stage1_b_isNaN;
	assign io_rawOut_isInf = stage1_notNaN_isInfOut;
	assign io_rawOut_isZero = io_rawOut_isZero_0;
	assign io_rawOut_sign = (((((stage1_eqSigns & stage1_a_sign) | (stage1_a_isInf & stage1_a_sign)) | (stage1_b_isInf & stage1_effSignB)) | ((io_rawOut_isZero_0 & ~stage1_eqSigns) & stage1_notEqSigns_signZero)) | (((~stage1_notNaN_specialCase & stage1_closeSubMags) & |_GEN[25:24]) & (stage1_a_sign ^ ($signed(stage1_close_sSigSum) < 27'sh0000000)))) | ((~stage1_notNaN_specialCase & ~stage1_closeSubMags) & stage1_far_signOut);
	assign io_rawOut_sExp = (stage1_closeSubMags | ($signed(stage1_sDiffExps) < 10'sh000) ? stage1_b_sExp : stage1_a_sExp) - {5'h00, (stage1_closeSubMags ? {stage1_close_normDistReduced2, 1'h0} : {4'h0, ~stage1_eqSigns})};
	assign io_rawOut_sig = (stage1_closeSubMags ? {_GEN[25:0], 1'h0} : (stage1_eqSigns ? {stage1_far_sigSum[27:2], stage1_far_sigSum[1] | stage1_far_sigSum[0]} : stage1_far_sigSum[26:0]));
endmodule
module AddRecFN_Pipelined_8_24 (
	clock,
	io_a,
	io_b,
	io_out
);
	input clock;
	input [32:0] io_a;
	input [32:0] io_b;
	output wire [32:0] io_out;
	wire [32:0] _roundRawFNToRecFN_io_out;
	wire _addRawFN_io_invalidExc;
	wire _addRawFN_io_rawOut_isNaN;
	wire _addRawFN_io_rawOut_isInf;
	wire _addRawFN_io_rawOut_isZero;
	wire _addRawFN_io_rawOut_sign;
	wire [9:0] _addRawFN_io_rawOut_sExp;
	wire [26:0] _addRawFN_io_rawOut_sig;
	reg [32:0] addRawFN_io_a_stage1_a;
	reg [32:0] addRawFN_io_b_stage1_b;
	reg roundRawFNToRecFN_io_invalidExc_stage3_addRawFN_invalidExc;
	reg roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isNaN;
	reg roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isInf;
	reg roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isZero;
	reg roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sign;
	reg [9:0] roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sExp;
	reg [26:0] roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sig;
	reg [32:0] io_out_stage4_roundRawFNToRecFN_out;
	always @(posedge clock) begin
		addRawFN_io_a_stage1_a <= io_a;
		addRawFN_io_b_stage1_b <= io_b;
		roundRawFNToRecFN_io_invalidExc_stage3_addRawFN_invalidExc <= _addRawFN_io_invalidExc;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isNaN <= _addRawFN_io_rawOut_isNaN;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isInf <= _addRawFN_io_rawOut_isInf;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isZero <= _addRawFN_io_rawOut_isZero;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sign <= _addRawFN_io_rawOut_sign;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sExp <= _addRawFN_io_rawOut_sExp;
		roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sig <= _addRawFN_io_rawOut_sig;
		io_out_stage4_roundRawFNToRecFN_out <= _roundRawFNToRecFN_io_out;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:4];
	end
	AddRawFN_Pipelined_8_24 addRawFN(
		.clock(clock),
		.io_a_isNaN(&addRawFN_io_a_stage1_a[31:30] & addRawFN_io_a_stage1_a[29]),
		.io_a_isInf(&addRawFN_io_a_stage1_a[31:30] & ~addRawFN_io_a_stage1_a[29]),
		.io_a_isZero(~(|addRawFN_io_a_stage1_a[31:29])),
		.io_a_sign(addRawFN_io_a_stage1_a[32]),
		.io_a_sExp({1'h0, addRawFN_io_a_stage1_a[31:23]}),
		.io_a_sig({1'h0, |addRawFN_io_a_stage1_a[31:29], addRawFN_io_a_stage1_a[22:0]}),
		.io_b_isNaN(&addRawFN_io_b_stage1_b[31:30] & addRawFN_io_b_stage1_b[29]),
		.io_b_isInf(&addRawFN_io_b_stage1_b[31:30] & ~addRawFN_io_b_stage1_b[29]),
		.io_b_isZero(~(|addRawFN_io_b_stage1_b[31:29])),
		.io_b_sign(addRawFN_io_b_stage1_b[32]),
		.io_b_sExp({1'h0, addRawFN_io_b_stage1_b[31:23]}),
		.io_b_sig({1'h0, |addRawFN_io_b_stage1_b[31:29], addRawFN_io_b_stage1_b[22:0]}),
		.io_invalidExc(_addRawFN_io_invalidExc),
		.io_rawOut_isNaN(_addRawFN_io_rawOut_isNaN),
		.io_rawOut_isInf(_addRawFN_io_rawOut_isInf),
		.io_rawOut_isZero(_addRawFN_io_rawOut_isZero),
		.io_rawOut_sign(_addRawFN_io_rawOut_sign),
		.io_rawOut_sExp(_addRawFN_io_rawOut_sExp),
		.io_rawOut_sig(_addRawFN_io_rawOut_sig)
	);
	RoundRawFNToRecFN_e8_s24 roundRawFNToRecFN(
		.io_invalidExc(roundRawFNToRecFN_io_invalidExc_stage3_addRawFN_invalidExc),
		.io_in_isNaN(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isNaN),
		.io_in_isInf(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isInf),
		.io_in_isZero(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_isZero),
		.io_in_sign(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sign),
		.io_in_sExp(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sExp),
		.io_in_sig(roundRawFNToRecFN_io_in_stage3_addRawFN_rawOut_sig),
		.io_out(_roundRawFNToRecFN_io_out)
	);
	assign io_out = io_out_stage4_roundRawFNToRecFN_out;
endmodule
module AddFp_Pipelined_8_23 (
	clock,
	io_in_a_sign,
	io_in_a_exponent,
	io_in_a_mantissa,
	io_in_b_sign,
	io_in_b_exponent,
	io_in_b_mantissa,
	io_out_sign,
	io_out_exponent,
	io_out_mantissa
);
	input clock;
	input io_in_a_sign;
	input [7:0] io_in_a_exponent;
	input [22:0] io_in_a_mantissa;
	input io_in_b_sign;
	input [7:0] io_in_b_exponent;
	input [22:0] io_in_b_mantissa;
	output wire io_out_sign;
	output wire [7:0] io_out_exponent;
	output wire [22:0] io_out_mantissa;
	wire [32:0] _addRecFN_io_out;
	wire addRecFN_io_a_rawIn_isZeroExpIn = io_in_a_exponent == 8'h00;
	wire [4:0] addRecFN_io_a_rawIn_normDist = (io_in_a_mantissa[22] ? 5'h00 : (io_in_a_mantissa[21] ? 5'h01 : (io_in_a_mantissa[20] ? 5'h02 : (io_in_a_mantissa[19] ? 5'h03 : (io_in_a_mantissa[18] ? 5'h04 : (io_in_a_mantissa[17] ? 5'h05 : (io_in_a_mantissa[16] ? 5'h06 : (io_in_a_mantissa[15] ? 5'h07 : (io_in_a_mantissa[14] ? 5'h08 : (io_in_a_mantissa[13] ? 5'h09 : (io_in_a_mantissa[12] ? 5'h0a : (io_in_a_mantissa[11] ? 5'h0b : (io_in_a_mantissa[10] ? 5'h0c : (io_in_a_mantissa[9] ? 5'h0d : (io_in_a_mantissa[8] ? 5'h0e : (io_in_a_mantissa[7] ? 5'h0f : (io_in_a_mantissa[6] ? 5'h10 : (io_in_a_mantissa[5] ? 5'h11 : (io_in_a_mantissa[4] ? 5'h12 : (io_in_a_mantissa[3] ? 5'h13 : (io_in_a_mantissa[2] ? 5'h14 : (io_in_a_mantissa[1] ? 5'h15 : 5'h16))))))))))))))))))))));
	wire [53:0] _addRecFN_io_a_rawIn_subnormFract_T = {31'h00000000, io_in_a_mantissa} << addRecFN_io_a_rawIn_normDist;
	wire [8:0] _addRecFN_io_a_rawIn_adjustedExp_T_4 = (addRecFN_io_a_rawIn_isZeroExpIn ? {4'hf, ~addRecFN_io_a_rawIn_normDist} : {1'h0, io_in_a_exponent}) + {7'h20, (addRecFN_io_a_rawIn_isZeroExpIn ? 2'h2 : 2'h1)};
	wire [2:0] _addRecFN_io_a_T_2 = (addRecFN_io_a_rawIn_isZeroExpIn & ~(|io_in_a_mantissa) ? 3'h0 : _addRecFN_io_a_rawIn_adjustedExp_T_4[8:6]);
	wire addRecFN_io_b_rawIn_isZeroExpIn = io_in_b_exponent == 8'h00;
	wire [4:0] addRecFN_io_b_rawIn_normDist = (io_in_b_mantissa[22] ? 5'h00 : (io_in_b_mantissa[21] ? 5'h01 : (io_in_b_mantissa[20] ? 5'h02 : (io_in_b_mantissa[19] ? 5'h03 : (io_in_b_mantissa[18] ? 5'h04 : (io_in_b_mantissa[17] ? 5'h05 : (io_in_b_mantissa[16] ? 5'h06 : (io_in_b_mantissa[15] ? 5'h07 : (io_in_b_mantissa[14] ? 5'h08 : (io_in_b_mantissa[13] ? 5'h09 : (io_in_b_mantissa[12] ? 5'h0a : (io_in_b_mantissa[11] ? 5'h0b : (io_in_b_mantissa[10] ? 5'h0c : (io_in_b_mantissa[9] ? 5'h0d : (io_in_b_mantissa[8] ? 5'h0e : (io_in_b_mantissa[7] ? 5'h0f : (io_in_b_mantissa[6] ? 5'h10 : (io_in_b_mantissa[5] ? 5'h11 : (io_in_b_mantissa[4] ? 5'h12 : (io_in_b_mantissa[3] ? 5'h13 : (io_in_b_mantissa[2] ? 5'h14 : (io_in_b_mantissa[1] ? 5'h15 : 5'h16))))))))))))))))))))));
	wire [53:0] _addRecFN_io_b_rawIn_subnormFract_T = {31'h00000000, io_in_b_mantissa} << addRecFN_io_b_rawIn_normDist;
	wire [8:0] _addRecFN_io_b_rawIn_adjustedExp_T_4 = (addRecFN_io_b_rawIn_isZeroExpIn ? {4'hf, ~addRecFN_io_b_rawIn_normDist} : {1'h0, io_in_b_exponent}) + {7'h20, (addRecFN_io_b_rawIn_isZeroExpIn ? 2'h2 : 2'h1)};
	wire [2:0] _addRecFN_io_b_T_2 = (addRecFN_io_b_rawIn_isZeroExpIn & ~(|io_in_b_mantissa) ? 3'h0 : _addRecFN_io_b_rawIn_adjustedExp_T_4[8:6]);
	wire io_out_rawIn_isInf = &_addRecFN_io_out[31:30] & ~_addRecFN_io_out[29];
	wire io_out_isSubnormal = $signed({1'h0, _addRecFN_io_out[31:23]}) < 10'sh082;
	wire [23:0] _io_out_denormFract_T_1 = {1'h0, |_addRecFN_io_out[31:29], _addRecFN_io_out[22:1]} >> (5'h01 - _addRecFN_io_out[27:23]);
	AddRecFN_Pipelined_8_24 addRecFN(
		.clock(clock),
		.io_a({io_in_a_sign, _addRecFN_io_a_T_2[2:1], _addRecFN_io_a_T_2[0] | (&_addRecFN_io_a_rawIn_adjustedExp_T_4[8:7] & |io_in_a_mantissa), _addRecFN_io_a_rawIn_adjustedExp_T_4[5:0], (addRecFN_io_a_rawIn_isZeroExpIn ? {_addRecFN_io_a_rawIn_subnormFract_T[21:0], 1'h0} : io_in_a_mantissa)}),
		.io_b({io_in_b_sign, _addRecFN_io_b_T_2[2:1], _addRecFN_io_b_T_2[0] | (&_addRecFN_io_b_rawIn_adjustedExp_T_4[8:7] & |io_in_b_mantissa), _addRecFN_io_b_rawIn_adjustedExp_T_4[5:0], (addRecFN_io_b_rawIn_isZeroExpIn ? {_addRecFN_io_b_rawIn_subnormFract_T[21:0], 1'h0} : io_in_b_mantissa)}),
		.io_out(_addRecFN_io_out)
	);
	assign io_out_sign = _addRecFN_io_out[32];
	assign io_out_exponent = (io_out_isSubnormal ? 8'h00 : _addRecFN_io_out[30:23] + 8'h7f) | {8 {(&_addRecFN_io_out[31:30] & _addRecFN_io_out[29]) | io_out_rawIn_isInf}};
	assign io_out_mantissa = (io_out_isSubnormal ? _io_out_denormFract_T_1[22:0] : (io_out_rawIn_isInf ? 23'h000000 : _addRecFN_io_out[22:0]));
endmodule
module OpAdd (
	clock,
	io_in_a_sign,
	io_in_a_exponent,
	io_in_a_mantissa,
	io_in_b_sign,
	io_in_b_exponent,
	io_in_b_mantissa,
	io_out_sign,
	io_out_exponent,
	io_out_mantissa
);
	input clock;
	input io_in_a_sign;
	input [7:0] io_in_a_exponent;
	input [22:0] io_in_a_mantissa;
	input io_in_b_sign;
	input [7:0] io_in_b_exponent;
	input [22:0] io_in_b_mantissa;
	output wire io_out_sign;
	output wire [7:0] io_out_exponent;
	output wire [22:0] io_out_mantissa;
	wire _module_io_out_sign;
	wire [7:0] _module_io_out_exponent;
	wire [22:0] _module_io_out_mantissa;
	wire [31:0] in_a__ = {io_in_a_sign, io_in_a_exponent, io_in_a_mantissa};
	wire [31:0] in_b__ = {io_in_b_sign, io_in_b_exponent, io_in_b_mantissa};
	wire [31:0] out__ = {_module_io_out_sign, _module_io_out_exponent, _module_io_out_mantissa};
	AddFp_Pipelined_8_23 module_0(
		.clock(clock),
		.io_in_a_sign(io_in_a_sign),
		.io_in_a_exponent(io_in_a_exponent),
		.io_in_a_mantissa(io_in_a_mantissa),
		.io_in_b_sign(io_in_b_sign),
		.io_in_b_exponent(io_in_b_exponent),
		.io_in_b_mantissa(io_in_b_mantissa),
		.io_out_sign(_module_io_out_sign),
		.io_out_exponent(_module_io_out_exponent),
		.io_out_mantissa(_module_io_out_mantissa)
	);
	assign io_out_sign = _module_io_out_sign;
	assign io_out_exponent = _module_io_out_exponent;
	assign io_out_mantissa = _module_io_out_mantissa;
endmodule
module Counter_33 (
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
	reg [3:0] rCounter;
	always @(posedge clock)
		if (reset)
			rCounter <= 4'h0;
		else if (~(io_incEn & io_decEn)) begin
			if (io_incEn)
				rCounter <= rCounter + 4'h1;
			else if (io_decEn)
				rCounter <= rCounter - 4'h1;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_full = rCounter == 4'h8;
endmodule
module ram_8x256 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [2:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [255:0] R0_data;
	input [2:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [255:0] W0_data;
	reg [255:0] Memory [0:7];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [255:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 256'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue8_UInt256 (
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
	input [255:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits;
	wire io_enq_ready;
	reg [2:0] enq_ptr_value;
	reg [2:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire do_enq = io_enq_ready & io_enq_valid;
	assign io_enq_ready = ~(ptr_match & maybe_full);
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 3'h0;
			deq_ptr_value <= 3'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 3'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 3'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_8x256 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_deq_valid = ~empty;
endmodule
module Wrapper_1 (
	clock,
	reset,
	source_ready,
	source_valid,
	source_bits__1,
	source_bits__2,
	sink_ready,
	sink_valid,
	sink_bits,
	moduleIn__1,
	moduleIn__2,
	moduleOut
);
	input clock;
	input reset;
	output wire source_ready;
	input source_valid;
	input [255:0] source_bits__1;
	input [255:0] source_bits__2;
	input sink_ready;
	output wire sink_valid;
	output wire [255:0] sink_bits;
	output wire [255:0] moduleIn__1;
	output wire [255:0] moduleIn__2;
	input [255:0] moduleOut;
	wire _qOutput_io_deq_valid;
	wire _ctr_io_full;
	wire source_ready_0 = ~_ctr_io_full & source_valid;
	wire _qOutput_io_enq_valid_T = source_ready_0 & source_valid;
	reg qOutput_io_enq_valid_r;
	reg qOutput_io_enq_valid_r_1;
	reg qOutput_io_enq_valid_r_2;
	reg qOutput_io_enq_valid_r_3;
	always @(posedge clock) begin
		qOutput_io_enq_valid_r <= _qOutput_io_enq_valid_T;
		qOutput_io_enq_valid_r_1 <= qOutput_io_enq_valid_r;
		qOutput_io_enq_valid_r_2 <= qOutput_io_enq_valid_r_1;
		qOutput_io_enq_valid_r_3 <= qOutput_io_enq_valid_r_2;
	end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Counter_33 ctr(
		.clock(clock),
		.reset(reset),
		.io_incEn(_qOutput_io_enq_valid_T),
		.io_decEn(sink_ready & _qOutput_io_deq_valid),
		.io_full(_ctr_io_full)
	);
	Queue8_UInt256 qOutput(
		.clock(clock),
		.reset(reset),
		.io_enq_valid(qOutput_io_enq_valid_r_3),
		.io_enq_bits(moduleOut),
		.io_deq_ready(sink_ready),
		.io_deq_valid(_qOutput_io_deq_valid),
		.io_deq_bits(sink_bits)
	);
	assign source_ready = source_ready_0;
	assign sink_valid = _qOutput_io_deq_valid;
	assign moduleIn__1 = source_bits__1;
	assign moduleIn__2 = source_bits__2;
endmodule
module BatchAdd (
	clock,
	reset,
	req_ready,
	req_valid,
	req_bits__1,
	req_bits__2,
	resp_ready,
	resp_valid,
	resp_bits
);
	input clock;
	input reset;
	output wire req_ready;
	input req_valid;
	input [255:0] req_bits__1;
	input [255:0] req_bits__2;
	input resp_ready;
	output wire resp_valid;
	output wire [255:0] resp_bits;
	wire [255:0] _wrapper_moduleIn__1;
	wire [255:0] _wrapper_moduleIn__2;
	wire _add7_io_out_sign;
	wire [7:0] _add7_io_out_exponent;
	wire [22:0] _add7_io_out_mantissa;
	wire _add6_io_out_sign;
	wire [7:0] _add6_io_out_exponent;
	wire [22:0] _add6_io_out_mantissa;
	wire _add5_io_out_sign;
	wire [7:0] _add5_io_out_exponent;
	wire [22:0] _add5_io_out_mantissa;
	wire _add4_io_out_sign;
	wire [7:0] _add4_io_out_exponent;
	wire [22:0] _add4_io_out_mantissa;
	wire _add3_io_out_sign;
	wire [7:0] _add3_io_out_exponent;
	wire [22:0] _add3_io_out_mantissa;
	wire _add2_io_out_sign;
	wire [7:0] _add2_io_out_exponent;
	wire [22:0] _add2_io_out_mantissa;
	wire _add1_io_out_sign;
	wire [7:0] _add1_io_out_exponent;
	wire [22:0] _add1_io_out_mantissa;
	wire _add0_io_out_sign;
	wire [7:0] _add0_io_out_exponent;
	wire [22:0] _add0_io_out_mantissa;
	OpAdd add0(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[31]),
		.io_in_a_exponent(_wrapper_moduleIn__1[30:23]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[22:0]),
		.io_in_b_sign(_wrapper_moduleIn__2[31]),
		.io_in_b_exponent(_wrapper_moduleIn__2[30:23]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[22:0]),
		.io_out_sign(_add0_io_out_sign),
		.io_out_exponent(_add0_io_out_exponent),
		.io_out_mantissa(_add0_io_out_mantissa)
	);
	OpAdd add1(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[63]),
		.io_in_a_exponent(_wrapper_moduleIn__1[62:55]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[54:32]),
		.io_in_b_sign(_wrapper_moduleIn__2[63]),
		.io_in_b_exponent(_wrapper_moduleIn__2[62:55]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[54:32]),
		.io_out_sign(_add1_io_out_sign),
		.io_out_exponent(_add1_io_out_exponent),
		.io_out_mantissa(_add1_io_out_mantissa)
	);
	OpAdd add2(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[95]),
		.io_in_a_exponent(_wrapper_moduleIn__1[94:87]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[86:64]),
		.io_in_b_sign(_wrapper_moduleIn__2[95]),
		.io_in_b_exponent(_wrapper_moduleIn__2[94:87]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[86:64]),
		.io_out_sign(_add2_io_out_sign),
		.io_out_exponent(_add2_io_out_exponent),
		.io_out_mantissa(_add2_io_out_mantissa)
	);
	OpAdd add3(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[127]),
		.io_in_a_exponent(_wrapper_moduleIn__1[126:119]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[118:96]),
		.io_in_b_sign(_wrapper_moduleIn__2[127]),
		.io_in_b_exponent(_wrapper_moduleIn__2[126:119]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[118:96]),
		.io_out_sign(_add3_io_out_sign),
		.io_out_exponent(_add3_io_out_exponent),
		.io_out_mantissa(_add3_io_out_mantissa)
	);
	OpAdd add4(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[159]),
		.io_in_a_exponent(_wrapper_moduleIn__1[158:151]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[150:128]),
		.io_in_b_sign(_wrapper_moduleIn__2[159]),
		.io_in_b_exponent(_wrapper_moduleIn__2[158:151]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[150:128]),
		.io_out_sign(_add4_io_out_sign),
		.io_out_exponent(_add4_io_out_exponent),
		.io_out_mantissa(_add4_io_out_mantissa)
	);
	OpAdd add5(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[191]),
		.io_in_a_exponent(_wrapper_moduleIn__1[190:183]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[182:160]),
		.io_in_b_sign(_wrapper_moduleIn__2[191]),
		.io_in_b_exponent(_wrapper_moduleIn__2[190:183]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[182:160]),
		.io_out_sign(_add5_io_out_sign),
		.io_out_exponent(_add5_io_out_exponent),
		.io_out_mantissa(_add5_io_out_mantissa)
	);
	OpAdd add6(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[223]),
		.io_in_a_exponent(_wrapper_moduleIn__1[222:215]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[214:192]),
		.io_in_b_sign(_wrapper_moduleIn__2[223]),
		.io_in_b_exponent(_wrapper_moduleIn__2[222:215]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[214:192]),
		.io_out_sign(_add6_io_out_sign),
		.io_out_exponent(_add6_io_out_exponent),
		.io_out_mantissa(_add6_io_out_mantissa)
	);
	OpAdd add7(
		.clock(clock),
		.io_in_a_sign(_wrapper_moduleIn__1[255]),
		.io_in_a_exponent(_wrapper_moduleIn__1[254:247]),
		.io_in_a_mantissa(_wrapper_moduleIn__1[246:224]),
		.io_in_b_sign(_wrapper_moduleIn__2[255]),
		.io_in_b_exponent(_wrapper_moduleIn__2[254:247]),
		.io_in_b_mantissa(_wrapper_moduleIn__2[246:224]),
		.io_out_sign(_add7_io_out_sign),
		.io_out_exponent(_add7_io_out_exponent),
		.io_out_mantissa(_add7_io_out_mantissa)
	);
	Wrapper_1 wrapper(
		.clock(clock),
		.reset(reset),
		.source_ready(req_ready),
		.source_valid(req_valid),
		.source_bits__1(req_bits__1),
		.source_bits__2(req_bits__2),
		.sink_ready(resp_ready),
		.sink_valid(resp_valid),
		.sink_bits(resp_bits),
		.moduleIn__1(_wrapper_moduleIn__1),
		.moduleIn__2(_wrapper_moduleIn__2),
		.moduleOut({_add7_io_out_sign, _add7_io_out_exponent, _add7_io_out_mantissa, _add6_io_out_sign, _add6_io_out_exponent, _add6_io_out_mantissa, _add5_io_out_sign, _add5_io_out_exponent, _add5_io_out_mantissa, _add4_io_out_sign, _add4_io_out_exponent, _add4_io_out_mantissa, _add3_io_out_sign, _add3_io_out_exponent, _add3_io_out_mantissa, _add2_io_out_sign, _add2_io_out_exponent, _add2_io_out_mantissa, _add1_io_out_sign, _add1_io_out_exponent, _add1_io_out_mantissa, _add0_io_out_sign, _add0_io_out_exponent, _add0_io_out_mantissa})
	);
endmodule
module ram_16x5 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [3:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [4:0] R0_data;
	input [3:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [4:0] W0_data;
	reg [4:0] Memory [0:15];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 5'bxxxxx);
endmodule
module Queue16_UInt5 (
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
	input [4:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [4:0] io_deq_bits;
	reg [3:0] enq_ptr_value;
	reg [3:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 4'h0;
			deq_ptr_value <= 4'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 4'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 4'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_16x5 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module ram_2x3 (
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
	output wire [2:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [2:0] W0_data;
	reg [2:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 3'bxxx);
endmodule
module Queue2_UInt3 (
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
	input [2:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [2:0] io_deq_bits;
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
	ram_2x3 ram_ext(
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
module elasticBasicArbiter_2 (
	clock,
	reset,
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits__1,
	io_sources_0_bits__2,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits__1,
	io_sources_1_bits__2,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits__1,
	io_sources_2_bits__2,
	io_sources_3_ready,
	io_sources_3_valid,
	io_sources_3_bits__1,
	io_sources_3_bits__2,
	io_sources_4_ready,
	io_sources_4_valid,
	io_sources_4_bits__1,
	io_sources_4_bits__2,
	io_sources_5_ready,
	io_sources_5_valid,
	io_sources_5_bits__1,
	io_sources_5_bits__2,
	io_sources_6_ready,
	io_sources_6_valid,
	io_sources_6_bits__1,
	io_sources_6_bits__2,
	io_sources_7_ready,
	io_sources_7_valid,
	io_sources_7_bits__1,
	io_sources_7_bits__2,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits__1,
	io_sink_bits__2,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	input clock;
	input reset;
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [255:0] io_sources_0_bits__1;
	input [255:0] io_sources_0_bits__2;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [255:0] io_sources_1_bits__1;
	input [255:0] io_sources_1_bits__2;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [255:0] io_sources_2_bits__1;
	input [255:0] io_sources_2_bits__2;
	output wire io_sources_3_ready;
	input io_sources_3_valid;
	input [255:0] io_sources_3_bits__1;
	input [255:0] io_sources_3_bits__2;
	output wire io_sources_4_ready;
	input io_sources_4_valid;
	input [255:0] io_sources_4_bits__1;
	input [255:0] io_sources_4_bits__2;
	output wire io_sources_5_ready;
	input io_sources_5_valid;
	input [255:0] io_sources_5_bits__1;
	input [255:0] io_sources_5_bits__2;
	output wire io_sources_6_ready;
	input io_sources_6_valid;
	input [255:0] io_sources_6_bits__1;
	input [255:0] io_sources_6_bits__2;
	output wire io_sources_7_ready;
	input io_sources_7_valid;
	input [255:0] io_sources_7_bits__1;
	input [255:0] io_sources_7_bits__2;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [255:0] io_sink_bits__1;
	output wire [255:0] io_sink_bits__2;
	input io_select_ready;
	output wire io_select_valid;
	output wire [2:0] io_select_bits;
	wire _select_sinkBuffer_io_enq_ready;
	wire _sink_sinkBuffer_io_enq_ready;
	reg [2:0] chooser_lastChoice;
	wire _chooser_rrChoice_T_4 = (chooser_lastChoice == 3'h0) & io_sources_1_valid;
	wire _chooser_rrChoice_T_6 = (chooser_lastChoice < 3'h2) & io_sources_2_valid;
	wire _chooser_rrChoice_T_8 = (chooser_lastChoice < 3'h3) & io_sources_3_valid;
	wire _chooser_rrChoice_T_10 = ~chooser_lastChoice[2] & io_sources_4_valid;
	wire _chooser_rrChoice_T_12 = (chooser_lastChoice < 3'h5) & io_sources_5_valid;
	wire [2:0] _chooser_rrChoice_T_17 = {2'h3, ~((chooser_lastChoice[2:1] != 2'h3) & io_sources_6_valid)};
	wire [2:0] chooser_rrChoice = (&chooser_lastChoice ? 3'h0 : (_chooser_rrChoice_T_4 ? 3'h1 : (_chooser_rrChoice_T_6 ? 3'h2 : (_chooser_rrChoice_T_8 ? 3'h3 : (_chooser_rrChoice_T_10 ? 3'h4 : (_chooser_rrChoice_T_12 ? 3'h5 : _chooser_rrChoice_T_17))))));
	wire [2:0] chooser_priorityChoice = (io_sources_0_valid ? 3'h0 : (io_sources_1_valid ? 3'h1 : (io_sources_2_valid ? 3'h2 : (io_sources_3_valid ? 3'h3 : (io_sources_4_valid ? 3'h4 : (io_sources_5_valid ? 3'h5 : {2'h3, ~io_sources_6_valid}))))));
	wire [7:0] _GEN = {io_sources_7_valid, io_sources_6_valid, io_sources_5_valid, io_sources_4_valid, io_sources_3_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [2:0] choice = (_GEN[chooser_rrChoice] ? chooser_rrChoice : chooser_priorityChoice);
	wire [2047:0] _GEN_0 = {io_sources_7_bits__1, io_sources_6_bits__1, io_sources_5_bits__1, io_sources_4_bits__1, io_sources_3_bits__1, io_sources_2_bits__1, io_sources_1_bits__1, io_sources_0_bits__1};
	wire [2047:0] _GEN_1 = {io_sources_7_bits__2, io_sources_6_bits__2, io_sources_5_bits__2, io_sources_4_bits__2, io_sources_3_bits__2, io_sources_2_bits__2, io_sources_1_bits__2, io_sources_0_bits__2};
	wire fire = (_GEN[choice] & _sink_sinkBuffer_io_enq_ready) & _select_sinkBuffer_io_enq_ready;
	always @(posedge clock)
		if (reset)
			chooser_lastChoice <= 3'h0;
		else if (fire) begin
			if (_GEN[chooser_rrChoice]) begin
				if (&chooser_lastChoice)
					chooser_lastChoice <= 3'h0;
				else if (_chooser_rrChoice_T_4)
					chooser_lastChoice <= 3'h1;
				else if (_chooser_rrChoice_T_6)
					chooser_lastChoice <= 3'h2;
				else if (_chooser_rrChoice_T_8)
					chooser_lastChoice <= 3'h3;
				else if (_chooser_rrChoice_T_10)
					chooser_lastChoice <= 3'h4;
				else if (_chooser_rrChoice_T_12)
					chooser_lastChoice <= 3'h5;
				else
					chooser_lastChoice <= _chooser_rrChoice_T_17;
			end
			else
				chooser_lastChoice <= chooser_priorityChoice;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_Bundle2 sink_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sink_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits__1(_GEN_0[choice * 256+:256]),
		.io_enq_bits__2(_GEN_1[choice * 256+:256]),
		.io_deq_ready(io_sink_ready),
		.io_deq_valid(io_sink_valid),
		.io_deq_bits__1(io_sink_bits__1),
		.io_deq_bits__2(io_sink_bits__2)
	);
	Queue2_UInt3 select_sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_select_sinkBuffer_io_enq_ready),
		.io_enq_valid(fire),
		.io_enq_bits(choice),
		.io_deq_ready(io_select_ready),
		.io_deq_valid(io_select_valid),
		.io_deq_bits(io_select_bits)
	);
	assign io_sources_0_ready = fire & (choice == 3'h0);
	assign io_sources_1_ready = fire & (choice == 3'h1);
	assign io_sources_2_ready = fire & (choice == 3'h2);
	assign io_sources_3_ready = fire & (choice == 3'h3);
	assign io_sources_4_ready = fire & (choice == 3'h4);
	assign io_sources_5_ready = fire & (choice == 3'h5);
	assign io_sources_6_ready = fire & (choice == 3'h6);
	assign io_sources_7_ready = fire & (&choice);
endmodule
module elasticDemux_34 (
	io_source_ready,
	io_source_valid,
	io_source_bits,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits,
	io_sinks_3_ready,
	io_sinks_3_valid,
	io_sinks_3_bits,
	io_sinks_4_ready,
	io_sinks_4_valid,
	io_sinks_4_bits,
	io_sinks_5_ready,
	io_sinks_5_valid,
	io_sinks_5_bits,
	io_sinks_6_ready,
	io_sinks_6_valid,
	io_sinks_6_bits,
	io_sinks_7_ready,
	io_sinks_7_valid,
	io_sinks_7_bits,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [255:0] io_source_bits;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [255:0] io_sinks_0_bits;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [255:0] io_sinks_1_bits;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [255:0] io_sinks_2_bits;
	input io_sinks_3_ready;
	output wire io_sinks_3_valid;
	output wire [255:0] io_sinks_3_bits;
	input io_sinks_4_ready;
	output wire io_sinks_4_valid;
	output wire [255:0] io_sinks_4_bits;
	input io_sinks_5_ready;
	output wire io_sinks_5_valid;
	output wire [255:0] io_sinks_5_bits;
	input io_sinks_6_ready;
	output wire io_sinks_6_valid;
	output wire [255:0] io_sinks_6_bits;
	input io_sinks_7_ready;
	output wire io_sinks_7_valid;
	output wire [255:0] io_sinks_7_bits;
	output wire io_select_ready;
	input io_select_valid;
	input [2:0] io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire [7:0] _GEN = {io_sinks_7_ready, io_sinks_6_ready, io_sinks_5_ready, io_sinks_4_ready, io_sinks_3_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & (io_select_bits == 3'h0);
	assign io_sinks_0_bits = io_source_bits;
	assign io_sinks_1_valid = valid & (io_select_bits == 3'h1);
	assign io_sinks_1_bits = io_source_bits;
	assign io_sinks_2_valid = valid & (io_select_bits == 3'h2);
	assign io_sinks_2_bits = io_source_bits;
	assign io_sinks_3_valid = valid & (io_select_bits == 3'h3);
	assign io_sinks_3_bits = io_source_bits;
	assign io_sinks_4_valid = valid & (io_select_bits == 3'h4);
	assign io_sinks_4_bits = io_source_bits;
	assign io_sinks_5_valid = valid & (io_select_bits == 3'h5);
	assign io_sinks_5_bits = io_source_bits;
	assign io_sinks_6_valid = valid & (io_select_bits == 3'h6);
	assign io_sinks_6_bits = io_source_bits;
	assign io_sinks_7_valid = valid & (&io_select_bits);
	assign io_sinks_7_bits = io_source_bits;
	assign io_select_ready = fire;
endmodule
module ram_32x257 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [4:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [256:0] R0_data;
	input [4:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [256:0] W0_data;
	reg [256:0] Memory [0:31];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 257'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue32_DataLast (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire io_deq_bits_last;
	wire [256:0] _ram_ext_R0_data;
	reg [4:0] enq_ptr_value;
	reg [4:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 5'h00;
			deq_ptr_value <= 5'h00;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 5'h01;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 5'h01;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_32x257 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_last = _ram_ext_R0_data[256];
endmodule
module Counter_37 (
	clock,
	reset,
	sink_ready,
	sink_bits
);
	input clock;
	input reset;
	input sink_ready;
	output wire [4:0] sink_bits;
	reg [4:0] counter;
	always @(posedge clock)
		if (reset)
			counter <= 5'h00;
		else if (sink_ready) begin
			if (&counter)
				counter <= 5'h00;
			else
				counter <= counter + 5'h01;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign sink_bits = counter;
endmodule
module elasticDemux_38 (
	io_source_ready,
	io_source_valid,
	io_source_bits_data,
	io_source_bits_last,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits_data,
	io_sinks_0_bits_last,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits_data,
	io_sinks_1_bits_last,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits_data,
	io_sinks_2_bits_last,
	io_sinks_3_ready,
	io_sinks_3_valid,
	io_sinks_3_bits_data,
	io_sinks_3_bits_last,
	io_sinks_4_ready,
	io_sinks_4_valid,
	io_sinks_4_bits_data,
	io_sinks_4_bits_last,
	io_sinks_5_ready,
	io_sinks_5_valid,
	io_sinks_5_bits_data,
	io_sinks_5_bits_last,
	io_sinks_6_ready,
	io_sinks_6_valid,
	io_sinks_6_bits_data,
	io_sinks_6_bits_last,
	io_sinks_7_ready,
	io_sinks_7_valid,
	io_sinks_7_bits_data,
	io_sinks_7_bits_last,
	io_sinks_8_ready,
	io_sinks_8_valid,
	io_sinks_8_bits_data,
	io_sinks_8_bits_last,
	io_sinks_9_ready,
	io_sinks_9_valid,
	io_sinks_9_bits_data,
	io_sinks_9_bits_last,
	io_sinks_10_ready,
	io_sinks_10_valid,
	io_sinks_10_bits_data,
	io_sinks_10_bits_last,
	io_sinks_11_ready,
	io_sinks_11_valid,
	io_sinks_11_bits_data,
	io_sinks_11_bits_last,
	io_sinks_12_ready,
	io_sinks_12_valid,
	io_sinks_12_bits_data,
	io_sinks_12_bits_last,
	io_sinks_13_ready,
	io_sinks_13_valid,
	io_sinks_13_bits_data,
	io_sinks_13_bits_last,
	io_sinks_14_ready,
	io_sinks_14_valid,
	io_sinks_14_bits_data,
	io_sinks_14_bits_last,
	io_sinks_15_ready,
	io_sinks_15_valid,
	io_sinks_15_bits_data,
	io_sinks_15_bits_last,
	io_sinks_16_ready,
	io_sinks_16_valid,
	io_sinks_16_bits_data,
	io_sinks_16_bits_last,
	io_sinks_17_ready,
	io_sinks_17_valid,
	io_sinks_17_bits_data,
	io_sinks_17_bits_last,
	io_sinks_18_ready,
	io_sinks_18_valid,
	io_sinks_18_bits_data,
	io_sinks_18_bits_last,
	io_sinks_19_ready,
	io_sinks_19_valid,
	io_sinks_19_bits_data,
	io_sinks_19_bits_last,
	io_sinks_20_ready,
	io_sinks_20_valid,
	io_sinks_20_bits_data,
	io_sinks_20_bits_last,
	io_sinks_21_ready,
	io_sinks_21_valid,
	io_sinks_21_bits_data,
	io_sinks_21_bits_last,
	io_sinks_22_ready,
	io_sinks_22_valid,
	io_sinks_22_bits_data,
	io_sinks_22_bits_last,
	io_sinks_23_ready,
	io_sinks_23_valid,
	io_sinks_23_bits_data,
	io_sinks_23_bits_last,
	io_sinks_24_ready,
	io_sinks_24_valid,
	io_sinks_24_bits_data,
	io_sinks_24_bits_last,
	io_sinks_25_ready,
	io_sinks_25_valid,
	io_sinks_25_bits_data,
	io_sinks_25_bits_last,
	io_sinks_26_ready,
	io_sinks_26_valid,
	io_sinks_26_bits_data,
	io_sinks_26_bits_last,
	io_sinks_27_ready,
	io_sinks_27_valid,
	io_sinks_27_bits_data,
	io_sinks_27_bits_last,
	io_sinks_28_ready,
	io_sinks_28_valid,
	io_sinks_28_bits_data,
	io_sinks_28_bits_last,
	io_sinks_29_ready,
	io_sinks_29_valid,
	io_sinks_29_bits_data,
	io_sinks_29_bits_last,
	io_sinks_30_ready,
	io_sinks_30_valid,
	io_sinks_30_bits_data,
	io_sinks_30_bits_last,
	io_sinks_31_ready,
	io_sinks_31_valid,
	io_sinks_31_bits_data,
	io_sinks_31_bits_last,
	io_select_ready,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [255:0] io_source_bits_data;
	input io_source_bits_last;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [255:0] io_sinks_0_bits_data;
	output wire io_sinks_0_bits_last;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [255:0] io_sinks_1_bits_data;
	output wire io_sinks_1_bits_last;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [255:0] io_sinks_2_bits_data;
	output wire io_sinks_2_bits_last;
	input io_sinks_3_ready;
	output wire io_sinks_3_valid;
	output wire [255:0] io_sinks_3_bits_data;
	output wire io_sinks_3_bits_last;
	input io_sinks_4_ready;
	output wire io_sinks_4_valid;
	output wire [255:0] io_sinks_4_bits_data;
	output wire io_sinks_4_bits_last;
	input io_sinks_5_ready;
	output wire io_sinks_5_valid;
	output wire [255:0] io_sinks_5_bits_data;
	output wire io_sinks_5_bits_last;
	input io_sinks_6_ready;
	output wire io_sinks_6_valid;
	output wire [255:0] io_sinks_6_bits_data;
	output wire io_sinks_6_bits_last;
	input io_sinks_7_ready;
	output wire io_sinks_7_valid;
	output wire [255:0] io_sinks_7_bits_data;
	output wire io_sinks_7_bits_last;
	input io_sinks_8_ready;
	output wire io_sinks_8_valid;
	output wire [255:0] io_sinks_8_bits_data;
	output wire io_sinks_8_bits_last;
	input io_sinks_9_ready;
	output wire io_sinks_9_valid;
	output wire [255:0] io_sinks_9_bits_data;
	output wire io_sinks_9_bits_last;
	input io_sinks_10_ready;
	output wire io_sinks_10_valid;
	output wire [255:0] io_sinks_10_bits_data;
	output wire io_sinks_10_bits_last;
	input io_sinks_11_ready;
	output wire io_sinks_11_valid;
	output wire [255:0] io_sinks_11_bits_data;
	output wire io_sinks_11_bits_last;
	input io_sinks_12_ready;
	output wire io_sinks_12_valid;
	output wire [255:0] io_sinks_12_bits_data;
	output wire io_sinks_12_bits_last;
	input io_sinks_13_ready;
	output wire io_sinks_13_valid;
	output wire [255:0] io_sinks_13_bits_data;
	output wire io_sinks_13_bits_last;
	input io_sinks_14_ready;
	output wire io_sinks_14_valid;
	output wire [255:0] io_sinks_14_bits_data;
	output wire io_sinks_14_bits_last;
	input io_sinks_15_ready;
	output wire io_sinks_15_valid;
	output wire [255:0] io_sinks_15_bits_data;
	output wire io_sinks_15_bits_last;
	input io_sinks_16_ready;
	output wire io_sinks_16_valid;
	output wire [255:0] io_sinks_16_bits_data;
	output wire io_sinks_16_bits_last;
	input io_sinks_17_ready;
	output wire io_sinks_17_valid;
	output wire [255:0] io_sinks_17_bits_data;
	output wire io_sinks_17_bits_last;
	input io_sinks_18_ready;
	output wire io_sinks_18_valid;
	output wire [255:0] io_sinks_18_bits_data;
	output wire io_sinks_18_bits_last;
	input io_sinks_19_ready;
	output wire io_sinks_19_valid;
	output wire [255:0] io_sinks_19_bits_data;
	output wire io_sinks_19_bits_last;
	input io_sinks_20_ready;
	output wire io_sinks_20_valid;
	output wire [255:0] io_sinks_20_bits_data;
	output wire io_sinks_20_bits_last;
	input io_sinks_21_ready;
	output wire io_sinks_21_valid;
	output wire [255:0] io_sinks_21_bits_data;
	output wire io_sinks_21_bits_last;
	input io_sinks_22_ready;
	output wire io_sinks_22_valid;
	output wire [255:0] io_sinks_22_bits_data;
	output wire io_sinks_22_bits_last;
	input io_sinks_23_ready;
	output wire io_sinks_23_valid;
	output wire [255:0] io_sinks_23_bits_data;
	output wire io_sinks_23_bits_last;
	input io_sinks_24_ready;
	output wire io_sinks_24_valid;
	output wire [255:0] io_sinks_24_bits_data;
	output wire io_sinks_24_bits_last;
	input io_sinks_25_ready;
	output wire io_sinks_25_valid;
	output wire [255:0] io_sinks_25_bits_data;
	output wire io_sinks_25_bits_last;
	input io_sinks_26_ready;
	output wire io_sinks_26_valid;
	output wire [255:0] io_sinks_26_bits_data;
	output wire io_sinks_26_bits_last;
	input io_sinks_27_ready;
	output wire io_sinks_27_valid;
	output wire [255:0] io_sinks_27_bits_data;
	output wire io_sinks_27_bits_last;
	input io_sinks_28_ready;
	output wire io_sinks_28_valid;
	output wire [255:0] io_sinks_28_bits_data;
	output wire io_sinks_28_bits_last;
	input io_sinks_29_ready;
	output wire io_sinks_29_valid;
	output wire [255:0] io_sinks_29_bits_data;
	output wire io_sinks_29_bits_last;
	input io_sinks_30_ready;
	output wire io_sinks_30_valid;
	output wire [255:0] io_sinks_30_bits_data;
	output wire io_sinks_30_bits_last;
	input io_sinks_31_ready;
	output wire io_sinks_31_valid;
	output wire [255:0] io_sinks_31_bits_data;
	output wire io_sinks_31_bits_last;
	output wire io_select_ready;
	input [4:0] io_select_bits;
	wire [31:0] _GEN = {io_sinks_31_ready, io_sinks_30_ready, io_sinks_29_ready, io_sinks_28_ready, io_sinks_27_ready, io_sinks_26_ready, io_sinks_25_ready, io_sinks_24_ready, io_sinks_23_ready, io_sinks_22_ready, io_sinks_21_ready, io_sinks_20_ready, io_sinks_19_ready, io_sinks_18_ready, io_sinks_17_ready, io_sinks_16_ready, io_sinks_15_ready, io_sinks_14_ready, io_sinks_13_ready, io_sinks_12_ready, io_sinks_11_ready, io_sinks_10_ready, io_sinks_9_ready, io_sinks_8_ready, io_sinks_7_ready, io_sinks_6_ready, io_sinks_5_ready, io_sinks_4_ready, io_sinks_3_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = io_source_valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = io_source_valid & (io_select_bits == 5'h00);
	assign io_sinks_0_bits_data = io_source_bits_data;
	assign io_sinks_0_bits_last = io_source_bits_last;
	assign io_sinks_1_valid = io_source_valid & (io_select_bits == 5'h01);
	assign io_sinks_1_bits_data = io_source_bits_data;
	assign io_sinks_1_bits_last = io_source_bits_last;
	assign io_sinks_2_valid = io_source_valid & (io_select_bits == 5'h02);
	assign io_sinks_2_bits_data = io_source_bits_data;
	assign io_sinks_2_bits_last = io_source_bits_last;
	assign io_sinks_3_valid = io_source_valid & (io_select_bits == 5'h03);
	assign io_sinks_3_bits_data = io_source_bits_data;
	assign io_sinks_3_bits_last = io_source_bits_last;
	assign io_sinks_4_valid = io_source_valid & (io_select_bits == 5'h04);
	assign io_sinks_4_bits_data = io_source_bits_data;
	assign io_sinks_4_bits_last = io_source_bits_last;
	assign io_sinks_5_valid = io_source_valid & (io_select_bits == 5'h05);
	assign io_sinks_5_bits_data = io_source_bits_data;
	assign io_sinks_5_bits_last = io_source_bits_last;
	assign io_sinks_6_valid = io_source_valid & (io_select_bits == 5'h06);
	assign io_sinks_6_bits_data = io_source_bits_data;
	assign io_sinks_6_bits_last = io_source_bits_last;
	assign io_sinks_7_valid = io_source_valid & (io_select_bits == 5'h07);
	assign io_sinks_7_bits_data = io_source_bits_data;
	assign io_sinks_7_bits_last = io_source_bits_last;
	assign io_sinks_8_valid = io_source_valid & (io_select_bits == 5'h08);
	assign io_sinks_8_bits_data = io_source_bits_data;
	assign io_sinks_8_bits_last = io_source_bits_last;
	assign io_sinks_9_valid = io_source_valid & (io_select_bits == 5'h09);
	assign io_sinks_9_bits_data = io_source_bits_data;
	assign io_sinks_9_bits_last = io_source_bits_last;
	assign io_sinks_10_valid = io_source_valid & (io_select_bits == 5'h0a);
	assign io_sinks_10_bits_data = io_source_bits_data;
	assign io_sinks_10_bits_last = io_source_bits_last;
	assign io_sinks_11_valid = io_source_valid & (io_select_bits == 5'h0b);
	assign io_sinks_11_bits_data = io_source_bits_data;
	assign io_sinks_11_bits_last = io_source_bits_last;
	assign io_sinks_12_valid = io_source_valid & (io_select_bits == 5'h0c);
	assign io_sinks_12_bits_data = io_source_bits_data;
	assign io_sinks_12_bits_last = io_source_bits_last;
	assign io_sinks_13_valid = io_source_valid & (io_select_bits == 5'h0d);
	assign io_sinks_13_bits_data = io_source_bits_data;
	assign io_sinks_13_bits_last = io_source_bits_last;
	assign io_sinks_14_valid = io_source_valid & (io_select_bits == 5'h0e);
	assign io_sinks_14_bits_data = io_source_bits_data;
	assign io_sinks_14_bits_last = io_source_bits_last;
	assign io_sinks_15_valid = io_source_valid & (io_select_bits == 5'h0f);
	assign io_sinks_15_bits_data = io_source_bits_data;
	assign io_sinks_15_bits_last = io_source_bits_last;
	assign io_sinks_16_valid = io_source_valid & (io_select_bits == 5'h10);
	assign io_sinks_16_bits_data = io_source_bits_data;
	assign io_sinks_16_bits_last = io_source_bits_last;
	assign io_sinks_17_valid = io_source_valid & (io_select_bits == 5'h11);
	assign io_sinks_17_bits_data = io_source_bits_data;
	assign io_sinks_17_bits_last = io_source_bits_last;
	assign io_sinks_18_valid = io_source_valid & (io_select_bits == 5'h12);
	assign io_sinks_18_bits_data = io_source_bits_data;
	assign io_sinks_18_bits_last = io_source_bits_last;
	assign io_sinks_19_valid = io_source_valid & (io_select_bits == 5'h13);
	assign io_sinks_19_bits_data = io_source_bits_data;
	assign io_sinks_19_bits_last = io_source_bits_last;
	assign io_sinks_20_valid = io_source_valid & (io_select_bits == 5'h14);
	assign io_sinks_20_bits_data = io_source_bits_data;
	assign io_sinks_20_bits_last = io_source_bits_last;
	assign io_sinks_21_valid = io_source_valid & (io_select_bits == 5'h15);
	assign io_sinks_21_bits_data = io_source_bits_data;
	assign io_sinks_21_bits_last = io_source_bits_last;
	assign io_sinks_22_valid = io_source_valid & (io_select_bits == 5'h16);
	assign io_sinks_22_bits_data = io_source_bits_data;
	assign io_sinks_22_bits_last = io_source_bits_last;
	assign io_sinks_23_valid = io_source_valid & (io_select_bits == 5'h17);
	assign io_sinks_23_bits_data = io_source_bits_data;
	assign io_sinks_23_bits_last = io_source_bits_last;
	assign io_sinks_24_valid = io_source_valid & (io_select_bits == 5'h18);
	assign io_sinks_24_bits_data = io_source_bits_data;
	assign io_sinks_24_bits_last = io_source_bits_last;
	assign io_sinks_25_valid = io_source_valid & (io_select_bits == 5'h19);
	assign io_sinks_25_bits_data = io_source_bits_data;
	assign io_sinks_25_bits_last = io_source_bits_last;
	assign io_sinks_26_valid = io_source_valid & (io_select_bits == 5'h1a);
	assign io_sinks_26_bits_data = io_source_bits_data;
	assign io_sinks_26_bits_last = io_source_bits_last;
	assign io_sinks_27_valid = io_source_valid & (io_select_bits == 5'h1b);
	assign io_sinks_27_bits_data = io_source_bits_data;
	assign io_sinks_27_bits_last = io_source_bits_last;
	assign io_sinks_28_valid = io_source_valid & (io_select_bits == 5'h1c);
	assign io_sinks_28_bits_data = io_source_bits_data;
	assign io_sinks_28_bits_last = io_source_bits_last;
	assign io_sinks_29_valid = io_source_valid & (io_select_bits == 5'h1d);
	assign io_sinks_29_bits_data = io_source_bits_data;
	assign io_sinks_29_bits_last = io_source_bits_last;
	assign io_sinks_30_valid = io_source_valid & (io_select_bits == 5'h1e);
	assign io_sinks_30_bits_data = io_source_bits_data;
	assign io_sinks_30_bits_last = io_source_bits_last;
	assign io_sinks_31_valid = io_source_valid & (&io_select_bits);
	assign io_sinks_31_bits_data = io_source_bits_data;
	assign io_sinks_31_bits_last = io_source_bits_last;
	assign io_select_ready = fire & io_source_bits_last;
endmodule
module elasticMux_33 (
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits,
	io_sources_3_ready,
	io_sources_3_valid,
	io_sources_3_bits,
	io_sources_4_ready,
	io_sources_4_valid,
	io_sources_4_bits,
	io_sources_5_ready,
	io_sources_5_valid,
	io_sources_5_bits,
	io_sources_6_ready,
	io_sources_6_valid,
	io_sources_6_bits,
	io_sources_7_ready,
	io_sources_7_valid,
	io_sources_7_bits,
	io_sources_8_ready,
	io_sources_8_valid,
	io_sources_8_bits,
	io_sources_9_ready,
	io_sources_9_valid,
	io_sources_9_bits,
	io_sources_10_ready,
	io_sources_10_valid,
	io_sources_10_bits,
	io_sources_11_ready,
	io_sources_11_valid,
	io_sources_11_bits,
	io_sources_12_ready,
	io_sources_12_valid,
	io_sources_12_bits,
	io_sources_13_ready,
	io_sources_13_valid,
	io_sources_13_bits,
	io_sources_14_ready,
	io_sources_14_valid,
	io_sources_14_bits,
	io_sources_15_ready,
	io_sources_15_valid,
	io_sources_15_bits,
	io_sources_16_ready,
	io_sources_16_valid,
	io_sources_16_bits,
	io_sources_17_ready,
	io_sources_17_valid,
	io_sources_17_bits,
	io_sources_18_ready,
	io_sources_18_valid,
	io_sources_18_bits,
	io_sources_19_ready,
	io_sources_19_valid,
	io_sources_19_bits,
	io_sources_20_ready,
	io_sources_20_valid,
	io_sources_20_bits,
	io_sources_21_ready,
	io_sources_21_valid,
	io_sources_21_bits,
	io_sources_22_ready,
	io_sources_22_valid,
	io_sources_22_bits,
	io_sources_23_ready,
	io_sources_23_valid,
	io_sources_23_bits,
	io_sources_24_ready,
	io_sources_24_valid,
	io_sources_24_bits,
	io_sources_25_ready,
	io_sources_25_valid,
	io_sources_25_bits,
	io_sources_26_ready,
	io_sources_26_valid,
	io_sources_26_bits,
	io_sources_27_ready,
	io_sources_27_valid,
	io_sources_27_bits,
	io_sources_28_ready,
	io_sources_28_valid,
	io_sources_28_bits,
	io_sources_29_ready,
	io_sources_29_valid,
	io_sources_29_bits,
	io_sources_30_ready,
	io_sources_30_valid,
	io_sources_30_bits,
	io_sources_31_ready,
	io_sources_31_valid,
	io_sources_31_bits,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits,
	io_select_ready,
	io_select_bits
);
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [255:0] io_sources_0_bits;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [255:0] io_sources_1_bits;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [255:0] io_sources_2_bits;
	output wire io_sources_3_ready;
	input io_sources_3_valid;
	input [255:0] io_sources_3_bits;
	output wire io_sources_4_ready;
	input io_sources_4_valid;
	input [255:0] io_sources_4_bits;
	output wire io_sources_5_ready;
	input io_sources_5_valid;
	input [255:0] io_sources_5_bits;
	output wire io_sources_6_ready;
	input io_sources_6_valid;
	input [255:0] io_sources_6_bits;
	output wire io_sources_7_ready;
	input io_sources_7_valid;
	input [255:0] io_sources_7_bits;
	output wire io_sources_8_ready;
	input io_sources_8_valid;
	input [255:0] io_sources_8_bits;
	output wire io_sources_9_ready;
	input io_sources_9_valid;
	input [255:0] io_sources_9_bits;
	output wire io_sources_10_ready;
	input io_sources_10_valid;
	input [255:0] io_sources_10_bits;
	output wire io_sources_11_ready;
	input io_sources_11_valid;
	input [255:0] io_sources_11_bits;
	output wire io_sources_12_ready;
	input io_sources_12_valid;
	input [255:0] io_sources_12_bits;
	output wire io_sources_13_ready;
	input io_sources_13_valid;
	input [255:0] io_sources_13_bits;
	output wire io_sources_14_ready;
	input io_sources_14_valid;
	input [255:0] io_sources_14_bits;
	output wire io_sources_15_ready;
	input io_sources_15_valid;
	input [255:0] io_sources_15_bits;
	output wire io_sources_16_ready;
	input io_sources_16_valid;
	input [255:0] io_sources_16_bits;
	output wire io_sources_17_ready;
	input io_sources_17_valid;
	input [255:0] io_sources_17_bits;
	output wire io_sources_18_ready;
	input io_sources_18_valid;
	input [255:0] io_sources_18_bits;
	output wire io_sources_19_ready;
	input io_sources_19_valid;
	input [255:0] io_sources_19_bits;
	output wire io_sources_20_ready;
	input io_sources_20_valid;
	input [255:0] io_sources_20_bits;
	output wire io_sources_21_ready;
	input io_sources_21_valid;
	input [255:0] io_sources_21_bits;
	output wire io_sources_22_ready;
	input io_sources_22_valid;
	input [255:0] io_sources_22_bits;
	output wire io_sources_23_ready;
	input io_sources_23_valid;
	input [255:0] io_sources_23_bits;
	output wire io_sources_24_ready;
	input io_sources_24_valid;
	input [255:0] io_sources_24_bits;
	output wire io_sources_25_ready;
	input io_sources_25_valid;
	input [255:0] io_sources_25_bits;
	output wire io_sources_26_ready;
	input io_sources_26_valid;
	input [255:0] io_sources_26_bits;
	output wire io_sources_27_ready;
	input io_sources_27_valid;
	input [255:0] io_sources_27_bits;
	output wire io_sources_28_ready;
	input io_sources_28_valid;
	input [255:0] io_sources_28_bits;
	output wire io_sources_29_ready;
	input io_sources_29_valid;
	input [255:0] io_sources_29_bits;
	output wire io_sources_30_ready;
	input io_sources_30_valid;
	input [255:0] io_sources_30_bits;
	output wire io_sources_31_ready;
	input io_sources_31_valid;
	input [255:0] io_sources_31_bits;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [255:0] io_sink_bits;
	output wire io_select_ready;
	input [4:0] io_select_bits;
	wire [31:0] _GEN = {io_sources_31_valid, io_sources_30_valid, io_sources_29_valid, io_sources_28_valid, io_sources_27_valid, io_sources_26_valid, io_sources_25_valid, io_sources_24_valid, io_sources_23_valid, io_sources_22_valid, io_sources_21_valid, io_sources_20_valid, io_sources_19_valid, io_sources_18_valid, io_sources_17_valid, io_sources_16_valid, io_sources_15_valid, io_sources_14_valid, io_sources_13_valid, io_sources_12_valid, io_sources_11_valid, io_sources_10_valid, io_sources_9_valid, io_sources_8_valid, io_sources_7_valid, io_sources_6_valid, io_sources_5_valid, io_sources_4_valid, io_sources_3_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [8191:0] _GEN_0 = {io_sources_31_bits, io_sources_30_bits, io_sources_29_bits, io_sources_28_bits, io_sources_27_bits, io_sources_26_bits, io_sources_25_bits, io_sources_24_bits, io_sources_23_bits, io_sources_22_bits, io_sources_21_bits, io_sources_20_bits, io_sources_19_bits, io_sources_18_bits, io_sources_17_bits, io_sources_16_bits, io_sources_15_bits, io_sources_14_bits, io_sources_13_bits, io_sources_12_bits, io_sources_11_bits, io_sources_10_bits, io_sources_9_bits, io_sources_8_bits, io_sources_7_bits, io_sources_6_bits, io_sources_5_bits, io_sources_4_bits, io_sources_3_bits, io_sources_2_bits, io_sources_1_bits, io_sources_0_bits};
	wire fire = _GEN[io_select_bits] & io_sink_ready;
	assign io_sources_0_ready = fire & (io_select_bits == 5'h00);
	assign io_sources_1_ready = fire & (io_select_bits == 5'h01);
	assign io_sources_2_ready = fire & (io_select_bits == 5'h02);
	assign io_sources_3_ready = fire & (io_select_bits == 5'h03);
	assign io_sources_4_ready = fire & (io_select_bits == 5'h04);
	assign io_sources_5_ready = fire & (io_select_bits == 5'h05);
	assign io_sources_6_ready = fire & (io_select_bits == 5'h06);
	assign io_sources_7_ready = fire & (io_select_bits == 5'h07);
	assign io_sources_8_ready = fire & (io_select_bits == 5'h08);
	assign io_sources_9_ready = fire & (io_select_bits == 5'h09);
	assign io_sources_10_ready = fire & (io_select_bits == 5'h0a);
	assign io_sources_11_ready = fire & (io_select_bits == 5'h0b);
	assign io_sources_12_ready = fire & (io_select_bits == 5'h0c);
	assign io_sources_13_ready = fire & (io_select_bits == 5'h0d);
	assign io_sources_14_ready = fire & (io_select_bits == 5'h0e);
	assign io_sources_15_ready = fire & (io_select_bits == 5'h0f);
	assign io_sources_16_ready = fire & (io_select_bits == 5'h10);
	assign io_sources_17_ready = fire & (io_select_bits == 5'h11);
	assign io_sources_18_ready = fire & (io_select_bits == 5'h12);
	assign io_sources_19_ready = fire & (io_select_bits == 5'h13);
	assign io_sources_20_ready = fire & (io_select_bits == 5'h14);
	assign io_sources_21_ready = fire & (io_select_bits == 5'h15);
	assign io_sources_22_ready = fire & (io_select_bits == 5'h16);
	assign io_sources_23_ready = fire & (io_select_bits == 5'h17);
	assign io_sources_24_ready = fire & (io_select_bits == 5'h18);
	assign io_sources_25_ready = fire & (io_select_bits == 5'h19);
	assign io_sources_26_ready = fire & (io_select_bits == 5'h1a);
	assign io_sources_27_ready = fire & (io_select_bits == 5'h1b);
	assign io_sources_28_ready = fire & (io_select_bits == 5'h1c);
	assign io_sources_29_ready = fire & (io_select_bits == 5'h1d);
	assign io_sources_30_ready = fire & (io_select_bits == 5'h1e);
	assign io_sources_31_ready = fire & (&io_select_bits);
	assign io_sink_valid = _GEN[io_select_bits];
	assign io_sink_bits = _GEN_0[io_select_bits * 256+:256];
	assign io_select_ready = fire;
endmodule
module RowReduce (
	clock,
	reset,
	sourceElem_ready,
	sourceElem_valid,
	sourceElem_bits,
	sourceCount_ready,
	sourceCount_valid,
	sourceCount_bits,
	sinkResult_ready,
	sinkResult_valid,
	sinkResult_bits
);
	input clock;
	input reset;
	output wire sourceElem_ready;
	input sourceElem_valid;
	input [255:0] sourceElem_bits;
	output wire sourceCount_ready;
	input sourceCount_valid;
	input [31:0] sourceCount_bits;
	input sinkResult_ready;
	output wire sinkResult_valid;
	output wire [255:0] sinkResult_bits;
	wire _mux_io_sources_0_ready;
	wire _mux_io_sources_1_ready;
	wire _mux_io_sources_2_ready;
	wire _mux_io_sources_3_ready;
	wire _mux_io_sources_4_ready;
	wire _mux_io_sources_5_ready;
	wire _mux_io_sources_6_ready;
	wire _mux_io_sources_7_ready;
	wire _mux_io_sources_8_ready;
	wire _mux_io_sources_9_ready;
	wire _mux_io_sources_10_ready;
	wire _mux_io_sources_11_ready;
	wire _mux_io_sources_12_ready;
	wire _mux_io_sources_13_ready;
	wire _mux_io_sources_14_ready;
	wire _mux_io_sources_15_ready;
	wire _mux_io_sources_16_ready;
	wire _mux_io_sources_17_ready;
	wire _mux_io_sources_18_ready;
	wire _mux_io_sources_19_ready;
	wire _mux_io_sources_20_ready;
	wire _mux_io_sources_21_ready;
	wire _mux_io_sources_22_ready;
	wire _mux_io_sources_23_ready;
	wire _mux_io_sources_24_ready;
	wire _mux_io_sources_25_ready;
	wire _mux_io_sources_26_ready;
	wire _mux_io_sources_27_ready;
	wire _mux_io_sources_28_ready;
	wire _mux_io_sources_29_ready;
	wire _mux_io_sources_30_ready;
	wire _mux_io_sources_31_ready;
	wire _mux_io_select_ready;
	wire [4:0] _elasticCounter_1_sink_bits;
	wire _sourceBuffer_31_io_enq_ready;
	wire _sourceBuffer_31_io_deq_valid;
	wire [255:0] _sourceBuffer_31_io_deq_bits;
	wire _sourceBuffer_30_io_enq_ready;
	wire _sourceBuffer_30_io_deq_valid;
	wire [255:0] _sourceBuffer_30_io_deq_bits;
	wire _sourceBuffer_29_io_enq_ready;
	wire _sourceBuffer_29_io_deq_valid;
	wire [255:0] _sourceBuffer_29_io_deq_bits;
	wire _sourceBuffer_28_io_enq_ready;
	wire _sourceBuffer_28_io_deq_valid;
	wire [255:0] _sourceBuffer_28_io_deq_bits;
	wire _sourceBuffer_27_io_enq_ready;
	wire _sourceBuffer_27_io_deq_valid;
	wire [255:0] _sourceBuffer_27_io_deq_bits;
	wire _sourceBuffer_26_io_enq_ready;
	wire _sourceBuffer_26_io_deq_valid;
	wire [255:0] _sourceBuffer_26_io_deq_bits;
	wire _sourceBuffer_25_io_enq_ready;
	wire _sourceBuffer_25_io_deq_valid;
	wire [255:0] _sourceBuffer_25_io_deq_bits;
	wire _sourceBuffer_24_io_enq_ready;
	wire _sourceBuffer_24_io_deq_valid;
	wire [255:0] _sourceBuffer_24_io_deq_bits;
	wire _sourceBuffer_23_io_enq_ready;
	wire _sourceBuffer_23_io_deq_valid;
	wire [255:0] _sourceBuffer_23_io_deq_bits;
	wire _sourceBuffer_22_io_enq_ready;
	wire _sourceBuffer_22_io_deq_valid;
	wire [255:0] _sourceBuffer_22_io_deq_bits;
	wire _sourceBuffer_21_io_enq_ready;
	wire _sourceBuffer_21_io_deq_valid;
	wire [255:0] _sourceBuffer_21_io_deq_bits;
	wire _sourceBuffer_20_io_enq_ready;
	wire _sourceBuffer_20_io_deq_valid;
	wire [255:0] _sourceBuffer_20_io_deq_bits;
	wire _sourceBuffer_19_io_enq_ready;
	wire _sourceBuffer_19_io_deq_valid;
	wire [255:0] _sourceBuffer_19_io_deq_bits;
	wire _sourceBuffer_18_io_enq_ready;
	wire _sourceBuffer_18_io_deq_valid;
	wire [255:0] _sourceBuffer_18_io_deq_bits;
	wire _sourceBuffer_17_io_enq_ready;
	wire _sourceBuffer_17_io_deq_valid;
	wire [255:0] _sourceBuffer_17_io_deq_bits;
	wire _sourceBuffer_16_io_enq_ready;
	wire _sourceBuffer_16_io_deq_valid;
	wire [255:0] _sourceBuffer_16_io_deq_bits;
	wire _sourceBuffer_15_io_enq_ready;
	wire _sourceBuffer_15_io_deq_valid;
	wire [255:0] _sourceBuffer_15_io_deq_bits;
	wire _sourceBuffer_14_io_enq_ready;
	wire _sourceBuffer_14_io_deq_valid;
	wire [255:0] _sourceBuffer_14_io_deq_bits;
	wire _sourceBuffer_13_io_enq_ready;
	wire _sourceBuffer_13_io_deq_valid;
	wire [255:0] _sourceBuffer_13_io_deq_bits;
	wire _sourceBuffer_12_io_enq_ready;
	wire _sourceBuffer_12_io_deq_valid;
	wire [255:0] _sourceBuffer_12_io_deq_bits;
	wire _sourceBuffer_11_io_enq_ready;
	wire _sourceBuffer_11_io_deq_valid;
	wire [255:0] _sourceBuffer_11_io_deq_bits;
	wire _sourceBuffer_10_io_enq_ready;
	wire _sourceBuffer_10_io_deq_valid;
	wire [255:0] _sourceBuffer_10_io_deq_bits;
	wire _sourceBuffer_9_io_enq_ready;
	wire _sourceBuffer_9_io_deq_valid;
	wire [255:0] _sourceBuffer_9_io_deq_bits;
	wire _sourceBuffer_8_io_enq_ready;
	wire _sourceBuffer_8_io_deq_valid;
	wire [255:0] _sourceBuffer_8_io_deq_bits;
	wire _sourceBuffer_7_io_enq_ready;
	wire _sourceBuffer_7_io_deq_valid;
	wire [255:0] _sourceBuffer_7_io_deq_bits;
	wire _sourceBuffer_6_io_enq_ready;
	wire _sourceBuffer_6_io_deq_valid;
	wire [255:0] _sourceBuffer_6_io_deq_bits;
	wire _sourceBuffer_5_io_enq_ready;
	wire _sourceBuffer_5_io_deq_valid;
	wire [255:0] _sourceBuffer_5_io_deq_bits;
	wire _sourceBuffer_4_io_enq_ready;
	wire _sourceBuffer_4_io_deq_valid;
	wire [255:0] _sourceBuffer_4_io_deq_bits;
	wire _sourceBuffer_3_io_enq_ready;
	wire _sourceBuffer_3_io_deq_valid;
	wire [255:0] _sourceBuffer_3_io_deq_bits;
	wire _sourceBuffer_2_io_enq_ready;
	wire _sourceBuffer_2_io_deq_valid;
	wire [255:0] _sourceBuffer_2_io_deq_bits;
	wire _sourceBuffer_1_io_enq_ready;
	wire _sourceBuffer_1_io_deq_valid;
	wire [255:0] _sourceBuffer_1_io_deq_bits;
	wire _sourceBuffer_io_enq_ready;
	wire _sourceBuffer_io_deq_valid;
	wire [255:0] _sourceBuffer_io_deq_bits;
	wire _demux_io_source_ready;
	wire _demux_io_sinks_0_valid;
	wire [255:0] _demux_io_sinks_0_bits_data;
	wire _demux_io_sinks_0_bits_last;
	wire _demux_io_sinks_1_valid;
	wire [255:0] _demux_io_sinks_1_bits_data;
	wire _demux_io_sinks_1_bits_last;
	wire _demux_io_sinks_2_valid;
	wire [255:0] _demux_io_sinks_2_bits_data;
	wire _demux_io_sinks_2_bits_last;
	wire _demux_io_sinks_3_valid;
	wire [255:0] _demux_io_sinks_3_bits_data;
	wire _demux_io_sinks_3_bits_last;
	wire _demux_io_sinks_4_valid;
	wire [255:0] _demux_io_sinks_4_bits_data;
	wire _demux_io_sinks_4_bits_last;
	wire _demux_io_sinks_5_valid;
	wire [255:0] _demux_io_sinks_5_bits_data;
	wire _demux_io_sinks_5_bits_last;
	wire _demux_io_sinks_6_valid;
	wire [255:0] _demux_io_sinks_6_bits_data;
	wire _demux_io_sinks_6_bits_last;
	wire _demux_io_sinks_7_valid;
	wire [255:0] _demux_io_sinks_7_bits_data;
	wire _demux_io_sinks_7_bits_last;
	wire _demux_io_sinks_8_valid;
	wire [255:0] _demux_io_sinks_8_bits_data;
	wire _demux_io_sinks_8_bits_last;
	wire _demux_io_sinks_9_valid;
	wire [255:0] _demux_io_sinks_9_bits_data;
	wire _demux_io_sinks_9_bits_last;
	wire _demux_io_sinks_10_valid;
	wire [255:0] _demux_io_sinks_10_bits_data;
	wire _demux_io_sinks_10_bits_last;
	wire _demux_io_sinks_11_valid;
	wire [255:0] _demux_io_sinks_11_bits_data;
	wire _demux_io_sinks_11_bits_last;
	wire _demux_io_sinks_12_valid;
	wire [255:0] _demux_io_sinks_12_bits_data;
	wire _demux_io_sinks_12_bits_last;
	wire _demux_io_sinks_13_valid;
	wire [255:0] _demux_io_sinks_13_bits_data;
	wire _demux_io_sinks_13_bits_last;
	wire _demux_io_sinks_14_valid;
	wire [255:0] _demux_io_sinks_14_bits_data;
	wire _demux_io_sinks_14_bits_last;
	wire _demux_io_sinks_15_valid;
	wire [255:0] _demux_io_sinks_15_bits_data;
	wire _demux_io_sinks_15_bits_last;
	wire _demux_io_sinks_16_valid;
	wire [255:0] _demux_io_sinks_16_bits_data;
	wire _demux_io_sinks_16_bits_last;
	wire _demux_io_sinks_17_valid;
	wire [255:0] _demux_io_sinks_17_bits_data;
	wire _demux_io_sinks_17_bits_last;
	wire _demux_io_sinks_18_valid;
	wire [255:0] _demux_io_sinks_18_bits_data;
	wire _demux_io_sinks_18_bits_last;
	wire _demux_io_sinks_19_valid;
	wire [255:0] _demux_io_sinks_19_bits_data;
	wire _demux_io_sinks_19_bits_last;
	wire _demux_io_sinks_20_valid;
	wire [255:0] _demux_io_sinks_20_bits_data;
	wire _demux_io_sinks_20_bits_last;
	wire _demux_io_sinks_21_valid;
	wire [255:0] _demux_io_sinks_21_bits_data;
	wire _demux_io_sinks_21_bits_last;
	wire _demux_io_sinks_22_valid;
	wire [255:0] _demux_io_sinks_22_bits_data;
	wire _demux_io_sinks_22_bits_last;
	wire _demux_io_sinks_23_valid;
	wire [255:0] _demux_io_sinks_23_bits_data;
	wire _demux_io_sinks_23_bits_last;
	wire _demux_io_sinks_24_valid;
	wire [255:0] _demux_io_sinks_24_bits_data;
	wire _demux_io_sinks_24_bits_last;
	wire _demux_io_sinks_25_valid;
	wire [255:0] _demux_io_sinks_25_bits_data;
	wire _demux_io_sinks_25_bits_last;
	wire _demux_io_sinks_26_valid;
	wire [255:0] _demux_io_sinks_26_bits_data;
	wire _demux_io_sinks_26_bits_last;
	wire _demux_io_sinks_27_valid;
	wire [255:0] _demux_io_sinks_27_bits_data;
	wire _demux_io_sinks_27_bits_last;
	wire _demux_io_sinks_28_valid;
	wire [255:0] _demux_io_sinks_28_bits_data;
	wire _demux_io_sinks_28_bits_last;
	wire _demux_io_sinks_29_valid;
	wire [255:0] _demux_io_sinks_29_bits_data;
	wire _demux_io_sinks_29_bits_last;
	wire _demux_io_sinks_30_valid;
	wire [255:0] _demux_io_sinks_30_bits_data;
	wire _demux_io_sinks_30_bits_last;
	wire _demux_io_sinks_31_valid;
	wire [255:0] _demux_io_sinks_31_bits_data;
	wire _demux_io_sinks_31_bits_last;
	wire _demux_io_select_ready;
	wire [4:0] _elasticCounter_sink_bits;
	wire _sinkBuffer_31_io_enq_ready;
	wire _sinkBuffer_31_io_deq_valid;
	wire [255:0] _sinkBuffer_31_io_deq_bits_data;
	wire _sinkBuffer_31_io_deq_bits_last;
	wire _sinkBuffer_30_io_enq_ready;
	wire _sinkBuffer_30_io_deq_valid;
	wire [255:0] _sinkBuffer_30_io_deq_bits_data;
	wire _sinkBuffer_30_io_deq_bits_last;
	wire _sinkBuffer_29_io_enq_ready;
	wire _sinkBuffer_29_io_deq_valid;
	wire [255:0] _sinkBuffer_29_io_deq_bits_data;
	wire _sinkBuffer_29_io_deq_bits_last;
	wire _sinkBuffer_28_io_enq_ready;
	wire _sinkBuffer_28_io_deq_valid;
	wire [255:0] _sinkBuffer_28_io_deq_bits_data;
	wire _sinkBuffer_28_io_deq_bits_last;
	wire _sinkBuffer_27_io_enq_ready;
	wire _sinkBuffer_27_io_deq_valid;
	wire [255:0] _sinkBuffer_27_io_deq_bits_data;
	wire _sinkBuffer_27_io_deq_bits_last;
	wire _sinkBuffer_26_io_enq_ready;
	wire _sinkBuffer_26_io_deq_valid;
	wire [255:0] _sinkBuffer_26_io_deq_bits_data;
	wire _sinkBuffer_26_io_deq_bits_last;
	wire _sinkBuffer_25_io_enq_ready;
	wire _sinkBuffer_25_io_deq_valid;
	wire [255:0] _sinkBuffer_25_io_deq_bits_data;
	wire _sinkBuffer_25_io_deq_bits_last;
	wire _sinkBuffer_24_io_enq_ready;
	wire _sinkBuffer_24_io_deq_valid;
	wire [255:0] _sinkBuffer_24_io_deq_bits_data;
	wire _sinkBuffer_24_io_deq_bits_last;
	wire _sinkBuffer_23_io_enq_ready;
	wire _sinkBuffer_23_io_deq_valid;
	wire [255:0] _sinkBuffer_23_io_deq_bits_data;
	wire _sinkBuffer_23_io_deq_bits_last;
	wire _sinkBuffer_22_io_enq_ready;
	wire _sinkBuffer_22_io_deq_valid;
	wire [255:0] _sinkBuffer_22_io_deq_bits_data;
	wire _sinkBuffer_22_io_deq_bits_last;
	wire _sinkBuffer_21_io_enq_ready;
	wire _sinkBuffer_21_io_deq_valid;
	wire [255:0] _sinkBuffer_21_io_deq_bits_data;
	wire _sinkBuffer_21_io_deq_bits_last;
	wire _sinkBuffer_20_io_enq_ready;
	wire _sinkBuffer_20_io_deq_valid;
	wire [255:0] _sinkBuffer_20_io_deq_bits_data;
	wire _sinkBuffer_20_io_deq_bits_last;
	wire _sinkBuffer_19_io_enq_ready;
	wire _sinkBuffer_19_io_deq_valid;
	wire [255:0] _sinkBuffer_19_io_deq_bits_data;
	wire _sinkBuffer_19_io_deq_bits_last;
	wire _sinkBuffer_18_io_enq_ready;
	wire _sinkBuffer_18_io_deq_valid;
	wire [255:0] _sinkBuffer_18_io_deq_bits_data;
	wire _sinkBuffer_18_io_deq_bits_last;
	wire _sinkBuffer_17_io_enq_ready;
	wire _sinkBuffer_17_io_deq_valid;
	wire [255:0] _sinkBuffer_17_io_deq_bits_data;
	wire _sinkBuffer_17_io_deq_bits_last;
	wire _sinkBuffer_16_io_enq_ready;
	wire _sinkBuffer_16_io_deq_valid;
	wire [255:0] _sinkBuffer_16_io_deq_bits_data;
	wire _sinkBuffer_16_io_deq_bits_last;
	wire _sinkBuffer_15_io_enq_ready;
	wire _sinkBuffer_15_io_deq_valid;
	wire [255:0] _sinkBuffer_15_io_deq_bits_data;
	wire _sinkBuffer_15_io_deq_bits_last;
	wire _sinkBuffer_14_io_enq_ready;
	wire _sinkBuffer_14_io_deq_valid;
	wire [255:0] _sinkBuffer_14_io_deq_bits_data;
	wire _sinkBuffer_14_io_deq_bits_last;
	wire _sinkBuffer_13_io_enq_ready;
	wire _sinkBuffer_13_io_deq_valid;
	wire [255:0] _sinkBuffer_13_io_deq_bits_data;
	wire _sinkBuffer_13_io_deq_bits_last;
	wire _sinkBuffer_12_io_enq_ready;
	wire _sinkBuffer_12_io_deq_valid;
	wire [255:0] _sinkBuffer_12_io_deq_bits_data;
	wire _sinkBuffer_12_io_deq_bits_last;
	wire _sinkBuffer_11_io_enq_ready;
	wire _sinkBuffer_11_io_deq_valid;
	wire [255:0] _sinkBuffer_11_io_deq_bits_data;
	wire _sinkBuffer_11_io_deq_bits_last;
	wire _sinkBuffer_10_io_enq_ready;
	wire _sinkBuffer_10_io_deq_valid;
	wire [255:0] _sinkBuffer_10_io_deq_bits_data;
	wire _sinkBuffer_10_io_deq_bits_last;
	wire _sinkBuffer_9_io_enq_ready;
	wire _sinkBuffer_9_io_deq_valid;
	wire [255:0] _sinkBuffer_9_io_deq_bits_data;
	wire _sinkBuffer_9_io_deq_bits_last;
	wire _sinkBuffer_8_io_enq_ready;
	wire _sinkBuffer_8_io_deq_valid;
	wire [255:0] _sinkBuffer_8_io_deq_bits_data;
	wire _sinkBuffer_8_io_deq_bits_last;
	wire _sinkBuffer_7_io_enq_ready;
	wire _sinkBuffer_7_io_deq_valid;
	wire [255:0] _sinkBuffer_7_io_deq_bits_data;
	wire _sinkBuffer_7_io_deq_bits_last;
	wire _sinkBuffer_6_io_enq_ready;
	wire _sinkBuffer_6_io_deq_valid;
	wire [255:0] _sinkBuffer_6_io_deq_bits_data;
	wire _sinkBuffer_6_io_deq_bits_last;
	wire _sinkBuffer_5_io_enq_ready;
	wire _sinkBuffer_5_io_deq_valid;
	wire [255:0] _sinkBuffer_5_io_deq_bits_data;
	wire _sinkBuffer_5_io_deq_bits_last;
	wire _sinkBuffer_4_io_enq_ready;
	wire _sinkBuffer_4_io_deq_valid;
	wire [255:0] _sinkBuffer_4_io_deq_bits_data;
	wire _sinkBuffer_4_io_deq_bits_last;
	wire _sinkBuffer_3_io_enq_ready;
	wire _sinkBuffer_3_io_deq_valid;
	wire [255:0] _sinkBuffer_3_io_deq_bits_data;
	wire _sinkBuffer_3_io_deq_bits_last;
	wire _sinkBuffer_2_io_enq_ready;
	wire _sinkBuffer_2_io_deq_valid;
	wire [255:0] _sinkBuffer_2_io_deq_bits_data;
	wire _sinkBuffer_2_io_deq_bits_last;
	wire _sinkBuffer_1_io_enq_ready;
	wire _sinkBuffer_1_io_deq_valid;
	wire [255:0] _sinkBuffer_1_io_deq_bits_data;
	wire _sinkBuffer_1_io_deq_bits_last;
	wire _sinkBuffer_io_enq_ready;
	wire _sinkBuffer_io_deq_valid;
	wire [255:0] _sinkBuffer_io_deq_bits_data;
	wire _sinkBuffer_io_deq_bits_last;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_deq_valid;
	wire [255:0] _sinkBuffered__sinkBuffer_io_deq_bits_data;
	wire _sinkBuffered__sinkBuffer_io_deq_bits_last;
	wire _batchAddCluster3_demux_io_source_ready;
	wire _batchAddCluster3_demux_io_sinks_0_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_0_bits;
	wire _batchAddCluster3_demux_io_sinks_1_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_1_bits;
	wire _batchAddCluster3_demux_io_sinks_2_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_2_bits;
	wire _batchAddCluster3_demux_io_sinks_3_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_3_bits;
	wire _batchAddCluster3_demux_io_sinks_4_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_4_bits;
	wire _batchAddCluster3_demux_io_sinks_5_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_5_bits;
	wire _batchAddCluster3_demux_io_sinks_6_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_6_bits;
	wire _batchAddCluster3_demux_io_sinks_7_valid;
	wire [255:0] _batchAddCluster3_demux_io_sinks_7_bits;
	wire _batchAddCluster3_demux_io_select_ready;
	wire _batchAddCluster3_arbiter_io_sources_0_ready;
	wire _batchAddCluster3_arbiter_io_sources_1_ready;
	wire _batchAddCluster3_arbiter_io_sources_2_ready;
	wire _batchAddCluster3_arbiter_io_sources_3_ready;
	wire _batchAddCluster3_arbiter_io_sources_4_ready;
	wire _batchAddCluster3_arbiter_io_sources_5_ready;
	wire _batchAddCluster3_arbiter_io_sources_6_ready;
	wire _batchAddCluster3_arbiter_io_sources_7_ready;
	wire _batchAddCluster3_arbiter_io_sink_valid;
	wire [255:0] _batchAddCluster3_arbiter_io_sink_bits__1;
	wire [255:0] _batchAddCluster3_arbiter_io_sink_bits__2;
	wire _batchAddCluster3_arbiter_io_select_valid;
	wire [2:0] _batchAddCluster3_arbiter_io_select_bits;
	wire _batchAddCluster3_batchAddQueue_io_enq_ready;
	wire _batchAddCluster3_batchAddQueue_io_deq_valid;
	wire [4:0] _batchAddCluster3_batchAddQueue_io_deq_bits;
	wire _batchAddCluster3_batchAdd_req_ready;
	wire _batchAddCluster3_batchAdd_resp_valid;
	wire [255:0] _batchAddCluster3_batchAdd_resp_bits;
	wire _batchAddCluster2_demux_io_source_ready;
	wire _batchAddCluster2_demux_io_sinks_0_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_0_bits;
	wire _batchAddCluster2_demux_io_sinks_1_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_1_bits;
	wire _batchAddCluster2_demux_io_sinks_2_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_2_bits;
	wire _batchAddCluster2_demux_io_sinks_3_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_3_bits;
	wire _batchAddCluster2_demux_io_sinks_4_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_4_bits;
	wire _batchAddCluster2_demux_io_sinks_5_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_5_bits;
	wire _batchAddCluster2_demux_io_sinks_6_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_6_bits;
	wire _batchAddCluster2_demux_io_sinks_7_valid;
	wire [255:0] _batchAddCluster2_demux_io_sinks_7_bits;
	wire _batchAddCluster2_demux_io_select_ready;
	wire _batchAddCluster2_arbiter_io_sources_0_ready;
	wire _batchAddCluster2_arbiter_io_sources_1_ready;
	wire _batchAddCluster2_arbiter_io_sources_2_ready;
	wire _batchAddCluster2_arbiter_io_sources_3_ready;
	wire _batchAddCluster2_arbiter_io_sources_4_ready;
	wire _batchAddCluster2_arbiter_io_sources_5_ready;
	wire _batchAddCluster2_arbiter_io_sources_6_ready;
	wire _batchAddCluster2_arbiter_io_sources_7_ready;
	wire _batchAddCluster2_arbiter_io_sink_valid;
	wire [255:0] _batchAddCluster2_arbiter_io_sink_bits__1;
	wire [255:0] _batchAddCluster2_arbiter_io_sink_bits__2;
	wire _batchAddCluster2_arbiter_io_select_valid;
	wire [2:0] _batchAddCluster2_arbiter_io_select_bits;
	wire _batchAddCluster2_batchAddQueue_io_enq_ready;
	wire _batchAddCluster2_batchAddQueue_io_deq_valid;
	wire [4:0] _batchAddCluster2_batchAddQueue_io_deq_bits;
	wire _batchAddCluster2_batchAdd_req_ready;
	wire _batchAddCluster2_batchAdd_resp_valid;
	wire [255:0] _batchAddCluster2_batchAdd_resp_bits;
	wire _batchAddCluster1_demux_io_source_ready;
	wire _batchAddCluster1_demux_io_sinks_0_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_0_bits;
	wire _batchAddCluster1_demux_io_sinks_1_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_1_bits;
	wire _batchAddCluster1_demux_io_sinks_2_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_2_bits;
	wire _batchAddCluster1_demux_io_sinks_3_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_3_bits;
	wire _batchAddCluster1_demux_io_sinks_4_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_4_bits;
	wire _batchAddCluster1_demux_io_sinks_5_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_5_bits;
	wire _batchAddCluster1_demux_io_sinks_6_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_6_bits;
	wire _batchAddCluster1_demux_io_sinks_7_valid;
	wire [255:0] _batchAddCluster1_demux_io_sinks_7_bits;
	wire _batchAddCluster1_demux_io_select_ready;
	wire _batchAddCluster1_arbiter_io_sources_0_ready;
	wire _batchAddCluster1_arbiter_io_sources_1_ready;
	wire _batchAddCluster1_arbiter_io_sources_2_ready;
	wire _batchAddCluster1_arbiter_io_sources_3_ready;
	wire _batchAddCluster1_arbiter_io_sources_4_ready;
	wire _batchAddCluster1_arbiter_io_sources_5_ready;
	wire _batchAddCluster1_arbiter_io_sources_6_ready;
	wire _batchAddCluster1_arbiter_io_sources_7_ready;
	wire _batchAddCluster1_arbiter_io_sink_valid;
	wire [255:0] _batchAddCluster1_arbiter_io_sink_bits__1;
	wire [255:0] _batchAddCluster1_arbiter_io_sink_bits__2;
	wire _batchAddCluster1_arbiter_io_select_valid;
	wire [2:0] _batchAddCluster1_arbiter_io_select_bits;
	wire _batchAddCluster1_batchAddQueue_io_enq_ready;
	wire _batchAddCluster1_batchAddQueue_io_deq_valid;
	wire [4:0] _batchAddCluster1_batchAddQueue_io_deq_bits;
	wire _batchAddCluster1_batchAdd_req_ready;
	wire _batchAddCluster1_batchAdd_resp_valid;
	wire [255:0] _batchAddCluster1_batchAdd_resp_bits;
	wire _batchAddCluster0_demux_io_source_ready;
	wire _batchAddCluster0_demux_io_sinks_0_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_0_bits;
	wire _batchAddCluster0_demux_io_sinks_1_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_1_bits;
	wire _batchAddCluster0_demux_io_sinks_2_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_2_bits;
	wire _batchAddCluster0_demux_io_sinks_3_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_3_bits;
	wire _batchAddCluster0_demux_io_sinks_4_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_4_bits;
	wire _batchAddCluster0_demux_io_sinks_5_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_5_bits;
	wire _batchAddCluster0_demux_io_sinks_6_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_6_bits;
	wire _batchAddCluster0_demux_io_sinks_7_valid;
	wire [255:0] _batchAddCluster0_demux_io_sinks_7_bits;
	wire _batchAddCluster0_demux_io_select_ready;
	wire _batchAddCluster0_arbiter_io_sources_0_ready;
	wire _batchAddCluster0_arbiter_io_sources_1_ready;
	wire _batchAddCluster0_arbiter_io_sources_2_ready;
	wire _batchAddCluster0_arbiter_io_sources_3_ready;
	wire _batchAddCluster0_arbiter_io_sources_4_ready;
	wire _batchAddCluster0_arbiter_io_sources_5_ready;
	wire _batchAddCluster0_arbiter_io_sources_6_ready;
	wire _batchAddCluster0_arbiter_io_sources_7_ready;
	wire _batchAddCluster0_arbiter_io_sink_valid;
	wire [255:0] _batchAddCluster0_arbiter_io_sink_bits__1;
	wire [255:0] _batchAddCluster0_arbiter_io_sink_bits__2;
	wire _batchAddCluster0_arbiter_io_select_valid;
	wire [2:0] _batchAddCluster0_arbiter_io_select_bits;
	wire _batchAddCluster0_batchAddQueue_io_enq_ready;
	wire _batchAddCluster0_batchAddQueue_io_deq_valid;
	wire [4:0] _batchAddCluster0_batchAddQueue_io_deq_bits;
	wire _batchAddCluster0_batchAdd_req_ready;
	wire _batchAddCluster0_batchAdd_resp_valid;
	wire [255:0] _batchAddCluster0_batchAdd_resp_bits;
	wire _rowReduceSingleN_31_sourceElem_ready;
	wire _rowReduceSingleN_31_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_31_sinkResult_bits;
	wire _rowReduceSingleN_31_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_31_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_31_batchAddReq_bits__2;
	wire _rowReduceSingleN_31_batchAddResp_ready;
	wire _rowReduceSingleN_30_sourceElem_ready;
	wire _rowReduceSingleN_30_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_30_sinkResult_bits;
	wire _rowReduceSingleN_30_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_30_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_30_batchAddReq_bits__2;
	wire _rowReduceSingleN_30_batchAddResp_ready;
	wire _rowReduceSingleN_29_sourceElem_ready;
	wire _rowReduceSingleN_29_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_29_sinkResult_bits;
	wire _rowReduceSingleN_29_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_29_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_29_batchAddReq_bits__2;
	wire _rowReduceSingleN_29_batchAddResp_ready;
	wire _rowReduceSingleN_28_sourceElem_ready;
	wire _rowReduceSingleN_28_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_28_sinkResult_bits;
	wire _rowReduceSingleN_28_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_28_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_28_batchAddReq_bits__2;
	wire _rowReduceSingleN_28_batchAddResp_ready;
	wire _rowReduceSingleN_27_sourceElem_ready;
	wire _rowReduceSingleN_27_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_27_sinkResult_bits;
	wire _rowReduceSingleN_27_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_27_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_27_batchAddReq_bits__2;
	wire _rowReduceSingleN_27_batchAddResp_ready;
	wire _rowReduceSingleN_26_sourceElem_ready;
	wire _rowReduceSingleN_26_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_26_sinkResult_bits;
	wire _rowReduceSingleN_26_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_26_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_26_batchAddReq_bits__2;
	wire _rowReduceSingleN_26_batchAddResp_ready;
	wire _rowReduceSingleN_25_sourceElem_ready;
	wire _rowReduceSingleN_25_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_25_sinkResult_bits;
	wire _rowReduceSingleN_25_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_25_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_25_batchAddReq_bits__2;
	wire _rowReduceSingleN_25_batchAddResp_ready;
	wire _rowReduceSingleN_24_sourceElem_ready;
	wire _rowReduceSingleN_24_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_24_sinkResult_bits;
	wire _rowReduceSingleN_24_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_24_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_24_batchAddReq_bits__2;
	wire _rowReduceSingleN_24_batchAddResp_ready;
	wire _rowReduceSingleN_23_sourceElem_ready;
	wire _rowReduceSingleN_23_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_23_sinkResult_bits;
	wire _rowReduceSingleN_23_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_23_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_23_batchAddReq_bits__2;
	wire _rowReduceSingleN_23_batchAddResp_ready;
	wire _rowReduceSingleN_22_sourceElem_ready;
	wire _rowReduceSingleN_22_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_22_sinkResult_bits;
	wire _rowReduceSingleN_22_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_22_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_22_batchAddReq_bits__2;
	wire _rowReduceSingleN_22_batchAddResp_ready;
	wire _rowReduceSingleN_21_sourceElem_ready;
	wire _rowReduceSingleN_21_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_21_sinkResult_bits;
	wire _rowReduceSingleN_21_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_21_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_21_batchAddReq_bits__2;
	wire _rowReduceSingleN_21_batchAddResp_ready;
	wire _rowReduceSingleN_20_sourceElem_ready;
	wire _rowReduceSingleN_20_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_20_sinkResult_bits;
	wire _rowReduceSingleN_20_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_20_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_20_batchAddReq_bits__2;
	wire _rowReduceSingleN_20_batchAddResp_ready;
	wire _rowReduceSingleN_19_sourceElem_ready;
	wire _rowReduceSingleN_19_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_19_sinkResult_bits;
	wire _rowReduceSingleN_19_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_19_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_19_batchAddReq_bits__2;
	wire _rowReduceSingleN_19_batchAddResp_ready;
	wire _rowReduceSingleN_18_sourceElem_ready;
	wire _rowReduceSingleN_18_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_18_sinkResult_bits;
	wire _rowReduceSingleN_18_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_18_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_18_batchAddReq_bits__2;
	wire _rowReduceSingleN_18_batchAddResp_ready;
	wire _rowReduceSingleN_17_sourceElem_ready;
	wire _rowReduceSingleN_17_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_17_sinkResult_bits;
	wire _rowReduceSingleN_17_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_17_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_17_batchAddReq_bits__2;
	wire _rowReduceSingleN_17_batchAddResp_ready;
	wire _rowReduceSingleN_16_sourceElem_ready;
	wire _rowReduceSingleN_16_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_16_sinkResult_bits;
	wire _rowReduceSingleN_16_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_16_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_16_batchAddReq_bits__2;
	wire _rowReduceSingleN_16_batchAddResp_ready;
	wire _rowReduceSingleN_15_sourceElem_ready;
	wire _rowReduceSingleN_15_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_15_sinkResult_bits;
	wire _rowReduceSingleN_15_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_15_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_15_batchAddReq_bits__2;
	wire _rowReduceSingleN_15_batchAddResp_ready;
	wire _rowReduceSingleN_14_sourceElem_ready;
	wire _rowReduceSingleN_14_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_14_sinkResult_bits;
	wire _rowReduceSingleN_14_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_14_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_14_batchAddReq_bits__2;
	wire _rowReduceSingleN_14_batchAddResp_ready;
	wire _rowReduceSingleN_13_sourceElem_ready;
	wire _rowReduceSingleN_13_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_13_sinkResult_bits;
	wire _rowReduceSingleN_13_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_13_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_13_batchAddReq_bits__2;
	wire _rowReduceSingleN_13_batchAddResp_ready;
	wire _rowReduceSingleN_12_sourceElem_ready;
	wire _rowReduceSingleN_12_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_12_sinkResult_bits;
	wire _rowReduceSingleN_12_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_12_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_12_batchAddReq_bits__2;
	wire _rowReduceSingleN_12_batchAddResp_ready;
	wire _rowReduceSingleN_11_sourceElem_ready;
	wire _rowReduceSingleN_11_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_11_sinkResult_bits;
	wire _rowReduceSingleN_11_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_11_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_11_batchAddReq_bits__2;
	wire _rowReduceSingleN_11_batchAddResp_ready;
	wire _rowReduceSingleN_10_sourceElem_ready;
	wire _rowReduceSingleN_10_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_10_sinkResult_bits;
	wire _rowReduceSingleN_10_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_10_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_10_batchAddReq_bits__2;
	wire _rowReduceSingleN_10_batchAddResp_ready;
	wire _rowReduceSingleN_9_sourceElem_ready;
	wire _rowReduceSingleN_9_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_9_sinkResult_bits;
	wire _rowReduceSingleN_9_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_9_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_9_batchAddReq_bits__2;
	wire _rowReduceSingleN_9_batchAddResp_ready;
	wire _rowReduceSingleN_8_sourceElem_ready;
	wire _rowReduceSingleN_8_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_8_sinkResult_bits;
	wire _rowReduceSingleN_8_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_8_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_8_batchAddReq_bits__2;
	wire _rowReduceSingleN_8_batchAddResp_ready;
	wire _rowReduceSingleN_7_sourceElem_ready;
	wire _rowReduceSingleN_7_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_7_sinkResult_bits;
	wire _rowReduceSingleN_7_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_7_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_7_batchAddReq_bits__2;
	wire _rowReduceSingleN_7_batchAddResp_ready;
	wire _rowReduceSingleN_6_sourceElem_ready;
	wire _rowReduceSingleN_6_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_6_sinkResult_bits;
	wire _rowReduceSingleN_6_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_6_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_6_batchAddReq_bits__2;
	wire _rowReduceSingleN_6_batchAddResp_ready;
	wire _rowReduceSingleN_5_sourceElem_ready;
	wire _rowReduceSingleN_5_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_5_sinkResult_bits;
	wire _rowReduceSingleN_5_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_5_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_5_batchAddReq_bits__2;
	wire _rowReduceSingleN_5_batchAddResp_ready;
	wire _rowReduceSingleN_4_sourceElem_ready;
	wire _rowReduceSingleN_4_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_4_sinkResult_bits;
	wire _rowReduceSingleN_4_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_4_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_4_batchAddReq_bits__2;
	wire _rowReduceSingleN_4_batchAddResp_ready;
	wire _rowReduceSingleN_3_sourceElem_ready;
	wire _rowReduceSingleN_3_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_3_sinkResult_bits;
	wire _rowReduceSingleN_3_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_3_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_3_batchAddReq_bits__2;
	wire _rowReduceSingleN_3_batchAddResp_ready;
	wire _rowReduceSingleN_2_sourceElem_ready;
	wire _rowReduceSingleN_2_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_2_sinkResult_bits;
	wire _rowReduceSingleN_2_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_2_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_2_batchAddReq_bits__2;
	wire _rowReduceSingleN_2_batchAddResp_ready;
	wire _rowReduceSingleN_1_sourceElem_ready;
	wire _rowReduceSingleN_1_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_1_sinkResult_bits;
	wire _rowReduceSingleN_1_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_1_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_1_batchAddReq_bits__2;
	wire _rowReduceSingleN_1_batchAddResp_ready;
	wire _rowReduceSingleN_0_sourceElem_ready;
	wire _rowReduceSingleN_0_sinkResult_valid;
	wire [255:0] _rowReduceSingleN_0_sinkResult_bits;
	wire _rowReduceSingleN_0_batchAddReq_valid;
	wire [255:0] _rowReduceSingleN_0_batchAddReq_bits__1;
	wire [255:0] _rowReduceSingleN_0_batchAddReq_bits__2;
	wire _rowReduceSingleN_0_batchAddResp_ready;
	reg rIsGenerating;
	reg [31:0] rRemaining;
	wire _GEN = _sinkBuffered__sinkBuffer_io_enq_ready & sourceCount_valid;
	wire _GEN_0 = rRemaining == 32'h00000001;
	wire _GEN_1 = sourceCount_bits == 32'h00000000;
	wire _GEN_2 = sourceCount_bits == 32'h00000001;
	wire _GEN_3 = rIsGenerating | ~_GEN_1;
	always @(posedge clock)
		if (reset) begin
			rIsGenerating <= 1'h0;
			rRemaining <= 32'h00000000;
		end
		else if (_GEN) begin
			if (rIsGenerating) begin
				rIsGenerating <= ~(sourceElem_valid & _GEN_0) & rIsGenerating;
				if (sourceElem_valid) begin
					if (_GEN_0)
						rRemaining <= 32'h00000000;
					else
						rRemaining <= rRemaining - 32'h00000001;
				end
			end
			else begin : sv2v_autoblock_1
				reg _GEN_4;
				_GEN_4 = _GEN_1 | _GEN_2;
				rIsGenerating <= (~_GEN_4 & sourceElem_valid) | rIsGenerating;
				if (_GEN_4 | ~sourceElem_valid)
					;
				else
					rRemaining <= sourceCount_bits - 32'h00000001;
			end
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:1];
	end
	RowReduceSingle rowReduceSingleN_0(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_0_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_0_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_0_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_0_ready),
		.batchAddReq_valid(_rowReduceSingleN_0_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_0_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_0_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_0_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_0_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_0_bits)
	);
	RowReduceSingle rowReduceSingleN_1(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_1_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_1_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_1_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_1_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_1_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_1_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_1_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_1_ready),
		.batchAddReq_valid(_rowReduceSingleN_1_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_1_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_1_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_1_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_1_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_1_bits)
	);
	RowReduceSingle rowReduceSingleN_2(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_2_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_2_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_2_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_2_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_2_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_2_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_2_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_2_ready),
		.batchAddReq_valid(_rowReduceSingleN_2_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_2_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_2_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_2_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_2_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_2_bits)
	);
	RowReduceSingle rowReduceSingleN_3(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_3_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_3_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_3_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_3_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_3_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_3_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_3_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_3_ready),
		.batchAddReq_valid(_rowReduceSingleN_3_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_3_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_3_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_3_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_3_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_3_bits)
	);
	RowReduceSingle rowReduceSingleN_4(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_4_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_4_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_4_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_4_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_4_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_4_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_4_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_4_ready),
		.batchAddReq_valid(_rowReduceSingleN_4_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_4_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_4_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_4_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_4_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_4_bits)
	);
	RowReduceSingle rowReduceSingleN_5(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_5_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_5_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_5_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_5_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_5_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_5_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_5_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_5_ready),
		.batchAddReq_valid(_rowReduceSingleN_5_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_5_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_5_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_5_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_5_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_5_bits)
	);
	RowReduceSingle rowReduceSingleN_6(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_6_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_6_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_6_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_6_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_6_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_6_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_6_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_6_ready),
		.batchAddReq_valid(_rowReduceSingleN_6_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_6_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_6_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_6_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_6_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_6_bits)
	);
	RowReduceSingle rowReduceSingleN_7(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_7_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_7_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_7_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_7_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_7_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_7_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_7_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster0_arbiter_io_sources_7_ready),
		.batchAddReq_valid(_rowReduceSingleN_7_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_7_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_7_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_7_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster0_demux_io_sinks_7_valid),
		.batchAddResp_bits(_batchAddCluster0_demux_io_sinks_7_bits)
	);
	RowReduceSingle rowReduceSingleN_8(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_8_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_8_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_8_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_8_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_8_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_8_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_8_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_0_ready),
		.batchAddReq_valid(_rowReduceSingleN_8_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_8_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_8_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_8_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_0_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_0_bits)
	);
	RowReduceSingle rowReduceSingleN_9(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_9_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_9_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_9_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_9_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_9_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_9_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_9_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_1_ready),
		.batchAddReq_valid(_rowReduceSingleN_9_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_9_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_9_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_9_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_1_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_1_bits)
	);
	RowReduceSingle rowReduceSingleN_10(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_10_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_10_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_10_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_10_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_10_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_10_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_10_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_2_ready),
		.batchAddReq_valid(_rowReduceSingleN_10_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_10_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_10_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_10_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_2_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_2_bits)
	);
	RowReduceSingle rowReduceSingleN_11(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_11_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_11_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_11_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_11_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_11_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_11_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_11_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_3_ready),
		.batchAddReq_valid(_rowReduceSingleN_11_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_11_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_11_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_11_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_3_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_3_bits)
	);
	RowReduceSingle rowReduceSingleN_12(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_12_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_12_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_12_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_12_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_12_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_12_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_12_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_4_ready),
		.batchAddReq_valid(_rowReduceSingleN_12_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_12_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_12_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_12_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_4_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_4_bits)
	);
	RowReduceSingle rowReduceSingleN_13(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_13_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_13_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_13_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_13_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_13_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_13_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_13_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_5_ready),
		.batchAddReq_valid(_rowReduceSingleN_13_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_13_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_13_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_13_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_5_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_5_bits)
	);
	RowReduceSingle rowReduceSingleN_14(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_14_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_14_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_14_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_14_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_14_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_14_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_14_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_6_ready),
		.batchAddReq_valid(_rowReduceSingleN_14_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_14_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_14_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_14_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_6_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_6_bits)
	);
	RowReduceSingle rowReduceSingleN_15(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_15_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_15_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_15_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_15_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_15_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_15_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_15_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster1_arbiter_io_sources_7_ready),
		.batchAddReq_valid(_rowReduceSingleN_15_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_15_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_15_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_15_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster1_demux_io_sinks_7_valid),
		.batchAddResp_bits(_batchAddCluster1_demux_io_sinks_7_bits)
	);
	RowReduceSingle rowReduceSingleN_16(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_16_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_16_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_16_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_16_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_16_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_16_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_16_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_0_ready),
		.batchAddReq_valid(_rowReduceSingleN_16_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_16_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_16_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_16_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_0_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_0_bits)
	);
	RowReduceSingle rowReduceSingleN_17(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_17_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_17_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_17_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_17_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_17_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_17_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_17_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_1_ready),
		.batchAddReq_valid(_rowReduceSingleN_17_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_17_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_17_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_17_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_1_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_1_bits)
	);
	RowReduceSingle rowReduceSingleN_18(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_18_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_18_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_18_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_18_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_18_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_18_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_18_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_2_ready),
		.batchAddReq_valid(_rowReduceSingleN_18_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_18_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_18_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_18_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_2_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_2_bits)
	);
	RowReduceSingle rowReduceSingleN_19(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_19_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_19_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_19_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_19_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_19_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_19_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_19_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_3_ready),
		.batchAddReq_valid(_rowReduceSingleN_19_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_19_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_19_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_19_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_3_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_3_bits)
	);
	RowReduceSingle rowReduceSingleN_20(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_20_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_20_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_20_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_20_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_20_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_20_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_20_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_4_ready),
		.batchAddReq_valid(_rowReduceSingleN_20_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_20_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_20_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_20_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_4_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_4_bits)
	);
	RowReduceSingle rowReduceSingleN_21(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_21_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_21_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_21_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_21_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_21_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_21_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_21_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_5_ready),
		.batchAddReq_valid(_rowReduceSingleN_21_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_21_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_21_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_21_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_5_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_5_bits)
	);
	RowReduceSingle rowReduceSingleN_22(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_22_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_22_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_22_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_22_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_22_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_22_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_22_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_6_ready),
		.batchAddReq_valid(_rowReduceSingleN_22_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_22_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_22_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_22_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_6_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_6_bits)
	);
	RowReduceSingle rowReduceSingleN_23(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_23_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_23_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_23_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_23_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_23_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_23_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_23_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster2_arbiter_io_sources_7_ready),
		.batchAddReq_valid(_rowReduceSingleN_23_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_23_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_23_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_23_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster2_demux_io_sinks_7_valid),
		.batchAddResp_bits(_batchAddCluster2_demux_io_sinks_7_bits)
	);
	RowReduceSingle rowReduceSingleN_24(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_24_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_24_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_24_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_24_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_24_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_24_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_24_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_0_ready),
		.batchAddReq_valid(_rowReduceSingleN_24_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_24_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_24_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_24_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_0_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_0_bits)
	);
	RowReduceSingle rowReduceSingleN_25(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_25_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_25_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_25_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_25_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_25_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_25_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_25_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_1_ready),
		.batchAddReq_valid(_rowReduceSingleN_25_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_25_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_25_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_25_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_1_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_1_bits)
	);
	RowReduceSingle rowReduceSingleN_26(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_26_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_26_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_26_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_26_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_26_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_26_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_26_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_2_ready),
		.batchAddReq_valid(_rowReduceSingleN_26_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_26_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_26_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_26_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_2_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_2_bits)
	);
	RowReduceSingle rowReduceSingleN_27(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_27_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_27_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_27_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_27_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_27_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_27_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_27_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_3_ready),
		.batchAddReq_valid(_rowReduceSingleN_27_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_27_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_27_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_27_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_3_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_3_bits)
	);
	RowReduceSingle rowReduceSingleN_28(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_28_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_28_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_28_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_28_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_28_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_28_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_28_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_4_ready),
		.batchAddReq_valid(_rowReduceSingleN_28_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_28_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_28_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_28_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_4_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_4_bits)
	);
	RowReduceSingle rowReduceSingleN_29(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_29_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_29_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_29_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_29_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_29_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_29_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_29_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_5_ready),
		.batchAddReq_valid(_rowReduceSingleN_29_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_29_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_29_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_29_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_5_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_5_bits)
	);
	RowReduceSingle rowReduceSingleN_30(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_30_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_30_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_30_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_30_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_30_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_30_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_30_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_6_ready),
		.batchAddReq_valid(_rowReduceSingleN_30_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_30_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_30_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_30_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_6_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_6_bits)
	);
	RowReduceSingle rowReduceSingleN_31(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduceSingleN_31_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_31_io_deq_valid),
		.sourceElem_bits_data(_sinkBuffer_31_io_deq_bits_data),
		.sourceElem_bits_last(_sinkBuffer_31_io_deq_bits_last),
		.sinkResult_ready(_sourceBuffer_31_io_enq_ready),
		.sinkResult_valid(_rowReduceSingleN_31_sinkResult_valid),
		.sinkResult_bits(_rowReduceSingleN_31_sinkResult_bits),
		.batchAddReq_ready(_batchAddCluster3_arbiter_io_sources_7_ready),
		.batchAddReq_valid(_rowReduceSingleN_31_batchAddReq_valid),
		.batchAddReq_bits__1(_rowReduceSingleN_31_batchAddReq_bits__1),
		.batchAddReq_bits__2(_rowReduceSingleN_31_batchAddReq_bits__2),
		.batchAddResp_ready(_rowReduceSingleN_31_batchAddResp_ready),
		.batchAddResp_valid(_batchAddCluster3_demux_io_sinks_7_valid),
		.batchAddResp_bits(_batchAddCluster3_demux_io_sinks_7_bits)
	);
	BatchAdd batchAddCluster0_batchAdd(
		.clock(clock),
		.reset(reset),
		.req_ready(_batchAddCluster0_batchAdd_req_ready),
		.req_valid(_batchAddCluster0_arbiter_io_sink_valid),
		.req_bits__1(_batchAddCluster0_arbiter_io_sink_bits__1),
		.req_bits__2(_batchAddCluster0_arbiter_io_sink_bits__2),
		.resp_ready(_batchAddCluster0_demux_io_source_ready),
		.resp_valid(_batchAddCluster0_batchAdd_resp_valid),
		.resp_bits(_batchAddCluster0_batchAdd_resp_bits)
	);
	Queue16_UInt5 batchAddCluster0_batchAddQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_batchAddCluster0_batchAddQueue_io_enq_ready),
		.io_enq_valid(_batchAddCluster0_arbiter_io_select_valid),
		.io_enq_bits({2'h0, _batchAddCluster0_arbiter_io_select_bits}),
		.io_deq_ready(_batchAddCluster0_demux_io_select_ready),
		.io_deq_valid(_batchAddCluster0_batchAddQueue_io_deq_valid),
		.io_deq_bits(_batchAddCluster0_batchAddQueue_io_deq_bits)
	);
	elasticBasicArbiter_2 batchAddCluster0_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_batchAddCluster0_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_rowReduceSingleN_0_batchAddReq_valid),
		.io_sources_0_bits__1(_rowReduceSingleN_0_batchAddReq_bits__1),
		.io_sources_0_bits__2(_rowReduceSingleN_0_batchAddReq_bits__2),
		.io_sources_1_ready(_batchAddCluster0_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_rowReduceSingleN_1_batchAddReq_valid),
		.io_sources_1_bits__1(_rowReduceSingleN_1_batchAddReq_bits__1),
		.io_sources_1_bits__2(_rowReduceSingleN_1_batchAddReq_bits__2),
		.io_sources_2_ready(_batchAddCluster0_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_rowReduceSingleN_2_batchAddReq_valid),
		.io_sources_2_bits__1(_rowReduceSingleN_2_batchAddReq_bits__1),
		.io_sources_2_bits__2(_rowReduceSingleN_2_batchAddReq_bits__2),
		.io_sources_3_ready(_batchAddCluster0_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_rowReduceSingleN_3_batchAddReq_valid),
		.io_sources_3_bits__1(_rowReduceSingleN_3_batchAddReq_bits__1),
		.io_sources_3_bits__2(_rowReduceSingleN_3_batchAddReq_bits__2),
		.io_sources_4_ready(_batchAddCluster0_arbiter_io_sources_4_ready),
		.io_sources_4_valid(_rowReduceSingleN_4_batchAddReq_valid),
		.io_sources_4_bits__1(_rowReduceSingleN_4_batchAddReq_bits__1),
		.io_sources_4_bits__2(_rowReduceSingleN_4_batchAddReq_bits__2),
		.io_sources_5_ready(_batchAddCluster0_arbiter_io_sources_5_ready),
		.io_sources_5_valid(_rowReduceSingleN_5_batchAddReq_valid),
		.io_sources_5_bits__1(_rowReduceSingleN_5_batchAddReq_bits__1),
		.io_sources_5_bits__2(_rowReduceSingleN_5_batchAddReq_bits__2),
		.io_sources_6_ready(_batchAddCluster0_arbiter_io_sources_6_ready),
		.io_sources_6_valid(_rowReduceSingleN_6_batchAddReq_valid),
		.io_sources_6_bits__1(_rowReduceSingleN_6_batchAddReq_bits__1),
		.io_sources_6_bits__2(_rowReduceSingleN_6_batchAddReq_bits__2),
		.io_sources_7_ready(_batchAddCluster0_arbiter_io_sources_7_ready),
		.io_sources_7_valid(_rowReduceSingleN_7_batchAddReq_valid),
		.io_sources_7_bits__1(_rowReduceSingleN_7_batchAddReq_bits__1),
		.io_sources_7_bits__2(_rowReduceSingleN_7_batchAddReq_bits__2),
		.io_sink_ready(_batchAddCluster0_batchAdd_req_ready),
		.io_sink_valid(_batchAddCluster0_arbiter_io_sink_valid),
		.io_sink_bits__1(_batchAddCluster0_arbiter_io_sink_bits__1),
		.io_sink_bits__2(_batchAddCluster0_arbiter_io_sink_bits__2),
		.io_select_ready(_batchAddCluster0_batchAddQueue_io_enq_ready),
		.io_select_valid(_batchAddCluster0_arbiter_io_select_valid),
		.io_select_bits(_batchAddCluster0_arbiter_io_select_bits)
	);
	elasticDemux_34 batchAddCluster0_demux(
		.io_source_ready(_batchAddCluster0_demux_io_source_ready),
		.io_source_valid(_batchAddCluster0_batchAdd_resp_valid),
		.io_source_bits(_batchAddCluster0_batchAdd_resp_bits),
		.io_sinks_0_ready(_rowReduceSingleN_0_batchAddResp_ready),
		.io_sinks_0_valid(_batchAddCluster0_demux_io_sinks_0_valid),
		.io_sinks_0_bits(_batchAddCluster0_demux_io_sinks_0_bits),
		.io_sinks_1_ready(_rowReduceSingleN_1_batchAddResp_ready),
		.io_sinks_1_valid(_batchAddCluster0_demux_io_sinks_1_valid),
		.io_sinks_1_bits(_batchAddCluster0_demux_io_sinks_1_bits),
		.io_sinks_2_ready(_rowReduceSingleN_2_batchAddResp_ready),
		.io_sinks_2_valid(_batchAddCluster0_demux_io_sinks_2_valid),
		.io_sinks_2_bits(_batchAddCluster0_demux_io_sinks_2_bits),
		.io_sinks_3_ready(_rowReduceSingleN_3_batchAddResp_ready),
		.io_sinks_3_valid(_batchAddCluster0_demux_io_sinks_3_valid),
		.io_sinks_3_bits(_batchAddCluster0_demux_io_sinks_3_bits),
		.io_sinks_4_ready(_rowReduceSingleN_4_batchAddResp_ready),
		.io_sinks_4_valid(_batchAddCluster0_demux_io_sinks_4_valid),
		.io_sinks_4_bits(_batchAddCluster0_demux_io_sinks_4_bits),
		.io_sinks_5_ready(_rowReduceSingleN_5_batchAddResp_ready),
		.io_sinks_5_valid(_batchAddCluster0_demux_io_sinks_5_valid),
		.io_sinks_5_bits(_batchAddCluster0_demux_io_sinks_5_bits),
		.io_sinks_6_ready(_rowReduceSingleN_6_batchAddResp_ready),
		.io_sinks_6_valid(_batchAddCluster0_demux_io_sinks_6_valid),
		.io_sinks_6_bits(_batchAddCluster0_demux_io_sinks_6_bits),
		.io_sinks_7_ready(_rowReduceSingleN_7_batchAddResp_ready),
		.io_sinks_7_valid(_batchAddCluster0_demux_io_sinks_7_valid),
		.io_sinks_7_bits(_batchAddCluster0_demux_io_sinks_7_bits),
		.io_select_ready(_batchAddCluster0_demux_io_select_ready),
		.io_select_valid(_batchAddCluster0_batchAddQueue_io_deq_valid),
		.io_select_bits(_batchAddCluster0_batchAddQueue_io_deq_bits[2:0])
	);
	BatchAdd batchAddCluster1_batchAdd(
		.clock(clock),
		.reset(reset),
		.req_ready(_batchAddCluster1_batchAdd_req_ready),
		.req_valid(_batchAddCluster1_arbiter_io_sink_valid),
		.req_bits__1(_batchAddCluster1_arbiter_io_sink_bits__1),
		.req_bits__2(_batchAddCluster1_arbiter_io_sink_bits__2),
		.resp_ready(_batchAddCluster1_demux_io_source_ready),
		.resp_valid(_batchAddCluster1_batchAdd_resp_valid),
		.resp_bits(_batchAddCluster1_batchAdd_resp_bits)
	);
	Queue16_UInt5 batchAddCluster1_batchAddQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_batchAddCluster1_batchAddQueue_io_enq_ready),
		.io_enq_valid(_batchAddCluster1_arbiter_io_select_valid),
		.io_enq_bits({2'h0, _batchAddCluster1_arbiter_io_select_bits}),
		.io_deq_ready(_batchAddCluster1_demux_io_select_ready),
		.io_deq_valid(_batchAddCluster1_batchAddQueue_io_deq_valid),
		.io_deq_bits(_batchAddCluster1_batchAddQueue_io_deq_bits)
	);
	elasticBasicArbiter_2 batchAddCluster1_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_batchAddCluster1_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_rowReduceSingleN_8_batchAddReq_valid),
		.io_sources_0_bits__1(_rowReduceSingleN_8_batchAddReq_bits__1),
		.io_sources_0_bits__2(_rowReduceSingleN_8_batchAddReq_bits__2),
		.io_sources_1_ready(_batchAddCluster1_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_rowReduceSingleN_9_batchAddReq_valid),
		.io_sources_1_bits__1(_rowReduceSingleN_9_batchAddReq_bits__1),
		.io_sources_1_bits__2(_rowReduceSingleN_9_batchAddReq_bits__2),
		.io_sources_2_ready(_batchAddCluster1_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_rowReduceSingleN_10_batchAddReq_valid),
		.io_sources_2_bits__1(_rowReduceSingleN_10_batchAddReq_bits__1),
		.io_sources_2_bits__2(_rowReduceSingleN_10_batchAddReq_bits__2),
		.io_sources_3_ready(_batchAddCluster1_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_rowReduceSingleN_11_batchAddReq_valid),
		.io_sources_3_bits__1(_rowReduceSingleN_11_batchAddReq_bits__1),
		.io_sources_3_bits__2(_rowReduceSingleN_11_batchAddReq_bits__2),
		.io_sources_4_ready(_batchAddCluster1_arbiter_io_sources_4_ready),
		.io_sources_4_valid(_rowReduceSingleN_12_batchAddReq_valid),
		.io_sources_4_bits__1(_rowReduceSingleN_12_batchAddReq_bits__1),
		.io_sources_4_bits__2(_rowReduceSingleN_12_batchAddReq_bits__2),
		.io_sources_5_ready(_batchAddCluster1_arbiter_io_sources_5_ready),
		.io_sources_5_valid(_rowReduceSingleN_13_batchAddReq_valid),
		.io_sources_5_bits__1(_rowReduceSingleN_13_batchAddReq_bits__1),
		.io_sources_5_bits__2(_rowReduceSingleN_13_batchAddReq_bits__2),
		.io_sources_6_ready(_batchAddCluster1_arbiter_io_sources_6_ready),
		.io_sources_6_valid(_rowReduceSingleN_14_batchAddReq_valid),
		.io_sources_6_bits__1(_rowReduceSingleN_14_batchAddReq_bits__1),
		.io_sources_6_bits__2(_rowReduceSingleN_14_batchAddReq_bits__2),
		.io_sources_7_ready(_batchAddCluster1_arbiter_io_sources_7_ready),
		.io_sources_7_valid(_rowReduceSingleN_15_batchAddReq_valid),
		.io_sources_7_bits__1(_rowReduceSingleN_15_batchAddReq_bits__1),
		.io_sources_7_bits__2(_rowReduceSingleN_15_batchAddReq_bits__2),
		.io_sink_ready(_batchAddCluster1_batchAdd_req_ready),
		.io_sink_valid(_batchAddCluster1_arbiter_io_sink_valid),
		.io_sink_bits__1(_batchAddCluster1_arbiter_io_sink_bits__1),
		.io_sink_bits__2(_batchAddCluster1_arbiter_io_sink_bits__2),
		.io_select_ready(_batchAddCluster1_batchAddQueue_io_enq_ready),
		.io_select_valid(_batchAddCluster1_arbiter_io_select_valid),
		.io_select_bits(_batchAddCluster1_arbiter_io_select_bits)
	);
	elasticDemux_34 batchAddCluster1_demux(
		.io_source_ready(_batchAddCluster1_demux_io_source_ready),
		.io_source_valid(_batchAddCluster1_batchAdd_resp_valid),
		.io_source_bits(_batchAddCluster1_batchAdd_resp_bits),
		.io_sinks_0_ready(_rowReduceSingleN_8_batchAddResp_ready),
		.io_sinks_0_valid(_batchAddCluster1_demux_io_sinks_0_valid),
		.io_sinks_0_bits(_batchAddCluster1_demux_io_sinks_0_bits),
		.io_sinks_1_ready(_rowReduceSingleN_9_batchAddResp_ready),
		.io_sinks_1_valid(_batchAddCluster1_demux_io_sinks_1_valid),
		.io_sinks_1_bits(_batchAddCluster1_demux_io_sinks_1_bits),
		.io_sinks_2_ready(_rowReduceSingleN_10_batchAddResp_ready),
		.io_sinks_2_valid(_batchAddCluster1_demux_io_sinks_2_valid),
		.io_sinks_2_bits(_batchAddCluster1_demux_io_sinks_2_bits),
		.io_sinks_3_ready(_rowReduceSingleN_11_batchAddResp_ready),
		.io_sinks_3_valid(_batchAddCluster1_demux_io_sinks_3_valid),
		.io_sinks_3_bits(_batchAddCluster1_demux_io_sinks_3_bits),
		.io_sinks_4_ready(_rowReduceSingleN_12_batchAddResp_ready),
		.io_sinks_4_valid(_batchAddCluster1_demux_io_sinks_4_valid),
		.io_sinks_4_bits(_batchAddCluster1_demux_io_sinks_4_bits),
		.io_sinks_5_ready(_rowReduceSingleN_13_batchAddResp_ready),
		.io_sinks_5_valid(_batchAddCluster1_demux_io_sinks_5_valid),
		.io_sinks_5_bits(_batchAddCluster1_demux_io_sinks_5_bits),
		.io_sinks_6_ready(_rowReduceSingleN_14_batchAddResp_ready),
		.io_sinks_6_valid(_batchAddCluster1_demux_io_sinks_6_valid),
		.io_sinks_6_bits(_batchAddCluster1_demux_io_sinks_6_bits),
		.io_sinks_7_ready(_rowReduceSingleN_15_batchAddResp_ready),
		.io_sinks_7_valid(_batchAddCluster1_demux_io_sinks_7_valid),
		.io_sinks_7_bits(_batchAddCluster1_demux_io_sinks_7_bits),
		.io_select_ready(_batchAddCluster1_demux_io_select_ready),
		.io_select_valid(_batchAddCluster1_batchAddQueue_io_deq_valid),
		.io_select_bits(_batchAddCluster1_batchAddQueue_io_deq_bits[2:0])
	);
	BatchAdd batchAddCluster2_batchAdd(
		.clock(clock),
		.reset(reset),
		.req_ready(_batchAddCluster2_batchAdd_req_ready),
		.req_valid(_batchAddCluster2_arbiter_io_sink_valid),
		.req_bits__1(_batchAddCluster2_arbiter_io_sink_bits__1),
		.req_bits__2(_batchAddCluster2_arbiter_io_sink_bits__2),
		.resp_ready(_batchAddCluster2_demux_io_source_ready),
		.resp_valid(_batchAddCluster2_batchAdd_resp_valid),
		.resp_bits(_batchAddCluster2_batchAdd_resp_bits)
	);
	Queue16_UInt5 batchAddCluster2_batchAddQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_batchAddCluster2_batchAddQueue_io_enq_ready),
		.io_enq_valid(_batchAddCluster2_arbiter_io_select_valid),
		.io_enq_bits({2'h0, _batchAddCluster2_arbiter_io_select_bits}),
		.io_deq_ready(_batchAddCluster2_demux_io_select_ready),
		.io_deq_valid(_batchAddCluster2_batchAddQueue_io_deq_valid),
		.io_deq_bits(_batchAddCluster2_batchAddQueue_io_deq_bits)
	);
	elasticBasicArbiter_2 batchAddCluster2_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_batchAddCluster2_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_rowReduceSingleN_16_batchAddReq_valid),
		.io_sources_0_bits__1(_rowReduceSingleN_16_batchAddReq_bits__1),
		.io_sources_0_bits__2(_rowReduceSingleN_16_batchAddReq_bits__2),
		.io_sources_1_ready(_batchAddCluster2_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_rowReduceSingleN_17_batchAddReq_valid),
		.io_sources_1_bits__1(_rowReduceSingleN_17_batchAddReq_bits__1),
		.io_sources_1_bits__2(_rowReduceSingleN_17_batchAddReq_bits__2),
		.io_sources_2_ready(_batchAddCluster2_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_rowReduceSingleN_18_batchAddReq_valid),
		.io_sources_2_bits__1(_rowReduceSingleN_18_batchAddReq_bits__1),
		.io_sources_2_bits__2(_rowReduceSingleN_18_batchAddReq_bits__2),
		.io_sources_3_ready(_batchAddCluster2_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_rowReduceSingleN_19_batchAddReq_valid),
		.io_sources_3_bits__1(_rowReduceSingleN_19_batchAddReq_bits__1),
		.io_sources_3_bits__2(_rowReduceSingleN_19_batchAddReq_bits__2),
		.io_sources_4_ready(_batchAddCluster2_arbiter_io_sources_4_ready),
		.io_sources_4_valid(_rowReduceSingleN_20_batchAddReq_valid),
		.io_sources_4_bits__1(_rowReduceSingleN_20_batchAddReq_bits__1),
		.io_sources_4_bits__2(_rowReduceSingleN_20_batchAddReq_bits__2),
		.io_sources_5_ready(_batchAddCluster2_arbiter_io_sources_5_ready),
		.io_sources_5_valid(_rowReduceSingleN_21_batchAddReq_valid),
		.io_sources_5_bits__1(_rowReduceSingleN_21_batchAddReq_bits__1),
		.io_sources_5_bits__2(_rowReduceSingleN_21_batchAddReq_bits__2),
		.io_sources_6_ready(_batchAddCluster2_arbiter_io_sources_6_ready),
		.io_sources_6_valid(_rowReduceSingleN_22_batchAddReq_valid),
		.io_sources_6_bits__1(_rowReduceSingleN_22_batchAddReq_bits__1),
		.io_sources_6_bits__2(_rowReduceSingleN_22_batchAddReq_bits__2),
		.io_sources_7_ready(_batchAddCluster2_arbiter_io_sources_7_ready),
		.io_sources_7_valid(_rowReduceSingleN_23_batchAddReq_valid),
		.io_sources_7_bits__1(_rowReduceSingleN_23_batchAddReq_bits__1),
		.io_sources_7_bits__2(_rowReduceSingleN_23_batchAddReq_bits__2),
		.io_sink_ready(_batchAddCluster2_batchAdd_req_ready),
		.io_sink_valid(_batchAddCluster2_arbiter_io_sink_valid),
		.io_sink_bits__1(_batchAddCluster2_arbiter_io_sink_bits__1),
		.io_sink_bits__2(_batchAddCluster2_arbiter_io_sink_bits__2),
		.io_select_ready(_batchAddCluster2_batchAddQueue_io_enq_ready),
		.io_select_valid(_batchAddCluster2_arbiter_io_select_valid),
		.io_select_bits(_batchAddCluster2_arbiter_io_select_bits)
	);
	elasticDemux_34 batchAddCluster2_demux(
		.io_source_ready(_batchAddCluster2_demux_io_source_ready),
		.io_source_valid(_batchAddCluster2_batchAdd_resp_valid),
		.io_source_bits(_batchAddCluster2_batchAdd_resp_bits),
		.io_sinks_0_ready(_rowReduceSingleN_16_batchAddResp_ready),
		.io_sinks_0_valid(_batchAddCluster2_demux_io_sinks_0_valid),
		.io_sinks_0_bits(_batchAddCluster2_demux_io_sinks_0_bits),
		.io_sinks_1_ready(_rowReduceSingleN_17_batchAddResp_ready),
		.io_sinks_1_valid(_batchAddCluster2_demux_io_sinks_1_valid),
		.io_sinks_1_bits(_batchAddCluster2_demux_io_sinks_1_bits),
		.io_sinks_2_ready(_rowReduceSingleN_18_batchAddResp_ready),
		.io_sinks_2_valid(_batchAddCluster2_demux_io_sinks_2_valid),
		.io_sinks_2_bits(_batchAddCluster2_demux_io_sinks_2_bits),
		.io_sinks_3_ready(_rowReduceSingleN_19_batchAddResp_ready),
		.io_sinks_3_valid(_batchAddCluster2_demux_io_sinks_3_valid),
		.io_sinks_3_bits(_batchAddCluster2_demux_io_sinks_3_bits),
		.io_sinks_4_ready(_rowReduceSingleN_20_batchAddResp_ready),
		.io_sinks_4_valid(_batchAddCluster2_demux_io_sinks_4_valid),
		.io_sinks_4_bits(_batchAddCluster2_demux_io_sinks_4_bits),
		.io_sinks_5_ready(_rowReduceSingleN_21_batchAddResp_ready),
		.io_sinks_5_valid(_batchAddCluster2_demux_io_sinks_5_valid),
		.io_sinks_5_bits(_batchAddCluster2_demux_io_sinks_5_bits),
		.io_sinks_6_ready(_rowReduceSingleN_22_batchAddResp_ready),
		.io_sinks_6_valid(_batchAddCluster2_demux_io_sinks_6_valid),
		.io_sinks_6_bits(_batchAddCluster2_demux_io_sinks_6_bits),
		.io_sinks_7_ready(_rowReduceSingleN_23_batchAddResp_ready),
		.io_sinks_7_valid(_batchAddCluster2_demux_io_sinks_7_valid),
		.io_sinks_7_bits(_batchAddCluster2_demux_io_sinks_7_bits),
		.io_select_ready(_batchAddCluster2_demux_io_select_ready),
		.io_select_valid(_batchAddCluster2_batchAddQueue_io_deq_valid),
		.io_select_bits(_batchAddCluster2_batchAddQueue_io_deq_bits[2:0])
	);
	BatchAdd batchAddCluster3_batchAdd(
		.clock(clock),
		.reset(reset),
		.req_ready(_batchAddCluster3_batchAdd_req_ready),
		.req_valid(_batchAddCluster3_arbiter_io_sink_valid),
		.req_bits__1(_batchAddCluster3_arbiter_io_sink_bits__1),
		.req_bits__2(_batchAddCluster3_arbiter_io_sink_bits__2),
		.resp_ready(_batchAddCluster3_demux_io_source_ready),
		.resp_valid(_batchAddCluster3_batchAdd_resp_valid),
		.resp_bits(_batchAddCluster3_batchAdd_resp_bits)
	);
	Queue16_UInt5 batchAddCluster3_batchAddQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_batchAddCluster3_batchAddQueue_io_enq_ready),
		.io_enq_valid(_batchAddCluster3_arbiter_io_select_valid),
		.io_enq_bits({2'h0, _batchAddCluster3_arbiter_io_select_bits}),
		.io_deq_ready(_batchAddCluster3_demux_io_select_ready),
		.io_deq_valid(_batchAddCluster3_batchAddQueue_io_deq_valid),
		.io_deq_bits(_batchAddCluster3_batchAddQueue_io_deq_bits)
	);
	elasticBasicArbiter_2 batchAddCluster3_arbiter(
		.clock(clock),
		.reset(reset),
		.io_sources_0_ready(_batchAddCluster3_arbiter_io_sources_0_ready),
		.io_sources_0_valid(_rowReduceSingleN_24_batchAddReq_valid),
		.io_sources_0_bits__1(_rowReduceSingleN_24_batchAddReq_bits__1),
		.io_sources_0_bits__2(_rowReduceSingleN_24_batchAddReq_bits__2),
		.io_sources_1_ready(_batchAddCluster3_arbiter_io_sources_1_ready),
		.io_sources_1_valid(_rowReduceSingleN_25_batchAddReq_valid),
		.io_sources_1_bits__1(_rowReduceSingleN_25_batchAddReq_bits__1),
		.io_sources_1_bits__2(_rowReduceSingleN_25_batchAddReq_bits__2),
		.io_sources_2_ready(_batchAddCluster3_arbiter_io_sources_2_ready),
		.io_sources_2_valid(_rowReduceSingleN_26_batchAddReq_valid),
		.io_sources_2_bits__1(_rowReduceSingleN_26_batchAddReq_bits__1),
		.io_sources_2_bits__2(_rowReduceSingleN_26_batchAddReq_bits__2),
		.io_sources_3_ready(_batchAddCluster3_arbiter_io_sources_3_ready),
		.io_sources_3_valid(_rowReduceSingleN_27_batchAddReq_valid),
		.io_sources_3_bits__1(_rowReduceSingleN_27_batchAddReq_bits__1),
		.io_sources_3_bits__2(_rowReduceSingleN_27_batchAddReq_bits__2),
		.io_sources_4_ready(_batchAddCluster3_arbiter_io_sources_4_ready),
		.io_sources_4_valid(_rowReduceSingleN_28_batchAddReq_valid),
		.io_sources_4_bits__1(_rowReduceSingleN_28_batchAddReq_bits__1),
		.io_sources_4_bits__2(_rowReduceSingleN_28_batchAddReq_bits__2),
		.io_sources_5_ready(_batchAddCluster3_arbiter_io_sources_5_ready),
		.io_sources_5_valid(_rowReduceSingleN_29_batchAddReq_valid),
		.io_sources_5_bits__1(_rowReduceSingleN_29_batchAddReq_bits__1),
		.io_sources_5_bits__2(_rowReduceSingleN_29_batchAddReq_bits__2),
		.io_sources_6_ready(_batchAddCluster3_arbiter_io_sources_6_ready),
		.io_sources_6_valid(_rowReduceSingleN_30_batchAddReq_valid),
		.io_sources_6_bits__1(_rowReduceSingleN_30_batchAddReq_bits__1),
		.io_sources_6_bits__2(_rowReduceSingleN_30_batchAddReq_bits__2),
		.io_sources_7_ready(_batchAddCluster3_arbiter_io_sources_7_ready),
		.io_sources_7_valid(_rowReduceSingleN_31_batchAddReq_valid),
		.io_sources_7_bits__1(_rowReduceSingleN_31_batchAddReq_bits__1),
		.io_sources_7_bits__2(_rowReduceSingleN_31_batchAddReq_bits__2),
		.io_sink_ready(_batchAddCluster3_batchAdd_req_ready),
		.io_sink_valid(_batchAddCluster3_arbiter_io_sink_valid),
		.io_sink_bits__1(_batchAddCluster3_arbiter_io_sink_bits__1),
		.io_sink_bits__2(_batchAddCluster3_arbiter_io_sink_bits__2),
		.io_select_ready(_batchAddCluster3_batchAddQueue_io_enq_ready),
		.io_select_valid(_batchAddCluster3_arbiter_io_select_valid),
		.io_select_bits(_batchAddCluster3_arbiter_io_select_bits)
	);
	elasticDemux_34 batchAddCluster3_demux(
		.io_source_ready(_batchAddCluster3_demux_io_source_ready),
		.io_source_valid(_batchAddCluster3_batchAdd_resp_valid),
		.io_source_bits(_batchAddCluster3_batchAdd_resp_bits),
		.io_sinks_0_ready(_rowReduceSingleN_24_batchAddResp_ready),
		.io_sinks_0_valid(_batchAddCluster3_demux_io_sinks_0_valid),
		.io_sinks_0_bits(_batchAddCluster3_demux_io_sinks_0_bits),
		.io_sinks_1_ready(_rowReduceSingleN_25_batchAddResp_ready),
		.io_sinks_1_valid(_batchAddCluster3_demux_io_sinks_1_valid),
		.io_sinks_1_bits(_batchAddCluster3_demux_io_sinks_1_bits),
		.io_sinks_2_ready(_rowReduceSingleN_26_batchAddResp_ready),
		.io_sinks_2_valid(_batchAddCluster3_demux_io_sinks_2_valid),
		.io_sinks_2_bits(_batchAddCluster3_demux_io_sinks_2_bits),
		.io_sinks_3_ready(_rowReduceSingleN_27_batchAddResp_ready),
		.io_sinks_3_valid(_batchAddCluster3_demux_io_sinks_3_valid),
		.io_sinks_3_bits(_batchAddCluster3_demux_io_sinks_3_bits),
		.io_sinks_4_ready(_rowReduceSingleN_28_batchAddResp_ready),
		.io_sinks_4_valid(_batchAddCluster3_demux_io_sinks_4_valid),
		.io_sinks_4_bits(_batchAddCluster3_demux_io_sinks_4_bits),
		.io_sinks_5_ready(_rowReduceSingleN_29_batchAddResp_ready),
		.io_sinks_5_valid(_batchAddCluster3_demux_io_sinks_5_valid),
		.io_sinks_5_bits(_batchAddCluster3_demux_io_sinks_5_bits),
		.io_sinks_6_ready(_rowReduceSingleN_30_batchAddResp_ready),
		.io_sinks_6_valid(_batchAddCluster3_demux_io_sinks_6_valid),
		.io_sinks_6_bits(_batchAddCluster3_demux_io_sinks_6_bits),
		.io_sinks_7_ready(_rowReduceSingleN_31_batchAddResp_ready),
		.io_sinks_7_valid(_batchAddCluster3_demux_io_sinks_7_valid),
		.io_sinks_7_bits(_batchAddCluster3_demux_io_sinks_7_bits),
		.io_select_ready(_batchAddCluster3_demux_io_select_ready),
		.io_select_valid(_batchAddCluster3_batchAddQueue_io_deq_valid),
		.io_select_bits(_batchAddCluster3_batchAddQueue_io_deq_bits[2:0])
	);
	Queue2_DataLast sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(_GEN & ((~rIsGenerating & _GEN_1) | sourceElem_valid)),
		.io_enq_bits_data((_GEN_3 ? sourceElem_bits : 256'h0000000000000000000000000000000000000000000000000000000000000000)),
		.io_enq_bits_last((rIsGenerating ? _GEN_0 : _GEN_1 | _GEN_2)),
		.io_deq_ready(_demux_io_source_ready),
		.io_deq_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_data(_sinkBuffered__sinkBuffer_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffered__sinkBuffer_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_0_valid),
		.io_enq_bits_data(_demux_io_sinks_0_bits_data),
		.io_enq_bits_last(_demux_io_sinks_0_bits_last),
		.io_deq_ready(_rowReduceSingleN_0_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_1_valid),
		.io_enq_bits_data(_demux_io_sinks_1_bits_data),
		.io_enq_bits_last(_demux_io_sinks_1_bits_last),
		.io_deq_ready(_rowReduceSingleN_1_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_1_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_1_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_1_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_2_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_2_valid),
		.io_enq_bits_data(_demux_io_sinks_2_bits_data),
		.io_enq_bits_last(_demux_io_sinks_2_bits_last),
		.io_deq_ready(_rowReduceSingleN_2_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_2_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_2_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_2_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_3_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_3_valid),
		.io_enq_bits_data(_demux_io_sinks_3_bits_data),
		.io_enq_bits_last(_demux_io_sinks_3_bits_last),
		.io_deq_ready(_rowReduceSingleN_3_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_3_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_3_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_3_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_4_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_4_valid),
		.io_enq_bits_data(_demux_io_sinks_4_bits_data),
		.io_enq_bits_last(_demux_io_sinks_4_bits_last),
		.io_deq_ready(_rowReduceSingleN_4_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_4_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_4_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_4_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_5_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_5_valid),
		.io_enq_bits_data(_demux_io_sinks_5_bits_data),
		.io_enq_bits_last(_demux_io_sinks_5_bits_last),
		.io_deq_ready(_rowReduceSingleN_5_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_5_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_5_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_5_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_6_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_6_valid),
		.io_enq_bits_data(_demux_io_sinks_6_bits_data),
		.io_enq_bits_last(_demux_io_sinks_6_bits_last),
		.io_deq_ready(_rowReduceSingleN_6_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_6_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_6_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_6_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_7_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_7_valid),
		.io_enq_bits_data(_demux_io_sinks_7_bits_data),
		.io_enq_bits_last(_demux_io_sinks_7_bits_last),
		.io_deq_ready(_rowReduceSingleN_7_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_7_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_7_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_7_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_8(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_8_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_8_valid),
		.io_enq_bits_data(_demux_io_sinks_8_bits_data),
		.io_enq_bits_last(_demux_io_sinks_8_bits_last),
		.io_deq_ready(_rowReduceSingleN_8_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_8_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_8_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_8_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_9(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_9_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_9_valid),
		.io_enq_bits_data(_demux_io_sinks_9_bits_data),
		.io_enq_bits_last(_demux_io_sinks_9_bits_last),
		.io_deq_ready(_rowReduceSingleN_9_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_9_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_9_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_9_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_10(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_10_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_10_valid),
		.io_enq_bits_data(_demux_io_sinks_10_bits_data),
		.io_enq_bits_last(_demux_io_sinks_10_bits_last),
		.io_deq_ready(_rowReduceSingleN_10_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_10_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_10_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_10_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_11(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_11_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_11_valid),
		.io_enq_bits_data(_demux_io_sinks_11_bits_data),
		.io_enq_bits_last(_demux_io_sinks_11_bits_last),
		.io_deq_ready(_rowReduceSingleN_11_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_11_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_11_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_11_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_12(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_12_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_12_valid),
		.io_enq_bits_data(_demux_io_sinks_12_bits_data),
		.io_enq_bits_last(_demux_io_sinks_12_bits_last),
		.io_deq_ready(_rowReduceSingleN_12_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_12_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_12_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_12_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_13(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_13_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_13_valid),
		.io_enq_bits_data(_demux_io_sinks_13_bits_data),
		.io_enq_bits_last(_demux_io_sinks_13_bits_last),
		.io_deq_ready(_rowReduceSingleN_13_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_13_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_13_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_13_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_14(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_14_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_14_valid),
		.io_enq_bits_data(_demux_io_sinks_14_bits_data),
		.io_enq_bits_last(_demux_io_sinks_14_bits_last),
		.io_deq_ready(_rowReduceSingleN_14_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_14_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_14_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_14_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_15(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_15_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_15_valid),
		.io_enq_bits_data(_demux_io_sinks_15_bits_data),
		.io_enq_bits_last(_demux_io_sinks_15_bits_last),
		.io_deq_ready(_rowReduceSingleN_15_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_15_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_15_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_15_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_16(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_16_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_16_valid),
		.io_enq_bits_data(_demux_io_sinks_16_bits_data),
		.io_enq_bits_last(_demux_io_sinks_16_bits_last),
		.io_deq_ready(_rowReduceSingleN_16_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_16_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_16_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_16_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_17(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_17_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_17_valid),
		.io_enq_bits_data(_demux_io_sinks_17_bits_data),
		.io_enq_bits_last(_demux_io_sinks_17_bits_last),
		.io_deq_ready(_rowReduceSingleN_17_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_17_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_17_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_17_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_18(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_18_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_18_valid),
		.io_enq_bits_data(_demux_io_sinks_18_bits_data),
		.io_enq_bits_last(_demux_io_sinks_18_bits_last),
		.io_deq_ready(_rowReduceSingleN_18_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_18_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_18_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_18_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_19(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_19_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_19_valid),
		.io_enq_bits_data(_demux_io_sinks_19_bits_data),
		.io_enq_bits_last(_demux_io_sinks_19_bits_last),
		.io_deq_ready(_rowReduceSingleN_19_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_19_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_19_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_19_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_20(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_20_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_20_valid),
		.io_enq_bits_data(_demux_io_sinks_20_bits_data),
		.io_enq_bits_last(_demux_io_sinks_20_bits_last),
		.io_deq_ready(_rowReduceSingleN_20_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_20_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_20_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_20_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_21(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_21_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_21_valid),
		.io_enq_bits_data(_demux_io_sinks_21_bits_data),
		.io_enq_bits_last(_demux_io_sinks_21_bits_last),
		.io_deq_ready(_rowReduceSingleN_21_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_21_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_21_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_21_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_22(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_22_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_22_valid),
		.io_enq_bits_data(_demux_io_sinks_22_bits_data),
		.io_enq_bits_last(_demux_io_sinks_22_bits_last),
		.io_deq_ready(_rowReduceSingleN_22_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_22_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_22_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_22_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_23(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_23_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_23_valid),
		.io_enq_bits_data(_demux_io_sinks_23_bits_data),
		.io_enq_bits_last(_demux_io_sinks_23_bits_last),
		.io_deq_ready(_rowReduceSingleN_23_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_23_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_23_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_23_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_24(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_24_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_24_valid),
		.io_enq_bits_data(_demux_io_sinks_24_bits_data),
		.io_enq_bits_last(_demux_io_sinks_24_bits_last),
		.io_deq_ready(_rowReduceSingleN_24_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_24_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_24_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_24_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_25(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_25_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_25_valid),
		.io_enq_bits_data(_demux_io_sinks_25_bits_data),
		.io_enq_bits_last(_demux_io_sinks_25_bits_last),
		.io_deq_ready(_rowReduceSingleN_25_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_25_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_25_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_25_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_26(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_26_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_26_valid),
		.io_enq_bits_data(_demux_io_sinks_26_bits_data),
		.io_enq_bits_last(_demux_io_sinks_26_bits_last),
		.io_deq_ready(_rowReduceSingleN_26_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_26_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_26_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_26_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_27(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_27_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_27_valid),
		.io_enq_bits_data(_demux_io_sinks_27_bits_data),
		.io_enq_bits_last(_demux_io_sinks_27_bits_last),
		.io_deq_ready(_rowReduceSingleN_27_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_27_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_27_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_27_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_28(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_28_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_28_valid),
		.io_enq_bits_data(_demux_io_sinks_28_bits_data),
		.io_enq_bits_last(_demux_io_sinks_28_bits_last),
		.io_deq_ready(_rowReduceSingleN_28_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_28_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_28_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_28_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_29(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_29_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_29_valid),
		.io_enq_bits_data(_demux_io_sinks_29_bits_data),
		.io_enq_bits_last(_demux_io_sinks_29_bits_last),
		.io_deq_ready(_rowReduceSingleN_29_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_29_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_29_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_29_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_30(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_30_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_30_valid),
		.io_enq_bits_data(_demux_io_sinks_30_bits_data),
		.io_enq_bits_last(_demux_io_sinks_30_bits_last),
		.io_deq_ready(_rowReduceSingleN_30_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_30_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_30_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_30_io_deq_bits_last)
	);
	Queue32_DataLast sinkBuffer_31(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_31_io_enq_ready),
		.io_enq_valid(_demux_io_sinks_31_valid),
		.io_enq_bits_data(_demux_io_sinks_31_bits_data),
		.io_enq_bits_last(_demux_io_sinks_31_bits_last),
		.io_deq_ready(_rowReduceSingleN_31_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_31_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_31_io_deq_bits_data),
		.io_deq_bits_last(_sinkBuffer_31_io_deq_bits_last)
	);
	Counter_37 elasticCounter(
		.clock(clock),
		.reset(reset),
		.sink_ready(_demux_io_select_ready),
		.sink_bits(_elasticCounter_sink_bits)
	);
	elasticDemux_38 demux(
		.io_source_ready(_demux_io_source_ready),
		.io_source_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_source_bits_data(_sinkBuffered__sinkBuffer_io_deq_bits_data),
		.io_source_bits_last(_sinkBuffered__sinkBuffer_io_deq_bits_last),
		.io_sinks_0_ready(_sinkBuffer_io_enq_ready),
		.io_sinks_0_valid(_demux_io_sinks_0_valid),
		.io_sinks_0_bits_data(_demux_io_sinks_0_bits_data),
		.io_sinks_0_bits_last(_demux_io_sinks_0_bits_last),
		.io_sinks_1_ready(_sinkBuffer_1_io_enq_ready),
		.io_sinks_1_valid(_demux_io_sinks_1_valid),
		.io_sinks_1_bits_data(_demux_io_sinks_1_bits_data),
		.io_sinks_1_bits_last(_demux_io_sinks_1_bits_last),
		.io_sinks_2_ready(_sinkBuffer_2_io_enq_ready),
		.io_sinks_2_valid(_demux_io_sinks_2_valid),
		.io_sinks_2_bits_data(_demux_io_sinks_2_bits_data),
		.io_sinks_2_bits_last(_demux_io_sinks_2_bits_last),
		.io_sinks_3_ready(_sinkBuffer_3_io_enq_ready),
		.io_sinks_3_valid(_demux_io_sinks_3_valid),
		.io_sinks_3_bits_data(_demux_io_sinks_3_bits_data),
		.io_sinks_3_bits_last(_demux_io_sinks_3_bits_last),
		.io_sinks_4_ready(_sinkBuffer_4_io_enq_ready),
		.io_sinks_4_valid(_demux_io_sinks_4_valid),
		.io_sinks_4_bits_data(_demux_io_sinks_4_bits_data),
		.io_sinks_4_bits_last(_demux_io_sinks_4_bits_last),
		.io_sinks_5_ready(_sinkBuffer_5_io_enq_ready),
		.io_sinks_5_valid(_demux_io_sinks_5_valid),
		.io_sinks_5_bits_data(_demux_io_sinks_5_bits_data),
		.io_sinks_5_bits_last(_demux_io_sinks_5_bits_last),
		.io_sinks_6_ready(_sinkBuffer_6_io_enq_ready),
		.io_sinks_6_valid(_demux_io_sinks_6_valid),
		.io_sinks_6_bits_data(_demux_io_sinks_6_bits_data),
		.io_sinks_6_bits_last(_demux_io_sinks_6_bits_last),
		.io_sinks_7_ready(_sinkBuffer_7_io_enq_ready),
		.io_sinks_7_valid(_demux_io_sinks_7_valid),
		.io_sinks_7_bits_data(_demux_io_sinks_7_bits_data),
		.io_sinks_7_bits_last(_demux_io_sinks_7_bits_last),
		.io_sinks_8_ready(_sinkBuffer_8_io_enq_ready),
		.io_sinks_8_valid(_demux_io_sinks_8_valid),
		.io_sinks_8_bits_data(_demux_io_sinks_8_bits_data),
		.io_sinks_8_bits_last(_demux_io_sinks_8_bits_last),
		.io_sinks_9_ready(_sinkBuffer_9_io_enq_ready),
		.io_sinks_9_valid(_demux_io_sinks_9_valid),
		.io_sinks_9_bits_data(_demux_io_sinks_9_bits_data),
		.io_sinks_9_bits_last(_demux_io_sinks_9_bits_last),
		.io_sinks_10_ready(_sinkBuffer_10_io_enq_ready),
		.io_sinks_10_valid(_demux_io_sinks_10_valid),
		.io_sinks_10_bits_data(_demux_io_sinks_10_bits_data),
		.io_sinks_10_bits_last(_demux_io_sinks_10_bits_last),
		.io_sinks_11_ready(_sinkBuffer_11_io_enq_ready),
		.io_sinks_11_valid(_demux_io_sinks_11_valid),
		.io_sinks_11_bits_data(_demux_io_sinks_11_bits_data),
		.io_sinks_11_bits_last(_demux_io_sinks_11_bits_last),
		.io_sinks_12_ready(_sinkBuffer_12_io_enq_ready),
		.io_sinks_12_valid(_demux_io_sinks_12_valid),
		.io_sinks_12_bits_data(_demux_io_sinks_12_bits_data),
		.io_sinks_12_bits_last(_demux_io_sinks_12_bits_last),
		.io_sinks_13_ready(_sinkBuffer_13_io_enq_ready),
		.io_sinks_13_valid(_demux_io_sinks_13_valid),
		.io_sinks_13_bits_data(_demux_io_sinks_13_bits_data),
		.io_sinks_13_bits_last(_demux_io_sinks_13_bits_last),
		.io_sinks_14_ready(_sinkBuffer_14_io_enq_ready),
		.io_sinks_14_valid(_demux_io_sinks_14_valid),
		.io_sinks_14_bits_data(_demux_io_sinks_14_bits_data),
		.io_sinks_14_bits_last(_demux_io_sinks_14_bits_last),
		.io_sinks_15_ready(_sinkBuffer_15_io_enq_ready),
		.io_sinks_15_valid(_demux_io_sinks_15_valid),
		.io_sinks_15_bits_data(_demux_io_sinks_15_bits_data),
		.io_sinks_15_bits_last(_demux_io_sinks_15_bits_last),
		.io_sinks_16_ready(_sinkBuffer_16_io_enq_ready),
		.io_sinks_16_valid(_demux_io_sinks_16_valid),
		.io_sinks_16_bits_data(_demux_io_sinks_16_bits_data),
		.io_sinks_16_bits_last(_demux_io_sinks_16_bits_last),
		.io_sinks_17_ready(_sinkBuffer_17_io_enq_ready),
		.io_sinks_17_valid(_demux_io_sinks_17_valid),
		.io_sinks_17_bits_data(_demux_io_sinks_17_bits_data),
		.io_sinks_17_bits_last(_demux_io_sinks_17_bits_last),
		.io_sinks_18_ready(_sinkBuffer_18_io_enq_ready),
		.io_sinks_18_valid(_demux_io_sinks_18_valid),
		.io_sinks_18_bits_data(_demux_io_sinks_18_bits_data),
		.io_sinks_18_bits_last(_demux_io_sinks_18_bits_last),
		.io_sinks_19_ready(_sinkBuffer_19_io_enq_ready),
		.io_sinks_19_valid(_demux_io_sinks_19_valid),
		.io_sinks_19_bits_data(_demux_io_sinks_19_bits_data),
		.io_sinks_19_bits_last(_demux_io_sinks_19_bits_last),
		.io_sinks_20_ready(_sinkBuffer_20_io_enq_ready),
		.io_sinks_20_valid(_demux_io_sinks_20_valid),
		.io_sinks_20_bits_data(_demux_io_sinks_20_bits_data),
		.io_sinks_20_bits_last(_demux_io_sinks_20_bits_last),
		.io_sinks_21_ready(_sinkBuffer_21_io_enq_ready),
		.io_sinks_21_valid(_demux_io_sinks_21_valid),
		.io_sinks_21_bits_data(_demux_io_sinks_21_bits_data),
		.io_sinks_21_bits_last(_demux_io_sinks_21_bits_last),
		.io_sinks_22_ready(_sinkBuffer_22_io_enq_ready),
		.io_sinks_22_valid(_demux_io_sinks_22_valid),
		.io_sinks_22_bits_data(_demux_io_sinks_22_bits_data),
		.io_sinks_22_bits_last(_demux_io_sinks_22_bits_last),
		.io_sinks_23_ready(_sinkBuffer_23_io_enq_ready),
		.io_sinks_23_valid(_demux_io_sinks_23_valid),
		.io_sinks_23_bits_data(_demux_io_sinks_23_bits_data),
		.io_sinks_23_bits_last(_demux_io_sinks_23_bits_last),
		.io_sinks_24_ready(_sinkBuffer_24_io_enq_ready),
		.io_sinks_24_valid(_demux_io_sinks_24_valid),
		.io_sinks_24_bits_data(_demux_io_sinks_24_bits_data),
		.io_sinks_24_bits_last(_demux_io_sinks_24_bits_last),
		.io_sinks_25_ready(_sinkBuffer_25_io_enq_ready),
		.io_sinks_25_valid(_demux_io_sinks_25_valid),
		.io_sinks_25_bits_data(_demux_io_sinks_25_bits_data),
		.io_sinks_25_bits_last(_demux_io_sinks_25_bits_last),
		.io_sinks_26_ready(_sinkBuffer_26_io_enq_ready),
		.io_sinks_26_valid(_demux_io_sinks_26_valid),
		.io_sinks_26_bits_data(_demux_io_sinks_26_bits_data),
		.io_sinks_26_bits_last(_demux_io_sinks_26_bits_last),
		.io_sinks_27_ready(_sinkBuffer_27_io_enq_ready),
		.io_sinks_27_valid(_demux_io_sinks_27_valid),
		.io_sinks_27_bits_data(_demux_io_sinks_27_bits_data),
		.io_sinks_27_bits_last(_demux_io_sinks_27_bits_last),
		.io_sinks_28_ready(_sinkBuffer_28_io_enq_ready),
		.io_sinks_28_valid(_demux_io_sinks_28_valid),
		.io_sinks_28_bits_data(_demux_io_sinks_28_bits_data),
		.io_sinks_28_bits_last(_demux_io_sinks_28_bits_last),
		.io_sinks_29_ready(_sinkBuffer_29_io_enq_ready),
		.io_sinks_29_valid(_demux_io_sinks_29_valid),
		.io_sinks_29_bits_data(_demux_io_sinks_29_bits_data),
		.io_sinks_29_bits_last(_demux_io_sinks_29_bits_last),
		.io_sinks_30_ready(_sinkBuffer_30_io_enq_ready),
		.io_sinks_30_valid(_demux_io_sinks_30_valid),
		.io_sinks_30_bits_data(_demux_io_sinks_30_bits_data),
		.io_sinks_30_bits_last(_demux_io_sinks_30_bits_last),
		.io_sinks_31_ready(_sinkBuffer_31_io_enq_ready),
		.io_sinks_31_valid(_demux_io_sinks_31_valid),
		.io_sinks_31_bits_data(_demux_io_sinks_31_bits_data),
		.io_sinks_31_bits_last(_demux_io_sinks_31_bits_last),
		.io_select_ready(_demux_io_select_ready),
		.io_select_bits(_elasticCounter_sink_bits)
	);
	Queue2_UInt256 sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_0_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_0_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_0_ready),
		.io_deq_valid(_sourceBuffer_io_deq_valid),
		.io_deq_bits(_sourceBuffer_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_1_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_1_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_1_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_1_ready),
		.io_deq_valid(_sourceBuffer_1_io_deq_valid),
		.io_deq_bits(_sourceBuffer_1_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_2_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_2_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_2_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_2_ready),
		.io_deq_valid(_sourceBuffer_2_io_deq_valid),
		.io_deq_bits(_sourceBuffer_2_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_3_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_3_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_3_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_3_ready),
		.io_deq_valid(_sourceBuffer_3_io_deq_valid),
		.io_deq_bits(_sourceBuffer_3_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_4_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_4_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_4_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_4_ready),
		.io_deq_valid(_sourceBuffer_4_io_deq_valid),
		.io_deq_bits(_sourceBuffer_4_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_5_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_5_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_5_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_5_ready),
		.io_deq_valid(_sourceBuffer_5_io_deq_valid),
		.io_deq_bits(_sourceBuffer_5_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_6_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_6_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_6_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_6_ready),
		.io_deq_valid(_sourceBuffer_6_io_deq_valid),
		.io_deq_bits(_sourceBuffer_6_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_7_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_7_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_7_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_7_ready),
		.io_deq_valid(_sourceBuffer_7_io_deq_valid),
		.io_deq_bits(_sourceBuffer_7_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_8(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_8_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_8_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_8_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_8_ready),
		.io_deq_valid(_sourceBuffer_8_io_deq_valid),
		.io_deq_bits(_sourceBuffer_8_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_9(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_9_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_9_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_9_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_9_ready),
		.io_deq_valid(_sourceBuffer_9_io_deq_valid),
		.io_deq_bits(_sourceBuffer_9_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_10(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_10_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_10_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_10_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_10_ready),
		.io_deq_valid(_sourceBuffer_10_io_deq_valid),
		.io_deq_bits(_sourceBuffer_10_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_11(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_11_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_11_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_11_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_11_ready),
		.io_deq_valid(_sourceBuffer_11_io_deq_valid),
		.io_deq_bits(_sourceBuffer_11_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_12(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_12_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_12_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_12_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_12_ready),
		.io_deq_valid(_sourceBuffer_12_io_deq_valid),
		.io_deq_bits(_sourceBuffer_12_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_13(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_13_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_13_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_13_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_13_ready),
		.io_deq_valid(_sourceBuffer_13_io_deq_valid),
		.io_deq_bits(_sourceBuffer_13_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_14(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_14_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_14_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_14_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_14_ready),
		.io_deq_valid(_sourceBuffer_14_io_deq_valid),
		.io_deq_bits(_sourceBuffer_14_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_15(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_15_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_15_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_15_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_15_ready),
		.io_deq_valid(_sourceBuffer_15_io_deq_valid),
		.io_deq_bits(_sourceBuffer_15_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_16(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_16_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_16_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_16_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_16_ready),
		.io_deq_valid(_sourceBuffer_16_io_deq_valid),
		.io_deq_bits(_sourceBuffer_16_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_17(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_17_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_17_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_17_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_17_ready),
		.io_deq_valid(_sourceBuffer_17_io_deq_valid),
		.io_deq_bits(_sourceBuffer_17_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_18(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_18_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_18_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_18_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_18_ready),
		.io_deq_valid(_sourceBuffer_18_io_deq_valid),
		.io_deq_bits(_sourceBuffer_18_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_19(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_19_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_19_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_19_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_19_ready),
		.io_deq_valid(_sourceBuffer_19_io_deq_valid),
		.io_deq_bits(_sourceBuffer_19_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_20(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_20_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_20_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_20_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_20_ready),
		.io_deq_valid(_sourceBuffer_20_io_deq_valid),
		.io_deq_bits(_sourceBuffer_20_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_21(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_21_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_21_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_21_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_21_ready),
		.io_deq_valid(_sourceBuffer_21_io_deq_valid),
		.io_deq_bits(_sourceBuffer_21_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_22(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_22_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_22_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_22_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_22_ready),
		.io_deq_valid(_sourceBuffer_22_io_deq_valid),
		.io_deq_bits(_sourceBuffer_22_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_23(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_23_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_23_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_23_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_23_ready),
		.io_deq_valid(_sourceBuffer_23_io_deq_valid),
		.io_deq_bits(_sourceBuffer_23_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_24(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_24_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_24_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_24_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_24_ready),
		.io_deq_valid(_sourceBuffer_24_io_deq_valid),
		.io_deq_bits(_sourceBuffer_24_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_25(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_25_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_25_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_25_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_25_ready),
		.io_deq_valid(_sourceBuffer_25_io_deq_valid),
		.io_deq_bits(_sourceBuffer_25_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_26(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_26_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_26_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_26_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_26_ready),
		.io_deq_valid(_sourceBuffer_26_io_deq_valid),
		.io_deq_bits(_sourceBuffer_26_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_27(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_27_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_27_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_27_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_27_ready),
		.io_deq_valid(_sourceBuffer_27_io_deq_valid),
		.io_deq_bits(_sourceBuffer_27_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_28(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_28_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_28_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_28_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_28_ready),
		.io_deq_valid(_sourceBuffer_28_io_deq_valid),
		.io_deq_bits(_sourceBuffer_28_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_29(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_29_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_29_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_29_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_29_ready),
		.io_deq_valid(_sourceBuffer_29_io_deq_valid),
		.io_deq_bits(_sourceBuffer_29_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_30(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_30_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_30_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_30_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_30_ready),
		.io_deq_valid(_sourceBuffer_30_io_deq_valid),
		.io_deq_bits(_sourceBuffer_30_io_deq_bits)
	);
	Queue2_UInt256 sourceBuffer_31(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_31_io_enq_ready),
		.io_enq_valid(_rowReduceSingleN_31_sinkResult_valid),
		.io_enq_bits(_rowReduceSingleN_31_sinkResult_bits),
		.io_deq_ready(_mux_io_sources_31_ready),
		.io_deq_valid(_sourceBuffer_31_io_deq_valid),
		.io_deq_bits(_sourceBuffer_31_io_deq_bits)
	);
	Counter_37 elasticCounter_1(
		.clock(clock),
		.reset(reset),
		.sink_ready(_mux_io_select_ready),
		.sink_bits(_elasticCounter_1_sink_bits)
	);
	elasticMux_33 mux(
		.io_sources_0_ready(_mux_io_sources_0_ready),
		.io_sources_0_valid(_sourceBuffer_io_deq_valid),
		.io_sources_0_bits(_sourceBuffer_io_deq_bits),
		.io_sources_1_ready(_mux_io_sources_1_ready),
		.io_sources_1_valid(_sourceBuffer_1_io_deq_valid),
		.io_sources_1_bits(_sourceBuffer_1_io_deq_bits),
		.io_sources_2_ready(_mux_io_sources_2_ready),
		.io_sources_2_valid(_sourceBuffer_2_io_deq_valid),
		.io_sources_2_bits(_sourceBuffer_2_io_deq_bits),
		.io_sources_3_ready(_mux_io_sources_3_ready),
		.io_sources_3_valid(_sourceBuffer_3_io_deq_valid),
		.io_sources_3_bits(_sourceBuffer_3_io_deq_bits),
		.io_sources_4_ready(_mux_io_sources_4_ready),
		.io_sources_4_valid(_sourceBuffer_4_io_deq_valid),
		.io_sources_4_bits(_sourceBuffer_4_io_deq_bits),
		.io_sources_5_ready(_mux_io_sources_5_ready),
		.io_sources_5_valid(_sourceBuffer_5_io_deq_valid),
		.io_sources_5_bits(_sourceBuffer_5_io_deq_bits),
		.io_sources_6_ready(_mux_io_sources_6_ready),
		.io_sources_6_valid(_sourceBuffer_6_io_deq_valid),
		.io_sources_6_bits(_sourceBuffer_6_io_deq_bits),
		.io_sources_7_ready(_mux_io_sources_7_ready),
		.io_sources_7_valid(_sourceBuffer_7_io_deq_valid),
		.io_sources_7_bits(_sourceBuffer_7_io_deq_bits),
		.io_sources_8_ready(_mux_io_sources_8_ready),
		.io_sources_8_valid(_sourceBuffer_8_io_deq_valid),
		.io_sources_8_bits(_sourceBuffer_8_io_deq_bits),
		.io_sources_9_ready(_mux_io_sources_9_ready),
		.io_sources_9_valid(_sourceBuffer_9_io_deq_valid),
		.io_sources_9_bits(_sourceBuffer_9_io_deq_bits),
		.io_sources_10_ready(_mux_io_sources_10_ready),
		.io_sources_10_valid(_sourceBuffer_10_io_deq_valid),
		.io_sources_10_bits(_sourceBuffer_10_io_deq_bits),
		.io_sources_11_ready(_mux_io_sources_11_ready),
		.io_sources_11_valid(_sourceBuffer_11_io_deq_valid),
		.io_sources_11_bits(_sourceBuffer_11_io_deq_bits),
		.io_sources_12_ready(_mux_io_sources_12_ready),
		.io_sources_12_valid(_sourceBuffer_12_io_deq_valid),
		.io_sources_12_bits(_sourceBuffer_12_io_deq_bits),
		.io_sources_13_ready(_mux_io_sources_13_ready),
		.io_sources_13_valid(_sourceBuffer_13_io_deq_valid),
		.io_sources_13_bits(_sourceBuffer_13_io_deq_bits),
		.io_sources_14_ready(_mux_io_sources_14_ready),
		.io_sources_14_valid(_sourceBuffer_14_io_deq_valid),
		.io_sources_14_bits(_sourceBuffer_14_io_deq_bits),
		.io_sources_15_ready(_mux_io_sources_15_ready),
		.io_sources_15_valid(_sourceBuffer_15_io_deq_valid),
		.io_sources_15_bits(_sourceBuffer_15_io_deq_bits),
		.io_sources_16_ready(_mux_io_sources_16_ready),
		.io_sources_16_valid(_sourceBuffer_16_io_deq_valid),
		.io_sources_16_bits(_sourceBuffer_16_io_deq_bits),
		.io_sources_17_ready(_mux_io_sources_17_ready),
		.io_sources_17_valid(_sourceBuffer_17_io_deq_valid),
		.io_sources_17_bits(_sourceBuffer_17_io_deq_bits),
		.io_sources_18_ready(_mux_io_sources_18_ready),
		.io_sources_18_valid(_sourceBuffer_18_io_deq_valid),
		.io_sources_18_bits(_sourceBuffer_18_io_deq_bits),
		.io_sources_19_ready(_mux_io_sources_19_ready),
		.io_sources_19_valid(_sourceBuffer_19_io_deq_valid),
		.io_sources_19_bits(_sourceBuffer_19_io_deq_bits),
		.io_sources_20_ready(_mux_io_sources_20_ready),
		.io_sources_20_valid(_sourceBuffer_20_io_deq_valid),
		.io_sources_20_bits(_sourceBuffer_20_io_deq_bits),
		.io_sources_21_ready(_mux_io_sources_21_ready),
		.io_sources_21_valid(_sourceBuffer_21_io_deq_valid),
		.io_sources_21_bits(_sourceBuffer_21_io_deq_bits),
		.io_sources_22_ready(_mux_io_sources_22_ready),
		.io_sources_22_valid(_sourceBuffer_22_io_deq_valid),
		.io_sources_22_bits(_sourceBuffer_22_io_deq_bits),
		.io_sources_23_ready(_mux_io_sources_23_ready),
		.io_sources_23_valid(_sourceBuffer_23_io_deq_valid),
		.io_sources_23_bits(_sourceBuffer_23_io_deq_bits),
		.io_sources_24_ready(_mux_io_sources_24_ready),
		.io_sources_24_valid(_sourceBuffer_24_io_deq_valid),
		.io_sources_24_bits(_sourceBuffer_24_io_deq_bits),
		.io_sources_25_ready(_mux_io_sources_25_ready),
		.io_sources_25_valid(_sourceBuffer_25_io_deq_valid),
		.io_sources_25_bits(_sourceBuffer_25_io_deq_bits),
		.io_sources_26_ready(_mux_io_sources_26_ready),
		.io_sources_26_valid(_sourceBuffer_26_io_deq_valid),
		.io_sources_26_bits(_sourceBuffer_26_io_deq_bits),
		.io_sources_27_ready(_mux_io_sources_27_ready),
		.io_sources_27_valid(_sourceBuffer_27_io_deq_valid),
		.io_sources_27_bits(_sourceBuffer_27_io_deq_bits),
		.io_sources_28_ready(_mux_io_sources_28_ready),
		.io_sources_28_valid(_sourceBuffer_28_io_deq_valid),
		.io_sources_28_bits(_sourceBuffer_28_io_deq_bits),
		.io_sources_29_ready(_mux_io_sources_29_ready),
		.io_sources_29_valid(_sourceBuffer_29_io_deq_valid),
		.io_sources_29_bits(_sourceBuffer_29_io_deq_bits),
		.io_sources_30_ready(_mux_io_sources_30_ready),
		.io_sources_30_valid(_sourceBuffer_30_io_deq_valid),
		.io_sources_30_bits(_sourceBuffer_30_io_deq_bits),
		.io_sources_31_ready(_mux_io_sources_31_ready),
		.io_sources_31_valid(_sourceBuffer_31_io_deq_valid),
		.io_sources_31_bits(_sourceBuffer_31_io_deq_bits),
		.io_sink_ready(sinkResult_ready),
		.io_sink_valid(sinkResult_valid),
		.io_sink_bits(sinkResult_bits),
		.io_select_ready(_mux_io_select_ready),
		.io_select_bits(_elasticCounter_1_sink_bits)
	);
	assign sourceElem_ready = (_GEN & _GEN_3) & sourceElem_valid;
	assign sourceCount_ready = _GEN & (rIsGenerating ? sourceElem_valid & _GEN_0 : _GEN_1 | (_GEN_2 & sourceElem_valid));
endmodule
module Spmv (
	clock,
	reset,
	sourceTask_ready,
	sourceTask_valid,
	sourceTask_bits_ptrValues,
	sourceTask_bits_ptrColumnIndices,
	sourceTask_bits_ptrRowLengths,
	sourceTask_bits_ptrInputVector,
	sourceTask_bits_ptrOutputVector,
	sourceTask_bits_numValues,
	sourceTask_bits_numRows,
	sinkDone_ready,
	sinkDone_valid,
	sinkDone_bits,
	m_axi_ls_ar_ready,
	m_axi_ls_ar_valid,
	m_axi_ls_ar_bits_addr,
	m_axi_ls_ar_bits_len,
	m_axi_ls_ar_bits_size,
	m_axi_ls_ar_bits_burst,
	m_axi_ls_ar_bits_lock,
	m_axi_ls_ar_bits_cache,
	m_axi_ls_ar_bits_prot,
	m_axi_ls_ar_bits_qos,
	m_axi_ls_ar_bits_region,
	m_axi_ls_r_ready,
	m_axi_ls_r_valid,
	m_axi_ls_r_bits_data,
	m_axi_gp_ar_ready,
	m_axi_gp_ar_valid,
	m_axi_gp_ar_bits_id,
	m_axi_gp_ar_bits_addr,
	m_axi_gp_ar_bits_len,
	m_axi_gp_ar_bits_size,
	m_axi_gp_ar_bits_burst,
	m_axi_gp_r_ready,
	m_axi_gp_r_valid,
	m_axi_gp_r_bits_id,
	m_axi_gp_r_bits_data,
	m_axi_gp_r_bits_resp,
	m_axi_gp_r_bits_last,
	m_axi_gp_aw_ready,
	m_axi_gp_aw_valid,
	m_axi_gp_aw_bits_id,
	m_axi_gp_aw_bits_addr,
	m_axi_gp_aw_bits_len,
	m_axi_gp_aw_bits_size,
	m_axi_gp_aw_bits_burst,
	m_axi_gp_w_ready,
	m_axi_gp_w_valid,
	m_axi_gp_w_bits_data,
	m_axi_gp_w_bits_strb,
	m_axi_gp_w_bits_last,
	m_axi_gp_b_ready,
	m_axi_gp_b_valid,
	m_axi_gp_b_bits_id,
	m_axi_gp_b_bits_resp
);
	input clock;
	input reset;
	output wire sourceTask_ready;
	input sourceTask_valid;
	input [63:0] sourceTask_bits_ptrValues;
	input [63:0] sourceTask_bits_ptrColumnIndices;
	input [63:0] sourceTask_bits_ptrRowLengths;
	input [63:0] sourceTask_bits_ptrInputVector;
	input [63:0] sourceTask_bits_ptrOutputVector;
	input [63:0] sourceTask_bits_numValues;
	input [63:0] sourceTask_bits_numRows;
	input sinkDone_ready;
	output wire sinkDone_valid;
	output wire [63:0] sinkDone_bits;
	input m_axi_ls_ar_ready;
	output wire m_axi_ls_ar_valid;
	output wire [63:0] m_axi_ls_ar_bits_addr;
	output wire [7:0] m_axi_ls_ar_bits_len;
	output wire [2:0] m_axi_ls_ar_bits_size;
	output wire [1:0] m_axi_ls_ar_bits_burst;
	output wire m_axi_ls_ar_bits_lock;
	output wire [3:0] m_axi_ls_ar_bits_cache;
	output wire [2:0] m_axi_ls_ar_bits_prot;
	output wire [3:0] m_axi_ls_ar_bits_qos;
	output wire [3:0] m_axi_ls_ar_bits_region;
	output wire m_axi_ls_r_ready;
	input m_axi_ls_r_valid;
	input [255:0] m_axi_ls_r_bits_data;
	input m_axi_gp_ar_ready;
	output wire m_axi_gp_ar_valid;
	output wire [1:0] m_axi_gp_ar_bits_id;
	output wire [63:0] m_axi_gp_ar_bits_addr;
	output wire [3:0] m_axi_gp_ar_bits_len;
	output wire [2:0] m_axi_gp_ar_bits_size;
	output wire [1:0] m_axi_gp_ar_bits_burst;
	output wire m_axi_gp_r_ready;
	input m_axi_gp_r_valid;
	input [1:0] m_axi_gp_r_bits_id;
	input [255:0] m_axi_gp_r_bits_data;
	input [1:0] m_axi_gp_r_bits_resp;
	input m_axi_gp_r_bits_last;
	input m_axi_gp_aw_ready;
	output wire m_axi_gp_aw_valid;
	output wire [1:0] m_axi_gp_aw_bits_id;
	output wire [63:0] m_axi_gp_aw_bits_addr;
	output wire [3:0] m_axi_gp_aw_bits_len;
	output wire [2:0] m_axi_gp_aw_bits_size;
	output wire [1:0] m_axi_gp_aw_bits_burst;
	input m_axi_gp_w_ready;
	output wire m_axi_gp_w_valid;
	output wire [255:0] m_axi_gp_w_bits_data;
	output wire [31:0] m_axi_gp_w_bits_strb;
	output wire m_axi_gp_w_bits_last;
	output wire m_axi_gp_b_ready;
	input m_axi_gp_b_valid;
	input [1:0] m_axi_gp_b_bits_id;
	input [1:0] m_axi_gp_b_bits_resp;
	wire _sinkBuffer_4_io_enq_ready;
	wire _sinkBuffer_4_io_deq_valid;
	wire [255:0] _sinkBuffer_4_io_deq_bits;
	wire _sinkBuffer_3_io_enq_ready;
	wire _sinkBuffer_3_io_deq_valid;
	wire [255:0] _sinkBuffer_3_io_deq_bits;
	wire _sinkBuffer_2_io_enq_ready;
	wire _sinkBuffer_2_io_deq_valid;
	wire [31:0] _sinkBuffer_2_io_deq_bits;
	wire _rowReduce_sourceElem_ready;
	wire _rowReduce_sourceCount_ready;
	wire _rowReduce_sinkResult_valid;
	wire [255:0] _rowReduce_sinkResult_bits;
	wire _sinkBuffer_1_io_deq_valid;
	wire [255:0] _sinkBuffer_1_io_deq_bits;
	wire _sinkBuffer_io_enq_ready;
	wire _sinkBuffer_io_deq_valid;
	wire [31:0] _sinkBuffer_io_deq_bits;
	wire _batchMultiply_sourceInA_ready;
	wire _batchMultiply_sourceInB_ready;
	wire _batchMultiply_sinkOut_valid;
	wire [255:0] _batchMultiply_sinkOut_bits;
	wire _sinkBuffered__sinkBuffer_1_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_enq_ready;
	wire _sinkBuffered__sinkBuffer_io_deq_valid;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_ptrValues;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_ptrColumnIndices;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_ptrRowLengths;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_ptrInputVector;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_ptrOutputVector;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_numValues;
	wire [63:0] _sinkBuffered__sinkBuffer_io_deq_bits_numRows;
	wire _qPtrInputVector_io_enq_ready;
	wire _qPtrInputVector_io_deq_valid;
	wire [63:0] _qPtrInputVector_io_deq_bits;
	wire _downsizerRowLengths_source_ready;
	wire _downsizerRowLengths_sink_valid;
	wire [31:0] _downsizerRowLengths_sink_bits;
	wire _downsizerColumnIndices_source_ready;
	wire _downsizerColumnIndices_sink_valid;
	wire [31:0] _downsizerColumnIndices_sink_bits_data;
	wire _downsizerColumnIndices_sink_bits_last;
	wire _downsizerValues_source_ready;
	wire _downsizerValues_sink_valid;
	wire [31:0] _downsizerValues_sink_bits;
	wire _mux_s_axi_0_ar_ready;
	wire _mux_s_axi_0_r_valid;
	wire [255:0] _mux_s_axi_0_r_bits_data;
	wire [1:0] _mux_s_axi_0_r_bits_resp;
	wire _mux_s_axi_0_r_bits_last;
	wire _mux_s_axi_1_ar_ready;
	wire _mux_s_axi_1_r_valid;
	wire [255:0] _mux_s_axi_1_r_bits_data;
	wire [1:0] _mux_s_axi_1_r_bits_resp;
	wire _mux_s_axi_1_r_bits_last;
	wire _mux_s_axi_2_ar_ready;
	wire _mux_s_axi_2_r_valid;
	wire [255:0] _mux_s_axi_2_r_bits_data;
	wire [1:0] _mux_s_axi_2_r_bits_resp;
	wire _mux_s_axi_2_r_bits_last;
	wire _mux_s_axi_3_aw_ready;
	wire _mux_s_axi_3_w_ready;
	wire _mux_s_axi_3_b_valid;
	wire [1:0] _mux_s_axi_3_b_bits_resp;
	wire _responseBufferReadStreamRowLengths_s_axi_ar_ready;
	wire _responseBufferReadStreamRowLengths_s_axi_r_valid;
	wire [255:0] _responseBufferReadStreamRowLengths_s_axi_r_bits_data;
	wire _responseBufferReadStreamRowLengths_m_axi_ar_valid;
	wire [63:0] _responseBufferReadStreamRowLengths_m_axi_ar_bits_addr;
	wire [3:0] _responseBufferReadStreamRowLengths_m_axi_ar_bits_len;
	wire [2:0] _responseBufferReadStreamRowLengths_m_axi_ar_bits_size;
	wire [1:0] _responseBufferReadStreamRowLengths_m_axi_ar_bits_burst;
	wire _responseBufferReadStreamRowLengths_m_axi_r_ready;
	wire _responseBufferReadStreamColumnIndices_s_axi_ar_ready;
	wire _responseBufferReadStreamColumnIndices_s_axi_r_valid;
	wire [255:0] _responseBufferReadStreamColumnIndices_s_axi_r_bits_data;
	wire _responseBufferReadStreamColumnIndices_m_axi_ar_valid;
	wire [63:0] _responseBufferReadStreamColumnIndices_m_axi_ar_bits_addr;
	wire [3:0] _responseBufferReadStreamColumnIndices_m_axi_ar_bits_len;
	wire [2:0] _responseBufferReadStreamColumnIndices_m_axi_ar_bits_size;
	wire [1:0] _responseBufferReadStreamColumnIndices_m_axi_ar_bits_burst;
	wire _responseBufferReadStreamColumnIndices_m_axi_r_ready;
	wire _responseBufferReadStreamValue_s_axi_ar_ready;
	wire _responseBufferReadStreamValue_s_axi_r_valid;
	wire [255:0] _responseBufferReadStreamValue_s_axi_r_bits_data;
	wire _responseBufferReadStreamValue_m_axi_ar_valid;
	wire [63:0] _responseBufferReadStreamValue_m_axi_ar_bits_addr;
	wire [3:0] _responseBufferReadStreamValue_m_axi_ar_bits_len;
	wire [2:0] _responseBufferReadStreamValue_m_axi_ar_bits_size;
	wire [1:0] _responseBufferReadStreamValue_m_axi_ar_bits_burst;
	wire _responseBufferReadStreamValue_m_axi_r_ready;
	wire _writeStreamResult_m_axi_aw_valid;
	wire [63:0] _writeStreamResult_m_axi_aw_bits_addr;
	wire [3:0] _writeStreamResult_m_axi_aw_bits_len;
	wire [2:0] _writeStreamResult_m_axi_aw_bits_size;
	wire [1:0] _writeStreamResult_m_axi_aw_bits_burst;
	wire _writeStreamResult_m_axi_w_valid;
	wire [255:0] _writeStreamResult_m_axi_w_bits_data;
	wire [31:0] _writeStreamResult_m_axi_w_bits_strb;
	wire _writeStreamResult_m_axi_w_bits_last;
	wire _writeStreamResult_m_axi_b_ready;
	wire _writeStreamResult_sourceTask_ready;
	wire _writeStreamResult_sinkDone_valid;
	wire _writeStreamResult_sourceData_ready;
	wire _readStreamRowLengths_m_axi_ar_valid;
	wire [63:0] _readStreamRowLengths_m_axi_ar_bits_addr;
	wire [3:0] _readStreamRowLengths_m_axi_ar_bits_len;
	wire [2:0] _readStreamRowLengths_m_axi_ar_bits_size;
	wire [1:0] _readStreamRowLengths_m_axi_ar_bits_burst;
	wire _readStreamRowLengths_m_axi_r_ready;
	wire _readStreamRowLengths_sourceTask_ready;
	wire _readStreamRowLengths_sinkData_valid;
	wire [255:0] _readStreamRowLengths_sinkData_bits;
	wire _readStreamColumnIndices_m_axi_ar_valid;
	wire [63:0] _readStreamColumnIndices_m_axi_ar_bits_addr;
	wire [3:0] _readStreamColumnIndices_m_axi_ar_bits_len;
	wire [2:0] _readStreamColumnIndices_m_axi_ar_bits_size;
	wire [1:0] _readStreamColumnIndices_m_axi_ar_bits_burst;
	wire _readStreamColumnIndices_m_axi_r_ready;
	wire _readStreamColumnIndices_sourceTask_ready;
	wire _readStreamColumnIndices_sinkData_valid;
	wire [255:0] _readStreamColumnIndices_sinkData_bits_data;
	wire _readStreamColumnIndices_sinkData_bits_last;
	wire _readStreamValues_m_axi_ar_valid;
	wire [63:0] _readStreamValues_m_axi_ar_bits_addr;
	wire [3:0] _readStreamValues_m_axi_ar_bits_len;
	wire [2:0] _readStreamValues_m_axi_ar_bits_size;
	wire [1:0] _readStreamValues_m_axi_ar_bits_burst;
	wire _readStreamValues_m_axi_r_ready;
	wire _readStreamValues_sourceTask_ready;
	wire _readStreamValues_sinkData_valid;
	wire [255:0] _readStreamValues_sinkData_bits;
	wire _qTime_io_enq_ready;
	wire _qTime_io_deq_valid;
	wire [63:0] _qTime_io_deq_bits;
	reg [63:0] rTime;
	wire sourceTask_ready_0 = (_sinkBuffered__sinkBuffer_io_enq_ready & sourceTask_valid) & _qTime_io_enq_ready;
	reg eagerFork_regs_0;
	reg eagerFork_regs_1;
	reg eagerFork_regs_2;
	reg eagerFork_regs_3;
	reg eagerFork_regs_4;
	wire eagerFork_rvTask_ready_qual1_0 = _readStreamValues_sourceTask_ready | eagerFork_regs_0;
	wire eagerFork_rvTask_ready_qual1_1 = _readStreamColumnIndices_sourceTask_ready | eagerFork_regs_1;
	wire eagerFork_rvTask_ready_qual1_2 = _readStreamRowLengths_sourceTask_ready | eagerFork_regs_2;
	wire eagerFork_rvTask_ready_qual1_3 = _writeStreamResult_sourceTask_ready | eagerFork_regs_3;
	wire eagerFork_rvTask_ready_qual1_4 = _qPtrInputVector_io_enq_ready | eagerFork_regs_4;
	wire rvTask_ready = (((eagerFork_rvTask_ready_qual1_0 & eagerFork_rvTask_ready_qual1_1) & eagerFork_rvTask_ready_qual1_2) & eagerFork_rvTask_ready_qual1_3) & eagerFork_rvTask_ready_qual1_4;
	wire _GEN = _sinkBuffered__sinkBuffer_1_io_enq_ready & _downsizerColumnIndices_sink_valid;
	wire _GEN_0 = _GEN & _qPtrInputVector_io_deq_valid;
	wire sinkDone_valid_0 = _writeStreamResult_sinkDone_valid & _qTime_io_deq_valid;
	wire mkJoin_fire = sinkDone_ready & sinkDone_valid_0;
	always @(posedge clock)
		if (reset) begin
			rTime <= 64'h0000000000000000;
			eagerFork_regs_0 <= 1'h0;
			eagerFork_regs_1 <= 1'h0;
			eagerFork_regs_2 <= 1'h0;
			eagerFork_regs_3 <= 1'h0;
			eagerFork_regs_4 <= 1'h0;
		end
		else begin
			rTime <= rTime + 64'h0000000000000001;
			eagerFork_regs_0 <= (eagerFork_rvTask_ready_qual1_0 & _sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask_ready;
			eagerFork_regs_1 <= (eagerFork_rvTask_ready_qual1_1 & _sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask_ready;
			eagerFork_regs_2 <= (eagerFork_rvTask_ready_qual1_2 & _sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask_ready;
			eagerFork_regs_3 <= (eagerFork_rvTask_ready_qual1_3 & _sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask_ready;
			eagerFork_regs_4 <= (eagerFork_rvTask_ready_qual1_4 & _sinkBuffered__sinkBuffer_io_deq_valid) & ~rvTask_ready;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:2];
	end
	Queue16_UInt64 qTime(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_qTime_io_enq_ready),
		.io_enq_valid(sourceTask_ready_0),
		.io_enq_bits(rTime),
		.io_deq_ready(mkJoin_fire),
		.io_deq_valid(_qTime_io_deq_valid),
		.io_deq_bits(_qTime_io_deq_bits)
	);
	ReadStream readStreamValues(
		.clock(clock),
		.reset(reset),
		.m_axi_ar_ready(_responseBufferReadStreamValue_s_axi_ar_ready),
		.m_axi_ar_valid(_readStreamValues_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_readStreamValues_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_readStreamValues_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_readStreamValues_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_readStreamValues_m_axi_ar_bits_burst),
		.m_axi_r_ready(_readStreamValues_m_axi_r_ready),
		.m_axi_r_valid(_responseBufferReadStreamValue_s_axi_r_valid),
		.m_axi_r_bits_data(_responseBufferReadStreamValue_s_axi_r_bits_data),
		.sourceTask_ready(_readStreamValues_sourceTask_ready),
		.sourceTask_valid(_sinkBuffered__sinkBuffer_io_deq_valid & ~eagerFork_regs_0),
		.sourceTask_bits_address(_sinkBuffered__sinkBuffer_io_deq_bits_ptrValues),
		.sourceTask_bits_length(_sinkBuffered__sinkBuffer_io_deq_bits_numValues),
		.sinkData_ready(_downsizerValues_source_ready),
		.sinkData_valid(_readStreamValues_sinkData_valid),
		.sinkData_bits(_readStreamValues_sinkData_bits)
	);
	ReadStreamWithLast readStreamColumnIndices(
		.clock(clock),
		.reset(reset),
		.m_axi_ar_ready(_responseBufferReadStreamColumnIndices_s_axi_ar_ready),
		.m_axi_ar_valid(_readStreamColumnIndices_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_readStreamColumnIndices_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_readStreamColumnIndices_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_readStreamColumnIndices_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_readStreamColumnIndices_m_axi_ar_bits_burst),
		.m_axi_r_ready(_readStreamColumnIndices_m_axi_r_ready),
		.m_axi_r_valid(_responseBufferReadStreamColumnIndices_s_axi_r_valid),
		.m_axi_r_bits_data(_responseBufferReadStreamColumnIndices_s_axi_r_bits_data),
		.sourceTask_ready(_readStreamColumnIndices_sourceTask_ready),
		.sourceTask_valid(_sinkBuffered__sinkBuffer_io_deq_valid & ~eagerFork_regs_1),
		.sourceTask_bits_address(_sinkBuffered__sinkBuffer_io_deq_bits_ptrColumnIndices),
		.sourceTask_bits_length(_sinkBuffered__sinkBuffer_io_deq_bits_numValues),
		.sinkData_ready(_downsizerColumnIndices_source_ready),
		.sinkData_valid(_readStreamColumnIndices_sinkData_valid),
		.sinkData_bits_data(_readStreamColumnIndices_sinkData_bits_data),
		.sinkData_bits_last(_readStreamColumnIndices_sinkData_bits_last)
	);
	ReadStream readStreamRowLengths(
		.clock(clock),
		.reset(reset),
		.m_axi_ar_ready(_responseBufferReadStreamRowLengths_s_axi_ar_ready),
		.m_axi_ar_valid(_readStreamRowLengths_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_readStreamRowLengths_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_readStreamRowLengths_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_readStreamRowLengths_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_readStreamRowLengths_m_axi_ar_bits_burst),
		.m_axi_r_ready(_readStreamRowLengths_m_axi_r_ready),
		.m_axi_r_valid(_responseBufferReadStreamRowLengths_s_axi_r_valid),
		.m_axi_r_bits_data(_responseBufferReadStreamRowLengths_s_axi_r_bits_data),
		.sourceTask_ready(_readStreamRowLengths_sourceTask_ready),
		.sourceTask_valid(_sinkBuffered__sinkBuffer_io_deq_valid & ~eagerFork_regs_2),
		.sourceTask_bits_address(_sinkBuffered__sinkBuffer_io_deq_bits_ptrRowLengths),
		.sourceTask_bits_length(_sinkBuffered__sinkBuffer_io_deq_bits_numRows),
		.sinkData_ready(_downsizerRowLengths_source_ready),
		.sinkData_valid(_readStreamRowLengths_sinkData_valid),
		.sinkData_bits(_readStreamRowLengths_sinkData_bits)
	);
	WriteStream writeStreamResult(
		.clock(clock),
		.reset(reset),
		.m_axi_aw_ready(_mux_s_axi_3_aw_ready),
		.m_axi_aw_valid(_writeStreamResult_m_axi_aw_valid),
		.m_axi_aw_bits_addr(_writeStreamResult_m_axi_aw_bits_addr),
		.m_axi_aw_bits_len(_writeStreamResult_m_axi_aw_bits_len),
		.m_axi_aw_bits_size(_writeStreamResult_m_axi_aw_bits_size),
		.m_axi_aw_bits_burst(_writeStreamResult_m_axi_aw_bits_burst),
		.m_axi_w_ready(_mux_s_axi_3_w_ready),
		.m_axi_w_valid(_writeStreamResult_m_axi_w_valid),
		.m_axi_w_bits_data(_writeStreamResult_m_axi_w_bits_data),
		.m_axi_w_bits_strb(_writeStreamResult_m_axi_w_bits_strb),
		.m_axi_w_bits_last(_writeStreamResult_m_axi_w_bits_last),
		.m_axi_b_ready(_writeStreamResult_m_axi_b_ready),
		.m_axi_b_valid(_mux_s_axi_3_b_valid),
		.m_axi_b_bits_resp(_mux_s_axi_3_b_bits_resp),
		.sourceTask_ready(_writeStreamResult_sourceTask_ready),
		.sourceTask_valid(_sinkBuffered__sinkBuffer_io_deq_valid & ~eagerFork_regs_3),
		.sourceTask_bits_address(_sinkBuffered__sinkBuffer_io_deq_bits_ptrOutputVector),
		.sourceTask_bits_length({_sinkBuffered__sinkBuffer_io_deq_bits_numRows[60:0], 3'h0}),
		.sinkDone_ready(mkJoin_fire),
		.sinkDone_valid(_writeStreamResult_sinkDone_valid),
		.sourceData_ready(_writeStreamResult_sourceData_ready),
		.sourceData_valid(_sinkBuffer_4_io_deq_valid),
		.sourceData_bits(_sinkBuffer_4_io_deq_bits)
	);
	ResponseBuffer responseBufferReadStreamValue(
		.clock(clock),
		.reset(reset),
		.s_axi_ar_ready(_responseBufferReadStreamValue_s_axi_ar_ready),
		.s_axi_ar_valid(_readStreamValues_m_axi_ar_valid),
		.s_axi_ar_bits_addr(_readStreamValues_m_axi_ar_bits_addr),
		.s_axi_ar_bits_len(_readStreamValues_m_axi_ar_bits_len),
		.s_axi_ar_bits_size(_readStreamValues_m_axi_ar_bits_size),
		.s_axi_ar_bits_burst(_readStreamValues_m_axi_ar_bits_burst),
		.s_axi_r_ready(_readStreamValues_m_axi_r_ready),
		.s_axi_r_valid(_responseBufferReadStreamValue_s_axi_r_valid),
		.s_axi_r_bits_data(_responseBufferReadStreamValue_s_axi_r_bits_data),
		.m_axi_ar_ready(_mux_s_axi_0_ar_ready),
		.m_axi_ar_valid(_responseBufferReadStreamValue_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_responseBufferReadStreamValue_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_responseBufferReadStreamValue_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_responseBufferReadStreamValue_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_responseBufferReadStreamValue_m_axi_ar_bits_burst),
		.m_axi_r_ready(_responseBufferReadStreamValue_m_axi_r_ready),
		.m_axi_r_valid(_mux_s_axi_0_r_valid),
		.m_axi_r_bits_data(_mux_s_axi_0_r_bits_data),
		.m_axi_r_bits_resp(_mux_s_axi_0_r_bits_resp),
		.m_axi_r_bits_last(_mux_s_axi_0_r_bits_last)
	);
	ResponseBuffer responseBufferReadStreamColumnIndices(
		.clock(clock),
		.reset(reset),
		.s_axi_ar_ready(_responseBufferReadStreamColumnIndices_s_axi_ar_ready),
		.s_axi_ar_valid(_readStreamColumnIndices_m_axi_ar_valid),
		.s_axi_ar_bits_addr(_readStreamColumnIndices_m_axi_ar_bits_addr),
		.s_axi_ar_bits_len(_readStreamColumnIndices_m_axi_ar_bits_len),
		.s_axi_ar_bits_size(_readStreamColumnIndices_m_axi_ar_bits_size),
		.s_axi_ar_bits_burst(_readStreamColumnIndices_m_axi_ar_bits_burst),
		.s_axi_r_ready(_readStreamColumnIndices_m_axi_r_ready),
		.s_axi_r_valid(_responseBufferReadStreamColumnIndices_s_axi_r_valid),
		.s_axi_r_bits_data(_responseBufferReadStreamColumnIndices_s_axi_r_bits_data),
		.m_axi_ar_ready(_mux_s_axi_1_ar_ready),
		.m_axi_ar_valid(_responseBufferReadStreamColumnIndices_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_burst),
		.m_axi_r_ready(_responseBufferReadStreamColumnIndices_m_axi_r_ready),
		.m_axi_r_valid(_mux_s_axi_1_r_valid),
		.m_axi_r_bits_data(_mux_s_axi_1_r_bits_data),
		.m_axi_r_bits_resp(_mux_s_axi_1_r_bits_resp),
		.m_axi_r_bits_last(_mux_s_axi_1_r_bits_last)
	);
	ResponseBuffer responseBufferReadStreamRowLengths(
		.clock(clock),
		.reset(reset),
		.s_axi_ar_ready(_responseBufferReadStreamRowLengths_s_axi_ar_ready),
		.s_axi_ar_valid(_readStreamRowLengths_m_axi_ar_valid),
		.s_axi_ar_bits_addr(_readStreamRowLengths_m_axi_ar_bits_addr),
		.s_axi_ar_bits_len(_readStreamRowLengths_m_axi_ar_bits_len),
		.s_axi_ar_bits_size(_readStreamRowLengths_m_axi_ar_bits_size),
		.s_axi_ar_bits_burst(_readStreamRowLengths_m_axi_ar_bits_burst),
		.s_axi_r_ready(_readStreamRowLengths_m_axi_r_ready),
		.s_axi_r_valid(_responseBufferReadStreamRowLengths_s_axi_r_valid),
		.s_axi_r_bits_data(_responseBufferReadStreamRowLengths_s_axi_r_bits_data),
		.m_axi_ar_ready(_mux_s_axi_2_ar_ready),
		.m_axi_ar_valid(_responseBufferReadStreamRowLengths_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_responseBufferReadStreamRowLengths_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_responseBufferReadStreamRowLengths_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_responseBufferReadStreamRowLengths_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_responseBufferReadStreamRowLengths_m_axi_ar_bits_burst),
		.m_axi_r_ready(_responseBufferReadStreamRowLengths_m_axi_r_ready),
		.m_axi_r_valid(_mux_s_axi_2_r_valid),
		.m_axi_r_bits_data(_mux_s_axi_2_r_bits_data),
		.m_axi_r_bits_resp(_mux_s_axi_2_r_bits_resp),
		.m_axi_r_bits_last(_mux_s_axi_2_r_bits_last)
	);
	Mux mux(
		.clock(clock),
		.reset(reset),
		.s_axi_0_ar_ready(_mux_s_axi_0_ar_ready),
		.s_axi_0_ar_valid(_responseBufferReadStreamValue_m_axi_ar_valid),
		.s_axi_0_ar_bits_addr(_responseBufferReadStreamValue_m_axi_ar_bits_addr),
		.s_axi_0_ar_bits_len(_responseBufferReadStreamValue_m_axi_ar_bits_len),
		.s_axi_0_ar_bits_size(_responseBufferReadStreamValue_m_axi_ar_bits_size),
		.s_axi_0_ar_bits_burst(_responseBufferReadStreamValue_m_axi_ar_bits_burst),
		.s_axi_0_r_ready(_responseBufferReadStreamValue_m_axi_r_ready),
		.s_axi_0_r_valid(_mux_s_axi_0_r_valid),
		.s_axi_0_r_bits_data(_mux_s_axi_0_r_bits_data),
		.s_axi_0_r_bits_resp(_mux_s_axi_0_r_bits_resp),
		.s_axi_0_r_bits_last(_mux_s_axi_0_r_bits_last),
		.s_axi_1_ar_ready(_mux_s_axi_1_ar_ready),
		.s_axi_1_ar_valid(_responseBufferReadStreamColumnIndices_m_axi_ar_valid),
		.s_axi_1_ar_bits_addr(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_addr),
		.s_axi_1_ar_bits_len(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_len),
		.s_axi_1_ar_bits_size(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_size),
		.s_axi_1_ar_bits_burst(_responseBufferReadStreamColumnIndices_m_axi_ar_bits_burst),
		.s_axi_1_r_ready(_responseBufferReadStreamColumnIndices_m_axi_r_ready),
		.s_axi_1_r_valid(_mux_s_axi_1_r_valid),
		.s_axi_1_r_bits_data(_mux_s_axi_1_r_bits_data),
		.s_axi_1_r_bits_resp(_mux_s_axi_1_r_bits_resp),
		.s_axi_1_r_bits_last(_mux_s_axi_1_r_bits_last),
		.s_axi_2_ar_ready(_mux_s_axi_2_ar_ready),
		.s_axi_2_ar_valid(_responseBufferReadStreamRowLengths_m_axi_ar_valid),
		.s_axi_2_ar_bits_addr(_responseBufferReadStreamRowLengths_m_axi_ar_bits_addr),
		.s_axi_2_ar_bits_len(_responseBufferReadStreamRowLengths_m_axi_ar_bits_len),
		.s_axi_2_ar_bits_size(_responseBufferReadStreamRowLengths_m_axi_ar_bits_size),
		.s_axi_2_ar_bits_burst(_responseBufferReadStreamRowLengths_m_axi_ar_bits_burst),
		.s_axi_2_r_ready(_responseBufferReadStreamRowLengths_m_axi_r_ready),
		.s_axi_2_r_valid(_mux_s_axi_2_r_valid),
		.s_axi_2_r_bits_data(_mux_s_axi_2_r_bits_data),
		.s_axi_2_r_bits_resp(_mux_s_axi_2_r_bits_resp),
		.s_axi_2_r_bits_last(_mux_s_axi_2_r_bits_last),
		.s_axi_3_aw_ready(_mux_s_axi_3_aw_ready),
		.s_axi_3_aw_valid(_writeStreamResult_m_axi_aw_valid),
		.s_axi_3_aw_bits_addr(_writeStreamResult_m_axi_aw_bits_addr),
		.s_axi_3_aw_bits_len(_writeStreamResult_m_axi_aw_bits_len),
		.s_axi_3_aw_bits_size(_writeStreamResult_m_axi_aw_bits_size),
		.s_axi_3_aw_bits_burst(_writeStreamResult_m_axi_aw_bits_burst),
		.s_axi_3_w_ready(_mux_s_axi_3_w_ready),
		.s_axi_3_w_valid(_writeStreamResult_m_axi_w_valid),
		.s_axi_3_w_bits_data(_writeStreamResult_m_axi_w_bits_data),
		.s_axi_3_w_bits_strb(_writeStreamResult_m_axi_w_bits_strb),
		.s_axi_3_w_bits_last(_writeStreamResult_m_axi_w_bits_last),
		.s_axi_3_b_ready(_writeStreamResult_m_axi_b_ready),
		.s_axi_3_b_valid(_mux_s_axi_3_b_valid),
		.s_axi_3_b_bits_resp(_mux_s_axi_3_b_bits_resp),
		.m_axi_ar_ready(m_axi_gp_ar_ready),
		.m_axi_ar_valid(m_axi_gp_ar_valid),
		.m_axi_ar_bits_id(m_axi_gp_ar_bits_id),
		.m_axi_ar_bits_addr(m_axi_gp_ar_bits_addr),
		.m_axi_ar_bits_len(m_axi_gp_ar_bits_len),
		.m_axi_ar_bits_size(m_axi_gp_ar_bits_size),
		.m_axi_ar_bits_burst(m_axi_gp_ar_bits_burst),
		.m_axi_r_ready(m_axi_gp_r_ready),
		.m_axi_r_valid(m_axi_gp_r_valid),
		.m_axi_r_bits_id(m_axi_gp_r_bits_id),
		.m_axi_r_bits_data(m_axi_gp_r_bits_data),
		.m_axi_r_bits_resp(m_axi_gp_r_bits_resp),
		.m_axi_r_bits_last(m_axi_gp_r_bits_last),
		.m_axi_aw_ready(m_axi_gp_aw_ready),
		.m_axi_aw_valid(m_axi_gp_aw_valid),
		.m_axi_aw_bits_id(m_axi_gp_aw_bits_id),
		.m_axi_aw_bits_addr(m_axi_gp_aw_bits_addr),
		.m_axi_aw_bits_len(m_axi_gp_aw_bits_len),
		.m_axi_aw_bits_size(m_axi_gp_aw_bits_size),
		.m_axi_aw_bits_burst(m_axi_gp_aw_bits_burst),
		.m_axi_w_ready(m_axi_gp_w_ready),
		.m_axi_w_valid(m_axi_gp_w_valid),
		.m_axi_w_bits_data(m_axi_gp_w_bits_data),
		.m_axi_w_bits_strb(m_axi_gp_w_bits_strb),
		.m_axi_w_bits_last(m_axi_gp_w_bits_last),
		.m_axi_b_ready(m_axi_gp_b_ready),
		.m_axi_b_valid(m_axi_gp_b_valid),
		.m_axi_b_bits_id(m_axi_gp_b_bits_id),
		.m_axi_b_bits_resp(m_axi_gp_b_bits_resp)
	);
	Downsize downsizerValues(
		.clock(clock),
		.reset(reset),
		.source_ready(_downsizerValues_source_ready),
		.source_valid(_readStreamValues_sinkData_valid),
		.source_bits(_readStreamValues_sinkData_bits),
		.sink_ready(_sinkBuffer_io_enq_ready),
		.sink_valid(_downsizerValues_sink_valid),
		.sink_bits(_downsizerValues_sink_bits)
	);
	DownsizeWithLast downsizerColumnIndices(
		.clock(clock),
		.reset(reset),
		.source_ready(_downsizerColumnIndices_source_ready),
		.source_valid(_readStreamColumnIndices_sinkData_valid),
		.source_bits_data(_readStreamColumnIndices_sinkData_bits_data),
		.source_bits_last(_readStreamColumnIndices_sinkData_bits_last),
		.sink_ready(_GEN_0),
		.sink_valid(_downsizerColumnIndices_sink_valid),
		.sink_bits_data(_downsizerColumnIndices_sink_bits_data),
		.sink_bits_last(_downsizerColumnIndices_sink_bits_last)
	);
	Downsize downsizerRowLengths(
		.clock(clock),
		.reset(reset),
		.source_ready(_downsizerRowLengths_source_ready),
		.source_valid(_readStreamRowLengths_sinkData_valid),
		.source_bits(_readStreamRowLengths_sinkData_bits),
		.sink_ready(_sinkBuffer_2_io_enq_ready),
		.sink_valid(_downsizerRowLengths_sink_valid),
		.sink_bits(_downsizerRowLengths_sink_bits)
	);
	Queue16_UInt64 qPtrInputVector(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_qPtrInputVector_io_enq_ready),
		.io_enq_valid(_sinkBuffered__sinkBuffer_io_deq_valid & ~eagerFork_regs_4),
		.io_enq_bits(_sinkBuffered__sinkBuffer_io_deq_bits_ptrInputVector),
		.io_deq_ready((_GEN & _qPtrInputVector_io_deq_valid) & _downsizerColumnIndices_sink_bits_last),
		.io_deq_valid(_qPtrInputVector_io_deq_valid),
		.io_deq_bits(_qPtrInputVector_io_deq_bits)
	);
	Queue2_SpmvTask sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(sourceTask_ready_0),
		.io_enq_bits_ptrValues(sourceTask_bits_ptrValues),
		.io_enq_bits_ptrColumnIndices(sourceTask_bits_ptrColumnIndices),
		.io_enq_bits_ptrRowLengths(sourceTask_bits_ptrRowLengths),
		.io_enq_bits_ptrInputVector(sourceTask_bits_ptrInputVector),
		.io_enq_bits_ptrOutputVector(sourceTask_bits_ptrOutputVector),
		.io_enq_bits_numValues(sourceTask_bits_numValues),
		.io_enq_bits_numRows(sourceTask_bits_numRows),
		.io_deq_ready(rvTask_ready),
		.io_deq_valid(_sinkBuffered__sinkBuffer_io_deq_valid),
		.io_deq_bits_ptrValues(_sinkBuffered__sinkBuffer_io_deq_bits_ptrValues),
		.io_deq_bits_ptrColumnIndices(_sinkBuffered__sinkBuffer_io_deq_bits_ptrColumnIndices),
		.io_deq_bits_ptrRowLengths(_sinkBuffered__sinkBuffer_io_deq_bits_ptrRowLengths),
		.io_deq_bits_ptrInputVector(_sinkBuffered__sinkBuffer_io_deq_bits_ptrInputVector),
		.io_deq_bits_ptrOutputVector(_sinkBuffered__sinkBuffer_io_deq_bits_ptrOutputVector),
		.io_deq_bits_numValues(_sinkBuffered__sinkBuffer_io_deq_bits_numValues),
		.io_deq_bits_numRows(_sinkBuffered__sinkBuffer_io_deq_bits_numRows)
	);
	Queue2_ReadAddressChannel_7 sinkBuffered__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffered__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_GEN_0),
		.io_enq_bits_addr((_qPtrInputVector_io_deq_valid ? {27'h0000000, _downsizerColumnIndices_sink_bits_data, 5'h00} + _qPtrInputVector_io_deq_bits : 64'h0000000000000000)),
		.io_enq_bits_len(8'h00),
		.io_enq_bits_size((_qPtrInputVector_io_deq_valid ? 3'h5 : 3'h0)),
		.io_enq_bits_burst(2'h0),
		.io_enq_bits_lock(1'h0),
		.io_enq_bits_cache(4'h0),
		.io_enq_bits_prot(3'h0),
		.io_enq_bits_qos(4'h0),
		.io_enq_bits_region(4'h0),
		.io_deq_ready(m_axi_ls_ar_ready),
		.io_deq_valid(m_axi_ls_ar_valid),
		.io_deq_bits_addr(m_axi_ls_ar_bits_addr),
		.io_deq_bits_len(m_axi_ls_ar_bits_len),
		.io_deq_bits_size(m_axi_ls_ar_bits_size),
		.io_deq_bits_burst(m_axi_ls_ar_bits_burst),
		.io_deq_bits_lock(m_axi_ls_ar_bits_lock),
		.io_deq_bits_cache(m_axi_ls_ar_bits_cache),
		.io_deq_bits_prot(m_axi_ls_ar_bits_prot),
		.io_deq_bits_qos(m_axi_ls_ar_bits_qos),
		.io_deq_bits_region(m_axi_ls_ar_bits_region)
	);
	BatchMultiply batchMultiply(
		.clock(clock),
		.reset(reset),
		.sourceInA_ready(_batchMultiply_sourceInA_ready),
		.sourceInA_valid(_sinkBuffer_io_deq_valid),
		.sourceInA_bits(_sinkBuffer_io_deq_bits),
		.sourceInB_ready(_batchMultiply_sourceInB_ready),
		.sourceInB_valid(_sinkBuffer_1_io_deq_valid),
		.sourceInB_bits(_sinkBuffer_1_io_deq_bits),
		.sinkOut_ready(_sinkBuffer_3_io_enq_ready),
		.sinkOut_valid(_batchMultiply_sinkOut_valid),
		.sinkOut_bits(_batchMultiply_sinkOut_bits)
	);
	Queue2_UInt32 sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_io_enq_ready),
		.io_enq_valid(_downsizerValues_sink_valid),
		.io_enq_bits(_downsizerValues_sink_bits),
		.io_deq_ready(_batchMultiply_sourceInA_ready),
		.io_deq_valid(_sinkBuffer_io_deq_valid),
		.io_deq_bits(_sinkBuffer_io_deq_bits)
	);
	Queue2_UInt256 sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(m_axi_ls_r_ready),
		.io_enq_valid(m_axi_ls_r_valid),
		.io_enq_bits(m_axi_ls_r_bits_data),
		.io_deq_ready(_batchMultiply_sourceInB_ready),
		.io_deq_valid(_sinkBuffer_1_io_deq_valid),
		.io_deq_bits(_sinkBuffer_1_io_deq_bits)
	);
	RowReduce rowReduce(
		.clock(clock),
		.reset(reset),
		.sourceElem_ready(_rowReduce_sourceElem_ready),
		.sourceElem_valid(_sinkBuffer_3_io_deq_valid),
		.sourceElem_bits(_sinkBuffer_3_io_deq_bits),
		.sourceCount_ready(_rowReduce_sourceCount_ready),
		.sourceCount_valid(_sinkBuffer_2_io_deq_valid),
		.sourceCount_bits(_sinkBuffer_2_io_deq_bits),
		.sinkResult_ready(_sinkBuffer_4_io_enq_ready),
		.sinkResult_valid(_rowReduce_sinkResult_valid),
		.sinkResult_bits(_rowReduce_sinkResult_bits)
	);
	Queue2_UInt32 sinkBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_2_io_enq_ready),
		.io_enq_valid(_downsizerRowLengths_sink_valid),
		.io_enq_bits(_downsizerRowLengths_sink_bits),
		.io_deq_ready(_rowReduce_sourceCount_ready),
		.io_deq_valid(_sinkBuffer_2_io_deq_valid),
		.io_deq_bits(_sinkBuffer_2_io_deq_bits)
	);
	Queue2_UInt256 sinkBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_3_io_enq_ready),
		.io_enq_valid(_batchMultiply_sinkOut_valid),
		.io_enq_bits(_batchMultiply_sinkOut_bits),
		.io_deq_ready(_rowReduce_sourceElem_ready),
		.io_deq_valid(_sinkBuffer_3_io_deq_valid),
		.io_deq_bits(_sinkBuffer_3_io_deq_bits)
	);
	Queue2_UInt256 sinkBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_4_io_enq_ready),
		.io_enq_valid(_rowReduce_sinkResult_valid),
		.io_enq_bits(_rowReduce_sinkResult_bits),
		.io_deq_ready(_writeStreamResult_sourceData_ready),
		.io_deq_valid(_sinkBuffer_4_io_deq_valid),
		.io_deq_bits(_sinkBuffer_4_io_deq_bits)
	);
	assign sourceTask_ready = sourceTask_ready_0;
	assign sinkDone_valid = sinkDone_valid_0;
	assign sinkDone_bits = rTime - _qTime_io_deq_bits;
endmodule
module ram_2x13 (
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
	output wire [12:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [12:0] W0_data;
	reg [12:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 13'bxxxxxxxxxxxxx);
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
	input [9:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_prot;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [9:0] io_deq_bits_addr;
	output wire [2:0] io_deq_bits_prot;
	wire [12:0] _ram_ext_R0_data;
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
	ram_2x13 ram_ext(
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
	assign io_deq_bits_addr = _ram_ext_R0_data[9:0];
	assign io_deq_bits_prot = _ram_ext_R0_data[12:10];
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
module Queue2_ReadDataChannel_3 (
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
module Queue2_WriteDataChannel_1 (
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
module Queue2_WriteResponseChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_resp,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_resp;
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
		.W0_data(io_enq_bits_resp)
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
	input [9:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_prot;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [9:0] io_deq_bits_addr;
	reg [12:0] ram;
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
	assign io_deq_bits_addr = ram[9:0];
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
module MemAdapter (
	clock,
	reset,
	s_axil_ar_ready,
	s_axil_ar_valid,
	s_axil_ar_bits_addr,
	s_axil_ar_bits_prot,
	s_axil_r_ready,
	s_axil_r_valid,
	s_axil_r_bits_data,
	s_axil_r_bits_resp,
	s_axil_aw_ready,
	s_axil_aw_valid,
	s_axil_aw_bits_addr,
	s_axil_aw_bits_prot,
	s_axil_w_ready,
	s_axil_w_valid,
	s_axil_w_bits_data,
	s_axil_w_bits_strb,
	s_axil_b_ready,
	s_axil_b_valid,
	s_axil_b_bits_resp,
	source_ready,
	source_valid,
	source_bits,
	sink_ready,
	sink_valid,
	sink_bits
);
	input clock;
	input reset;
	output wire s_axil_ar_ready;
	input s_axil_ar_valid;
	input [9:0] s_axil_ar_bits_addr;
	input [2:0] s_axil_ar_bits_prot;
	input s_axil_r_ready;
	output wire s_axil_r_valid;
	output wire [31:0] s_axil_r_bits_data;
	output wire [1:0] s_axil_r_bits_resp;
	output wire s_axil_aw_ready;
	input s_axil_aw_valid;
	input [9:0] s_axil_aw_bits_addr;
	input [2:0] s_axil_aw_bits_prot;
	output wire s_axil_w_ready;
	input s_axil_w_valid;
	input [31:0] s_axil_w_bits_data;
	input [3:0] s_axil_w_bits_strb;
	input s_axil_b_ready;
	output wire s_axil_b_valid;
	output wire [1:0] s_axil_b_bits_resp;
	output wire source_ready;
	input source_valid;
	input [63:0] source_bits;
	input sink_ready;
	output wire sink_valid;
	output wire [447:0] sink_bits;
	wire _wrRespQueue__io_enq_ready;
	wire _wrRespQueue__io_deq_valid;
	wire _wrReqData__deq_q_io_enq_ready;
	wire _wrReqData__deq_q_io_deq_valid;
	wire [31:0] _wrReqData__deq_q_io_deq_bits_data;
	wire [3:0] _wrReqData__deq_q_io_deq_bits_strb;
	wire _wrReq__deq_q_io_enq_ready;
	wire _wrReq__deq_q_io_deq_valid;
	wire [9:0] _wrReq__deq_q_io_deq_bits_addr;
	wire _rdRespQueue__io_enq_ready;
	wire _rdRespQueue__io_deq_valid;
	wire [31:0] _rdRespQueue__io_deq_bits_data;
	wire [1:0] _rdRespQueue__io_deq_bits_resp;
	wire _rdReq__deq_q_io_enq_ready;
	wire _rdReq__deq_q_io_deq_valid;
	wire [9:0] _rdReq__deq_q_io_deq_bits_addr;
	wire _s_axil__sinkBuffer_1_io_enq_ready;
	wire _s_axil__sourceBuffer_2_io_deq_valid;
	wire [31:0] _s_axil__sourceBuffer_2_io_deq_bits_data;
	wire [3:0] _s_axil__sourceBuffer_2_io_deq_bits_strb;
	wire _s_axil__sourceBuffer_1_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_1_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_1_io_deq_bits_prot;
	wire _s_axil__sinkBuffer_io_enq_ready;
	wire _s_axil__sourceBuffer_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_io_deq_bits_prot;
	wire rdReq = _rdReq__deq_q_io_deq_valid & _rdRespQueue__io_enq_ready;
	wire wrReq = (_wrReq__deq_q_io_deq_valid & _wrReqData__deq_q_io_deq_valid) & _wrRespQueue__io_enq_ready;
	reg rSourceDeqOne;
	reg rSinkEnqOne;
	reg [31:0] rSinkDataVector_0;
	reg [31:0] rSinkDataVector_1;
	reg [31:0] rSinkDataVector_2;
	reg [31:0] rSinkDataVector_3;
	reg [31:0] rSinkDataVector_4;
	reg [31:0] rSinkDataVector_5;
	reg [31:0] rSinkDataVector_6;
	reg [31:0] rSinkDataVector_7;
	reg [31:0] rSinkDataVector_8;
	reg [31:0] rSinkDataVector_9;
	reg [31:0] rSinkDataVector_10;
	reg [31:0] rSinkDataVector_11;
	reg [31:0] rSinkDataVector_12;
	reg [31:0] rSinkDataVector_13;
	always @(posedge clock)
		if (reset) begin
			rSourceDeqOne <= 1'h0;
			rSinkEnqOne <= 1'h0;
			rSinkDataVector_0 <= 32'h00000000;
			rSinkDataVector_1 <= 32'h00000000;
			rSinkDataVector_2 <= 32'h00000000;
			rSinkDataVector_3 <= 32'h00000000;
			rSinkDataVector_4 <= 32'h00000000;
			rSinkDataVector_5 <= 32'h00000000;
			rSinkDataVector_6 <= 32'h00000000;
			rSinkDataVector_7 <= 32'h00000000;
			rSinkDataVector_8 <= 32'h00000000;
			rSinkDataVector_9 <= 32'h00000000;
			rSinkDataVector_10 <= 32'h00000000;
			rSinkDataVector_11 <= 32'h00000000;
			rSinkDataVector_12 <= 32'h00000000;
			rSinkDataVector_13 <= 32'h00000000;
		end
		else begin
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'h01))
				rSourceDeqOne <= (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[0] : rSourceDeqOne);
			else
				rSourceDeqOne <= ~(rSourceDeqOne & source_valid) & rSourceDeqOne;
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'h03))
				rSinkEnqOne <= (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[0] : rSinkEnqOne);
			else
				rSinkEnqOne <= ~(rSinkEnqOne & sink_ready) & rSinkEnqOne;
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc0))
				rSinkDataVector_0 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_0[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_0[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_0[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_0[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc1))
				rSinkDataVector_1 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_1[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_1[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_1[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_1[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc2))
				rSinkDataVector_2 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_2[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_2[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_2[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_2[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc3))
				rSinkDataVector_3 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_3[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_3[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_3[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_3[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc4))
				rSinkDataVector_4 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_4[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_4[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_4[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_4[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc5))
				rSinkDataVector_5 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_5[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_5[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_5[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_5[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc6))
				rSinkDataVector_6 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_6[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_6[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_6[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_6[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc7))
				rSinkDataVector_7 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_7[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_7[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_7[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_7[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc8))
				rSinkDataVector_8 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_8[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_8[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_8[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_8[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hc9))
				rSinkDataVector_9 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_9[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_9[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_9[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_9[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hca))
				rSinkDataVector_10 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_10[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_10[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_10[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_10[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hcb))
				rSinkDataVector_11 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_11[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_11[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_11[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_11[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hcc))
				rSinkDataVector_12 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_12[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_12[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_12[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_12[7:0])};
			if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'hcd))
				rSinkDataVector_13 <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSinkDataVector_13[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSinkDataVector_13[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSinkDataVector_13[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSinkDataVector_13[7:0])};
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:14];
	end
	Queue2_AddressChannel s_axil__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_ar_ready),
		.io_enq_valid(s_axil_ar_valid),
		.io_enq_bits_addr(s_axil_ar_bits_addr),
		.io_enq_bits_prot(s_axil_ar_bits_prot),
		.io_deq_ready(_rdReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot)
	);
	Queue2_ReadDataChannel_3 s_axil__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_enq_valid(_rdRespQueue__io_deq_valid),
		.io_enq_bits_data(_rdRespQueue__io_deq_bits_data),
		.io_enq_bits_resp(_rdRespQueue__io_deq_bits_resp),
		.io_deq_ready(s_axil_r_ready),
		.io_deq_valid(s_axil_r_valid),
		.io_deq_bits_data(s_axil_r_bits_data),
		.io_deq_bits_resp(s_axil_r_bits_resp)
	);
	Queue2_AddressChannel s_axil__sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_aw_ready),
		.io_enq_valid(s_axil_aw_valid),
		.io_enq_bits_addr(s_axil_aw_bits_addr),
		.io_enq_bits_prot(s_axil_aw_bits_prot),
		.io_deq_ready(_wrReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot)
	);
	Queue2_WriteDataChannel_1 s_axil__sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_w_ready),
		.io_enq_valid(s_axil_w_valid),
		.io_enq_bits_data(s_axil_w_bits_data),
		.io_enq_bits_strb(s_axil_w_bits_strb),
		.io_deq_ready(_wrReqData__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb)
	);
	Queue2_WriteResponseChannel s_axil__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_wrRespQueue__io_deq_valid),
		.io_enq_bits_resp(2'h0),
		.io_deq_ready(s_axil_b_ready),
		.io_deq_valid(s_axil_b_valid),
		.io_deq_bits_resp(s_axil_b_bits_resp)
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
		.io_enq_bits_data((_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hcd ? rSinkDataVector_13 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hcc ? rSinkDataVector_12 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hcb ? rSinkDataVector_11 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hca ? rSinkDataVector_10 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc9 ? rSinkDataVector_9 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc8 ? rSinkDataVector_8 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc7 ? rSinkDataVector_7 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc6 ? rSinkDataVector_6 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc5 ? rSinkDataVector_5 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc4 ? rSinkDataVector_4 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc3 ? rSinkDataVector_3 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc2 ? rSinkDataVector_2 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc1 ? rSinkDataVector_1 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'hc0 ? rSinkDataVector_0 : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h81 ? source_bits[63:32] : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h80 ? source_bits[31:0] : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h03 ? {31'h00000000, rSinkEnqOne} : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h02 ? {31'h00000000, sink_ready} : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h01 ? {31'h00000000, rSourceDeqOne} : (_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h00 ? {31'h00000000, source_valid} : 32'hffffffff))))))))))))))))))))),
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
	assign source_ready = rSourceDeqOne;
	assign sink_valid = rSinkEnqOne;
	assign sink_bits = {rSinkDataVector_13, rSinkDataVector_12, rSinkDataVector_11, rSinkDataVector_10, rSinkDataVector_9, rSinkDataVector_8, rSinkDataVector_7, rSinkDataVector_6, rSinkDataVector_5, rSinkDataVector_4, rSinkDataVector_3, rSinkDataVector_2, rSinkDataVector_1, rSinkDataVector_0};
endmodule
module AddressTransform (
	select,
	in,
	out
);
	input [2:0] select;
	input [33:0] in;
	output wire [33:0] out;
	wire [271:0] _GEN = {in, in, in[18:14], in[28:19], in[33:29], in[13:0], in[33], in[17:14], in[28:18], in[32:29], in[13:0], in[33:32], in[16:14], in[28:17], in[31:29], in[13:0], in[33:31], in[15:14], in[28:16], in[30:29], in[13:0], in[33:30], in[14], in[28:15], in[29], in[13:0], in};
	assign out = _GEN[select * 34+:34];
endmodule
module Stripe (
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
	S_AXI_0_ARREADY,
	S_AXI_0_ARVALID,
	S_AXI_0_ARADDR,
	S_AXI_0_ARLEN,
	S_AXI_0_ARSIZE,
	S_AXI_0_ARBURST,
	S_AXI_0_ARLOCK,
	S_AXI_0_ARCACHE,
	S_AXI_0_ARPROT,
	S_AXI_0_ARQOS,
	S_AXI_0_ARREGION,
	S_AXI_0_RREADY,
	S_AXI_0_RVALID,
	S_AXI_0_RDATA,
	S_AXI_0_RRESP,
	S_AXI_0_RLAST,
	S_AXI_0_AWREADY,
	S_AXI_0_AWVALID,
	S_AXI_0_AWADDR,
	S_AXI_0_AWLEN,
	S_AXI_0_AWSIZE,
	S_AXI_0_AWBURST,
	S_AXI_0_AWLOCK,
	S_AXI_0_AWCACHE,
	S_AXI_0_AWPROT,
	S_AXI_0_AWQOS,
	S_AXI_0_AWREGION,
	S_AXI_0_WREADY,
	S_AXI_0_WVALID,
	S_AXI_0_WDATA,
	S_AXI_0_WSTRB,
	S_AXI_0_WLAST,
	S_AXI_0_BREADY,
	S_AXI_0_BVALID,
	M_AXI_0_ARREADY,
	M_AXI_0_ARVALID,
	M_AXI_0_ARADDR,
	M_AXI_0_ARLEN,
	M_AXI_0_ARSIZE,
	M_AXI_0_ARBURST,
	M_AXI_0_ARLOCK,
	M_AXI_0_ARCACHE,
	M_AXI_0_ARPROT,
	M_AXI_0_ARQOS,
	M_AXI_0_ARREGION,
	M_AXI_0_RREADY,
	M_AXI_0_RVALID,
	M_AXI_0_RDATA,
	M_AXI_0_RRESP,
	M_AXI_0_RLAST,
	M_AXI_0_AWREADY,
	M_AXI_0_AWVALID,
	M_AXI_0_AWADDR,
	M_AXI_0_AWLEN,
	M_AXI_0_AWSIZE,
	M_AXI_0_AWBURST,
	M_AXI_0_AWLOCK,
	M_AXI_0_AWCACHE,
	M_AXI_0_AWPROT,
	M_AXI_0_AWQOS,
	M_AXI_0_AWREGION,
	M_AXI_0_WREADY,
	M_AXI_0_WVALID,
	M_AXI_0_WDATA,
	M_AXI_0_WSTRB,
	M_AXI_0_WLAST,
	M_AXI_0_BREADY,
	M_AXI_0_BVALID
);
	input clock;
	input reset;
	output wire S_AXI_CONTROL_ARREADY;
	input S_AXI_CONTROL_ARVALID;
	input [9:0] S_AXI_CONTROL_ARADDR;
	input [2:0] S_AXI_CONTROL_ARPROT;
	input S_AXI_CONTROL_RREADY;
	output wire S_AXI_CONTROL_RVALID;
	output wire [31:0] S_AXI_CONTROL_RDATA;
	output wire [1:0] S_AXI_CONTROL_RRESP;
	output wire S_AXI_CONTROL_AWREADY;
	input S_AXI_CONTROL_AWVALID;
	input [9:0] S_AXI_CONTROL_AWADDR;
	input [2:0] S_AXI_CONTROL_AWPROT;
	output wire S_AXI_CONTROL_WREADY;
	input S_AXI_CONTROL_WVALID;
	input [31:0] S_AXI_CONTROL_WDATA;
	input [3:0] S_AXI_CONTROL_WSTRB;
	input S_AXI_CONTROL_BREADY;
	output wire S_AXI_CONTROL_BVALID;
	output wire [1:0] S_AXI_CONTROL_BRESP;
	output wire S_AXI_0_ARREADY;
	input S_AXI_0_ARVALID;
	input [33:0] S_AXI_0_ARADDR;
	input [7:0] S_AXI_0_ARLEN;
	input [2:0] S_AXI_0_ARSIZE;
	input [1:0] S_AXI_0_ARBURST;
	input S_AXI_0_ARLOCK;
	input [3:0] S_AXI_0_ARCACHE;
	input [2:0] S_AXI_0_ARPROT;
	input [3:0] S_AXI_0_ARQOS;
	input [3:0] S_AXI_0_ARREGION;
	input S_AXI_0_RREADY;
	output wire S_AXI_0_RVALID;
	output wire [255:0] S_AXI_0_RDATA;
	output wire [1:0] S_AXI_0_RRESP;
	output wire S_AXI_0_RLAST;
	output wire S_AXI_0_AWREADY;
	input S_AXI_0_AWVALID;
	input [33:0] S_AXI_0_AWADDR;
	input [7:0] S_AXI_0_AWLEN;
	input [2:0] S_AXI_0_AWSIZE;
	input [1:0] S_AXI_0_AWBURST;
	input S_AXI_0_AWLOCK;
	input [3:0] S_AXI_0_AWCACHE;
	input [2:0] S_AXI_0_AWPROT;
	input [3:0] S_AXI_0_AWQOS;
	input [3:0] S_AXI_0_AWREGION;
	output wire S_AXI_0_WREADY;
	input S_AXI_0_WVALID;
	input [255:0] S_AXI_0_WDATA;
	input [31:0] S_AXI_0_WSTRB;
	input S_AXI_0_WLAST;
	input S_AXI_0_BREADY;
	output wire S_AXI_0_BVALID;
	input M_AXI_0_ARREADY;
	output wire M_AXI_0_ARVALID;
	output wire [33:0] M_AXI_0_ARADDR;
	output wire [7:0] M_AXI_0_ARLEN;
	output wire [2:0] M_AXI_0_ARSIZE;
	output wire [1:0] M_AXI_0_ARBURST;
	output wire M_AXI_0_ARLOCK;
	output wire [3:0] M_AXI_0_ARCACHE;
	output wire [2:0] M_AXI_0_ARPROT;
	output wire [3:0] M_AXI_0_ARQOS;
	output wire [3:0] M_AXI_0_ARREGION;
	output wire M_AXI_0_RREADY;
	input M_AXI_0_RVALID;
	input [255:0] M_AXI_0_RDATA;
	input [1:0] M_AXI_0_RRESP;
	input M_AXI_0_RLAST;
	input M_AXI_0_AWREADY;
	output wire M_AXI_0_AWVALID;
	output wire [33:0] M_AXI_0_AWADDR;
	output wire [7:0] M_AXI_0_AWLEN;
	output wire [2:0] M_AXI_0_AWSIZE;
	output wire [1:0] M_AXI_0_AWBURST;
	output wire M_AXI_0_AWLOCK;
	output wire [3:0] M_AXI_0_AWCACHE;
	output wire [2:0] M_AXI_0_AWPROT;
	output wire [3:0] M_AXI_0_AWQOS;
	output wire [3:0] M_AXI_0_AWREGION;
	input M_AXI_0_WREADY;
	output wire M_AXI_0_WVALID;
	output wire [255:0] M_AXI_0_WDATA;
	output wire [31:0] M_AXI_0_WSTRB;
	output wire M_AXI_0_WLAST;
	output wire M_AXI_0_BREADY;
	input M_AXI_0_BVALID;
	wire _wrRespQueue__io_enq_ready;
	wire _wrRespQueue__io_deq_valid;
	wire _wrReqData__deq_q_io_enq_ready;
	wire _wrReqData__deq_q_io_deq_valid;
	wire [31:0] _wrReqData__deq_q_io_deq_bits_data;
	wire [3:0] _wrReqData__deq_q_io_deq_bits_strb;
	wire _wrReq__deq_q_io_enq_ready;
	wire _wrReq__deq_q_io_deq_valid;
	wire [9:0] _wrReq__deq_q_io_deq_bits_addr;
	wire _rdRespQueue__io_enq_ready;
	wire _rdRespQueue__io_deq_valid;
	wire [31:0] _rdRespQueue__io_deq_bits_data;
	wire [1:0] _rdRespQueue__io_deq_bits_resp;
	wire _rdReq__deq_q_io_enq_ready;
	wire _rdReq__deq_q_io_deq_valid;
	wire [9:0] _rdReq__deq_q_io_deq_bits_addr;
	wire _s_axil__sinkBuffer_1_io_enq_ready;
	wire _s_axil__sourceBuffer_2_io_deq_valid;
	wire [31:0] _s_axil__sourceBuffer_2_io_deq_bits_data;
	wire [3:0] _s_axil__sourceBuffer_2_io_deq_bits_strb;
	wire _s_axil__sourceBuffer_1_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_1_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_1_io_deq_bits_prot;
	wire _s_axil__sinkBuffer_io_enq_ready;
	wire _s_axil__sourceBuffer_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_io_deq_bits_prot;
	reg [31:0] rSelect;
	wire rdReq = _rdReq__deq_q_io_deq_valid & _rdRespQueue__io_enq_ready;
	wire wrReq = (_wrReq__deq_q_io_deq_valid & _wrReqData__deq_q_io_deq_valid) & _wrRespQueue__io_enq_ready;
	always @(posedge clock)
		if (reset)
			rSelect <= 32'h00000000;
		else if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'h00))
			rSelect <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSelect[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSelect[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSelect[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSelect[7:0])};
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_AddressChannel s_axil__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_ARREADY),
		.io_enq_valid(S_AXI_CONTROL_ARVALID),
		.io_enq_bits_addr(S_AXI_CONTROL_ARADDR),
		.io_enq_bits_prot(S_AXI_CONTROL_ARPROT),
		.io_deq_ready(_rdReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot)
	);
	Queue2_ReadDataChannel_3 s_axil__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_enq_valid(_rdRespQueue__io_deq_valid),
		.io_enq_bits_data(_rdRespQueue__io_deq_bits_data),
		.io_enq_bits_resp(_rdRespQueue__io_deq_bits_resp),
		.io_deq_ready(S_AXI_CONTROL_RREADY),
		.io_deq_valid(S_AXI_CONTROL_RVALID),
		.io_deq_bits_data(S_AXI_CONTROL_RDATA),
		.io_deq_bits_resp(S_AXI_CONTROL_RRESP)
	);
	Queue2_AddressChannel s_axil__sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_AWREADY),
		.io_enq_valid(S_AXI_CONTROL_AWVALID),
		.io_enq_bits_addr(S_AXI_CONTROL_AWADDR),
		.io_enq_bits_prot(S_AXI_CONTROL_AWPROT),
		.io_deq_ready(_wrReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot)
	);
	Queue2_WriteDataChannel_1 s_axil__sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_WREADY),
		.io_enq_valid(S_AXI_CONTROL_WVALID),
		.io_enq_bits_data(S_AXI_CONTROL_WDATA),
		.io_enq_bits_strb(S_AXI_CONTROL_WSTRB),
		.io_deq_ready(_wrReqData__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb)
	);
	Queue2_WriteResponseChannel s_axil__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_wrRespQueue__io_deq_valid),
		.io_enq_bits_resp(2'h0),
		.io_deq_ready(S_AXI_CONTROL_BREADY),
		.io_deq_valid(S_AXI_CONTROL_BVALID),
		.io_deq_bits_resp(S_AXI_CONTROL_BRESP)
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
		.io_enq_bits_data((_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h00 ? rSelect : 32'hffffffff)),
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
	AddressTransform addressTransform(
		.select(rSelect[2:0]),
		.in(S_AXI_0_ARADDR),
		.out(M_AXI_0_ARADDR)
	);
	AddressTransform addressTransform_1(
		.select(rSelect[2:0]),
		.in(S_AXI_0_AWADDR),
		.out(M_AXI_0_AWADDR)
	);
	assign S_AXI_0_ARREADY = M_AXI_0_ARREADY;
	assign S_AXI_0_RVALID = M_AXI_0_RVALID;
	assign S_AXI_0_RDATA = M_AXI_0_RDATA;
	assign S_AXI_0_RRESP = M_AXI_0_RRESP;
	assign S_AXI_0_RLAST = M_AXI_0_RLAST;
	assign S_AXI_0_AWREADY = M_AXI_0_AWREADY;
	assign S_AXI_0_WREADY = M_AXI_0_WREADY;
	assign S_AXI_0_BVALID = M_AXI_0_BVALID;
	assign M_AXI_0_ARVALID = S_AXI_0_ARVALID;
	assign M_AXI_0_ARLEN = S_AXI_0_ARLEN;
	assign M_AXI_0_ARSIZE = S_AXI_0_ARSIZE;
	assign M_AXI_0_ARBURST = S_AXI_0_ARBURST;
	assign M_AXI_0_ARLOCK = S_AXI_0_ARLOCK;
	assign M_AXI_0_ARCACHE = S_AXI_0_ARCACHE;
	assign M_AXI_0_ARPROT = S_AXI_0_ARPROT;
	assign M_AXI_0_ARQOS = S_AXI_0_ARQOS;
	assign M_AXI_0_ARREGION = S_AXI_0_ARREGION;
	assign M_AXI_0_RREADY = S_AXI_0_RREADY;
	assign M_AXI_0_AWVALID = S_AXI_0_AWVALID;
	assign M_AXI_0_AWLEN = S_AXI_0_AWLEN;
	assign M_AXI_0_AWSIZE = S_AXI_0_AWSIZE;
	assign M_AXI_0_AWBURST = S_AXI_0_AWBURST;
	assign M_AXI_0_AWLOCK = S_AXI_0_AWLOCK;
	assign M_AXI_0_AWCACHE = S_AXI_0_AWCACHE;
	assign M_AXI_0_AWPROT = S_AXI_0_AWPROT;
	assign M_AXI_0_AWQOS = S_AXI_0_AWQOS;
	assign M_AXI_0_AWREGION = S_AXI_0_AWREGION;
	assign M_AXI_0_WVALID = S_AXI_0_WVALID;
	assign M_AXI_0_WDATA = S_AXI_0_WDATA;
	assign M_AXI_0_WSTRB = S_AXI_0_WSTRB;
	assign M_AXI_0_WLAST = S_AXI_0_WLAST;
	assign M_AXI_0_BREADY = S_AXI_0_BREADY;
endmodule
module Stripe_1 (
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
	S_AXI_0_ARREADY,
	S_AXI_0_ARVALID,
	S_AXI_0_ARID,
	S_AXI_0_ARADDR,
	S_AXI_0_ARLEN,
	S_AXI_0_ARSIZE,
	S_AXI_0_ARBURST,
	S_AXI_0_RREADY,
	S_AXI_0_RVALID,
	S_AXI_0_RID,
	S_AXI_0_RDATA,
	S_AXI_0_RRESP,
	S_AXI_0_RLAST,
	S_AXI_0_AWREADY,
	S_AXI_0_AWVALID,
	S_AXI_0_AWID,
	S_AXI_0_AWADDR,
	S_AXI_0_AWLEN,
	S_AXI_0_AWSIZE,
	S_AXI_0_AWBURST,
	S_AXI_0_WREADY,
	S_AXI_0_WVALID,
	S_AXI_0_WDATA,
	S_AXI_0_WSTRB,
	S_AXI_0_WLAST,
	S_AXI_0_BREADY,
	S_AXI_0_BVALID,
	S_AXI_0_BID,
	S_AXI_0_BRESP,
	M_AXI_0_ARREADY,
	M_AXI_0_ARVALID,
	M_AXI_0_ARID,
	M_AXI_0_ARADDR,
	M_AXI_0_ARLEN,
	M_AXI_0_ARSIZE,
	M_AXI_0_ARBURST,
	M_AXI_0_RREADY,
	M_AXI_0_RVALID,
	M_AXI_0_RID,
	M_AXI_0_RDATA,
	M_AXI_0_RRESP,
	M_AXI_0_RLAST,
	M_AXI_0_AWREADY,
	M_AXI_0_AWVALID,
	M_AXI_0_AWID,
	M_AXI_0_AWADDR,
	M_AXI_0_AWLEN,
	M_AXI_0_AWSIZE,
	M_AXI_0_AWBURST,
	M_AXI_0_WREADY,
	M_AXI_0_WVALID,
	M_AXI_0_WDATA,
	M_AXI_0_WSTRB,
	M_AXI_0_WLAST,
	M_AXI_0_BREADY,
	M_AXI_0_BVALID,
	M_AXI_0_BID,
	M_AXI_0_BRESP
);
	input clock;
	input reset;
	output wire S_AXI_CONTROL_ARREADY;
	input S_AXI_CONTROL_ARVALID;
	input [9:0] S_AXI_CONTROL_ARADDR;
	input [2:0] S_AXI_CONTROL_ARPROT;
	input S_AXI_CONTROL_RREADY;
	output wire S_AXI_CONTROL_RVALID;
	output wire [31:0] S_AXI_CONTROL_RDATA;
	output wire [1:0] S_AXI_CONTROL_RRESP;
	output wire S_AXI_CONTROL_AWREADY;
	input S_AXI_CONTROL_AWVALID;
	input [9:0] S_AXI_CONTROL_AWADDR;
	input [2:0] S_AXI_CONTROL_AWPROT;
	output wire S_AXI_CONTROL_WREADY;
	input S_AXI_CONTROL_WVALID;
	input [31:0] S_AXI_CONTROL_WDATA;
	input [3:0] S_AXI_CONTROL_WSTRB;
	input S_AXI_CONTROL_BREADY;
	output wire S_AXI_CONTROL_BVALID;
	output wire [1:0] S_AXI_CONTROL_BRESP;
	output wire S_AXI_0_ARREADY;
	input S_AXI_0_ARVALID;
	input [1:0] S_AXI_0_ARID;
	input [33:0] S_AXI_0_ARADDR;
	input [3:0] S_AXI_0_ARLEN;
	input [2:0] S_AXI_0_ARSIZE;
	input [1:0] S_AXI_0_ARBURST;
	input S_AXI_0_RREADY;
	output wire S_AXI_0_RVALID;
	output wire [1:0] S_AXI_0_RID;
	output wire [255:0] S_AXI_0_RDATA;
	output wire [1:0] S_AXI_0_RRESP;
	output wire S_AXI_0_RLAST;
	output wire S_AXI_0_AWREADY;
	input S_AXI_0_AWVALID;
	input [1:0] S_AXI_0_AWID;
	input [33:0] S_AXI_0_AWADDR;
	input [3:0] S_AXI_0_AWLEN;
	input [2:0] S_AXI_0_AWSIZE;
	input [1:0] S_AXI_0_AWBURST;
	output wire S_AXI_0_WREADY;
	input S_AXI_0_WVALID;
	input [255:0] S_AXI_0_WDATA;
	input [31:0] S_AXI_0_WSTRB;
	input S_AXI_0_WLAST;
	input S_AXI_0_BREADY;
	output wire S_AXI_0_BVALID;
	output wire [1:0] S_AXI_0_BID;
	output wire [1:0] S_AXI_0_BRESP;
	input M_AXI_0_ARREADY;
	output wire M_AXI_0_ARVALID;
	output wire [1:0] M_AXI_0_ARID;
	output wire [33:0] M_AXI_0_ARADDR;
	output wire [3:0] M_AXI_0_ARLEN;
	output wire [2:0] M_AXI_0_ARSIZE;
	output wire [1:0] M_AXI_0_ARBURST;
	output wire M_AXI_0_RREADY;
	input M_AXI_0_RVALID;
	input [1:0] M_AXI_0_RID;
	input [255:0] M_AXI_0_RDATA;
	input [1:0] M_AXI_0_RRESP;
	input M_AXI_0_RLAST;
	input M_AXI_0_AWREADY;
	output wire M_AXI_0_AWVALID;
	output wire [1:0] M_AXI_0_AWID;
	output wire [33:0] M_AXI_0_AWADDR;
	output wire [3:0] M_AXI_0_AWLEN;
	output wire [2:0] M_AXI_0_AWSIZE;
	output wire [1:0] M_AXI_0_AWBURST;
	input M_AXI_0_WREADY;
	output wire M_AXI_0_WVALID;
	output wire [255:0] M_AXI_0_WDATA;
	output wire [31:0] M_AXI_0_WSTRB;
	output wire M_AXI_0_WLAST;
	output wire M_AXI_0_BREADY;
	input M_AXI_0_BVALID;
	input [1:0] M_AXI_0_BID;
	input [1:0] M_AXI_0_BRESP;
	wire _wrRespQueue__io_enq_ready;
	wire _wrRespQueue__io_deq_valid;
	wire _wrReqData__deq_q_io_enq_ready;
	wire _wrReqData__deq_q_io_deq_valid;
	wire [31:0] _wrReqData__deq_q_io_deq_bits_data;
	wire [3:0] _wrReqData__deq_q_io_deq_bits_strb;
	wire _wrReq__deq_q_io_enq_ready;
	wire _wrReq__deq_q_io_deq_valid;
	wire [9:0] _wrReq__deq_q_io_deq_bits_addr;
	wire _rdRespQueue__io_enq_ready;
	wire _rdRespQueue__io_deq_valid;
	wire [31:0] _rdRespQueue__io_deq_bits_data;
	wire [1:0] _rdRespQueue__io_deq_bits_resp;
	wire _rdReq__deq_q_io_enq_ready;
	wire _rdReq__deq_q_io_deq_valid;
	wire [9:0] _rdReq__deq_q_io_deq_bits_addr;
	wire _s_axil__sinkBuffer_1_io_enq_ready;
	wire _s_axil__sourceBuffer_2_io_deq_valid;
	wire [31:0] _s_axil__sourceBuffer_2_io_deq_bits_data;
	wire [3:0] _s_axil__sourceBuffer_2_io_deq_bits_strb;
	wire _s_axil__sourceBuffer_1_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_1_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_1_io_deq_bits_prot;
	wire _s_axil__sinkBuffer_io_enq_ready;
	wire _s_axil__sourceBuffer_io_deq_valid;
	wire [9:0] _s_axil__sourceBuffer_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_io_deq_bits_prot;
	reg [31:0] rSelect;
	wire rdReq = _rdReq__deq_q_io_deq_valid & _rdRespQueue__io_enq_ready;
	wire wrReq = (_wrReq__deq_q_io_deq_valid & _wrReqData__deq_q_io_deq_valid) & _wrRespQueue__io_enq_ready;
	always @(posedge clock)
		if (reset)
			rSelect <= 32'h00000000;
		else if (wrReq & (_wrReq__deq_q_io_deq_bits_addr[9:2] == 8'h00))
			rSelect <= {(_wrReqData__deq_q_io_deq_bits_strb[3] ? _wrReqData__deq_q_io_deq_bits_data[31:24] : rSelect[31:24]), (_wrReqData__deq_q_io_deq_bits_strb[2] ? _wrReqData__deq_q_io_deq_bits_data[23:16] : rSelect[23:16]), (_wrReqData__deq_q_io_deq_bits_strb[1] ? _wrReqData__deq_q_io_deq_bits_data[15:8] : rSelect[15:8]), (_wrReqData__deq_q_io_deq_bits_strb[0] ? _wrReqData__deq_q_io_deq_bits_data[7:0] : rSelect[7:0])};
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_AddressChannel s_axil__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_ARREADY),
		.io_enq_valid(S_AXI_CONTROL_ARVALID),
		.io_enq_bits_addr(S_AXI_CONTROL_ARADDR),
		.io_enq_bits_prot(S_AXI_CONTROL_ARPROT),
		.io_deq_ready(_rdReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot)
	);
	Queue2_ReadDataChannel_3 s_axil__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_enq_valid(_rdRespQueue__io_deq_valid),
		.io_enq_bits_data(_rdRespQueue__io_deq_bits_data),
		.io_enq_bits_resp(_rdRespQueue__io_deq_bits_resp),
		.io_deq_ready(S_AXI_CONTROL_RREADY),
		.io_deq_valid(S_AXI_CONTROL_RVALID),
		.io_deq_bits_data(S_AXI_CONTROL_RDATA),
		.io_deq_bits_resp(S_AXI_CONTROL_RRESP)
	);
	Queue2_AddressChannel s_axil__sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_AWREADY),
		.io_enq_valid(S_AXI_CONTROL_AWVALID),
		.io_enq_bits_addr(S_AXI_CONTROL_AWADDR),
		.io_enq_bits_prot(S_AXI_CONTROL_AWPROT),
		.io_deq_ready(_wrReq__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot)
	);
	Queue2_WriteDataChannel_1 s_axil__sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(S_AXI_CONTROL_WREADY),
		.io_enq_valid(S_AXI_CONTROL_WVALID),
		.io_enq_bits_data(S_AXI_CONTROL_WDATA),
		.io_enq_bits_strb(S_AXI_CONTROL_WSTRB),
		.io_deq_ready(_wrReqData__deq_q_io_enq_ready),
		.io_deq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb)
	);
	Queue2_WriteResponseChannel s_axil__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_wrRespQueue__io_deq_valid),
		.io_enq_bits_resp(2'h0),
		.io_deq_ready(S_AXI_CONTROL_BREADY),
		.io_deq_valid(S_AXI_CONTROL_BVALID),
		.io_deq_bits_resp(S_AXI_CONTROL_BRESP)
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
		.io_enq_bits_data((_rdReq__deq_q_io_deq_bits_addr[9:2] == 8'h00 ? rSelect : 32'hffffffff)),
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
	AddressTransform addressTransform(
		.select(rSelect[2:0]),
		.in(S_AXI_0_ARADDR),
		.out(M_AXI_0_ARADDR)
	);
	AddressTransform addressTransform_1(
		.select(rSelect[2:0]),
		.in(S_AXI_0_AWADDR),
		.out(M_AXI_0_AWADDR)
	);
	assign S_AXI_0_ARREADY = M_AXI_0_ARREADY;
	assign S_AXI_0_RVALID = M_AXI_0_RVALID;
	assign S_AXI_0_RID = M_AXI_0_RID;
	assign S_AXI_0_RDATA = M_AXI_0_RDATA;
	assign S_AXI_0_RRESP = M_AXI_0_RRESP;
	assign S_AXI_0_RLAST = M_AXI_0_RLAST;
	assign S_AXI_0_AWREADY = M_AXI_0_AWREADY;
	assign S_AXI_0_WREADY = M_AXI_0_WREADY;
	assign S_AXI_0_BVALID = M_AXI_0_BVALID;
	assign S_AXI_0_BID = M_AXI_0_BID;
	assign S_AXI_0_BRESP = M_AXI_0_BRESP;
	assign M_AXI_0_ARVALID = S_AXI_0_ARVALID;
	assign M_AXI_0_ARID = S_AXI_0_ARID;
	assign M_AXI_0_ARLEN = S_AXI_0_ARLEN;
	assign M_AXI_0_ARSIZE = S_AXI_0_ARSIZE;
	assign M_AXI_0_ARBURST = S_AXI_0_ARBURST;
	assign M_AXI_0_RREADY = S_AXI_0_RREADY;
	assign M_AXI_0_AWVALID = S_AXI_0_AWVALID;
	assign M_AXI_0_AWID = S_AXI_0_AWID;
	assign M_AXI_0_AWLEN = S_AXI_0_AWLEN;
	assign M_AXI_0_AWSIZE = S_AXI_0_AWSIZE;
	assign M_AXI_0_AWBURST = S_AXI_0_AWBURST;
	assign M_AXI_0_WVALID = S_AXI_0_WVALID;
	assign M_AXI_0_WDATA = S_AXI_0_WDATA;
	assign M_AXI_0_WSTRB = S_AXI_0_WSTRB;
	assign M_AXI_0_WLAST = S_AXI_0_WLAST;
	assign M_AXI_0_BREADY = S_AXI_0_BREADY;
endmodule
module ram_2x15 (
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
	output wire [14:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [14:0] W0_data;
	reg [14:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 15'bxxxxxxxxxxxxxxx);
endmodule
module Queue2_AddressChannel_6 (
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
	input [11:0] io_enq_bits_addr;
	input [2:0] io_enq_bits_prot;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [11:0] io_deq_bits_addr;
	output wire [2:0] io_deq_bits_prot;
	wire [14:0] _ram_ext_R0_data;
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
	ram_2x15 ram_ext(
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
	assign io_deq_bits_addr = _ram_ext_R0_data[11:0];
	assign io_deq_bits_prot = _ram_ext_R0_data[14:12];
endmodule
module ram_8x2 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [2:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [1:0] R0_data;
	input [2:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [1:0] W0_data;
	reg [1:0] Memory [0:7];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 2'bxx);
endmodule
module Queue8_UInt2 (
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
	input [1:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits;
	wire io_enq_ready_0;
	wire [1:0] _ram_ext_R0_data;
	reg [2:0] enq_ptr_value;
	reg [2:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire io_deq_valid_0 = io_enq_valid | ~empty;
	wire do_deq = (~empty & io_deq_ready) & io_deq_valid_0;
	wire do_enq = (~(empty & io_deq_ready) & io_enq_ready_0) & io_enq_valid;
	assign io_enq_ready_0 = io_deq_ready | ~(ptr_match & maybe_full);
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 3'h0;
			deq_ptr_value <= 3'h0;
			maybe_full <= 1'h0;
		end
		else begin
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 3'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 3'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	ram_8x2 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = io_enq_ready_0;
	assign io_deq_valid = io_deq_valid_0;
	assign io_deq_bits = (empty ? io_enq_bits : _ram_ext_R0_data);
endmodule
module elasticDemux_39 (
	io_source_ready,
	io_source_valid,
	io_source_bits_addr,
	io_source_bits_prot,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits_addr,
	io_sinks_0_bits_prot,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits_addr,
	io_sinks_1_bits_prot,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits_addr,
	io_sinks_2_bits_prot,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [11:0] io_source_bits_addr;
	input [2:0] io_source_bits_prot;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [11:0] io_sinks_0_bits_addr;
	output wire [2:0] io_sinks_0_bits_prot;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [11:0] io_sinks_1_bits_addr;
	output wire [2:0] io_sinks_1_bits_prot;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [11:0] io_sinks_2_bits_addr;
	output wire [2:0] io_sinks_2_bits_prot;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire [3:0] _GEN = {io_sinks_0_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & (io_select_bits == 2'h0);
	assign io_sinks_0_bits_addr = io_source_bits_addr;
	assign io_sinks_0_bits_prot = io_source_bits_prot;
	assign io_sinks_1_valid = valid & (io_select_bits == 2'h1);
	assign io_sinks_1_bits_addr = io_source_bits_addr;
	assign io_sinks_1_bits_prot = io_source_bits_prot;
	assign io_sinks_2_valid = valid & (io_select_bits == 2'h2);
	assign io_sinks_2_bits_addr = io_source_bits_addr;
	assign io_sinks_2_bits_prot = io_source_bits_prot;
	assign io_select_ready = fire;
endmodule
module elasticMux_34 (
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits_data,
	io_sources_0_bits_resp,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits_data,
	io_sources_1_bits_resp,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits_data,
	io_sources_2_bits_resp,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits_data,
	io_sink_bits_resp,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [31:0] io_sources_0_bits_data;
	input [1:0] io_sources_0_bits_resp;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [31:0] io_sources_1_bits_data;
	input [1:0] io_sources_1_bits_resp;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [31:0] io_sources_2_bits_data;
	input [1:0] io_sources_2_bits_resp;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [31:0] io_sink_bits_data;
	output wire [1:0] io_sink_bits_resp;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire [3:0] _GEN = {io_sources_0_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [127:0] _GEN_0 = {io_sources_0_bits_data, io_sources_2_bits_data, io_sources_1_bits_data, io_sources_0_bits_data};
	wire [7:0] _GEN_1 = {io_sources_0_bits_resp, io_sources_2_bits_resp, io_sources_1_bits_resp, io_sources_0_bits_resp};
	wire valid = io_select_valid & _GEN[io_select_bits];
	wire fire = valid & io_sink_ready;
	assign io_sources_0_ready = fire & (io_select_bits == 2'h0);
	assign io_sources_1_ready = fire & (io_select_bits == 2'h1);
	assign io_sources_2_ready = fire & (io_select_bits == 2'h2);
	assign io_sink_valid = valid;
	assign io_sink_bits_data = _GEN_0[io_select_bits * 32+:32];
	assign io_sink_bits_resp = _GEN_1[io_select_bits * 2+:2];
	assign io_select_ready = fire;
endmodule
module elasticDemux_41 (
	io_source_ready,
	io_source_valid,
	io_source_bits_data,
	io_source_bits_strb,
	io_sinks_0_ready,
	io_sinks_0_valid,
	io_sinks_0_bits_data,
	io_sinks_0_bits_strb,
	io_sinks_1_ready,
	io_sinks_1_valid,
	io_sinks_1_bits_data,
	io_sinks_1_bits_strb,
	io_sinks_2_ready,
	io_sinks_2_valid,
	io_sinks_2_bits_data,
	io_sinks_2_bits_strb,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_source_ready;
	input io_source_valid;
	input [31:0] io_source_bits_data;
	input [3:0] io_source_bits_strb;
	input io_sinks_0_ready;
	output wire io_sinks_0_valid;
	output wire [31:0] io_sinks_0_bits_data;
	output wire [3:0] io_sinks_0_bits_strb;
	input io_sinks_1_ready;
	output wire io_sinks_1_valid;
	output wire [31:0] io_sinks_1_bits_data;
	output wire [3:0] io_sinks_1_bits_strb;
	input io_sinks_2_ready;
	output wire io_sinks_2_valid;
	output wire [31:0] io_sinks_2_bits_data;
	output wire [3:0] io_sinks_2_bits_strb;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire valid = io_select_valid & io_source_valid;
	wire [3:0] _GEN = {io_sinks_0_ready, io_sinks_2_ready, io_sinks_1_ready, io_sinks_0_ready};
	wire fire = valid & _GEN[io_select_bits];
	assign io_source_ready = fire;
	assign io_sinks_0_valid = valid & (io_select_bits == 2'h0);
	assign io_sinks_0_bits_data = io_source_bits_data;
	assign io_sinks_0_bits_strb = io_source_bits_strb;
	assign io_sinks_1_valid = valid & (io_select_bits == 2'h1);
	assign io_sinks_1_bits_data = io_source_bits_data;
	assign io_sinks_1_bits_strb = io_source_bits_strb;
	assign io_sinks_2_valid = valid & (io_select_bits == 2'h2);
	assign io_sinks_2_bits_data = io_source_bits_data;
	assign io_sinks_2_bits_strb = io_source_bits_strb;
	assign io_select_ready = fire;
endmodule
module elasticMux_35 (
	io_sources_0_ready,
	io_sources_0_valid,
	io_sources_0_bits_resp,
	io_sources_1_ready,
	io_sources_1_valid,
	io_sources_1_bits_resp,
	io_sources_2_ready,
	io_sources_2_valid,
	io_sources_2_bits_resp,
	io_sink_ready,
	io_sink_valid,
	io_sink_bits_resp,
	io_select_ready,
	io_select_valid,
	io_select_bits
);
	output wire io_sources_0_ready;
	input io_sources_0_valid;
	input [1:0] io_sources_0_bits_resp;
	output wire io_sources_1_ready;
	input io_sources_1_valid;
	input [1:0] io_sources_1_bits_resp;
	output wire io_sources_2_ready;
	input io_sources_2_valid;
	input [1:0] io_sources_2_bits_resp;
	input io_sink_ready;
	output wire io_sink_valid;
	output wire [1:0] io_sink_bits_resp;
	output wire io_select_ready;
	input io_select_valid;
	input [1:0] io_select_bits;
	wire [3:0] _GEN = {io_sources_0_valid, io_sources_2_valid, io_sources_1_valid, io_sources_0_valid};
	wire [7:0] _GEN_0 = {io_sources_0_bits_resp, io_sources_2_bits_resp, io_sources_1_bits_resp, io_sources_0_bits_resp};
	wire valid = io_select_valid & _GEN[io_select_bits];
	wire fire = valid & io_sink_ready;
	assign io_sources_0_ready = fire & (io_select_bits == 2'h0);
	assign io_sources_1_ready = fire & (io_select_bits == 2'h1);
	assign io_sources_2_ready = fire & (io_select_bits == 2'h2);
	assign io_sink_valid = valid;
	assign io_sink_bits_resp = _GEN_0[io_select_bits * 2+:2];
	assign io_select_ready = fire;
endmodule
module axi4LiteDemux (
	clock,
	reset,
	s_axil_ar_ready,
	s_axil_ar_valid,
	s_axil_ar_bits_addr,
	s_axil_ar_bits_prot,
	s_axil_r_ready,
	s_axil_r_valid,
	s_axil_r_bits_data,
	s_axil_r_bits_resp,
	s_axil_aw_ready,
	s_axil_aw_valid,
	s_axil_aw_bits_addr,
	s_axil_aw_bits_prot,
	s_axil_w_ready,
	s_axil_w_valid,
	s_axil_w_bits_data,
	s_axil_w_bits_strb,
	s_axil_b_ready,
	s_axil_b_valid,
	s_axil_b_bits_resp,
	m_axil_0_ar_ready,
	m_axil_0_ar_valid,
	m_axil_0_ar_bits_addr,
	m_axil_0_ar_bits_prot,
	m_axil_0_r_ready,
	m_axil_0_r_valid,
	m_axil_0_r_bits_data,
	m_axil_0_r_bits_resp,
	m_axil_0_aw_ready,
	m_axil_0_aw_valid,
	m_axil_0_aw_bits_addr,
	m_axil_0_aw_bits_prot,
	m_axil_0_w_ready,
	m_axil_0_w_valid,
	m_axil_0_w_bits_data,
	m_axil_0_w_bits_strb,
	m_axil_0_b_ready,
	m_axil_0_b_valid,
	m_axil_0_b_bits_resp,
	m_axil_1_ar_ready,
	m_axil_1_ar_valid,
	m_axil_1_ar_bits_addr,
	m_axil_1_ar_bits_prot,
	m_axil_1_r_ready,
	m_axil_1_r_valid,
	m_axil_1_r_bits_data,
	m_axil_1_r_bits_resp,
	m_axil_1_aw_ready,
	m_axil_1_aw_valid,
	m_axil_1_aw_bits_addr,
	m_axil_1_aw_bits_prot,
	m_axil_1_w_ready,
	m_axil_1_w_valid,
	m_axil_1_w_bits_data,
	m_axil_1_w_bits_strb,
	m_axil_1_b_ready,
	m_axil_1_b_valid,
	m_axil_1_b_bits_resp,
	m_axil_2_ar_ready,
	m_axil_2_ar_valid,
	m_axil_2_ar_bits_addr,
	m_axil_2_ar_bits_prot,
	m_axil_2_r_ready,
	m_axil_2_r_valid,
	m_axil_2_r_bits_data,
	m_axil_2_r_bits_resp,
	m_axil_2_aw_ready,
	m_axil_2_aw_valid,
	m_axil_2_aw_bits_addr,
	m_axil_2_aw_bits_prot,
	m_axil_2_w_ready,
	m_axil_2_w_valid,
	m_axil_2_w_bits_data,
	m_axil_2_w_bits_strb,
	m_axil_2_b_ready,
	m_axil_2_b_valid,
	m_axil_2_b_bits_resp
);
	input clock;
	input reset;
	output wire s_axil_ar_ready;
	input s_axil_ar_valid;
	input [11:0] s_axil_ar_bits_addr;
	input [2:0] s_axil_ar_bits_prot;
	input s_axil_r_ready;
	output wire s_axil_r_valid;
	output wire [31:0] s_axil_r_bits_data;
	output wire [1:0] s_axil_r_bits_resp;
	output wire s_axil_aw_ready;
	input s_axil_aw_valid;
	input [11:0] s_axil_aw_bits_addr;
	input [2:0] s_axil_aw_bits_prot;
	output wire s_axil_w_ready;
	input s_axil_w_valid;
	input [31:0] s_axil_w_bits_data;
	input [3:0] s_axil_w_bits_strb;
	input s_axil_b_ready;
	output wire s_axil_b_valid;
	output wire [1:0] s_axil_b_bits_resp;
	input m_axil_0_ar_ready;
	output wire m_axil_0_ar_valid;
	output wire [11:0] m_axil_0_ar_bits_addr;
	output wire [2:0] m_axil_0_ar_bits_prot;
	output wire m_axil_0_r_ready;
	input m_axil_0_r_valid;
	input [31:0] m_axil_0_r_bits_data;
	input [1:0] m_axil_0_r_bits_resp;
	input m_axil_0_aw_ready;
	output wire m_axil_0_aw_valid;
	output wire [11:0] m_axil_0_aw_bits_addr;
	output wire [2:0] m_axil_0_aw_bits_prot;
	input m_axil_0_w_ready;
	output wire m_axil_0_w_valid;
	output wire [31:0] m_axil_0_w_bits_data;
	output wire [3:0] m_axil_0_w_bits_strb;
	output wire m_axil_0_b_ready;
	input m_axil_0_b_valid;
	input [1:0] m_axil_0_b_bits_resp;
	input m_axil_1_ar_ready;
	output wire m_axil_1_ar_valid;
	output wire [11:0] m_axil_1_ar_bits_addr;
	output wire [2:0] m_axil_1_ar_bits_prot;
	output wire m_axil_1_r_ready;
	input m_axil_1_r_valid;
	input [31:0] m_axil_1_r_bits_data;
	input [1:0] m_axil_1_r_bits_resp;
	input m_axil_1_aw_ready;
	output wire m_axil_1_aw_valid;
	output wire [11:0] m_axil_1_aw_bits_addr;
	output wire [2:0] m_axil_1_aw_bits_prot;
	input m_axil_1_w_ready;
	output wire m_axil_1_w_valid;
	output wire [31:0] m_axil_1_w_bits_data;
	output wire [3:0] m_axil_1_w_bits_strb;
	output wire m_axil_1_b_ready;
	input m_axil_1_b_valid;
	input [1:0] m_axil_1_b_bits_resp;
	input m_axil_2_ar_ready;
	output wire m_axil_2_ar_valid;
	output wire [11:0] m_axil_2_ar_bits_addr;
	output wire [2:0] m_axil_2_ar_bits_prot;
	output wire m_axil_2_r_ready;
	input m_axil_2_r_valid;
	input [31:0] m_axil_2_r_bits_data;
	input [1:0] m_axil_2_r_bits_resp;
	input m_axil_2_aw_ready;
	output wire m_axil_2_aw_valid;
	output wire [11:0] m_axil_2_aw_bits_addr;
	output wire [2:0] m_axil_2_aw_bits_prot;
	input m_axil_2_w_ready;
	output wire m_axil_2_w_valid;
	output wire [31:0] m_axil_2_w_bits_data;
	output wire [3:0] m_axil_2_w_bits_strb;
	output wire m_axil_2_b_ready;
	input m_axil_2_b_valid;
	input [1:0] m_axil_2_b_bits_resp;
	wire _write_mux_io_sink_valid;
	wire [1:0] _write_mux_io_sink_bits_resp;
	wire _write_mux_io_select_ready;
	wire _write_demux_1_io_source_ready;
	wire _write_demux_1_io_select_ready;
	wire _write_demux_io_source_ready;
	wire _write_demux_io_select_ready;
	wire _write_portQueueB_io_enq_ready;
	wire _write_portQueueB_io_deq_valid;
	wire [1:0] _write_portQueueB_io_deq_bits;
	wire _write_portQueueW_io_enq_ready;
	wire _write_portQueueW_io_deq_valid;
	wire [1:0] _write_portQueueW_io_deq_bits;
	wire _read_mux_io_sink_valid;
	wire [31:0] _read_mux_io_sink_bits_data;
	wire [1:0] _read_mux_io_sink_bits_resp;
	wire _read_mux_io_select_ready;
	wire _read_demux_io_source_ready;
	wire _read_demux_io_select_ready;
	wire _read_portQueue_io_enq_ready;
	wire _read_portQueue_io_deq_valid;
	wire [1:0] _read_portQueue_io_deq_bits;
	wire _s_axil__sinkBuffer_1_io_enq_ready;
	wire _s_axil__sourceBuffer_2_io_deq_valid;
	wire [31:0] _s_axil__sourceBuffer_2_io_deq_bits_data;
	wire [3:0] _s_axil__sourceBuffer_2_io_deq_bits_strb;
	wire _s_axil__sourceBuffer_1_io_deq_valid;
	wire [11:0] _s_axil__sourceBuffer_1_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_1_io_deq_bits_prot;
	wire _s_axil__sinkBuffer_io_enq_ready;
	wire _s_axil__sourceBuffer_io_deq_valid;
	wire [11:0] _s_axil__sourceBuffer_io_deq_bits_addr;
	wire [2:0] _s_axil__sourceBuffer_io_deq_bits_prot;
	reg read_eagerFork_regs_0;
	reg read_eagerFork_regs_1;
	reg read_eagerFork_regs_2;
	wire read_eagerFork_arPort_ready_qual1_0 = _read_demux_io_source_ready | read_eagerFork_regs_0;
	wire read_eagerFork_arPort_ready_qual1_1 = _read_demux_io_select_ready | read_eagerFork_regs_1;
	wire read_eagerFork_arPort_ready_qual1_2 = _read_portQueue_io_enq_ready | read_eagerFork_regs_2;
	wire read_result_ready = (read_eagerFork_arPort_ready_qual1_0 & read_eagerFork_arPort_ready_qual1_1) & read_eagerFork_arPort_ready_qual1_2;
	reg write_eagerFork_regs_0;
	reg write_eagerFork_regs_1;
	reg write_eagerFork_regs_2;
	reg write_eagerFork_regs_3;
	wire write_eagerFork_awPort_ready_qual1_0 = _write_demux_io_source_ready | write_eagerFork_regs_0;
	wire write_eagerFork_awPort_ready_qual1_1 = _write_demux_io_select_ready | write_eagerFork_regs_1;
	wire write_eagerFork_awPort_ready_qual1_2 = _write_portQueueW_io_enq_ready | write_eagerFork_regs_2;
	wire write_eagerFork_awPort_ready_qual1_3 = _write_portQueueB_io_enq_ready | write_eagerFork_regs_3;
	wire write_result_ready = ((write_eagerFork_awPort_ready_qual1_0 & write_eagerFork_awPort_ready_qual1_1) & write_eagerFork_awPort_ready_qual1_2) & write_eagerFork_awPort_ready_qual1_3;
	always @(posedge clock)
		if (reset) begin
			read_eagerFork_regs_0 <= 1'h0;
			read_eagerFork_regs_1 <= 1'h0;
			read_eagerFork_regs_2 <= 1'h0;
			write_eagerFork_regs_0 <= 1'h0;
			write_eagerFork_regs_1 <= 1'h0;
			write_eagerFork_regs_2 <= 1'h0;
			write_eagerFork_regs_3 <= 1'h0;
		end
		else begin
			read_eagerFork_regs_0 <= (read_eagerFork_arPort_ready_qual1_0 & _s_axil__sourceBuffer_io_deq_valid) & ~read_result_ready;
			read_eagerFork_regs_1 <= (read_eagerFork_arPort_ready_qual1_1 & _s_axil__sourceBuffer_io_deq_valid) & ~read_result_ready;
			read_eagerFork_regs_2 <= (read_eagerFork_arPort_ready_qual1_2 & _s_axil__sourceBuffer_io_deq_valid) & ~read_result_ready;
			write_eagerFork_regs_0 <= (write_eagerFork_awPort_ready_qual1_0 & _s_axil__sourceBuffer_1_io_deq_valid) & ~write_result_ready;
			write_eagerFork_regs_1 <= (write_eagerFork_awPort_ready_qual1_1 & _s_axil__sourceBuffer_1_io_deq_valid) & ~write_result_ready;
			write_eagerFork_regs_2 <= (write_eagerFork_awPort_ready_qual1_2 & _s_axil__sourceBuffer_1_io_deq_valid) & ~write_result_ready;
			write_eagerFork_regs_3 <= (write_eagerFork_awPort_ready_qual1_3 & _s_axil__sourceBuffer_1_io_deq_valid) & ~write_result_ready;
		end
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	Queue2_AddressChannel_6 s_axil__sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_ar_ready),
		.io_enq_valid(s_axil_ar_valid),
		.io_enq_bits_addr(s_axil_ar_bits_addr),
		.io_enq_bits_prot(s_axil_ar_bits_prot),
		.io_deq_ready(read_result_ready),
		.io_deq_valid(_s_axil__sourceBuffer_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot)
	);
	Queue2_ReadDataChannel_3 s_axil__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_enq_valid(_read_mux_io_sink_valid),
		.io_enq_bits_data(_read_mux_io_sink_bits_data),
		.io_enq_bits_resp(_read_mux_io_sink_bits_resp),
		.io_deq_ready(s_axil_r_ready),
		.io_deq_valid(s_axil_r_valid),
		.io_deq_bits_data(s_axil_r_bits_data),
		.io_deq_bits_resp(s_axil_r_bits_resp)
	);
	Queue2_AddressChannel_6 s_axil__sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_aw_ready),
		.io_enq_valid(s_axil_aw_valid),
		.io_enq_bits_addr(s_axil_aw_bits_addr),
		.io_enq_bits_prot(s_axil_aw_bits_prot),
		.io_deq_ready(write_result_ready),
		.io_deq_valid(_s_axil__sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot)
	);
	Queue2_WriteDataChannel_1 s_axil__sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(s_axil_w_ready),
		.io_enq_valid(s_axil_w_valid),
		.io_enq_bits_data(s_axil_w_bits_data),
		.io_enq_bits_strb(s_axil_w_bits_strb),
		.io_deq_ready(_write_demux_1_io_source_ready),
		.io_deq_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_deq_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_deq_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb)
	);
	Queue2_WriteResponseChannel s_axil__sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_write_mux_io_sink_valid),
		.io_enq_bits_resp(_write_mux_io_sink_bits_resp),
		.io_deq_ready(s_axil_b_ready),
		.io_deq_valid(s_axil_b_valid),
		.io_deq_bits_resp(s_axil_b_bits_resp)
	);
	Queue8_UInt2 read_portQueue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_portQueue_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_io_deq_valid & ~read_eagerFork_regs_2),
		.io_enq_bits(_s_axil__sourceBuffer_io_deq_bits_addr[11:10]),
		.io_deq_ready(_read_mux_io_select_ready),
		.io_deq_valid(_read_portQueue_io_deq_valid),
		.io_deq_bits(_read_portQueue_io_deq_bits)
	);
	elasticDemux_39 read_demux(
		.io_source_ready(_read_demux_io_source_ready),
		.io_source_valid(_s_axil__sourceBuffer_io_deq_valid & ~read_eagerFork_regs_0),
		.io_source_bits_addr(_s_axil__sourceBuffer_io_deq_bits_addr),
		.io_source_bits_prot(_s_axil__sourceBuffer_io_deq_bits_prot),
		.io_sinks_0_ready(m_axil_0_ar_ready),
		.io_sinks_0_valid(m_axil_0_ar_valid),
		.io_sinks_0_bits_addr(m_axil_0_ar_bits_addr),
		.io_sinks_0_bits_prot(m_axil_0_ar_bits_prot),
		.io_sinks_1_ready(m_axil_1_ar_ready),
		.io_sinks_1_valid(m_axil_1_ar_valid),
		.io_sinks_1_bits_addr(m_axil_1_ar_bits_addr),
		.io_sinks_1_bits_prot(m_axil_1_ar_bits_prot),
		.io_sinks_2_ready(m_axil_2_ar_ready),
		.io_sinks_2_valid(m_axil_2_ar_valid),
		.io_sinks_2_bits_addr(m_axil_2_ar_bits_addr),
		.io_sinks_2_bits_prot(m_axil_2_ar_bits_prot),
		.io_select_ready(_read_demux_io_select_ready),
		.io_select_valid(_s_axil__sourceBuffer_io_deq_valid & ~read_eagerFork_regs_1),
		.io_select_bits(_s_axil__sourceBuffer_io_deq_bits_addr[11:10])
	);
	elasticMux_34 read_mux(
		.io_sources_0_ready(m_axil_0_r_ready),
		.io_sources_0_valid(m_axil_0_r_valid),
		.io_sources_0_bits_data(m_axil_0_r_bits_data),
		.io_sources_0_bits_resp(m_axil_0_r_bits_resp),
		.io_sources_1_ready(m_axil_1_r_ready),
		.io_sources_1_valid(m_axil_1_r_valid),
		.io_sources_1_bits_data(m_axil_1_r_bits_data),
		.io_sources_1_bits_resp(m_axil_1_r_bits_resp),
		.io_sources_2_ready(m_axil_2_r_ready),
		.io_sources_2_valid(m_axil_2_r_valid),
		.io_sources_2_bits_data(m_axil_2_r_bits_data),
		.io_sources_2_bits_resp(m_axil_2_r_bits_resp),
		.io_sink_ready(_s_axil__sinkBuffer_io_enq_ready),
		.io_sink_valid(_read_mux_io_sink_valid),
		.io_sink_bits_data(_read_mux_io_sink_bits_data),
		.io_sink_bits_resp(_read_mux_io_sink_bits_resp),
		.io_select_ready(_read_mux_io_select_ready),
		.io_select_valid(_read_portQueue_io_deq_valid),
		.io_select_bits(_read_portQueue_io_deq_bits)
	);
	Queue8_UInt2 write_portQueueW(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_portQueueW_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_1_io_deq_valid & ~write_eagerFork_regs_2),
		.io_enq_bits(_s_axil__sourceBuffer_1_io_deq_bits_addr[11:10]),
		.io_deq_ready(_write_demux_1_io_select_ready),
		.io_deq_valid(_write_portQueueW_io_deq_valid),
		.io_deq_bits(_write_portQueueW_io_deq_bits)
	);
	Queue8_UInt2 write_portQueueB(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_write_portQueueB_io_enq_ready),
		.io_enq_valid(_s_axil__sourceBuffer_1_io_deq_valid & ~write_eagerFork_regs_3),
		.io_enq_bits(_s_axil__sourceBuffer_1_io_deq_bits_addr[11:10]),
		.io_deq_ready(_write_mux_io_select_ready),
		.io_deq_valid(_write_portQueueB_io_deq_valid),
		.io_deq_bits(_write_portQueueB_io_deq_bits)
	);
	elasticDemux_39 write_demux(
		.io_source_ready(_write_demux_io_source_ready),
		.io_source_valid(_s_axil__sourceBuffer_1_io_deq_valid & ~write_eagerFork_regs_0),
		.io_source_bits_addr(_s_axil__sourceBuffer_1_io_deq_bits_addr),
		.io_source_bits_prot(_s_axil__sourceBuffer_1_io_deq_bits_prot),
		.io_sinks_0_ready(m_axil_0_aw_ready),
		.io_sinks_0_valid(m_axil_0_aw_valid),
		.io_sinks_0_bits_addr(m_axil_0_aw_bits_addr),
		.io_sinks_0_bits_prot(m_axil_0_aw_bits_prot),
		.io_sinks_1_ready(m_axil_1_aw_ready),
		.io_sinks_1_valid(m_axil_1_aw_valid),
		.io_sinks_1_bits_addr(m_axil_1_aw_bits_addr),
		.io_sinks_1_bits_prot(m_axil_1_aw_bits_prot),
		.io_sinks_2_ready(m_axil_2_aw_ready),
		.io_sinks_2_valid(m_axil_2_aw_valid),
		.io_sinks_2_bits_addr(m_axil_2_aw_bits_addr),
		.io_sinks_2_bits_prot(m_axil_2_aw_bits_prot),
		.io_select_ready(_write_demux_io_select_ready),
		.io_select_valid(_s_axil__sourceBuffer_1_io_deq_valid & ~write_eagerFork_regs_1),
		.io_select_bits(_s_axil__sourceBuffer_1_io_deq_bits_addr[11:10])
	);
	elasticDemux_41 write_demux_1(
		.io_source_ready(_write_demux_1_io_source_ready),
		.io_source_valid(_s_axil__sourceBuffer_2_io_deq_valid),
		.io_source_bits_data(_s_axil__sourceBuffer_2_io_deq_bits_data),
		.io_source_bits_strb(_s_axil__sourceBuffer_2_io_deq_bits_strb),
		.io_sinks_0_ready(m_axil_0_w_ready),
		.io_sinks_0_valid(m_axil_0_w_valid),
		.io_sinks_0_bits_data(m_axil_0_w_bits_data),
		.io_sinks_0_bits_strb(m_axil_0_w_bits_strb),
		.io_sinks_1_ready(m_axil_1_w_ready),
		.io_sinks_1_valid(m_axil_1_w_valid),
		.io_sinks_1_bits_data(m_axil_1_w_bits_data),
		.io_sinks_1_bits_strb(m_axil_1_w_bits_strb),
		.io_sinks_2_ready(m_axil_2_w_ready),
		.io_sinks_2_valid(m_axil_2_w_valid),
		.io_sinks_2_bits_data(m_axil_2_w_bits_data),
		.io_sinks_2_bits_strb(m_axil_2_w_bits_strb),
		.io_select_ready(_write_demux_1_io_select_ready),
		.io_select_valid(_write_portQueueW_io_deq_valid),
		.io_select_bits(_write_portQueueW_io_deq_bits)
	);
	elasticMux_35 write_mux(
		.io_sources_0_ready(m_axil_0_b_ready),
		.io_sources_0_valid(m_axil_0_b_valid),
		.io_sources_0_bits_resp(m_axil_0_b_bits_resp),
		.io_sources_1_ready(m_axil_1_b_ready),
		.io_sources_1_valid(m_axil_1_b_valid),
		.io_sources_1_bits_resp(m_axil_1_b_bits_resp),
		.io_sources_2_ready(m_axil_2_b_ready),
		.io_sources_2_valid(m_axil_2_b_valid),
		.io_sources_2_bits_resp(m_axil_2_b_bits_resp),
		.io_sink_ready(_s_axil__sinkBuffer_1_io_enq_ready),
		.io_sink_valid(_write_mux_io_sink_valid),
		.io_sink_bits_resp(_write_mux_io_sink_bits_resp),
		.io_select_ready(_write_mux_io_select_ready),
		.io_select_valid(_write_portQueueB_io_deq_valid),
		.io_select_bits(_write_portQueueB_io_deq_bits)
	);
endmodule
module ram_4x448 (
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
	output wire [447:0] R0_data;
	input [1:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [447:0] W0_data;
	reg [447:0] Memory [0:3];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [447:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 448'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue4_UInt448 (
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
	input [447:0] io_enq_bits;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [447:0] io_deq_bits;
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
	ram_4x448 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
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
	ram_4x64 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(io_deq_bits),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data(io_enq_bits)
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
endmodule
module CounterEx_3 (
	clock,
	reset,
	io_up,
	io_down,
	io_left
);
	input clock;
	input reset;
	input [9:0] io_up;
	input [9:0] io_down;
	output wire [9:0] io_left;
	reg [9:0] rLeft;
	always @(posedge clock)
		if (reset)
			rLeft <= 10'h200;
		else if (io_up > io_down)
			rLeft <= rLeft - (io_up - io_down);
		else
			rLeft <= (rLeft + io_down) - io_up;
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_left = rLeft;
endmodule
module ram_512x259 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [8:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [258:0] R0_data;
	input [8:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [258:0] W0_data;
	reg [258:0] Memory [0:511];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 259'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue512_ReadDataChannel (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_data,
	io_deq_bits_resp,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [255:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [255:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	output wire io_deq_bits_last;
	wire [258:0] _ram_ext_R0_data;
	reg [8:0] enq_ptr_value;
	reg [8:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 9'h000;
			deq_ptr_value <= 9'h000;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 9'h001;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 9'h001;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	initial begin : sv2v_autoblock_2
		reg [31:0] _RANDOM [0:0];
	end
	ram_512x259 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_resp, io_enq_bits_data})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_data = _ram_ext_R0_data[255:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[257:256];
	assign io_deq_bits_last = _ram_ext_R0_data[258];
endmodule
module ResponseBuffer_3 (
	clock,
	reset,
	s_axi_ar_ready,
	s_axi_ar_valid,
	s_axi_ar_bits_addr,
	s_axi_ar_bits_len,
	s_axi_ar_bits_size,
	s_axi_ar_bits_burst,
	s_axi_ar_bits_lock,
	s_axi_ar_bits_cache,
	s_axi_ar_bits_prot,
	s_axi_ar_bits_qos,
	s_axi_ar_bits_region,
	s_axi_r_ready,
	s_axi_r_valid,
	s_axi_r_bits_data,
	s_axi_r_bits_resp,
	s_axi_r_bits_last,
	s_axi_aw_ready,
	s_axi_aw_valid,
	s_axi_aw_bits_addr,
	s_axi_aw_bits_len,
	s_axi_aw_bits_size,
	s_axi_aw_bits_burst,
	s_axi_aw_bits_lock,
	s_axi_aw_bits_cache,
	s_axi_aw_bits_prot,
	s_axi_aw_bits_qos,
	s_axi_aw_bits_region,
	s_axi_w_ready,
	s_axi_w_valid,
	s_axi_w_bits_data,
	s_axi_w_bits_strb,
	s_axi_w_bits_last,
	s_axi_b_ready,
	s_axi_b_valid,
	m_axi_ar_ready,
	m_axi_ar_valid,
	m_axi_ar_bits_addr,
	m_axi_ar_bits_len,
	m_axi_ar_bits_size,
	m_axi_ar_bits_burst,
	m_axi_ar_bits_lock,
	m_axi_ar_bits_cache,
	m_axi_ar_bits_prot,
	m_axi_ar_bits_qos,
	m_axi_ar_bits_region,
	m_axi_r_ready,
	m_axi_r_valid,
	m_axi_r_bits_data,
	m_axi_r_bits_resp,
	m_axi_r_bits_last,
	m_axi_aw_ready,
	m_axi_aw_valid,
	m_axi_aw_bits_addr,
	m_axi_aw_bits_len,
	m_axi_aw_bits_size,
	m_axi_aw_bits_burst,
	m_axi_aw_bits_lock,
	m_axi_aw_bits_cache,
	m_axi_aw_bits_prot,
	m_axi_aw_bits_qos,
	m_axi_aw_bits_region,
	m_axi_w_ready,
	m_axi_w_valid,
	m_axi_w_bits_data,
	m_axi_w_bits_strb,
	m_axi_w_bits_last,
	m_axi_b_ready,
	m_axi_b_valid
);
	input clock;
	input reset;
	output wire s_axi_ar_ready;
	input s_axi_ar_valid;
	input [63:0] s_axi_ar_bits_addr;
	input [7:0] s_axi_ar_bits_len;
	input [2:0] s_axi_ar_bits_size;
	input [1:0] s_axi_ar_bits_burst;
	input s_axi_ar_bits_lock;
	input [3:0] s_axi_ar_bits_cache;
	input [2:0] s_axi_ar_bits_prot;
	input [3:0] s_axi_ar_bits_qos;
	input [3:0] s_axi_ar_bits_region;
	input s_axi_r_ready;
	output wire s_axi_r_valid;
	output wire [255:0] s_axi_r_bits_data;
	output wire [1:0] s_axi_r_bits_resp;
	output wire s_axi_r_bits_last;
	output wire s_axi_aw_ready;
	input s_axi_aw_valid;
	input [63:0] s_axi_aw_bits_addr;
	input [7:0] s_axi_aw_bits_len;
	input [2:0] s_axi_aw_bits_size;
	input [1:0] s_axi_aw_bits_burst;
	input s_axi_aw_bits_lock;
	input [3:0] s_axi_aw_bits_cache;
	input [2:0] s_axi_aw_bits_prot;
	input [3:0] s_axi_aw_bits_qos;
	input [3:0] s_axi_aw_bits_region;
	output wire s_axi_w_ready;
	input s_axi_w_valid;
	input [255:0] s_axi_w_bits_data;
	input [31:0] s_axi_w_bits_strb;
	input s_axi_w_bits_last;
	input s_axi_b_ready;
	output wire s_axi_b_valid;
	input m_axi_ar_ready;
	output wire m_axi_ar_valid;
	output wire [63:0] m_axi_ar_bits_addr;
	output wire [7:0] m_axi_ar_bits_len;
	output wire [2:0] m_axi_ar_bits_size;
	output wire [1:0] m_axi_ar_bits_burst;
	output wire m_axi_ar_bits_lock;
	output wire [3:0] m_axi_ar_bits_cache;
	output wire [2:0] m_axi_ar_bits_prot;
	output wire [3:0] m_axi_ar_bits_qos;
	output wire [3:0] m_axi_ar_bits_region;
	output wire m_axi_r_ready;
	input m_axi_r_valid;
	input [255:0] m_axi_r_bits_data;
	input [1:0] m_axi_r_bits_resp;
	input m_axi_r_bits_last;
	input m_axi_aw_ready;
	output wire m_axi_aw_valid;
	output wire [63:0] m_axi_aw_bits_addr;
	output wire [7:0] m_axi_aw_bits_len;
	output wire [2:0] m_axi_aw_bits_size;
	output wire [1:0] m_axi_aw_bits_burst;
	output wire m_axi_aw_bits_lock;
	output wire [3:0] m_axi_aw_bits_cache;
	output wire [2:0] m_axi_aw_bits_prot;
	output wire [3:0] m_axi_aw_bits_qos;
	output wire [3:0] m_axi_aw_bits_region;
	input m_axi_w_ready;
	output wire m_axi_w_valid;
	output wire [255:0] m_axi_w_bits_data;
	output wire [31:0] m_axi_w_bits_strb;
	output wire m_axi_w_bits_last;
	output wire m_axi_b_ready;
	input m_axi_b_valid;
	wire _read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready;
	wire _read_arrival1_sourceBuffer_io_deq_valid;
	wire [255:0] _read_arrival1_sourceBuffer_io_deq_bits_data;
	wire [1:0] _read_arrival1_sourceBuffer_io_deq_bits_resp;
	wire _read_arrival1_sourceBuffer_io_deq_bits_last;
	wire _read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready;
	wire [9:0] _read_ctrR_io_left;
	wire _read_arrival0_T = _read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready & s_axi_ar_valid;
	wire [9:0] _GEN = {1'h0, {1'h0, s_axi_ar_bits_len} + 9'h001};
	wire _read_arrival0_T_1 = _read_ctrR_io_left >= _GEN;
	wire s_axi_ar_ready_0 = _read_arrival0_T & _read_arrival0_T_1;
	wire read_arrival1_result_ready = _read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready & _read_arrival1_sourceBuffer_io_deq_valid;
	CounterEx_3 read_ctrR(
		.clock(clock),
		.reset(reset),
		.io_up((_read_arrival0_T & _read_arrival0_T_1 ? _GEN : 10'h000)),
		.io_down({9'h000, read_arrival1_result_ready}),
		.io_left(_read_ctrR_io_left)
	);
	Queue2_ReadAddressChannel_7 read_arrival0_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_arrival0_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(s_axi_ar_ready_0),
		.io_enq_bits_addr(s_axi_ar_bits_addr),
		.io_enq_bits_len(s_axi_ar_bits_len),
		.io_enq_bits_size(s_axi_ar_bits_size),
		.io_enq_bits_burst(s_axi_ar_bits_burst),
		.io_enq_bits_lock(s_axi_ar_bits_lock),
		.io_enq_bits_cache(s_axi_ar_bits_cache),
		.io_enq_bits_prot(s_axi_ar_bits_prot),
		.io_enq_bits_qos(s_axi_ar_bits_qos),
		.io_enq_bits_region(s_axi_ar_bits_region),
		.io_deq_ready(m_axi_ar_ready),
		.io_deq_valid(m_axi_ar_valid),
		.io_deq_bits_addr(m_axi_ar_bits_addr),
		.io_deq_bits_len(m_axi_ar_bits_len),
		.io_deq_bits_size(m_axi_ar_bits_size),
		.io_deq_bits_burst(m_axi_ar_bits_burst),
		.io_deq_bits_lock(m_axi_ar_bits_lock),
		.io_deq_bits_cache(m_axi_ar_bits_cache),
		.io_deq_bits_prot(m_axi_ar_bits_prot),
		.io_deq_bits_qos(m_axi_ar_bits_qos),
		.io_deq_bits_region(m_axi_ar_bits_region)
	);
	Queue512_ReadDataChannel read_arrival1_sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(m_axi_r_ready),
		.io_enq_valid(m_axi_r_valid),
		.io_enq_bits_data(m_axi_r_bits_data),
		.io_enq_bits_resp(m_axi_r_bits_resp),
		.io_enq_bits_last(m_axi_r_bits_last),
		.io_deq_ready(read_arrival1_result_ready),
		.io_deq_valid(_read_arrival1_sourceBuffer_io_deq_valid),
		.io_deq_bits_data(_read_arrival1_sourceBuffer_io_deq_bits_data),
		.io_deq_bits_resp(_read_arrival1_sourceBuffer_io_deq_bits_resp),
		.io_deq_bits_last(_read_arrival1_sourceBuffer_io_deq_bits_last)
	);
	Queue2_ReadDataChannel read_arrival1_sinkBuffered__sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_read_arrival1_sinkBuffered__sinkBuffer_io_enq_ready),
		.io_enq_valid(read_arrival1_result_ready),
		.io_enq_bits_data(_read_arrival1_sourceBuffer_io_deq_bits_data),
		.io_enq_bits_resp(_read_arrival1_sourceBuffer_io_deq_bits_resp),
		.io_enq_bits_last(_read_arrival1_sourceBuffer_io_deq_bits_last),
		.io_deq_ready(s_axi_r_ready),
		.io_deq_valid(s_axi_r_valid),
		.io_deq_bits_data(s_axi_r_bits_data),
		.io_deq_bits_resp(s_axi_r_bits_resp),
		.io_deq_bits_last(s_axi_r_bits_last)
	);
	assign s_axi_ar_ready = s_axi_ar_ready_0;
	assign s_axi_aw_ready = m_axi_aw_ready;
	assign s_axi_w_ready = m_axi_w_ready;
	assign s_axi_b_valid = m_axi_b_valid;
	assign m_axi_aw_valid = s_axi_aw_valid;
	assign m_axi_aw_bits_addr = s_axi_aw_bits_addr;
	assign m_axi_aw_bits_len = s_axi_aw_bits_len;
	assign m_axi_aw_bits_size = s_axi_aw_bits_size;
	assign m_axi_aw_bits_burst = s_axi_aw_bits_burst;
	assign m_axi_aw_bits_lock = s_axi_aw_bits_lock;
	assign m_axi_aw_bits_cache = s_axi_aw_bits_cache;
	assign m_axi_aw_bits_prot = s_axi_aw_bits_prot;
	assign m_axi_aw_bits_qos = s_axi_aw_bits_qos;
	assign m_axi_aw_bits_region = s_axi_aw_bits_region;
	assign m_axi_w_valid = s_axi_w_valid;
	assign m_axi_w_bits_data = s_axi_w_bits_data;
	assign m_axi_w_bits_strb = s_axi_w_bits_strb;
	assign m_axi_w_bits_last = s_axi_w_bits_last;
	assign m_axi_b_ready = s_axi_b_ready;
endmodule
module ram_2x63 (
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
	output wire [62:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [62:0] W0_data;
	reg [62:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [63:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 63'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadAddressChannel_9 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_enq_bits_lock,
	io_enq_bits_cache,
	io_enq_bits_prot,
	io_enq_bits_qos,
	io_enq_bits_region,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst,
	io_deq_bits_lock,
	io_deq_bits_cache,
	io_deq_bits_prot,
	io_deq_bits_qos,
	io_deq_bits_region
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [33:0] io_enq_bits_addr;
	input [7:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_enq_bits_lock;
	input [3:0] io_enq_bits_cache;
	input [2:0] io_enq_bits_prot;
	input [3:0] io_enq_bits_qos;
	input [3:0] io_enq_bits_region;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [33:0] io_deq_bits_addr;
	output wire [7:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	output wire io_deq_bits_lock;
	output wire [3:0] io_deq_bits_cache;
	output wire [2:0] io_deq_bits_prot;
	output wire [3:0] io_deq_bits_qos;
	output wire [3:0] io_deq_bits_region;
	wire [62:0] _ram_ext_R0_data;
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
	ram_2x63 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_region, io_enq_bits_qos, io_enq_bits_prot, io_enq_bits_cache, io_enq_bits_lock, io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[33:0];
	assign io_deq_bits_len = _ram_ext_R0_data[41:34];
	assign io_deq_bits_size = _ram_ext_R0_data[44:42];
	assign io_deq_bits_burst = _ram_ext_R0_data[46:45];
	assign io_deq_bits_lock = _ram_ext_R0_data[47];
	assign io_deq_bits_cache = _ram_ext_R0_data[51:48];
	assign io_deq_bits_prot = _ram_ext_R0_data[54:52];
	assign io_deq_bits_qos = _ram_ext_R0_data[58:55];
	assign io_deq_bits_region = _ram_ext_R0_data[62:59];
endmodule
module Queue2_WriteAddressChannel_2 (
	clock,
	reset,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst,
	io_deq_bits_lock,
	io_deq_bits_cache,
	io_deq_bits_prot,
	io_deq_bits_qos,
	io_deq_bits_region
);
	input clock;
	input reset;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [33:0] io_deq_bits_addr;
	output wire [7:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	output wire io_deq_bits_lock;
	output wire [3:0] io_deq_bits_cache;
	output wire [2:0] io_deq_bits_prot;
	output wire [3:0] io_deq_bits_qos;
	output wire [3:0] io_deq_bits_region;
	reg wrap_1;
	always @(posedge clock)
		if (reset)
			wrap_1 <= 1'h0;
		else if (io_deq_ready & wrap_1)
			wrap_1 <= wrap_1 - 1'h1;
	initial begin : sv2v_autoblock_1
		reg [31:0] _RANDOM [0:0];
	end
	assign io_deq_valid = wrap_1;
	assign io_deq_bits_addr = 34'h000000000;
	assign io_deq_bits_len = 8'h00;
	assign io_deq_bits_size = 3'h0;
	assign io_deq_bits_burst = 2'h0;
	assign io_deq_bits_lock = 1'h0;
	assign io_deq_bits_cache = 4'h0;
	assign io_deq_bits_prot = 3'h0;
	assign io_deq_bits_qos = 4'h0;
	assign io_deq_bits_region = 4'h0;
endmodule
module Queue2_WriteResponseChannel_4 (
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
module Queue2_WriteAddressChannel_3 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_addr,
	io_enq_bits_len,
	io_enq_bits_size,
	io_enq_bits_burst,
	io_enq_bits_lock,
	io_enq_bits_cache,
	io_enq_bits_prot,
	io_enq_bits_qos,
	io_enq_bits_region,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_addr,
	io_deq_bits_len,
	io_deq_bits_size,
	io_deq_bits_burst,
	io_deq_bits_lock,
	io_deq_bits_cache,
	io_deq_bits_prot,
	io_deq_bits_qos,
	io_deq_bits_region
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [63:0] io_enq_bits_addr;
	input [7:0] io_enq_bits_len;
	input [2:0] io_enq_bits_size;
	input [1:0] io_enq_bits_burst;
	input io_enq_bits_lock;
	input [3:0] io_enq_bits_cache;
	input [2:0] io_enq_bits_prot;
	input [3:0] io_enq_bits_qos;
	input [3:0] io_enq_bits_region;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_addr;
	output wire [7:0] io_deq_bits_len;
	output wire [2:0] io_deq_bits_size;
	output wire [1:0] io_deq_bits_burst;
	output wire io_deq_bits_lock;
	output wire [3:0] io_deq_bits_cache;
	output wire [2:0] io_deq_bits_prot;
	output wire [3:0] io_deq_bits_qos;
	output wire [3:0] io_deq_bits_region;
	wire [92:0] _ram_ext_R0_data;
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
	ram_2x93 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_region, io_enq_bits_qos, io_enq_bits_prot, io_enq_bits_cache, io_enq_bits_lock, io_enq_bits_burst, io_enq_bits_size, io_enq_bits_len, io_enq_bits_addr})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_addr = _ram_ext_R0_data[63:0];
	assign io_deq_bits_len = _ram_ext_R0_data[71:64];
	assign io_deq_bits_size = _ram_ext_R0_data[74:72];
	assign io_deq_bits_burst = _ram_ext_R0_data[76:75];
	assign io_deq_bits_lock = _ram_ext_R0_data[77];
	assign io_deq_bits_cache = _ram_ext_R0_data[81:78];
	assign io_deq_bits_prot = _ram_ext_R0_data[84:82];
	assign io_deq_bits_qos = _ram_ext_R0_data[88:85];
	assign io_deq_bits_region = _ram_ext_R0_data[92:89];
endmodule
module ram_2x261 (
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
	output wire [260:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [260:0] W0_data;
	reg [260:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [287:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 261'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_ReadDataChannel_11 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_id,
	io_enq_bits_data,
	io_enq_bits_resp,
	io_enq_bits_last,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_id,
	io_deq_bits_data,
	io_deq_bits_resp,
	io_deq_bits_last
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_id;
	input [255:0] io_enq_bits_data;
	input [1:0] io_enq_bits_resp;
	input io_enq_bits_last;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_id;
	output wire [255:0] io_deq_bits_data;
	output wire [1:0] io_deq_bits_resp;
	output wire io_deq_bits_last;
	wire [260:0] _ram_ext_R0_data;
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
	ram_2x261 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_last, io_enq_bits_resp, io_enq_bits_data, io_enq_bits_id})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_id = _ram_ext_R0_data[1:0];
	assign io_deq_bits_data = _ram_ext_R0_data[257:2];
	assign io_deq_bits_resp = _ram_ext_R0_data[259:258];
	assign io_deq_bits_last = _ram_ext_R0_data[260];
endmodule
module ram_2x4 (
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
	output wire [3:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [3:0] W0_data;
	reg [3:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	reg [31:0] _RANDOM_MEM;
	assign R0_data = (R0_en ? Memory[R0_addr] : 4'bxxxx);
endmodule
module Queue2_WriteResponseChannel_7 (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_id,
	io_enq_bits_resp,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_id,
	io_deq_bits_resp
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [1:0] io_enq_bits_id;
	input [1:0] io_enq_bits_resp;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [1:0] io_deq_bits_id;
	output wire [1:0] io_deq_bits_resp;
	wire [3:0] _ram_ext_R0_data;
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
	ram_2x4 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_resp, io_enq_bits_id})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_id = _ram_ext_R0_data[1:0];
	assign io_deq_bits_resp = _ram_ext_R0_data[3:2];
endmodule
module SpmvExp1 (
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
	S_AXI_STRIPED_ARREADY,
	S_AXI_STRIPED_ARVALID,
	S_AXI_STRIPED_ARID,
	S_AXI_STRIPED_ARADDR,
	S_AXI_STRIPED_ARLEN,
	S_AXI_STRIPED_ARSIZE,
	S_AXI_STRIPED_ARBURST,
	S_AXI_STRIPED_RREADY,
	S_AXI_STRIPED_RVALID,
	S_AXI_STRIPED_RID,
	S_AXI_STRIPED_RDATA,
	S_AXI_STRIPED_RRESP,
	S_AXI_STRIPED_RLAST,
	S_AXI_STRIPED_AWREADY,
	S_AXI_STRIPED_AWVALID,
	S_AXI_STRIPED_AWID,
	S_AXI_STRIPED_AWADDR,
	S_AXI_STRIPED_AWLEN,
	S_AXI_STRIPED_AWSIZE,
	S_AXI_STRIPED_AWBURST,
	S_AXI_STRIPED_WREADY,
	S_AXI_STRIPED_WVALID,
	S_AXI_STRIPED_WDATA,
	S_AXI_STRIPED_WSTRB,
	S_AXI_STRIPED_WLAST,
	S_AXI_STRIPED_BREADY,
	S_AXI_STRIPED_BVALID,
	S_AXI_STRIPED_BID,
	S_AXI_STRIPED_BRESP,
	M_AXI_STRIPED_ARREADY,
	M_AXI_STRIPED_ARVALID,
	M_AXI_STRIPED_ARID,
	M_AXI_STRIPED_ARADDR,
	M_AXI_STRIPED_ARLEN,
	M_AXI_STRIPED_ARSIZE,
	M_AXI_STRIPED_ARBURST,
	M_AXI_STRIPED_RREADY,
	M_AXI_STRIPED_RVALID,
	M_AXI_STRIPED_RID,
	M_AXI_STRIPED_RDATA,
	M_AXI_STRIPED_RRESP,
	M_AXI_STRIPED_RLAST,
	M_AXI_STRIPED_AWREADY,
	M_AXI_STRIPED_AWVALID,
	M_AXI_STRIPED_AWID,
	M_AXI_STRIPED_AWADDR,
	M_AXI_STRIPED_AWLEN,
	M_AXI_STRIPED_AWSIZE,
	M_AXI_STRIPED_AWBURST,
	M_AXI_STRIPED_WREADY,
	M_AXI_STRIPED_WVALID,
	M_AXI_STRIPED_WDATA,
	M_AXI_STRIPED_WSTRB,
	M_AXI_STRIPED_WLAST,
	M_AXI_STRIPED_BREADY,
	M_AXI_STRIPED_BVALID,
	M_AXI_STRIPED_BID,
	M_AXI_STRIPED_BRESP,
	M_AXI_LS_ARREADY,
	M_AXI_LS_ARVALID,
	M_AXI_LS_ARADDR,
	M_AXI_LS_ARLEN,
	M_AXI_LS_ARSIZE,
	M_AXI_LS_ARBURST,
	M_AXI_LS_ARLOCK,
	M_AXI_LS_ARCACHE,
	M_AXI_LS_ARPROT,
	M_AXI_LS_ARQOS,
	M_AXI_LS_ARREGION,
	M_AXI_LS_RREADY,
	M_AXI_LS_RVALID,
	M_AXI_LS_RDATA,
	M_AXI_LS_RRESP,
	M_AXI_LS_RLAST,
	M_AXI_LS_AWREADY,
	M_AXI_LS_AWVALID,
	M_AXI_LS_AWADDR,
	M_AXI_LS_AWLEN,
	M_AXI_LS_AWSIZE,
	M_AXI_LS_AWBURST,
	M_AXI_LS_AWLOCK,
	M_AXI_LS_AWCACHE,
	M_AXI_LS_AWPROT,
	M_AXI_LS_AWQOS,
	M_AXI_LS_AWREGION,
	M_AXI_LS_WREADY,
	M_AXI_LS_WVALID,
	M_AXI_LS_WDATA,
	M_AXI_LS_WSTRB,
	M_AXI_LS_WLAST,
	M_AXI_LS_BREADY,
	M_AXI_LS_BVALID,
	M_AXI_LS_BRESP,
	M_AXI_GP_ARREADY,
	M_AXI_GP_ARVALID,
	M_AXI_GP_ARID,
	M_AXI_GP_ARADDR,
	M_AXI_GP_ARLEN,
	M_AXI_GP_ARSIZE,
	M_AXI_GP_ARBURST,
	M_AXI_GP_RREADY,
	M_AXI_GP_RVALID,
	M_AXI_GP_RID,
	M_AXI_GP_RDATA,
	M_AXI_GP_RRESP,
	M_AXI_GP_RLAST,
	M_AXI_GP_AWREADY,
	M_AXI_GP_AWVALID,
	M_AXI_GP_AWID,
	M_AXI_GP_AWADDR,
	M_AXI_GP_AWLEN,
	M_AXI_GP_AWSIZE,
	M_AXI_GP_AWBURST,
	M_AXI_GP_WREADY,
	M_AXI_GP_WVALID,
	M_AXI_GP_WDATA,
	M_AXI_GP_WSTRB,
	M_AXI_GP_WLAST,
	M_AXI_GP_BREADY,
	M_AXI_GP_BVALID,
	M_AXI_GP_BID,
	M_AXI_GP_BRESP
);
	input clock;
	input reset;
	output wire S_AXI_CONTROL_ARREADY;
	input S_AXI_CONTROL_ARVALID;
	input [11:0] S_AXI_CONTROL_ARADDR;
	input [2:0] S_AXI_CONTROL_ARPROT;
	input S_AXI_CONTROL_RREADY;
	output wire S_AXI_CONTROL_RVALID;
	output wire [31:0] S_AXI_CONTROL_RDATA;
	output wire [1:0] S_AXI_CONTROL_RRESP;
	output wire S_AXI_CONTROL_AWREADY;
	input S_AXI_CONTROL_AWVALID;
	input [11:0] S_AXI_CONTROL_AWADDR;
	input [2:0] S_AXI_CONTROL_AWPROT;
	output wire S_AXI_CONTROL_WREADY;
	input S_AXI_CONTROL_WVALID;
	input [31:0] S_AXI_CONTROL_WDATA;
	input [3:0] S_AXI_CONTROL_WSTRB;
	input S_AXI_CONTROL_BREADY;
	output wire S_AXI_CONTROL_BVALID;
	output wire [1:0] S_AXI_CONTROL_BRESP;
	output wire S_AXI_STRIPED_ARREADY;
	input S_AXI_STRIPED_ARVALID;
	input [1:0] S_AXI_STRIPED_ARID;
	input [33:0] S_AXI_STRIPED_ARADDR;
	input [3:0] S_AXI_STRIPED_ARLEN;
	input [2:0] S_AXI_STRIPED_ARSIZE;
	input [1:0] S_AXI_STRIPED_ARBURST;
	input S_AXI_STRIPED_RREADY;
	output wire S_AXI_STRIPED_RVALID;
	output wire [1:0] S_AXI_STRIPED_RID;
	output wire [255:0] S_AXI_STRIPED_RDATA;
	output wire [1:0] S_AXI_STRIPED_RRESP;
	output wire S_AXI_STRIPED_RLAST;
	output wire S_AXI_STRIPED_AWREADY;
	input S_AXI_STRIPED_AWVALID;
	input [1:0] S_AXI_STRIPED_AWID;
	input [33:0] S_AXI_STRIPED_AWADDR;
	input [3:0] S_AXI_STRIPED_AWLEN;
	input [2:0] S_AXI_STRIPED_AWSIZE;
	input [1:0] S_AXI_STRIPED_AWBURST;
	output wire S_AXI_STRIPED_WREADY;
	input S_AXI_STRIPED_WVALID;
	input [255:0] S_AXI_STRIPED_WDATA;
	input [31:0] S_AXI_STRIPED_WSTRB;
	input S_AXI_STRIPED_WLAST;
	input S_AXI_STRIPED_BREADY;
	output wire S_AXI_STRIPED_BVALID;
	output wire [1:0] S_AXI_STRIPED_BID;
	output wire [1:0] S_AXI_STRIPED_BRESP;
	input M_AXI_STRIPED_ARREADY;
	output wire M_AXI_STRIPED_ARVALID;
	output wire [1:0] M_AXI_STRIPED_ARID;
	output wire [33:0] M_AXI_STRIPED_ARADDR;
	output wire [3:0] M_AXI_STRIPED_ARLEN;
	output wire [2:0] M_AXI_STRIPED_ARSIZE;
	output wire [1:0] M_AXI_STRIPED_ARBURST;
	output wire M_AXI_STRIPED_RREADY;
	input M_AXI_STRIPED_RVALID;
	input [1:0] M_AXI_STRIPED_RID;
	input [255:0] M_AXI_STRIPED_RDATA;
	input [1:0] M_AXI_STRIPED_RRESP;
	input M_AXI_STRIPED_RLAST;
	input M_AXI_STRIPED_AWREADY;
	output wire M_AXI_STRIPED_AWVALID;
	output wire [1:0] M_AXI_STRIPED_AWID;
	output wire [33:0] M_AXI_STRIPED_AWADDR;
	output wire [3:0] M_AXI_STRIPED_AWLEN;
	output wire [2:0] M_AXI_STRIPED_AWSIZE;
	output wire [1:0] M_AXI_STRIPED_AWBURST;
	input M_AXI_STRIPED_WREADY;
	output wire M_AXI_STRIPED_WVALID;
	output wire [255:0] M_AXI_STRIPED_WDATA;
	output wire [31:0] M_AXI_STRIPED_WSTRB;
	output wire M_AXI_STRIPED_WLAST;
	output wire M_AXI_STRIPED_BREADY;
	input M_AXI_STRIPED_BVALID;
	input [1:0] M_AXI_STRIPED_BID;
	input [1:0] M_AXI_STRIPED_BRESP;
	input M_AXI_LS_ARREADY;
	output wire M_AXI_LS_ARVALID;
	output wire [63:0] M_AXI_LS_ARADDR;
	output wire [7:0] M_AXI_LS_ARLEN;
	output wire [2:0] M_AXI_LS_ARSIZE;
	output wire [1:0] M_AXI_LS_ARBURST;
	output wire M_AXI_LS_ARLOCK;
	output wire [3:0] M_AXI_LS_ARCACHE;
	output wire [2:0] M_AXI_LS_ARPROT;
	output wire [3:0] M_AXI_LS_ARQOS;
	output wire [3:0] M_AXI_LS_ARREGION;
	output wire M_AXI_LS_RREADY;
	input M_AXI_LS_RVALID;
	input [255:0] M_AXI_LS_RDATA;
	input [1:0] M_AXI_LS_RRESP;
	input M_AXI_LS_RLAST;
	input M_AXI_LS_AWREADY;
	output wire M_AXI_LS_AWVALID;
	output wire [63:0] M_AXI_LS_AWADDR;
	output wire [7:0] M_AXI_LS_AWLEN;
	output wire [2:0] M_AXI_LS_AWSIZE;
	output wire [1:0] M_AXI_LS_AWBURST;
	output wire M_AXI_LS_AWLOCK;
	output wire [3:0] M_AXI_LS_AWCACHE;
	output wire [2:0] M_AXI_LS_AWPROT;
	output wire [3:0] M_AXI_LS_AWQOS;
	output wire [3:0] M_AXI_LS_AWREGION;
	input M_AXI_LS_WREADY;
	output wire M_AXI_LS_WVALID;
	output wire [255:0] M_AXI_LS_WDATA;
	output wire [31:0] M_AXI_LS_WSTRB;
	output wire M_AXI_LS_WLAST;
	output wire M_AXI_LS_BREADY;
	input M_AXI_LS_BVALID;
	input [1:0] M_AXI_LS_BRESP;
	input M_AXI_GP_ARREADY;
	output wire M_AXI_GP_ARVALID;
	output wire [1:0] M_AXI_GP_ARID;
	output wire [63:0] M_AXI_GP_ARADDR;
	output wire [3:0] M_AXI_GP_ARLEN;
	output wire [2:0] M_AXI_GP_ARSIZE;
	output wire [1:0] M_AXI_GP_ARBURST;
	output wire M_AXI_GP_RREADY;
	input M_AXI_GP_RVALID;
	input [1:0] M_AXI_GP_RID;
	input [255:0] M_AXI_GP_RDATA;
	input [1:0] M_AXI_GP_RRESP;
	input M_AXI_GP_RLAST;
	input M_AXI_GP_AWREADY;
	output wire M_AXI_GP_AWVALID;
	output wire [1:0] M_AXI_GP_AWID;
	output wire [63:0] M_AXI_GP_AWADDR;
	output wire [3:0] M_AXI_GP_AWLEN;
	output wire [2:0] M_AXI_GP_AWSIZE;
	output wire [1:0] M_AXI_GP_AWBURST;
	input M_AXI_GP_WREADY;
	output wire M_AXI_GP_WVALID;
	output wire [255:0] M_AXI_GP_WDATA;
	output wire [31:0] M_AXI_GP_WSTRB;
	output wire M_AXI_GP_WLAST;
	output wire M_AXI_GP_BREADY;
	input M_AXI_GP_BVALID;
	input [1:0] M_AXI_GP_BID;
	input [1:0] M_AXI_GP_BRESP;
	wire _sinkBuffer_8_io_deq_valid;
	wire [1:0] _sinkBuffer_8_io_deq_bits_id;
	wire [1:0] _sinkBuffer_8_io_deq_bits_resp;
	wire _sourceBuffer_12_io_enq_ready;
	wire _sourceBuffer_11_io_enq_ready;
	wire _sinkBuffer_7_io_deq_valid;
	wire [1:0] _sinkBuffer_7_io_deq_bits_id;
	wire [255:0] _sinkBuffer_7_io_deq_bits_data;
	wire [1:0] _sinkBuffer_7_io_deq_bits_resp;
	wire _sinkBuffer_7_io_deq_bits_last;
	wire _sourceBuffer_10_io_enq_ready;
	wire _sinkBuffer_6_io_deq_valid;
	wire _sourceBuffer_9_io_enq_ready;
	wire _sourceBuffer_8_io_enq_ready;
	wire _sinkBuffer_5_io_deq_valid;
	wire [255:0] _sinkBuffer_5_io_deq_bits_data;
	wire [1:0] _sinkBuffer_5_io_deq_bits_resp;
	wire _sinkBuffer_5_io_deq_bits_last;
	wire _sourceBuffer_7_io_enq_ready;
	wire _sinkBuffer_4_io_enq_ready;
	wire _sinkBuffer_4_io_deq_valid;
	wire _sourceBuffer_6_io_enq_ready;
	wire _sourceBuffer_6_io_deq_valid;
	wire [255:0] _sourceBuffer_6_io_deq_bits_data;
	wire [31:0] _sourceBuffer_6_io_deq_bits_strb;
	wire _sourceBuffer_6_io_deq_bits_last;
	wire _sourceBuffer_5_io_enq_ready;
	wire _sourceBuffer_5_io_deq_valid;
	wire [63:0] _sourceBuffer_5_io_deq_bits_addr;
	wire [7:0] _sourceBuffer_5_io_deq_bits_len;
	wire [2:0] _sourceBuffer_5_io_deq_bits_size;
	wire [1:0] _sourceBuffer_5_io_deq_bits_burst;
	wire _sourceBuffer_5_io_deq_bits_lock;
	wire [3:0] _sourceBuffer_5_io_deq_bits_cache;
	wire [2:0] _sourceBuffer_5_io_deq_bits_prot;
	wire [3:0] _sourceBuffer_5_io_deq_bits_qos;
	wire [3:0] _sourceBuffer_5_io_deq_bits_region;
	wire _sinkBuffer_3_io_enq_ready;
	wire _sinkBuffer_3_io_deq_valid;
	wire [255:0] _sinkBuffer_3_io_deq_bits_data;
	wire [1:0] _sinkBuffer_3_io_deq_bits_resp;
	wire _sinkBuffer_3_io_deq_bits_last;
	wire _sourceBuffer_4_io_enq_ready;
	wire _sourceBuffer_4_io_deq_valid;
	wire [63:0] _sourceBuffer_4_io_deq_bits_addr;
	wire [7:0] _sourceBuffer_4_io_deq_bits_len;
	wire [2:0] _sourceBuffer_4_io_deq_bits_size;
	wire [1:0] _sourceBuffer_4_io_deq_bits_burst;
	wire _sourceBuffer_4_io_deq_bits_lock;
	wire [3:0] _sourceBuffer_4_io_deq_bits_cache;
	wire [2:0] _sourceBuffer_4_io_deq_bits_prot;
	wire [3:0] _sourceBuffer_4_io_deq_bits_qos;
	wire [3:0] _sourceBuffer_4_io_deq_bits_region;
	wire _sinkBuffer_2_io_enq_ready;
	wire _sourceBuffer_3_io_deq_valid;
	wire [255:0] _sourceBuffer_3_io_deq_bits_data;
	wire [31:0] _sourceBuffer_3_io_deq_bits_strb;
	wire _sourceBuffer_3_io_deq_bits_last;
	wire _sourceBuffer_2_io_deq_valid;
	wire [33:0] _sourceBuffer_2_io_deq_bits_addr;
	wire [7:0] _sourceBuffer_2_io_deq_bits_len;
	wire [2:0] _sourceBuffer_2_io_deq_bits_size;
	wire [1:0] _sourceBuffer_2_io_deq_bits_burst;
	wire _sourceBuffer_2_io_deq_bits_lock;
	wire [3:0] _sourceBuffer_2_io_deq_bits_cache;
	wire [2:0] _sourceBuffer_2_io_deq_bits_prot;
	wire [3:0] _sourceBuffer_2_io_deq_bits_qos;
	wire [3:0] _sourceBuffer_2_io_deq_bits_region;
	wire _sinkBuffer_1_io_enq_ready;
	wire _sinkBuffer_1_io_deq_valid;
	wire [255:0] _sinkBuffer_1_io_deq_bits_data;
	wire _sourceBuffer_1_io_enq_ready;
	wire _sourceBuffer_1_io_deq_valid;
	wire [33:0] _sourceBuffer_1_io_deq_bits_addr;
	wire [7:0] _sourceBuffer_1_io_deq_bits_len;
	wire [2:0] _sourceBuffer_1_io_deq_bits_size;
	wire [1:0] _sourceBuffer_1_io_deq_bits_burst;
	wire _sourceBuffer_1_io_deq_bits_lock;
	wire [3:0] _sourceBuffer_1_io_deq_bits_cache;
	wire [2:0] _sourceBuffer_1_io_deq_bits_prot;
	wire [3:0] _sourceBuffer_1_io_deq_bits_qos;
	wire [3:0] _sourceBuffer_1_io_deq_bits_region;
	wire _responseBuffer_s_axi_ar_ready;
	wire _responseBuffer_s_axi_r_valid;
	wire [255:0] _responseBuffer_s_axi_r_bits_data;
	wire [1:0] _responseBuffer_s_axi_r_bits_resp;
	wire _responseBuffer_s_axi_r_bits_last;
	wire _responseBuffer_s_axi_aw_ready;
	wire _responseBuffer_s_axi_w_ready;
	wire _responseBuffer_s_axi_b_valid;
	wire _responseBuffer_m_axi_ar_valid;
	wire [63:0] _responseBuffer_m_axi_ar_bits_addr;
	wire [7:0] _responseBuffer_m_axi_ar_bits_len;
	wire [2:0] _responseBuffer_m_axi_ar_bits_size;
	wire [1:0] _responseBuffer_m_axi_ar_bits_burst;
	wire _responseBuffer_m_axi_ar_bits_lock;
	wire [3:0] _responseBuffer_m_axi_ar_bits_cache;
	wire [2:0] _responseBuffer_m_axi_ar_bits_prot;
	wire [3:0] _responseBuffer_m_axi_ar_bits_qos;
	wire [3:0] _responseBuffer_m_axi_ar_bits_region;
	wire _responseBuffer_m_axi_r_ready;
	wire _responseBuffer_m_axi_aw_valid;
	wire [63:0] _responseBuffer_m_axi_aw_bits_addr;
	wire [7:0] _responseBuffer_m_axi_aw_bits_len;
	wire [2:0] _responseBuffer_m_axi_aw_bits_size;
	wire [1:0] _responseBuffer_m_axi_aw_bits_burst;
	wire _responseBuffer_m_axi_aw_bits_lock;
	wire [3:0] _responseBuffer_m_axi_aw_bits_cache;
	wire [2:0] _responseBuffer_m_axi_aw_bits_prot;
	wire [3:0] _responseBuffer_m_axi_aw_bits_qos;
	wire [3:0] _responseBuffer_m_axi_aw_bits_region;
	wire _responseBuffer_m_axi_w_valid;
	wire [255:0] _responseBuffer_m_axi_w_bits_data;
	wire [31:0] _responseBuffer_m_axi_w_bits_strb;
	wire _responseBuffer_m_axi_w_bits_last;
	wire _responseBuffer_m_axi_b_ready;
	wire _sinkBuffer_io_enq_ready;
	wire _sinkBuffer_io_deq_valid;
	wire [63:0] _sinkBuffer_io_deq_bits;
	wire _sourceBuffer_io_enq_ready;
	wire _sourceBuffer_io_deq_valid;
	wire [447:0] _sourceBuffer_io_deq_bits;
	wire _controlDemux_m_axil_0_ar_valid;
	wire [11:0] _controlDemux_m_axil_0_ar_bits_addr;
	wire [2:0] _controlDemux_m_axil_0_ar_bits_prot;
	wire _controlDemux_m_axil_0_r_ready;
	wire _controlDemux_m_axil_0_aw_valid;
	wire [11:0] _controlDemux_m_axil_0_aw_bits_addr;
	wire [2:0] _controlDemux_m_axil_0_aw_bits_prot;
	wire _controlDemux_m_axil_0_w_valid;
	wire [31:0] _controlDemux_m_axil_0_w_bits_data;
	wire [3:0] _controlDemux_m_axil_0_w_bits_strb;
	wire _controlDemux_m_axil_0_b_ready;
	wire _controlDemux_m_axil_1_ar_valid;
	wire [11:0] _controlDemux_m_axil_1_ar_bits_addr;
	wire [2:0] _controlDemux_m_axil_1_ar_bits_prot;
	wire _controlDemux_m_axil_1_r_ready;
	wire _controlDemux_m_axil_1_aw_valid;
	wire [11:0] _controlDemux_m_axil_1_aw_bits_addr;
	wire [2:0] _controlDemux_m_axil_1_aw_bits_prot;
	wire _controlDemux_m_axil_1_w_valid;
	wire [31:0] _controlDemux_m_axil_1_w_bits_data;
	wire [3:0] _controlDemux_m_axil_1_w_bits_strb;
	wire _controlDemux_m_axil_1_b_ready;
	wire _controlDemux_m_axil_2_ar_valid;
	wire [11:0] _controlDemux_m_axil_2_ar_bits_addr;
	wire [2:0] _controlDemux_m_axil_2_ar_bits_prot;
	wire _controlDemux_m_axil_2_r_ready;
	wire _controlDemux_m_axil_2_aw_valid;
	wire [11:0] _controlDemux_m_axil_2_aw_bits_addr;
	wire [2:0] _controlDemux_m_axil_2_aw_bits_prot;
	wire _controlDemux_m_axil_2_w_valid;
	wire [31:0] _controlDemux_m_axil_2_w_bits_data;
	wire [3:0] _controlDemux_m_axil_2_w_bits_strb;
	wire _controlDemux_m_axil_2_b_ready;
	wire _stripe1_S_AXI_CONTROL_ARREADY;
	wire _stripe1_S_AXI_CONTROL_RVALID;
	wire [31:0] _stripe1_S_AXI_CONTROL_RDATA;
	wire [1:0] _stripe1_S_AXI_CONTROL_RRESP;
	wire _stripe1_S_AXI_CONTROL_AWREADY;
	wire _stripe1_S_AXI_CONTROL_WREADY;
	wire _stripe1_S_AXI_CONTROL_BVALID;
	wire [1:0] _stripe1_S_AXI_CONTROL_BRESP;
	wire _stripe0_S_AXI_CONTROL_ARREADY;
	wire _stripe0_S_AXI_CONTROL_RVALID;
	wire [31:0] _stripe0_S_AXI_CONTROL_RDATA;
	wire [1:0] _stripe0_S_AXI_CONTROL_RRESP;
	wire _stripe0_S_AXI_CONTROL_AWREADY;
	wire _stripe0_S_AXI_CONTROL_WREADY;
	wire _stripe0_S_AXI_CONTROL_BVALID;
	wire [1:0] _stripe0_S_AXI_CONTROL_BRESP;
	wire _stripe0_S_AXI_0_ARREADY;
	wire _stripe0_S_AXI_0_RVALID;
	wire [255:0] _stripe0_S_AXI_0_RDATA;
	wire [1:0] _stripe0_S_AXI_0_RRESP;
	wire _stripe0_S_AXI_0_RLAST;
	wire _stripe0_S_AXI_0_AWREADY;
	wire _stripe0_S_AXI_0_WREADY;
	wire _stripe0_S_AXI_0_BVALID;
	wire _stripe0_M_AXI_0_ARVALID;
	wire [33:0] _stripe0_M_AXI_0_ARADDR;
	wire [7:0] _stripe0_M_AXI_0_ARLEN;
	wire [2:0] _stripe0_M_AXI_0_ARSIZE;
	wire [1:0] _stripe0_M_AXI_0_ARBURST;
	wire _stripe0_M_AXI_0_ARLOCK;
	wire [3:0] _stripe0_M_AXI_0_ARCACHE;
	wire [2:0] _stripe0_M_AXI_0_ARPROT;
	wire [3:0] _stripe0_M_AXI_0_ARQOS;
	wire [3:0] _stripe0_M_AXI_0_ARREGION;
	wire _stripe0_M_AXI_0_RREADY;
	wire _stripe0_M_AXI_0_AWVALID;
	wire [33:0] _stripe0_M_AXI_0_AWADDR;
	wire [7:0] _stripe0_M_AXI_0_AWLEN;
	wire [2:0] _stripe0_M_AXI_0_AWSIZE;
	wire [1:0] _stripe0_M_AXI_0_AWBURST;
	wire _stripe0_M_AXI_0_AWLOCK;
	wire [3:0] _stripe0_M_AXI_0_AWCACHE;
	wire [2:0] _stripe0_M_AXI_0_AWPROT;
	wire [3:0] _stripe0_M_AXI_0_AWQOS;
	wire [3:0] _stripe0_M_AXI_0_AWREGION;
	wire _stripe0_M_AXI_0_WVALID;
	wire [255:0] _stripe0_M_AXI_0_WDATA;
	wire [31:0] _stripe0_M_AXI_0_WSTRB;
	wire _stripe0_M_AXI_0_WLAST;
	wire _stripe0_M_AXI_0_BREADY;
	wire _memAdapter0_s_axil_ar_ready;
	wire _memAdapter0_s_axil_r_valid;
	wire [31:0] _memAdapter0_s_axil_r_bits_data;
	wire [1:0] _memAdapter0_s_axil_r_bits_resp;
	wire _memAdapter0_s_axil_aw_ready;
	wire _memAdapter0_s_axil_w_ready;
	wire _memAdapter0_s_axil_b_valid;
	wire [1:0] _memAdapter0_s_axil_b_bits_resp;
	wire _memAdapter0_source_ready;
	wire _memAdapter0_sink_valid;
	wire [447:0] _memAdapter0_sink_bits;
	wire _spmv0_sourceTask_ready;
	wire _spmv0_sinkDone_valid;
	wire [63:0] _spmv0_sinkDone_bits;
	wire _spmv0_m_axi_ls_ar_valid;
	wire [63:0] _spmv0_m_axi_ls_ar_bits_addr;
	wire [7:0] _spmv0_m_axi_ls_ar_bits_len;
	wire [2:0] _spmv0_m_axi_ls_ar_bits_size;
	wire [1:0] _spmv0_m_axi_ls_ar_bits_burst;
	wire _spmv0_m_axi_ls_ar_bits_lock;
	wire [3:0] _spmv0_m_axi_ls_ar_bits_cache;
	wire [2:0] _spmv0_m_axi_ls_ar_bits_prot;
	wire [3:0] _spmv0_m_axi_ls_ar_bits_qos;
	wire [3:0] _spmv0_m_axi_ls_ar_bits_region;
	wire _spmv0_m_axi_ls_r_ready;
	wire _spmv0_m_axi_gp_ar_valid;
	wire [1:0] _spmv0_m_axi_gp_ar_bits_id;
	wire [63:0] _spmv0_m_axi_gp_ar_bits_addr;
	wire [3:0] _spmv0_m_axi_gp_ar_bits_len;
	wire [2:0] _spmv0_m_axi_gp_ar_bits_size;
	wire [1:0] _spmv0_m_axi_gp_ar_bits_burst;
	wire _spmv0_m_axi_gp_r_ready;
	wire _spmv0_m_axi_gp_aw_valid;
	wire [1:0] _spmv0_m_axi_gp_aw_bits_id;
	wire [63:0] _spmv0_m_axi_gp_aw_bits_addr;
	wire [3:0] _spmv0_m_axi_gp_aw_bits_len;
	wire [2:0] _spmv0_m_axi_gp_aw_bits_size;
	wire [1:0] _spmv0_m_axi_gp_aw_bits_burst;
	wire _spmv0_m_axi_gp_w_valid;
	wire [255:0] _spmv0_m_axi_gp_w_bits_data;
	wire [31:0] _spmv0_m_axi_gp_w_bits_strb;
	wire _spmv0_m_axi_gp_w_bits_last;
	wire _spmv0_m_axi_gp_b_ready;
	Spmv spmv0(
		.clock(clock),
		.reset(reset),
		.sourceTask_ready(_spmv0_sourceTask_ready),
		.sourceTask_valid(_sourceBuffer_io_deq_valid),
		.sourceTask_bits_ptrValues(_sourceBuffer_io_deq_bits[447:384]),
		.sourceTask_bits_ptrColumnIndices(_sourceBuffer_io_deq_bits[383:320]),
		.sourceTask_bits_ptrRowLengths(_sourceBuffer_io_deq_bits[319:256]),
		.sourceTask_bits_ptrInputVector(_sourceBuffer_io_deq_bits[255:192]),
		.sourceTask_bits_ptrOutputVector(_sourceBuffer_io_deq_bits[191:128]),
		.sourceTask_bits_numValues(_sourceBuffer_io_deq_bits[127:64]),
		.sourceTask_bits_numRows(_sourceBuffer_io_deq_bits[63:0]),
		.sinkDone_ready(_sinkBuffer_io_enq_ready),
		.sinkDone_valid(_spmv0_sinkDone_valid),
		.sinkDone_bits(_spmv0_sinkDone_bits),
		.m_axi_ls_ar_ready(_sourceBuffer_1_io_enq_ready),
		.m_axi_ls_ar_valid(_spmv0_m_axi_ls_ar_valid),
		.m_axi_ls_ar_bits_addr(_spmv0_m_axi_ls_ar_bits_addr),
		.m_axi_ls_ar_bits_len(_spmv0_m_axi_ls_ar_bits_len),
		.m_axi_ls_ar_bits_size(_spmv0_m_axi_ls_ar_bits_size),
		.m_axi_ls_ar_bits_burst(_spmv0_m_axi_ls_ar_bits_burst),
		.m_axi_ls_ar_bits_lock(_spmv0_m_axi_ls_ar_bits_lock),
		.m_axi_ls_ar_bits_cache(_spmv0_m_axi_ls_ar_bits_cache),
		.m_axi_ls_ar_bits_prot(_spmv0_m_axi_ls_ar_bits_prot),
		.m_axi_ls_ar_bits_qos(_spmv0_m_axi_ls_ar_bits_qos),
		.m_axi_ls_ar_bits_region(_spmv0_m_axi_ls_ar_bits_region),
		.m_axi_ls_r_ready(_spmv0_m_axi_ls_r_ready),
		.m_axi_ls_r_valid(_sinkBuffer_1_io_deq_valid),
		.m_axi_ls_r_bits_data(_sinkBuffer_1_io_deq_bits_data),
		.m_axi_gp_ar_ready(_sourceBuffer_10_io_enq_ready),
		.m_axi_gp_ar_valid(_spmv0_m_axi_gp_ar_valid),
		.m_axi_gp_ar_bits_id(_spmv0_m_axi_gp_ar_bits_id),
		.m_axi_gp_ar_bits_addr(_spmv0_m_axi_gp_ar_bits_addr),
		.m_axi_gp_ar_bits_len(_spmv0_m_axi_gp_ar_bits_len),
		.m_axi_gp_ar_bits_size(_spmv0_m_axi_gp_ar_bits_size),
		.m_axi_gp_ar_bits_burst(_spmv0_m_axi_gp_ar_bits_burst),
		.m_axi_gp_r_ready(_spmv0_m_axi_gp_r_ready),
		.m_axi_gp_r_valid(_sinkBuffer_7_io_deq_valid),
		.m_axi_gp_r_bits_id(_sinkBuffer_7_io_deq_bits_id),
		.m_axi_gp_r_bits_data(_sinkBuffer_7_io_deq_bits_data),
		.m_axi_gp_r_bits_resp(_sinkBuffer_7_io_deq_bits_resp),
		.m_axi_gp_r_bits_last(_sinkBuffer_7_io_deq_bits_last),
		.m_axi_gp_aw_ready(_sourceBuffer_11_io_enq_ready),
		.m_axi_gp_aw_valid(_spmv0_m_axi_gp_aw_valid),
		.m_axi_gp_aw_bits_id(_spmv0_m_axi_gp_aw_bits_id),
		.m_axi_gp_aw_bits_addr(_spmv0_m_axi_gp_aw_bits_addr),
		.m_axi_gp_aw_bits_len(_spmv0_m_axi_gp_aw_bits_len),
		.m_axi_gp_aw_bits_size(_spmv0_m_axi_gp_aw_bits_size),
		.m_axi_gp_aw_bits_burst(_spmv0_m_axi_gp_aw_bits_burst),
		.m_axi_gp_w_ready(_sourceBuffer_12_io_enq_ready),
		.m_axi_gp_w_valid(_spmv0_m_axi_gp_w_valid),
		.m_axi_gp_w_bits_data(_spmv0_m_axi_gp_w_bits_data),
		.m_axi_gp_w_bits_strb(_spmv0_m_axi_gp_w_bits_strb),
		.m_axi_gp_w_bits_last(_spmv0_m_axi_gp_w_bits_last),
		.m_axi_gp_b_ready(_spmv0_m_axi_gp_b_ready),
		.m_axi_gp_b_valid(_sinkBuffer_8_io_deq_valid),
		.m_axi_gp_b_bits_id(_sinkBuffer_8_io_deq_bits_id),
		.m_axi_gp_b_bits_resp(_sinkBuffer_8_io_deq_bits_resp)
	);
	MemAdapter memAdapter0(
		.clock(clock),
		.reset(reset),
		.s_axil_ar_ready(_memAdapter0_s_axil_ar_ready),
		.s_axil_ar_valid(_controlDemux_m_axil_0_ar_valid),
		.s_axil_ar_bits_addr(_controlDemux_m_axil_0_ar_bits_addr[9:0]),
		.s_axil_ar_bits_prot(_controlDemux_m_axil_0_ar_bits_prot),
		.s_axil_r_ready(_controlDemux_m_axil_0_r_ready),
		.s_axil_r_valid(_memAdapter0_s_axil_r_valid),
		.s_axil_r_bits_data(_memAdapter0_s_axil_r_bits_data),
		.s_axil_r_bits_resp(_memAdapter0_s_axil_r_bits_resp),
		.s_axil_aw_ready(_memAdapter0_s_axil_aw_ready),
		.s_axil_aw_valid(_controlDemux_m_axil_0_aw_valid),
		.s_axil_aw_bits_addr(_controlDemux_m_axil_0_aw_bits_addr[9:0]),
		.s_axil_aw_bits_prot(_controlDemux_m_axil_0_aw_bits_prot),
		.s_axil_w_ready(_memAdapter0_s_axil_w_ready),
		.s_axil_w_valid(_controlDemux_m_axil_0_w_valid),
		.s_axil_w_bits_data(_controlDemux_m_axil_0_w_bits_data),
		.s_axil_w_bits_strb(_controlDemux_m_axil_0_w_bits_strb),
		.s_axil_b_ready(_controlDemux_m_axil_0_b_ready),
		.s_axil_b_valid(_memAdapter0_s_axil_b_valid),
		.s_axil_b_bits_resp(_memAdapter0_s_axil_b_bits_resp),
		.source_ready(_memAdapter0_source_ready),
		.source_valid(_sinkBuffer_io_deq_valid),
		.source_bits(_sinkBuffer_io_deq_bits),
		.sink_ready(_sourceBuffer_io_enq_ready),
		.sink_valid(_memAdapter0_sink_valid),
		.sink_bits(_memAdapter0_sink_bits)
	);
	Stripe stripe0(
		.clock(clock),
		.reset(reset),
		.S_AXI_CONTROL_ARREADY(_stripe0_S_AXI_CONTROL_ARREADY),
		.S_AXI_CONTROL_ARVALID(_controlDemux_m_axil_1_ar_valid),
		.S_AXI_CONTROL_ARADDR(_controlDemux_m_axil_1_ar_bits_addr[9:0]),
		.S_AXI_CONTROL_ARPROT(_controlDemux_m_axil_1_ar_bits_prot),
		.S_AXI_CONTROL_RREADY(_controlDemux_m_axil_1_r_ready),
		.S_AXI_CONTROL_RVALID(_stripe0_S_AXI_CONTROL_RVALID),
		.S_AXI_CONTROL_RDATA(_stripe0_S_AXI_CONTROL_RDATA),
		.S_AXI_CONTROL_RRESP(_stripe0_S_AXI_CONTROL_RRESP),
		.S_AXI_CONTROL_AWREADY(_stripe0_S_AXI_CONTROL_AWREADY),
		.S_AXI_CONTROL_AWVALID(_controlDemux_m_axil_1_aw_valid),
		.S_AXI_CONTROL_AWADDR(_controlDemux_m_axil_1_aw_bits_addr[9:0]),
		.S_AXI_CONTROL_AWPROT(_controlDemux_m_axil_1_aw_bits_prot),
		.S_AXI_CONTROL_WREADY(_stripe0_S_AXI_CONTROL_WREADY),
		.S_AXI_CONTROL_WVALID(_controlDemux_m_axil_1_w_valid),
		.S_AXI_CONTROL_WDATA(_controlDemux_m_axil_1_w_bits_data),
		.S_AXI_CONTROL_WSTRB(_controlDemux_m_axil_1_w_bits_strb),
		.S_AXI_CONTROL_BREADY(_controlDemux_m_axil_1_b_ready),
		.S_AXI_CONTROL_BVALID(_stripe0_S_AXI_CONTROL_BVALID),
		.S_AXI_CONTROL_BRESP(_stripe0_S_AXI_CONTROL_BRESP),
		.S_AXI_0_ARREADY(_stripe0_S_AXI_0_ARREADY),
		.S_AXI_0_ARVALID(_sourceBuffer_1_io_deq_valid),
		.S_AXI_0_ARADDR(_sourceBuffer_1_io_deq_bits_addr),
		.S_AXI_0_ARLEN(_sourceBuffer_1_io_deq_bits_len),
		.S_AXI_0_ARSIZE(_sourceBuffer_1_io_deq_bits_size),
		.S_AXI_0_ARBURST(_sourceBuffer_1_io_deq_bits_burst),
		.S_AXI_0_ARLOCK(_sourceBuffer_1_io_deq_bits_lock),
		.S_AXI_0_ARCACHE(_sourceBuffer_1_io_deq_bits_cache),
		.S_AXI_0_ARPROT(_sourceBuffer_1_io_deq_bits_prot),
		.S_AXI_0_ARQOS(_sourceBuffer_1_io_deq_bits_qos),
		.S_AXI_0_ARREGION(_sourceBuffer_1_io_deq_bits_region),
		.S_AXI_0_RREADY(_sinkBuffer_1_io_enq_ready),
		.S_AXI_0_RVALID(_stripe0_S_AXI_0_RVALID),
		.S_AXI_0_RDATA(_stripe0_S_AXI_0_RDATA),
		.S_AXI_0_RRESP(_stripe0_S_AXI_0_RRESP),
		.S_AXI_0_RLAST(_stripe0_S_AXI_0_RLAST),
		.S_AXI_0_AWREADY(_stripe0_S_AXI_0_AWREADY),
		.S_AXI_0_AWVALID(_sourceBuffer_2_io_deq_valid),
		.S_AXI_0_AWADDR(_sourceBuffer_2_io_deq_bits_addr),
		.S_AXI_0_AWLEN(_sourceBuffer_2_io_deq_bits_len),
		.S_AXI_0_AWSIZE(_sourceBuffer_2_io_deq_bits_size),
		.S_AXI_0_AWBURST(_sourceBuffer_2_io_deq_bits_burst),
		.S_AXI_0_AWLOCK(_sourceBuffer_2_io_deq_bits_lock),
		.S_AXI_0_AWCACHE(_sourceBuffer_2_io_deq_bits_cache),
		.S_AXI_0_AWPROT(_sourceBuffer_2_io_deq_bits_prot),
		.S_AXI_0_AWQOS(_sourceBuffer_2_io_deq_bits_qos),
		.S_AXI_0_AWREGION(_sourceBuffer_2_io_deq_bits_region),
		.S_AXI_0_WREADY(_stripe0_S_AXI_0_WREADY),
		.S_AXI_0_WVALID(_sourceBuffer_3_io_deq_valid),
		.S_AXI_0_WDATA(_sourceBuffer_3_io_deq_bits_data),
		.S_AXI_0_WSTRB(_sourceBuffer_3_io_deq_bits_strb),
		.S_AXI_0_WLAST(_sourceBuffer_3_io_deq_bits_last),
		.S_AXI_0_BREADY(_sinkBuffer_2_io_enq_ready),
		.S_AXI_0_BVALID(_stripe0_S_AXI_0_BVALID),
		.M_AXI_0_ARREADY(_sourceBuffer_4_io_enq_ready),
		.M_AXI_0_ARVALID(_stripe0_M_AXI_0_ARVALID),
		.M_AXI_0_ARADDR(_stripe0_M_AXI_0_ARADDR),
		.M_AXI_0_ARLEN(_stripe0_M_AXI_0_ARLEN),
		.M_AXI_0_ARSIZE(_stripe0_M_AXI_0_ARSIZE),
		.M_AXI_0_ARBURST(_stripe0_M_AXI_0_ARBURST),
		.M_AXI_0_ARLOCK(_stripe0_M_AXI_0_ARLOCK),
		.M_AXI_0_ARCACHE(_stripe0_M_AXI_0_ARCACHE),
		.M_AXI_0_ARPROT(_stripe0_M_AXI_0_ARPROT),
		.M_AXI_0_ARQOS(_stripe0_M_AXI_0_ARQOS),
		.M_AXI_0_ARREGION(_stripe0_M_AXI_0_ARREGION),
		.M_AXI_0_RREADY(_stripe0_M_AXI_0_RREADY),
		.M_AXI_0_RVALID(_sinkBuffer_3_io_deq_valid),
		.M_AXI_0_RDATA(_sinkBuffer_3_io_deq_bits_data),
		.M_AXI_0_RRESP(_sinkBuffer_3_io_deq_bits_resp),
		.M_AXI_0_RLAST(_sinkBuffer_3_io_deq_bits_last),
		.M_AXI_0_AWREADY(_sourceBuffer_5_io_enq_ready),
		.M_AXI_0_AWVALID(_stripe0_M_AXI_0_AWVALID),
		.M_AXI_0_AWADDR(_stripe0_M_AXI_0_AWADDR),
		.M_AXI_0_AWLEN(_stripe0_M_AXI_0_AWLEN),
		.M_AXI_0_AWSIZE(_stripe0_M_AXI_0_AWSIZE),
		.M_AXI_0_AWBURST(_stripe0_M_AXI_0_AWBURST),
		.M_AXI_0_AWLOCK(_stripe0_M_AXI_0_AWLOCK),
		.M_AXI_0_AWCACHE(_stripe0_M_AXI_0_AWCACHE),
		.M_AXI_0_AWPROT(_stripe0_M_AXI_0_AWPROT),
		.M_AXI_0_AWQOS(_stripe0_M_AXI_0_AWQOS),
		.M_AXI_0_AWREGION(_stripe0_M_AXI_0_AWREGION),
		.M_AXI_0_WREADY(_sourceBuffer_6_io_enq_ready),
		.M_AXI_0_WVALID(_stripe0_M_AXI_0_WVALID),
		.M_AXI_0_WDATA(_stripe0_M_AXI_0_WDATA),
		.M_AXI_0_WSTRB(_stripe0_M_AXI_0_WSTRB),
		.M_AXI_0_WLAST(_stripe0_M_AXI_0_WLAST),
		.M_AXI_0_BREADY(_stripe0_M_AXI_0_BREADY),
		.M_AXI_0_BVALID(_sinkBuffer_4_io_deq_valid)
	);
	Stripe_1 stripe1(
		.clock(clock),
		.reset(reset),
		.S_AXI_CONTROL_ARREADY(_stripe1_S_AXI_CONTROL_ARREADY),
		.S_AXI_CONTROL_ARVALID(_controlDemux_m_axil_2_ar_valid),
		.S_AXI_CONTROL_ARADDR(_controlDemux_m_axil_2_ar_bits_addr[9:0]),
		.S_AXI_CONTROL_ARPROT(_controlDemux_m_axil_2_ar_bits_prot),
		.S_AXI_CONTROL_RREADY(_controlDemux_m_axil_2_r_ready),
		.S_AXI_CONTROL_RVALID(_stripe1_S_AXI_CONTROL_RVALID),
		.S_AXI_CONTROL_RDATA(_stripe1_S_AXI_CONTROL_RDATA),
		.S_AXI_CONTROL_RRESP(_stripe1_S_AXI_CONTROL_RRESP),
		.S_AXI_CONTROL_AWREADY(_stripe1_S_AXI_CONTROL_AWREADY),
		.S_AXI_CONTROL_AWVALID(_controlDemux_m_axil_2_aw_valid),
		.S_AXI_CONTROL_AWADDR(_controlDemux_m_axil_2_aw_bits_addr[9:0]),
		.S_AXI_CONTROL_AWPROT(_controlDemux_m_axil_2_aw_bits_prot),
		.S_AXI_CONTROL_WREADY(_stripe1_S_AXI_CONTROL_WREADY),
		.S_AXI_CONTROL_WVALID(_controlDemux_m_axil_2_w_valid),
		.S_AXI_CONTROL_WDATA(_controlDemux_m_axil_2_w_bits_data),
		.S_AXI_CONTROL_WSTRB(_controlDemux_m_axil_2_w_bits_strb),
		.S_AXI_CONTROL_BREADY(_controlDemux_m_axil_2_b_ready),
		.S_AXI_CONTROL_BVALID(_stripe1_S_AXI_CONTROL_BVALID),
		.S_AXI_CONTROL_BRESP(_stripe1_S_AXI_CONTROL_BRESP),
		.S_AXI_0_ARREADY(S_AXI_STRIPED_ARREADY),
		.S_AXI_0_ARVALID(S_AXI_STRIPED_ARVALID),
		.S_AXI_0_ARID(S_AXI_STRIPED_ARID),
		.S_AXI_0_ARADDR(S_AXI_STRIPED_ARADDR),
		.S_AXI_0_ARLEN(S_AXI_STRIPED_ARLEN),
		.S_AXI_0_ARSIZE(S_AXI_STRIPED_ARSIZE),
		.S_AXI_0_ARBURST(S_AXI_STRIPED_ARBURST),
		.S_AXI_0_RREADY(S_AXI_STRIPED_RREADY),
		.S_AXI_0_RVALID(S_AXI_STRIPED_RVALID),
		.S_AXI_0_RID(S_AXI_STRIPED_RID),
		.S_AXI_0_RDATA(S_AXI_STRIPED_RDATA),
		.S_AXI_0_RRESP(S_AXI_STRIPED_RRESP),
		.S_AXI_0_RLAST(S_AXI_STRIPED_RLAST),
		.S_AXI_0_AWREADY(S_AXI_STRIPED_AWREADY),
		.S_AXI_0_AWVALID(S_AXI_STRIPED_AWVALID),
		.S_AXI_0_AWID(S_AXI_STRIPED_AWID),
		.S_AXI_0_AWADDR(S_AXI_STRIPED_AWADDR),
		.S_AXI_0_AWLEN(S_AXI_STRIPED_AWLEN),
		.S_AXI_0_AWSIZE(S_AXI_STRIPED_AWSIZE),
		.S_AXI_0_AWBURST(S_AXI_STRIPED_AWBURST),
		.S_AXI_0_WREADY(S_AXI_STRIPED_WREADY),
		.S_AXI_0_WVALID(S_AXI_STRIPED_WVALID),
		.S_AXI_0_WDATA(S_AXI_STRIPED_WDATA),
		.S_AXI_0_WSTRB(S_AXI_STRIPED_WSTRB),
		.S_AXI_0_WLAST(S_AXI_STRIPED_WLAST),
		.S_AXI_0_BREADY(S_AXI_STRIPED_BREADY),
		.S_AXI_0_BVALID(S_AXI_STRIPED_BVALID),
		.S_AXI_0_BID(S_AXI_STRIPED_BID),
		.S_AXI_0_BRESP(S_AXI_STRIPED_BRESP),
		.M_AXI_0_ARREADY(M_AXI_STRIPED_ARREADY),
		.M_AXI_0_ARVALID(M_AXI_STRIPED_ARVALID),
		.M_AXI_0_ARID(M_AXI_STRIPED_ARID),
		.M_AXI_0_ARADDR(M_AXI_STRIPED_ARADDR),
		.M_AXI_0_ARLEN(M_AXI_STRIPED_ARLEN),
		.M_AXI_0_ARSIZE(M_AXI_STRIPED_ARSIZE),
		.M_AXI_0_ARBURST(M_AXI_STRIPED_ARBURST),
		.M_AXI_0_RREADY(M_AXI_STRIPED_RREADY),
		.M_AXI_0_RVALID(M_AXI_STRIPED_RVALID),
		.M_AXI_0_RID(M_AXI_STRIPED_RID),
		.M_AXI_0_RDATA(M_AXI_STRIPED_RDATA),
		.M_AXI_0_RRESP(M_AXI_STRIPED_RRESP),
		.M_AXI_0_RLAST(M_AXI_STRIPED_RLAST),
		.M_AXI_0_AWREADY(M_AXI_STRIPED_AWREADY),
		.M_AXI_0_AWVALID(M_AXI_STRIPED_AWVALID),
		.M_AXI_0_AWID(M_AXI_STRIPED_AWID),
		.M_AXI_0_AWADDR(M_AXI_STRIPED_AWADDR),
		.M_AXI_0_AWLEN(M_AXI_STRIPED_AWLEN),
		.M_AXI_0_AWSIZE(M_AXI_STRIPED_AWSIZE),
		.M_AXI_0_AWBURST(M_AXI_STRIPED_AWBURST),
		.M_AXI_0_WREADY(M_AXI_STRIPED_WREADY),
		.M_AXI_0_WVALID(M_AXI_STRIPED_WVALID),
		.M_AXI_0_WDATA(M_AXI_STRIPED_WDATA),
		.M_AXI_0_WSTRB(M_AXI_STRIPED_WSTRB),
		.M_AXI_0_WLAST(M_AXI_STRIPED_WLAST),
		.M_AXI_0_BREADY(M_AXI_STRIPED_BREADY),
		.M_AXI_0_BVALID(M_AXI_STRIPED_BVALID),
		.M_AXI_0_BID(M_AXI_STRIPED_BID),
		.M_AXI_0_BRESP(M_AXI_STRIPED_BRESP)
	);
	axi4LiteDemux controlDemux(
		.clock(clock),
		.reset(reset),
		.s_axil_ar_ready(S_AXI_CONTROL_ARREADY),
		.s_axil_ar_valid(S_AXI_CONTROL_ARVALID),
		.s_axil_ar_bits_addr(S_AXI_CONTROL_ARADDR),
		.s_axil_ar_bits_prot(S_AXI_CONTROL_ARPROT),
		.s_axil_r_ready(S_AXI_CONTROL_RREADY),
		.s_axil_r_valid(S_AXI_CONTROL_RVALID),
		.s_axil_r_bits_data(S_AXI_CONTROL_RDATA),
		.s_axil_r_bits_resp(S_AXI_CONTROL_RRESP),
		.s_axil_aw_ready(S_AXI_CONTROL_AWREADY),
		.s_axil_aw_valid(S_AXI_CONTROL_AWVALID),
		.s_axil_aw_bits_addr(S_AXI_CONTROL_AWADDR),
		.s_axil_aw_bits_prot(S_AXI_CONTROL_AWPROT),
		.s_axil_w_ready(S_AXI_CONTROL_WREADY),
		.s_axil_w_valid(S_AXI_CONTROL_WVALID),
		.s_axil_w_bits_data(S_AXI_CONTROL_WDATA),
		.s_axil_w_bits_strb(S_AXI_CONTROL_WSTRB),
		.s_axil_b_ready(S_AXI_CONTROL_BREADY),
		.s_axil_b_valid(S_AXI_CONTROL_BVALID),
		.s_axil_b_bits_resp(S_AXI_CONTROL_BRESP),
		.m_axil_0_ar_ready(_memAdapter0_s_axil_ar_ready),
		.m_axil_0_ar_valid(_controlDemux_m_axil_0_ar_valid),
		.m_axil_0_ar_bits_addr(_controlDemux_m_axil_0_ar_bits_addr),
		.m_axil_0_ar_bits_prot(_controlDemux_m_axil_0_ar_bits_prot),
		.m_axil_0_r_ready(_controlDemux_m_axil_0_r_ready),
		.m_axil_0_r_valid(_memAdapter0_s_axil_r_valid),
		.m_axil_0_r_bits_data(_memAdapter0_s_axil_r_bits_data),
		.m_axil_0_r_bits_resp(_memAdapter0_s_axil_r_bits_resp),
		.m_axil_0_aw_ready(_memAdapter0_s_axil_aw_ready),
		.m_axil_0_aw_valid(_controlDemux_m_axil_0_aw_valid),
		.m_axil_0_aw_bits_addr(_controlDemux_m_axil_0_aw_bits_addr),
		.m_axil_0_aw_bits_prot(_controlDemux_m_axil_0_aw_bits_prot),
		.m_axil_0_w_ready(_memAdapter0_s_axil_w_ready),
		.m_axil_0_w_valid(_controlDemux_m_axil_0_w_valid),
		.m_axil_0_w_bits_data(_controlDemux_m_axil_0_w_bits_data),
		.m_axil_0_w_bits_strb(_controlDemux_m_axil_0_w_bits_strb),
		.m_axil_0_b_ready(_controlDemux_m_axil_0_b_ready),
		.m_axil_0_b_valid(_memAdapter0_s_axil_b_valid),
		.m_axil_0_b_bits_resp(_memAdapter0_s_axil_b_bits_resp),
		.m_axil_1_ar_ready(_stripe0_S_AXI_CONTROL_ARREADY),
		.m_axil_1_ar_valid(_controlDemux_m_axil_1_ar_valid),
		.m_axil_1_ar_bits_addr(_controlDemux_m_axil_1_ar_bits_addr),
		.m_axil_1_ar_bits_prot(_controlDemux_m_axil_1_ar_bits_prot),
		.m_axil_1_r_ready(_controlDemux_m_axil_1_r_ready),
		.m_axil_1_r_valid(_stripe0_S_AXI_CONTROL_RVALID),
		.m_axil_1_r_bits_data(_stripe0_S_AXI_CONTROL_RDATA),
		.m_axil_1_r_bits_resp(_stripe0_S_AXI_CONTROL_RRESP),
		.m_axil_1_aw_ready(_stripe0_S_AXI_CONTROL_AWREADY),
		.m_axil_1_aw_valid(_controlDemux_m_axil_1_aw_valid),
		.m_axil_1_aw_bits_addr(_controlDemux_m_axil_1_aw_bits_addr),
		.m_axil_1_aw_bits_prot(_controlDemux_m_axil_1_aw_bits_prot),
		.m_axil_1_w_ready(_stripe0_S_AXI_CONTROL_WREADY),
		.m_axil_1_w_valid(_controlDemux_m_axil_1_w_valid),
		.m_axil_1_w_bits_data(_controlDemux_m_axil_1_w_bits_data),
		.m_axil_1_w_bits_strb(_controlDemux_m_axil_1_w_bits_strb),
		.m_axil_1_b_ready(_controlDemux_m_axil_1_b_ready),
		.m_axil_1_b_valid(_stripe0_S_AXI_CONTROL_BVALID),
		.m_axil_1_b_bits_resp(_stripe0_S_AXI_CONTROL_BRESP),
		.m_axil_2_ar_ready(_stripe1_S_AXI_CONTROL_ARREADY),
		.m_axil_2_ar_valid(_controlDemux_m_axil_2_ar_valid),
		.m_axil_2_ar_bits_addr(_controlDemux_m_axil_2_ar_bits_addr),
		.m_axil_2_ar_bits_prot(_controlDemux_m_axil_2_ar_bits_prot),
		.m_axil_2_r_ready(_controlDemux_m_axil_2_r_ready),
		.m_axil_2_r_valid(_stripe1_S_AXI_CONTROL_RVALID),
		.m_axil_2_r_bits_data(_stripe1_S_AXI_CONTROL_RDATA),
		.m_axil_2_r_bits_resp(_stripe1_S_AXI_CONTROL_RRESP),
		.m_axil_2_aw_ready(_stripe1_S_AXI_CONTROL_AWREADY),
		.m_axil_2_aw_valid(_controlDemux_m_axil_2_aw_valid),
		.m_axil_2_aw_bits_addr(_controlDemux_m_axil_2_aw_bits_addr),
		.m_axil_2_aw_bits_prot(_controlDemux_m_axil_2_aw_bits_prot),
		.m_axil_2_w_ready(_stripe1_S_AXI_CONTROL_WREADY),
		.m_axil_2_w_valid(_controlDemux_m_axil_2_w_valid),
		.m_axil_2_w_bits_data(_controlDemux_m_axil_2_w_bits_data),
		.m_axil_2_w_bits_strb(_controlDemux_m_axil_2_w_bits_strb),
		.m_axil_2_b_ready(_controlDemux_m_axil_2_b_ready),
		.m_axil_2_b_valid(_stripe1_S_AXI_CONTROL_BVALID),
		.m_axil_2_b_bits_resp(_stripe1_S_AXI_CONTROL_BRESP)
	);
	Queue4_UInt448 sourceBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_io_enq_ready),
		.io_enq_valid(_memAdapter0_sink_valid),
		.io_enq_bits(_memAdapter0_sink_bits),
		.io_deq_ready(_spmv0_sourceTask_ready),
		.io_deq_valid(_sourceBuffer_io_deq_valid),
		.io_deq_bits(_sourceBuffer_io_deq_bits)
	);
	Queue4_UInt64 sinkBuffer(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_io_enq_ready),
		.io_enq_valid(_spmv0_sinkDone_valid),
		.io_enq_bits(_spmv0_sinkDone_bits),
		.io_deq_ready(_memAdapter0_source_ready),
		.io_deq_valid(_sinkBuffer_io_deq_valid),
		.io_deq_bits(_sinkBuffer_io_deq_bits)
	);
	ResponseBuffer_3 responseBuffer(
		.clock(clock),
		.reset(reset),
		.s_axi_ar_ready(_responseBuffer_s_axi_ar_ready),
		.s_axi_ar_valid(_sourceBuffer_4_io_deq_valid),
		.s_axi_ar_bits_addr(_sourceBuffer_4_io_deq_bits_addr),
		.s_axi_ar_bits_len(_sourceBuffer_4_io_deq_bits_len),
		.s_axi_ar_bits_size(_sourceBuffer_4_io_deq_bits_size),
		.s_axi_ar_bits_burst(_sourceBuffer_4_io_deq_bits_burst),
		.s_axi_ar_bits_lock(_sourceBuffer_4_io_deq_bits_lock),
		.s_axi_ar_bits_cache(_sourceBuffer_4_io_deq_bits_cache),
		.s_axi_ar_bits_prot(_sourceBuffer_4_io_deq_bits_prot),
		.s_axi_ar_bits_qos(_sourceBuffer_4_io_deq_bits_qos),
		.s_axi_ar_bits_region(_sourceBuffer_4_io_deq_bits_region),
		.s_axi_r_ready(_sinkBuffer_3_io_enq_ready),
		.s_axi_r_valid(_responseBuffer_s_axi_r_valid),
		.s_axi_r_bits_data(_responseBuffer_s_axi_r_bits_data),
		.s_axi_r_bits_resp(_responseBuffer_s_axi_r_bits_resp),
		.s_axi_r_bits_last(_responseBuffer_s_axi_r_bits_last),
		.s_axi_aw_ready(_responseBuffer_s_axi_aw_ready),
		.s_axi_aw_valid(_sourceBuffer_5_io_deq_valid),
		.s_axi_aw_bits_addr(_sourceBuffer_5_io_deq_bits_addr),
		.s_axi_aw_bits_len(_sourceBuffer_5_io_deq_bits_len),
		.s_axi_aw_bits_size(_sourceBuffer_5_io_deq_bits_size),
		.s_axi_aw_bits_burst(_sourceBuffer_5_io_deq_bits_burst),
		.s_axi_aw_bits_lock(_sourceBuffer_5_io_deq_bits_lock),
		.s_axi_aw_bits_cache(_sourceBuffer_5_io_deq_bits_cache),
		.s_axi_aw_bits_prot(_sourceBuffer_5_io_deq_bits_prot),
		.s_axi_aw_bits_qos(_sourceBuffer_5_io_deq_bits_qos),
		.s_axi_aw_bits_region(_sourceBuffer_5_io_deq_bits_region),
		.s_axi_w_ready(_responseBuffer_s_axi_w_ready),
		.s_axi_w_valid(_sourceBuffer_6_io_deq_valid),
		.s_axi_w_bits_data(_sourceBuffer_6_io_deq_bits_data),
		.s_axi_w_bits_strb(_sourceBuffer_6_io_deq_bits_strb),
		.s_axi_w_bits_last(_sourceBuffer_6_io_deq_bits_last),
		.s_axi_b_ready(_sinkBuffer_4_io_enq_ready),
		.s_axi_b_valid(_responseBuffer_s_axi_b_valid),
		.m_axi_ar_ready(_sourceBuffer_7_io_enq_ready),
		.m_axi_ar_valid(_responseBuffer_m_axi_ar_valid),
		.m_axi_ar_bits_addr(_responseBuffer_m_axi_ar_bits_addr),
		.m_axi_ar_bits_len(_responseBuffer_m_axi_ar_bits_len),
		.m_axi_ar_bits_size(_responseBuffer_m_axi_ar_bits_size),
		.m_axi_ar_bits_burst(_responseBuffer_m_axi_ar_bits_burst),
		.m_axi_ar_bits_lock(_responseBuffer_m_axi_ar_bits_lock),
		.m_axi_ar_bits_cache(_responseBuffer_m_axi_ar_bits_cache),
		.m_axi_ar_bits_prot(_responseBuffer_m_axi_ar_bits_prot),
		.m_axi_ar_bits_qos(_responseBuffer_m_axi_ar_bits_qos),
		.m_axi_ar_bits_region(_responseBuffer_m_axi_ar_bits_region),
		.m_axi_r_ready(_responseBuffer_m_axi_r_ready),
		.m_axi_r_valid(_sinkBuffer_5_io_deq_valid),
		.m_axi_r_bits_data(_sinkBuffer_5_io_deq_bits_data),
		.m_axi_r_bits_resp(_sinkBuffer_5_io_deq_bits_resp),
		.m_axi_r_bits_last(_sinkBuffer_5_io_deq_bits_last),
		.m_axi_aw_ready(_sourceBuffer_8_io_enq_ready),
		.m_axi_aw_valid(_responseBuffer_m_axi_aw_valid),
		.m_axi_aw_bits_addr(_responseBuffer_m_axi_aw_bits_addr),
		.m_axi_aw_bits_len(_responseBuffer_m_axi_aw_bits_len),
		.m_axi_aw_bits_size(_responseBuffer_m_axi_aw_bits_size),
		.m_axi_aw_bits_burst(_responseBuffer_m_axi_aw_bits_burst),
		.m_axi_aw_bits_lock(_responseBuffer_m_axi_aw_bits_lock),
		.m_axi_aw_bits_cache(_responseBuffer_m_axi_aw_bits_cache),
		.m_axi_aw_bits_prot(_responseBuffer_m_axi_aw_bits_prot),
		.m_axi_aw_bits_qos(_responseBuffer_m_axi_aw_bits_qos),
		.m_axi_aw_bits_region(_responseBuffer_m_axi_aw_bits_region),
		.m_axi_w_ready(_sourceBuffer_9_io_enq_ready),
		.m_axi_w_valid(_responseBuffer_m_axi_w_valid),
		.m_axi_w_bits_data(_responseBuffer_m_axi_w_bits_data),
		.m_axi_w_bits_strb(_responseBuffer_m_axi_w_bits_strb),
		.m_axi_w_bits_last(_responseBuffer_m_axi_w_bits_last),
		.m_axi_b_ready(_responseBuffer_m_axi_b_ready),
		.m_axi_b_valid(_sinkBuffer_6_io_deq_valid)
	);
	Queue2_ReadAddressChannel_9 sourceBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_1_io_enq_ready),
		.io_enq_valid(_spmv0_m_axi_ls_ar_valid),
		.io_enq_bits_addr(_spmv0_m_axi_ls_ar_bits_addr[33:0]),
		.io_enq_bits_len(_spmv0_m_axi_ls_ar_bits_len),
		.io_enq_bits_size(_spmv0_m_axi_ls_ar_bits_size),
		.io_enq_bits_burst(_spmv0_m_axi_ls_ar_bits_burst),
		.io_enq_bits_lock(_spmv0_m_axi_ls_ar_bits_lock),
		.io_enq_bits_cache(_spmv0_m_axi_ls_ar_bits_cache),
		.io_enq_bits_prot(_spmv0_m_axi_ls_ar_bits_prot),
		.io_enq_bits_qos(_spmv0_m_axi_ls_ar_bits_qos),
		.io_enq_bits_region(_spmv0_m_axi_ls_ar_bits_region),
		.io_deq_ready(_stripe0_S_AXI_0_ARREADY),
		.io_deq_valid(_sourceBuffer_1_io_deq_valid),
		.io_deq_bits_addr(_sourceBuffer_1_io_deq_bits_addr),
		.io_deq_bits_len(_sourceBuffer_1_io_deq_bits_len),
		.io_deq_bits_size(_sourceBuffer_1_io_deq_bits_size),
		.io_deq_bits_burst(_sourceBuffer_1_io_deq_bits_burst),
		.io_deq_bits_lock(_sourceBuffer_1_io_deq_bits_lock),
		.io_deq_bits_cache(_sourceBuffer_1_io_deq_bits_cache),
		.io_deq_bits_prot(_sourceBuffer_1_io_deq_bits_prot),
		.io_deq_bits_qos(_sourceBuffer_1_io_deq_bits_qos),
		.io_deq_bits_region(_sourceBuffer_1_io_deq_bits_region)
	);
	Queue2_ReadDataChannel sinkBuffer_1(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_1_io_enq_ready),
		.io_enq_valid(_stripe0_S_AXI_0_RVALID),
		.io_enq_bits_data(_stripe0_S_AXI_0_RDATA),
		.io_enq_bits_resp(_stripe0_S_AXI_0_RRESP),
		.io_enq_bits_last(_stripe0_S_AXI_0_RLAST),
		.io_deq_ready(_spmv0_m_axi_ls_r_ready),
		.io_deq_valid(_sinkBuffer_1_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_1_io_deq_bits_data),
		.io_deq_bits_resp(),
		.io_deq_bits_last()
	);
	Queue2_WriteAddressChannel_2 sourceBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_deq_ready(_stripe0_S_AXI_0_AWREADY),
		.io_deq_valid(_sourceBuffer_2_io_deq_valid),
		.io_deq_bits_addr(_sourceBuffer_2_io_deq_bits_addr),
		.io_deq_bits_len(_sourceBuffer_2_io_deq_bits_len),
		.io_deq_bits_size(_sourceBuffer_2_io_deq_bits_size),
		.io_deq_bits_burst(_sourceBuffer_2_io_deq_bits_burst),
		.io_deq_bits_lock(_sourceBuffer_2_io_deq_bits_lock),
		.io_deq_bits_cache(_sourceBuffer_2_io_deq_bits_cache),
		.io_deq_bits_prot(_sourceBuffer_2_io_deq_bits_prot),
		.io_deq_bits_qos(_sourceBuffer_2_io_deq_bits_qos),
		.io_deq_bits_region(_sourceBuffer_2_io_deq_bits_region)
	);
	Queue2_WriteDataChannel sourceBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(),
		.io_enq_valid(1'h0),
		.io_enq_bits_data(256'h0000000000000000000000000000000000000000000000000000000000000000),
		.io_enq_bits_strb(32'h00000000),
		.io_enq_bits_last(1'h0),
		.io_deq_ready(_stripe0_S_AXI_0_WREADY),
		.io_deq_valid(_sourceBuffer_3_io_deq_valid),
		.io_deq_bits_data(_sourceBuffer_3_io_deq_bits_data),
		.io_deq_bits_strb(_sourceBuffer_3_io_deq_bits_strb),
		.io_deq_bits_last(_sourceBuffer_3_io_deq_bits_last)
	);
	Queue2_WriteResponseChannel_4 sinkBuffer_2(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_2_io_enq_ready),
		.io_enq_valid(_stripe0_S_AXI_0_BVALID),
		.io_deq_ready(1'h0),
		.io_deq_valid()
	);
	Queue2_ReadAddressChannel_7 sourceBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_4_io_enq_ready),
		.io_enq_valid(_stripe0_M_AXI_0_ARVALID),
		.io_enq_bits_addr({30'h00000000, _stripe0_M_AXI_0_ARADDR}),
		.io_enq_bits_len(_stripe0_M_AXI_0_ARLEN),
		.io_enq_bits_size(_stripe0_M_AXI_0_ARSIZE),
		.io_enq_bits_burst(_stripe0_M_AXI_0_ARBURST),
		.io_enq_bits_lock(_stripe0_M_AXI_0_ARLOCK),
		.io_enq_bits_cache(_stripe0_M_AXI_0_ARCACHE),
		.io_enq_bits_prot(_stripe0_M_AXI_0_ARPROT),
		.io_enq_bits_qos(_stripe0_M_AXI_0_ARQOS),
		.io_enq_bits_region(_stripe0_M_AXI_0_ARREGION),
		.io_deq_ready(_responseBuffer_s_axi_ar_ready),
		.io_deq_valid(_sourceBuffer_4_io_deq_valid),
		.io_deq_bits_addr(_sourceBuffer_4_io_deq_bits_addr),
		.io_deq_bits_len(_sourceBuffer_4_io_deq_bits_len),
		.io_deq_bits_size(_sourceBuffer_4_io_deq_bits_size),
		.io_deq_bits_burst(_sourceBuffer_4_io_deq_bits_burst),
		.io_deq_bits_lock(_sourceBuffer_4_io_deq_bits_lock),
		.io_deq_bits_cache(_sourceBuffer_4_io_deq_bits_cache),
		.io_deq_bits_prot(_sourceBuffer_4_io_deq_bits_prot),
		.io_deq_bits_qos(_sourceBuffer_4_io_deq_bits_qos),
		.io_deq_bits_region(_sourceBuffer_4_io_deq_bits_region)
	);
	Queue2_ReadDataChannel sinkBuffer_3(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_3_io_enq_ready),
		.io_enq_valid(_responseBuffer_s_axi_r_valid),
		.io_enq_bits_data(_responseBuffer_s_axi_r_bits_data),
		.io_enq_bits_resp(_responseBuffer_s_axi_r_bits_resp),
		.io_enq_bits_last(_responseBuffer_s_axi_r_bits_last),
		.io_deq_ready(_stripe0_M_AXI_0_RREADY),
		.io_deq_valid(_sinkBuffer_3_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_3_io_deq_bits_data),
		.io_deq_bits_resp(_sinkBuffer_3_io_deq_bits_resp),
		.io_deq_bits_last(_sinkBuffer_3_io_deq_bits_last)
	);
	Queue2_WriteAddressChannel_3 sourceBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_5_io_enq_ready),
		.io_enq_valid(_stripe0_M_AXI_0_AWVALID),
		.io_enq_bits_addr({30'h00000000, _stripe0_M_AXI_0_AWADDR}),
		.io_enq_bits_len(_stripe0_M_AXI_0_AWLEN),
		.io_enq_bits_size(_stripe0_M_AXI_0_AWSIZE),
		.io_enq_bits_burst(_stripe0_M_AXI_0_AWBURST),
		.io_enq_bits_lock(_stripe0_M_AXI_0_AWLOCK),
		.io_enq_bits_cache(_stripe0_M_AXI_0_AWCACHE),
		.io_enq_bits_prot(_stripe0_M_AXI_0_AWPROT),
		.io_enq_bits_qos(_stripe0_M_AXI_0_AWQOS),
		.io_enq_bits_region(_stripe0_M_AXI_0_AWREGION),
		.io_deq_ready(_responseBuffer_s_axi_aw_ready),
		.io_deq_valid(_sourceBuffer_5_io_deq_valid),
		.io_deq_bits_addr(_sourceBuffer_5_io_deq_bits_addr),
		.io_deq_bits_len(_sourceBuffer_5_io_deq_bits_len),
		.io_deq_bits_size(_sourceBuffer_5_io_deq_bits_size),
		.io_deq_bits_burst(_sourceBuffer_5_io_deq_bits_burst),
		.io_deq_bits_lock(_sourceBuffer_5_io_deq_bits_lock),
		.io_deq_bits_cache(_sourceBuffer_5_io_deq_bits_cache),
		.io_deq_bits_prot(_sourceBuffer_5_io_deq_bits_prot),
		.io_deq_bits_qos(_sourceBuffer_5_io_deq_bits_qos),
		.io_deq_bits_region(_sourceBuffer_5_io_deq_bits_region)
	);
	Queue2_WriteDataChannel sourceBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_6_io_enq_ready),
		.io_enq_valid(_stripe0_M_AXI_0_WVALID),
		.io_enq_bits_data(_stripe0_M_AXI_0_WDATA),
		.io_enq_bits_strb(_stripe0_M_AXI_0_WSTRB),
		.io_enq_bits_last(_stripe0_M_AXI_0_WLAST),
		.io_deq_ready(_responseBuffer_s_axi_w_ready),
		.io_deq_valid(_sourceBuffer_6_io_deq_valid),
		.io_deq_bits_data(_sourceBuffer_6_io_deq_bits_data),
		.io_deq_bits_strb(_sourceBuffer_6_io_deq_bits_strb),
		.io_deq_bits_last(_sourceBuffer_6_io_deq_bits_last)
	);
	Queue2_WriteResponseChannel_4 sinkBuffer_4(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sinkBuffer_4_io_enq_ready),
		.io_enq_valid(_responseBuffer_s_axi_b_valid),
		.io_deq_ready(_stripe0_M_AXI_0_BREADY),
		.io_deq_valid(_sinkBuffer_4_io_deq_valid)
	);
	Queue2_ReadAddressChannel_7 sourceBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_7_io_enq_ready),
		.io_enq_valid(_responseBuffer_m_axi_ar_valid),
		.io_enq_bits_addr(_responseBuffer_m_axi_ar_bits_addr),
		.io_enq_bits_len(_responseBuffer_m_axi_ar_bits_len),
		.io_enq_bits_size(_responseBuffer_m_axi_ar_bits_size),
		.io_enq_bits_burst(_responseBuffer_m_axi_ar_bits_burst),
		.io_enq_bits_lock(_responseBuffer_m_axi_ar_bits_lock),
		.io_enq_bits_cache(_responseBuffer_m_axi_ar_bits_cache),
		.io_enq_bits_prot(_responseBuffer_m_axi_ar_bits_prot),
		.io_enq_bits_qos(_responseBuffer_m_axi_ar_bits_qos),
		.io_enq_bits_region(_responseBuffer_m_axi_ar_bits_region),
		.io_deq_ready(M_AXI_LS_ARREADY),
		.io_deq_valid(M_AXI_LS_ARVALID),
		.io_deq_bits_addr(M_AXI_LS_ARADDR),
		.io_deq_bits_len(M_AXI_LS_ARLEN),
		.io_deq_bits_size(M_AXI_LS_ARSIZE),
		.io_deq_bits_burst(M_AXI_LS_ARBURST),
		.io_deq_bits_lock(M_AXI_LS_ARLOCK),
		.io_deq_bits_cache(M_AXI_LS_ARCACHE),
		.io_deq_bits_prot(M_AXI_LS_ARPROT),
		.io_deq_bits_qos(M_AXI_LS_ARQOS),
		.io_deq_bits_region(M_AXI_LS_ARREGION)
	);
	Queue2_ReadDataChannel sinkBuffer_5(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(M_AXI_LS_RREADY),
		.io_enq_valid(M_AXI_LS_RVALID),
		.io_enq_bits_data(M_AXI_LS_RDATA),
		.io_enq_bits_resp(M_AXI_LS_RRESP),
		.io_enq_bits_last(M_AXI_LS_RLAST),
		.io_deq_ready(_responseBuffer_m_axi_r_ready),
		.io_deq_valid(_sinkBuffer_5_io_deq_valid),
		.io_deq_bits_data(_sinkBuffer_5_io_deq_bits_data),
		.io_deq_bits_resp(_sinkBuffer_5_io_deq_bits_resp),
		.io_deq_bits_last(_sinkBuffer_5_io_deq_bits_last)
	);
	Queue2_WriteAddressChannel_3 sourceBuffer_8(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_8_io_enq_ready),
		.io_enq_valid(_responseBuffer_m_axi_aw_valid),
		.io_enq_bits_addr(_responseBuffer_m_axi_aw_bits_addr),
		.io_enq_bits_len(_responseBuffer_m_axi_aw_bits_len),
		.io_enq_bits_size(_responseBuffer_m_axi_aw_bits_size),
		.io_enq_bits_burst(_responseBuffer_m_axi_aw_bits_burst),
		.io_enq_bits_lock(_responseBuffer_m_axi_aw_bits_lock),
		.io_enq_bits_cache(_responseBuffer_m_axi_aw_bits_cache),
		.io_enq_bits_prot(_responseBuffer_m_axi_aw_bits_prot),
		.io_enq_bits_qos(_responseBuffer_m_axi_aw_bits_qos),
		.io_enq_bits_region(_responseBuffer_m_axi_aw_bits_region),
		.io_deq_ready(M_AXI_LS_AWREADY),
		.io_deq_valid(M_AXI_LS_AWVALID),
		.io_deq_bits_addr(M_AXI_LS_AWADDR),
		.io_deq_bits_len(M_AXI_LS_AWLEN),
		.io_deq_bits_size(M_AXI_LS_AWSIZE),
		.io_deq_bits_burst(M_AXI_LS_AWBURST),
		.io_deq_bits_lock(M_AXI_LS_AWLOCK),
		.io_deq_bits_cache(M_AXI_LS_AWCACHE),
		.io_deq_bits_prot(M_AXI_LS_AWPROT),
		.io_deq_bits_qos(M_AXI_LS_AWQOS),
		.io_deq_bits_region(M_AXI_LS_AWREGION)
	);
	Queue2_WriteDataChannel sourceBuffer_9(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_9_io_enq_ready),
		.io_enq_valid(_responseBuffer_m_axi_w_valid),
		.io_enq_bits_data(_responseBuffer_m_axi_w_bits_data),
		.io_enq_bits_strb(_responseBuffer_m_axi_w_bits_strb),
		.io_enq_bits_last(_responseBuffer_m_axi_w_bits_last),
		.io_deq_ready(M_AXI_LS_WREADY),
		.io_deq_valid(M_AXI_LS_WVALID),
		.io_deq_bits_data(M_AXI_LS_WDATA),
		.io_deq_bits_strb(M_AXI_LS_WSTRB),
		.io_deq_bits_last(M_AXI_LS_WLAST)
	);
	Queue2_WriteResponseChannel_4 sinkBuffer_6(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(M_AXI_LS_BREADY),
		.io_enq_valid(M_AXI_LS_BVALID),
		.io_deq_ready(_responseBuffer_m_axi_b_ready),
		.io_deq_valid(_sinkBuffer_6_io_deq_valid)
	);
	Queue2_ReadAddressChannel_6 sourceBuffer_10(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_10_io_enq_ready),
		.io_enq_valid(_spmv0_m_axi_gp_ar_valid),
		.io_enq_bits_id(_spmv0_m_axi_gp_ar_bits_id),
		.io_enq_bits_addr(_spmv0_m_axi_gp_ar_bits_addr),
		.io_enq_bits_len(_spmv0_m_axi_gp_ar_bits_len),
		.io_enq_bits_size(_spmv0_m_axi_gp_ar_bits_size),
		.io_enq_bits_burst(_spmv0_m_axi_gp_ar_bits_burst),
		.io_deq_ready(M_AXI_GP_ARREADY),
		.io_deq_valid(M_AXI_GP_ARVALID),
		.io_deq_bits_id(M_AXI_GP_ARID),
		.io_deq_bits_addr(M_AXI_GP_ARADDR),
		.io_deq_bits_len(M_AXI_GP_ARLEN),
		.io_deq_bits_size(M_AXI_GP_ARSIZE),
		.io_deq_bits_burst(M_AXI_GP_ARBURST)
	);
	Queue2_ReadDataChannel_11 sinkBuffer_7(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(M_AXI_GP_RREADY),
		.io_enq_valid(M_AXI_GP_RVALID),
		.io_enq_bits_id(M_AXI_GP_RID),
		.io_enq_bits_data(M_AXI_GP_RDATA),
		.io_enq_bits_resp(M_AXI_GP_RRESP),
		.io_enq_bits_last(M_AXI_GP_RLAST),
		.io_deq_ready(_spmv0_m_axi_gp_r_ready),
		.io_deq_valid(_sinkBuffer_7_io_deq_valid),
		.io_deq_bits_id(_sinkBuffer_7_io_deq_bits_id),
		.io_deq_bits_data(_sinkBuffer_7_io_deq_bits_data),
		.io_deq_bits_resp(_sinkBuffer_7_io_deq_bits_resp),
		.io_deq_bits_last(_sinkBuffer_7_io_deq_bits_last)
	);
	Queue2_WriteAddressChannel_1 sourceBuffer_11(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_11_io_enq_ready),
		.io_enq_valid(_spmv0_m_axi_gp_aw_valid),
		.io_enq_bits_id(_spmv0_m_axi_gp_aw_bits_id),
		.io_enq_bits_addr(_spmv0_m_axi_gp_aw_bits_addr),
		.io_enq_bits_len(_spmv0_m_axi_gp_aw_bits_len),
		.io_enq_bits_size(_spmv0_m_axi_gp_aw_bits_size),
		.io_enq_bits_burst(_spmv0_m_axi_gp_aw_bits_burst),
		.io_deq_ready(M_AXI_GP_AWREADY),
		.io_deq_valid(M_AXI_GP_AWVALID),
		.io_deq_bits_id(M_AXI_GP_AWID),
		.io_deq_bits_addr(M_AXI_GP_AWADDR),
		.io_deq_bits_len(M_AXI_GP_AWLEN),
		.io_deq_bits_size(M_AXI_GP_AWSIZE),
		.io_deq_bits_burst(M_AXI_GP_AWBURST)
	);
	Queue2_WriteDataChannel sourceBuffer_12(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_sourceBuffer_12_io_enq_ready),
		.io_enq_valid(_spmv0_m_axi_gp_w_valid),
		.io_enq_bits_data(_spmv0_m_axi_gp_w_bits_data),
		.io_enq_bits_strb(_spmv0_m_axi_gp_w_bits_strb),
		.io_enq_bits_last(_spmv0_m_axi_gp_w_bits_last),
		.io_deq_ready(M_AXI_GP_WREADY),
		.io_deq_valid(M_AXI_GP_WVALID),
		.io_deq_bits_data(M_AXI_GP_WDATA),
		.io_deq_bits_strb(M_AXI_GP_WSTRB),
		.io_deq_bits_last(M_AXI_GP_WLAST)
	);
	Queue2_WriteResponseChannel_7 sinkBuffer_8(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(M_AXI_GP_BREADY),
		.io_enq_valid(M_AXI_GP_BVALID),
		.io_enq_bits_id(M_AXI_GP_BID),
		.io_enq_bits_resp(M_AXI_GP_BRESP),
		.io_deq_ready(_spmv0_m_axi_gp_b_ready),
		.io_deq_valid(_sinkBuffer_8_io_deq_valid),
		.io_deq_bits_id(_sinkBuffer_8_io_deq_bits_id),
		.io_deq_bits_resp(_sinkBuffer_8_io_deq_bits_resp)
	);
endmodule
