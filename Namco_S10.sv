//============================================================================
//  PSX
//  Copyright (C) 2019 Robert Peip
//
//  Port to MiSTer
//  Copyright (C) 2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign HDMI_FREEZE = 1'b0;
assign HDMI_BOB_DEINT = 1'b0;   // weave only: ascal's bob read-address path does not fit the HDMI clock

assign ADC_BUS  = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign AUDIO_S   = 1;
assign AUDIO_MIX = status[8:7];

assign LED_USER  = rom_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

wire [ 3:0] frameindex;
wire [11:0] DisplayWidth;
wire [11:0] DisplayHeight;
wire [ 9:0] DisplayOffsetX;
wire [ 8:0] DisplayOffsetY;

// Orientation (OSD), labelled as in the owner's other cores: "Horizontal" is the raster exactly
// as the board generates it (Tenkomori is ROT90, so the game lies on its side - for a rotated
// CRT/tate display, or to rotate elsewhere); Vertical CW/CCW rotate it 90 degrees on HDMI so the
// game stands upright on a normal screen; Flipped turns the raster 180 degrees in the GPU.
//   0 Horizontal   : native raster
//   1 Vertical CW  : HDMI picture rotated 90 CW (upright on a landscape screen)
//   2 Vertical CCW : HDMI picture rotated 90 CCW
//   3 Flipped      : native raster rotated 180 (GPU; analog output too)
// Rotation (1/2) uses MiSTer's screen_rotate frame buffer and applies to HDMI; the analog
// output always carries the native raster.
wire [1:0] orient         = status[13:12];
wire       rot_en         = (orient == 2'd1) || (orient == 2'd2);
wire       rot_ccw        = (orient == 2'd2);
wire       orient_flip180 = (orient == 2'd3);

wire        sr_fb_en;
wire  [4:0] sr_fb_format;
wire [11:0] sr_fb_width;
wire [11:0] sr_fb_height;
wire [31:0] sr_fb_base;
wire [13:0] sr_fb_stride;

// HPS frame buffer: only the screen_rotate output (Orientation Horizontal / Horizontal Flipped)
assign FB_BASE    = sr_fb_base;
assign FB_EN      = rot_en ? sr_fb_en : 1'b0;
assign FB_FORMAT  = sr_fb_format;
assign FB_WIDTH   = sr_fb_width;
assign FB_HEIGHT  = sr_fb_height;
assign FB_STRIDE  = sr_fb_stride;
assign FB_FORCE_BLANK = 0;


///////////////////////  CLOCK/RESET  ///////////////////////////////////

wire pll_locked;
wire clk_1x;
wire clk_2x;
wire clk_3x;
wire clk_3x_ps;   // clk_3x (101.6MHz) phase-shifted +2460ps (+90deg): drives main SDRAM_CLK to test write/interface timing
wire clk_vid;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_1x),
	.outclk_1(clk_2x),
	.outclk_2(clk_3x),
	.outclk_3(clk_3x_ps),
	.locked(pll_locked)
);

pll2 pll2
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_vid),
   .reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);

wire [63:0] reconfig_to_pll;
wire [63:0] reconfig_from_pll;
wire        cfg_waitrequest;
reg         cfg_write;
reg   [5:0] cfg_address;
reg  [31:0] cfg_data;

pll_cfg pll_cfg
(
	.mgmt_clk(CLK_50M),
	.mgmt_reset(0),
	.mgmt_waitrequest(cfg_waitrequest),
	.mgmt_read(0),
	.mgmt_readdata(),
	.mgmt_write(cfg_write),
	.mgmt_address(cfg_address),
	.mgmt_writedata(cfg_data),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);


wire FFrequest = joy[17] && ~FB_LL && ~DIRECT_VIDEO;
wire syncVideoOut = 0; //status[57] && ~FB_LL && ~DIRECT_VIDEO;
wire syncVideoClock = 0; //status[56] && ~FB_LL && ~DIRECT_VIDEO;

always @(posedge CLK_50M) begin : cfg_block
	reg pald = 0, pald2 = 0;
	reg pdbg = 0, pdbg2 = 0;
	reg pffw = 0, pffw2 = 0;
	reg [3:0] state = 0;

	pald  <= isPal;
	pald2 <= pald;

	pdbg  <= syncVideoClock;
	pdbg2 <= pdbg;

	pffw  <= fast_forward;
	pffw2 <= pffw;

	cfg_write <= 0;
	if(pald2 != pald || pdbg2 != pdbg || pffw2 != pffw) state <= 1;

	if(!cfg_waitrequest) begin
		if(state) state<=state+1'd1;
		case(state)
			1: begin
					cfg_address <= 0;
					cfg_data <= 0;
					cfg_write <= 1;
				end
         3: begin
					cfg_address <= 5;
					cfg_data <= pffw2 ? 131842 : pdbg2 ? 771 : 1028;
					cfg_write <= 1;
				end
			5: begin
					cfg_address <= 7;
					cfg_data <= pffw2 ? 2147483648 : pdbg2 ? 551954751 : pald2 ? 2201376898 : 2537930535;
					cfg_write <= 1;
				end
			7: begin
					cfg_address <= 2;
					cfg_data <= 0;
					cfg_write <= 1;
				end
		endcase
	end
end

reg fast_forward;
reg ff_latch;

always @(posedge clk_1x) begin : ffwd
	reg last_ffw;
	reg ff_was_held;
	longint ff_count;

	last_ffw <= FFrequest;

	if (FFrequest)
		ff_count <= ff_count + 1;

	if (~last_ffw & FFrequest) begin
		ff_latch <= 0;
		ff_count <= 0;
	end

	if ((last_ffw & ~FFrequest)) begin
		ff_was_held <= 0;

		if (ff_count < 10000000 && ~ff_was_held) begin
			ff_was_held <= 1;
			ff_latch <= 1;
		end
	end

	fast_forward <= (FFrequest | ff_latch);
end


////////////////////////////  HPS I/O  //////////////////////////////////

// Status Bit Map: (0..31 => "O", 32..63 => "o")
// 0         1         2         3          4         5         6          7         8         9
// 01234567890123456789012345678901 23456789012345678901234567890123 45678901234567890123456789012345
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
//  XXXX XXXXXX XXXXXX XXXXX  XX XX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXX

`include "build_id.v"
parameter CONF_STR = {
	"Namco_S10;;",
	"-;",
	"O[3:2],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O[13:12],Orientation,Horizontal,Vertical CW,Vertical CCW,Flipped;",
	"-;",
	"H3SC0,BINISO,Mount CD;",
	"H4SC0,P3A,Mount audio;",
	"H3-;",
	"P1,Video & Audio;",
	"P1-;",
	"P1O[33:32],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O[35:34],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1O[22],Dithering,On,Off;",
	"P1O[8:7],Stereo Mix,None,25%,50%,100%;",
	"P2,CRT Adjust;",
	"P2O[96],CRT Adjust,Off,On;",
	"H1P2O[116:112],CRT H-Size,0,+1,+2,+3,+4,+5,+6,+7,+8,+9,+10,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1;",
	"H1P2O[104:101],CRT H-Position,0,+4,+8,+12,+16,+20,+24,+28,-32,-28,-24,-20,-16,-12,-8,-4;",
	"H1P2O[108:105],CRT V-Shift,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"H2P4,Light Gun;",
	"H2P4-;",
	"H2P4O[120],Gun aim P1,Joystick,Mouse;",
	"H2P4O[121],Crosshair,Off,On;",
	"H5P5,Trackball;",
	"H5P5-;",
	"H5P5O[123:122],Trackball Speed,1x,2x,4x,1/2;",
	"H5P5O[124],Trackball Invert X,Off,On;",
	"H5P5O[125],Trackball Invert Y,Off,On;",
	"H5P5O[126],Analog Stick as Trackball,On,Off;",
	"DIP;",
	"P3,Hardware;",
	"P3-;",
	"P3O[64],Pause when OSD open,Off,On;",
	"P3O[65],IRQ10 (Input),100Hz,2xVBlank;",
	"-;",
	"R0,Reset;",
	"J1,Button 1,Button 2,Button 3,Button 4,Button 5,Button 6,Start,Coin,Test,Service,Pause;",
	"jn,A,B,X,Y,R2,L2,Start,Select,L,R,R3;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [127:0] status;
// Bit 0 hides the Light Gun OSD page (H0 prefix) for every game whose MRA does
// not declare itself a gun game — light-gun support must not be offered to
// games that don't natively have it.
wire        b_light_gun, b_cdrom, b_exio_mcu, b_exio_analog, b_memp3, b_edge_mask;
wire  [3:0] b_in1_layout;
// H1: CRT Adjust items hidden while Off; H2: Light Gun page, gun games only; H3: Mount CD, CD games only;
// H4: Mount audio, MEM(P3) games only; H5: Trackball page, NFL Classic Football only
wire        b_nfl = (b_in1_layout == 4'd4);
wire [15:0] status_menumask = {10'd0, ~b_nfl, ~b_memp3, ~b_cdrom, ~b_light_gun, ~status[96], 1'b0};
wire        forced_scandoubler;
wire [31:0] sd_lba0;                   // slot 0: CD-ROM image (s10_atapi) or MEM(P3) audio (s10_p3audio)
wire [31:0] cd_lba, p3_lba;
wire  [5:0] p3_blk_cnt;
wire        p3_sd_rd;
wire [31:0] sd_lba1 = 0;
wire [ 6:0] sd_lba2 = 0;
wire [ 6:0] sd_lba3 = 0;
wire        cd_sd_rd;
wire  [3:0] sd_rd = {3'b000, b_memp3 ? p3_sd_rd : cd_sd_rd};
assign      sd_lba0 = b_memp3 ? p3_lba : cd_lba;
wire  [3:0] sd_wr = 4'b0000;
wire  [3:0] sd_ack;
wire [12:0] sd_buff_addr;                // 16-bit words; multi-block requests count on across blocks
wire  [5:0] cd_blk_cnt;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din2;
wire [15:0] sd_buff_din3;
wire        sd_buff_wr;
wire  [3:0] img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [26:0] ioctl_addr;
wire [15:0] ioctl_dout;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire        rom_download = ioctl_download && ioctl_index != 8'd254;   // index 254 = MRA DIP switches
// nvram (MEM board settings block in the DDR3 image) save path
wire        ioctl_upload;
wire [15:0] ioctl_din;
wire        ioctl_rd;
wire        ioctl_upload_req;
wire  [7:0] ioctl_upload_index = 8'd9;   // nvram is MRA index 9
wire        ioctl_wait;

wire [19:0] joy;
wire [19:0] joy_unmod;
wire [19:0] joy2;
wire [19:0] joy3;
wire [19:0] joy4;

wire [10:0] ps2_key;

wire [21:0] gamma_bus;
wire [15:0] sdram_sz;

wire [15:0] joystick_analog_l0;
wire [15:0] joystick_analog_r0;
wire [15:0] joystick_analog_l1;
wire [15:0] joystick_analog_r1;
wire [15:0] joystick_analog_l2;
wire [15:0] joystick_analog_r2;
wire [15:0] joystick_analog_l3;
wire [15:0] joystick_analog_r3;

wire [7:0] paddle_0;

wire [24:0] mouse;

wire [15:0] joystick1_rumble;
wire [15:0] joystick2_rumble;
wire [15:0] joystick3_rumble;
wire [15:0] joystick4_rumble;
wire [32:0] RTC_time;
wire [64:0] rtc_msm;

wire filter_on = (status[82:81] == 2'b00) ? 1'b0 : 1'b1;

assign HDMI_BLACKOUT = ~status[61];

wire [127:0] status_in = {status[127:39],ss_slot,status[36:19], 2'b00, status[16:0]};

wire bk_pending = 1'b0;
wire saving_memcard = 1'b0;
wire DIRECT_VIDEO;

hps_io #(.CONF_STR(CONF_STR), .WIDE(1), .VDNUM(4), .BLKSZ(3)) hps_io
(
	.clk_sys(clk_1x),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(EXT_BUS),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),

	.joystick_0(joy_unmod),
	.joystick_1(joy2),
	.joystick_2(joy3),
	.joystick_3(joy4),
	.ps2_key(ps2_key),

	.status(status),
	.status_in(status_in),
	.status_set(statusUpdate),
	.status_menumask(status_menumask),
	.info_req(psx_info_req),
	.info(psx_info),

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait | s10_up_wait),

	// nvram (MEM board settings) save path
	.ioctl_upload(ioctl_upload),
	.ioctl_rd(ioctl_rd),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_upload_index(ioctl_upload_index),
	.ioctl_din(ioctl_din),

	.sd_lba('{sd_lba0, sd_lba1, sd_lba2, sd_lba3}),
	.sd_blk_cnt('{b_memp3 ? p3_blk_cnt : cd_blk_cnt, 0, 0, 0}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{0, 0, sd_buff_din2, sd_buff_din3}),
	.sd_buff_wr(sd_buff_wr),

	.TIMESTAMP(RTC_time),
	.RTC(rtc_msm),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.sdram_sz(sdram_sz),
	.gamma_bus(gamma_bus),

   .joystick_l_analog_0(joystick_analog_l0),
   .joystick_r_analog_0(joystick_analog_r0),
   .joystick_l_analog_1(joystick_analog_l1),
   .joystick_r_analog_1(joystick_analog_r1),
   .joystick_l_analog_2(joystick_analog_l2),
   .joystick_r_analog_2(joystick_analog_r2),
   .joystick_l_analog_3(joystick_analog_l3),
   .joystick_r_analog_3(joystick_analog_r3),
   .ps2_mouse(mouse),
   .joystick_0_rumble(paused ? 16'h0000 : joystick1_rumble),
   .joystick_1_rumble(paused ? 16'h0000 : joystick2_rumble),

   .paddle_0(paddle_0),

   .direct_video(DIRECT_VIDEO)
);

assign joy = joy_unmod[16] ? 20'b0 : joy_unmod;


wire [35:0] EXT_BUS;
wire        heartbeat;

hps_ext hps_ext
(
	.clk_sys(clk_1x),
	.EXT_BUS(EXT_BUS),
	.heartbeat(heartbeat)
);


//////////////////////////  ROM DOWNLOAD  ///////////////////////////////

// SDRAM (byte addresses; 32 MB is enough):
//   0x0000000-0x03FFFFF  main RAM        4 MB
//   0x0400000-0x07FFFFF  BIOS            4 MB   descrambled from the MEM board at load (MRA index 0)
//   0x0800000-0x08FFFFF  MEM(N) SRAM     1 MB   bad-block table (0x1F500000)
// DDR3 (from 0x30000000: VRAM, SPU RAM, GPU buffers up to 0x307FFFFF): MEM board image at 0x30800000 (MRA indexes
// 2/3, fast loading, up to 232 MB), MEM(P3) MCU RAM at 0x3F000000 (8 MB), PB3 nonlinear table at 0x3F800000.
localparam BIOS_START = 27'h0400000;

wire        exe_download  = 1'b0;
wire        code_download = 1'b0;
reg         cart_loaded  = 0;
always @(posedge clk_1x) if (rom_download && ioctl_index == 8'd0) cart_loaded <= 1;

wire hasCD = 1'b0;
wire loadExe = 1'b0;
wire [31:0] exe_initial_pc    = 32'h0;
wire [31:0] exe_initial_gp    = 32'h0;
wire [31:0] exe_load_address  = 32'h0;
wire [31:0] exe_file_size     = 32'h0;
wire [31:0] exe_stackpointer  = 32'h0;

reg  [1:0] biosregion = 2'b01;
wire [1:0] region_out;
reg        isPal = 1'b0;

// board record (MRA index 1) and loader
wire         b_memn, b_nand_big, b_record_ok;
wire   [1:0] b_crypt;
wire   [4:0] b_nand_count;
wire  [15:0] b_data_xor;
wire  [63:0] b_perm;
wire   [7:0] b_exio_ident;
wire  [27:0] b_save_base;
wire         b_t2_row_we;
wire   [5:0] b_t2_row_addr;
wire   [2:0] b_t2_row_lane, b_t2_nterms;
wire  [15:0] b_t2_row_data, b_t2_xmask, b_t2_nl_out;
wire         b_nl_table;
wire  [20:0] b_nl_bits;
localparam [27:0] IMG_BASE = 28'h0800000;   // MEM board image: DDR3 0x30800000
localparam [27:0] NL_OFF = 28'hF000000;     // nonlinear decrypter table, from IMG_BASE: DDR3 0x3F800000 (MRA index 4)

wire        ld_dl_req;
wire [26:0] ld_dl_addr;
wire [31:0] ld_dl_data;
wire        dl_done;
wire        ld_fill_start;
wire [26:0] ld_fill_base;
wire [20:0] ld_fill_words;
wire [31:0] ld_fill_value;
wire        fill_busy;
wire        ld_ddr_own, ld_ddr_we, ld_ddr_busy;
wire [27:0] ld_ddr_addr;
wire [63:0] ld_ddr_din;
wire  [7:0] ld_ddr_be;

s10_loader #(.BIOS_SDRAM(BIOS_START), .IMG_BASE(IMG_BASE), .NL_OFF(NL_OFF)) s10_loader
(
	.clk           (clk_1x),
	.clk2          (clk_2x),
	.ioctl_download(rom_download),
	.ioctl_index   (ioctl_index),
	.ioctl_wr      (ioctl_wr),
	.ioctl_addr    (ioctl_addr),
	.ioctl_dout    (ioctl_dout),
	.ioctl_wait    (ioctl_wait),
	.board_memn    (b_memn),
	.crypt_type    (b_crypt),
	.nand_count    (b_nand_count),
	.nand_big      (b_nand_big),
	.data_xor      (b_data_xor),
	.perm          (b_perm),
	.exio_ident    (b_exio_ident),
	.save_base     (b_save_base),
	.t2_row_we     (b_t2_row_we),
	.t2_row_addr   (b_t2_row_addr),
	.t2_row_lane   (b_t2_row_lane),
	.t2_row_data   (b_t2_row_data),
	.t2_xmask      (b_t2_xmask),
	.t2_nl_out     (b_t2_nl_out),
	.t2_nterms     (b_t2_nterms),
	.nl_table      (b_nl_table),
	.light_gun     (b_light_gun),
	.cdrom         (b_cdrom),
	.exio_mcu      (b_exio_mcu),
	.exio_analog   (b_exio_analog),
	.memp3         (b_memp3),
	.edge_mask     (b_edge_mask),
	.in1_layout    (b_in1_layout),
	.nl_bits       (b_nl_bits),
	.record_ok     (b_record_ok),
	.dl_req        (ld_dl_req),
	.dl_addr       (ld_dl_addr),
	.dl_data       (ld_dl_data),
	.dl_done       (dl_done),
	.fill_start    (ld_fill_start),
	.fill_base     (ld_fill_base),
	.fill_words    (ld_fill_words),
	.fill_value    (ld_fill_value),
	.fill_busy     (fill_busy),
	.ddr_own       (ld_ddr_own),
	.ddr_we        (ld_ddr_we),
	.ddr_addr      (ld_ddr_addr),
	.ddr_din       (ld_ddr_din),
	.ddr_be        (ld_ddr_be),
	.ddr_busy      (ld_ddr_busy)
);

// Main RAM zero fill after the download (MAME's RAM is zero initialised) - SDRAM channel 3 fill
reg        clr_start   = 0;
reg        ram_cleared = 0;
reg        dl_seen     = 0;
reg        clr_run     = 0;
reg [15:0] clr_settle  = 0;
always @(posedge clk_1x) begin
	clr_start <= 0;
	if (rom_download) begin
		dl_seen     <= 1;
		clr_settle  <= 0;
		ram_cleared <= 0;
	end else if (dl_seen) begin
		if (&clr_settle) begin
			dl_seen   <= 0;
			clr_start <= 1;
			clr_run   <= 1;
		end else clr_settle <= clr_settle + 1'd1;
	end
	if (clr_run && !clr_start && !fill_busy) begin clr_run <= 0; ram_cleared <= 1; end
end

// Mounting a CD image restarts the game: the Taiko games look for the drive only at boot (without a disc they
// stop on a black screen after the NOTICE screen), so a disc chosen from the OSD takes effect right away.
reg [15:0] mount_rst = 0;
always @(posedge clk_1x) begin
	if (mount_rst != 0) mount_rst <= mount_rst - 1'd1;
	if (img_mounted[0] && img_size != 0 && b_cdrom) mount_rst <= 16'hFFFF;
end

wire reset_or = RESET | buttons[1] | status[0] | rom_download | ~ram_cleared | clr_start | clr_run | (mount_rst != 0);

///////////////////////////  SAVESTATE  /////////////////////////////////

wire [1:0] ss_slot;
wire [7:0] ss_info;
wire [3:0] validSStates;
wire ss_save, ss_load, ss_info_req;
wire statusUpdate;

savestate_ui savestate_ui
(
	.clk            (clk_1x        ),
	.ps2_key        (ps2_key[10:0] ),
	.allow_ss       (cart_loaded   ),
	.joySS          (joy_unmod[16] ),
	.joyRight       (joy_unmod[0]  ),
	.joyLeft        (joy_unmod[1]  ),
	.joyDown        (joy_unmod[2]  ),
	.joyUp          (joy_unmod[3]  ),
	.joyRewind      (0             ),
	.rewindEnable   (0             ),
	.status_slot    (status[38:37] ),
	.autoincslot    (status[68]    ),
	.OSD_saveload   (status[18:17] ),
   .validSStates   (validSStates  ),
	.ss_save        (ss_save       ),
	.ss_load        (ss_load       ),
	.ss_info_req    (ss_info_req   ),
	.ss_info        (ss_info       ),
	.statusUpdate   (statusUpdate  ),
	.selected_slot  (ss_slot       )
);
defparam savestate_ui.INFO_TIMEOUT_BITS = 25;

////////////////////////////  PAD  ///////////////////////////////////

// 0000 -> DualShock
// 0001 -> off
// 0010 -> digital
// 0011 -> analog
// 0100 -> Namco GunCon lightgun
// 0101 -> Namco NeGcon
// 0110 -> Wheel Negcon
// 0111 -> Wheel Analog
// 1000 -> mouse
// 1001 -> Konami Justifier lightgun
// 1010 -> SNAC
// 1011 -> Analog Joystick
// 1100..1111 -> reserved

wire PadPortDS1      = (status[48:45] == 4'b0000);
wire PadPortEnable1  = (status[48:45] != 4'b0001);
wire PadPortDigital1 = (status[48:45] == 4'b0010) || (status[52:49] == 4'b1100);
wire PadPortAnalog1  = (status[48:45] == 4'b0011) || (status[48:45] == 4'b0111);
wire PadPortGunCon1  = (status[48:45] == 4'b0100);
wire PadPortNeGcon1  = (status[48:45] == 4'b0101) || (status[48:45] == 4'b0110);
wire PadPortWheel1   = (status[48:45] == 4'b0110) || (status[48:45] == 4'b0111);
wire PadPortMouse1   = (status[48:45] == 4'b1000);
wire PadPortJustif1  = (status[48:45] == 4'b1001);
wire snacPort1       = (status[48:45] == 4'b1010) && ~multitap;
wire PadPortStick1   = (status[48:45] == 4'b1011);
wire PadPortPopn1    = (status[48:45] == 4'b1100);

wire PadPortDS2      = (status[52:49] == 4'b0000);
wire PadPortEnable2  = (status[52:49] != 4'b0001) && ~multitap;
wire PadPortDigital2 = (status[52:49] == 4'b0010) || (status[52:49] == 4'b1100);
wire PadPortAnalog2  = (status[52:49] == 4'b0011) || (status[52:49] == 4'b0111);
wire PadPortGunCon2  = (status[52:49] == 4'b0100);
wire PadPortNeGcon2  = (status[52:49] == 4'b0101) || (status[52:49] == 4'b0110);
wire PadPortWheel2   = (status[52:49] == 4'b0110) || (status[52:49] == 4'b0111);
wire PadPortMouse2   = (status[52:49] == 4'b1000);
wire PadPortJustif2  = (status[52:49] == 4'b1001);
wire snacPort2       = (status[52:49] == 4'b1010) && ~multitap;
wire PadPortStick2   = (status[52:49] == 4'b1011);
wire PadPortPopn2    = (status[52:49] == 4'b1100);

reg paddleMode = 0;
reg paddleMin = 0;
reg paddleMax = 0;
wire [7:0] joy0_xmuxed = (paddleMode) ? (paddle_0 - 8'd128) : joystick_analog_l0[7:0];

// to activate paddleMode negcon mode must be active and paddle must best moved
always @(posedge clk_1x) begin
   if (PadPortNeGcon1) begin
      if (paddle_0 < 112) paddleMin <= 1'b1;
      if (paddle_0 > 144) paddleMax <= 1'b1;
      if (paddleMin && paddleMax) paddleMode <= 1'b1;
   end else begin
      paddleMode <= 0;
      paddleMin <= 0;
      paddleMax <= 0;
   end
end

// 00 -> multitap off
// 01 -> port1, 4 x digital
// 10 -> port1, 4 x analog
wire multitap        = (status[57:56] != 2'b00);
wire multitapDigital = (status[57:56] == 2'b01);
wire multitapAnalog  = (status[57:56] == 2'b10);

wire [1:0] padMode;
reg  [1:0] padMode_1;

reg [7:0] psx_info;
reg psx_info_req;

wire resetFromCD = 1'b0;

reg [3:0] ToggleDS = 0;
reg [3:0] joy19_1 = 0;

always @(posedge clk_1x) begin

   psx_info_req <= 0;
   padMode_1    <= padMode;

   if (ss_info_req) begin
      psx_info_req <= 1;
      psx_info     <= ss_info;
   end


   // DS toggle (unused in arcade but kept for joypad struct compatibility)
   joy19_1 <= {joy4[19] ,joy3[19] ,joy2[19] ,joy[19] };
   ToggleDS[0] <=  joy[19] & ~joy19_1[0];
   ToggleDS[1] <= joy2[19] & ~joy19_1[1];
   ToggleDS[2] <= joy3[19] & ~joy19_1[2];
   ToggleDS[3] <= joy4[19] & ~joy19_1[3];

end

////////////////////////////  PAUSE and RESET  ///////////////////////////
reg paused = 0;
reg [9:0] unpause = 0;
reg status1_1;
wire isPaused;

reg [20:0] aliveCnt = 0;
reg heartbeat_1 = 0;
reg hps_busy = 0;

reg reset = 0;

reg buttonpause_1 = 0;
reg button_paused = 0;

reg TURBO_MEM;
reg TURBO_COMP;
reg TURBO_CACHE;
reg TURBO_CACHE50;

always @(posedge clk_1x) begin

   paused <= 0;

   // pause from OSD open — only when the "Pause when OSD is open" option is On
   // (status[64]; default Off per policy rev 4, so the game keeps running under
   // an open OSD unless the user opts in)
   if (status[64] & OSD_STATUS & (unpause == 0)) begin
      paused <= 1;
   end

   // pause from button: joy[14] = Pause (11th entry of the MRA/J1 button list)
   buttonpause_1 <= joy[14];
   if (joy[14] & ~buttonpause_1) begin
      button_paused <= ~button_paused;
   end
   if (button_paused) begin
      paused <= 1;
   end

   // Advance Pause OSD trigger
   status1_1 <= status[1];
   if (status[1] & ~status1_1) begin
      unpause <= 1023;
   end else if (unpause > 0) begin
      unpause <= unpause - 1'd1;
   end

   // pause from heartbeat -> only used for savestate
   hps_busy    <= 0;
   heartbeat_1 <= heartbeat;
   if (heartbeat == heartbeat_1) begin
      if (aliveCnt[20] == 0) begin
         aliveCnt <= aliveCnt + 1'b1;
      end else begin
         hps_busy <= 1;
      end
   end else begin
      aliveCnt <= 0;
   end

   // reset
   reset <= 0;
   if (reset_or) begin
      reset    <= 1;
      aliveCnt <= 0;
   end

   // System 10's CXD8606 runs from 101.4912 MHz / 2 = 50.7456 MHz (MAME CXD8606BQ at 101.4912 MHz, internal
   // /2), 1.5x the PlayStation. The core clocks the CPU at 33.8688 MHz and makes up the speed with the
   // PSX core's turbo modes: faster memory access, no compute stalls, full-rate data cache. The half-rate cache
   // left Mr. Driller 2 / G short of CPU time in the 13-column stages (stutter); the full rate makes the PSY-Q VSync()
   // wait loop faster than on the board, which rtl/cpu.vhd compensates (vsync_fix).
   TURBO_MEM      <= 1'b1;
   TURBO_COMP     <= 1'b1;
   TURBO_CACHE    <= 1'b1;
   TURBO_CACHE50  <= 1'b0;

end

////////////////////////////  SYSTEM  ///////////////////////////////////

// ===== Namco System 10: main-board I/O CPLD + MEM ROM board =====
wire signed [15:0] psx_aud_l, psx_aud_r;
wire signed [15:0] p3_aud_l, p3_aud_r;                // MEM(P3) MP3 board audio (pre-converted, s10_p3audio)
wire signed [16:0] mix_l = psx_aud_l + p3_aud_l;
wire signed [16:0] mix_r = psx_aud_r + p3_aud_r;
assign AUDIO_L = (mix_l[16] == mix_l[15]) ? mix_l[15:0] : {mix_l[16], {15{~mix_l[16]}}};
assign AUDIO_R = (mix_r[16] == mix_r[15]) ? mix_r[15:0] : {mix_r[16], {15{~mix_r[16]}}};

// board bus from the PSX core (EXP1/EXP3)
wire [23:0] s10_addr;
wire [31:0] s10_wdata;
wire  [3:0] s10_wmask;
wire  [1:0] s10_size;
wire        s10_rd, s10_wr, s10_stall, s10_irq10;
wire [31:0] s10_io_rdata, s10_mem_rdata;
// MEM board DDR3 client (into psx_top's arbiter)
wire        s10_ddr_request, s10_ddr_ack, s10_ddr_we, s10_ddr_rd;
wire  [7:0] s10_ddr_burstcnt, s10_ddr_be;
wire [27:0] s10_ddr_addr;
wire [63:0] s10_ddr_din;
// PSX DMA channel 5 <- MEM(N) data register
wire        s12_rdma_start;
wire [26:0] s12_rdma_src;
wire        s12_rdma_valid;
wire        s12_rdma_pop;
wire        s12_rdma_want;
wire [31:0] s12_rdma_data;
// MEM(N) SRAM on SDRAM channel 3
wire        s10_sram_req, s10_sram_rnw, s10_sram_ready;
wire [19:0] s10_sram_addr;
wire  [3:0] s10_sram_be;
wire [31:0] s10_sram_wdata, s10_sram_rdata;
wire        s10_up_wait;

// JAMMA inputs, MAME namcos10 IN1 layout (active low). joy follows the MRA <buttons> order:
// [0]R [1]L [2]D [3]U [4..9]Buttons 1-6 [10]Start [11]Coin [12]Test [13]Service [14]Pause
reg  test_p1 = 0, test_p2 = 0, test_sw = 0;
always @(posedge clk_1x) begin                       // MAME: TEST is a slide switch (PORT_TOGGLE)
	test_p1 <= joy[12];
	test_p2 <= joy2[12];
	if ((joy[12] & ~test_p1) | (joy2[12] & ~test_p2)) test_sw <= ~test_sw;
	if (reset_or) test_sw <= 1'b0;
end
// GAHAHA (record: EXIO analog) has its own IN1 layout (MAME 'gahaha' port): b0 Button 2, b1 Button 1,
// b2 Select Down, b3 Select Up, b4 Enter (= Button 3 here), b7 / b15 Start; the sticks go to the EXIO ADC.
// MEM(P3) games' IN1 layouts (MAME g13jnr / nicetsuk / squizchs ports), active high here, inverted below:
//   1 Golgo 13: standard + b27 scope sensor (active high on the board, toggled by Button 3 as MAME's PORT_TOGGLE)
//   2 Nice Tsukkomi: b0/b3 Up, b1/b2 Down (play / operator menu), b4 Enter (Button 5), b5 Pedal (Button 4),
//     b7 Choose (Start), b17 Forehead (Button 1), b12 Chest (Button 2), b18 Back of head (Button 3)
//   3 Seishun Quiz: b3-b0 answer buttons 1-4 (P1), b11-b8 (P2), b7 / b15 Start
reg  scope = 0, scope_btn = 0;
always @(posedge clk_1x) begin
	scope_btn <= joy[6];
	if (joy[6] & ~scope_btn) scope <= ~scope;
	if (reset_or) scope <= 1'b0;
end
wire [31:0] in1_nicetsuk = {joy[13] | joy2[13], test_sw, joy[11], joy2[11], 4'b0000, 5'd0, joy[6], joy[4], 1'b0,
                            3'b000, joy[5], 4'b0000, joy[10], 1'b0, joy[7], joy[8], joy[3], joy[2], joy[2], joy[3]};
wire [31:0] in1_squizchs = {joy[13] | joy2[13], test_sw, joy[11], joy2[11], 12'd0,
                            joy2[10], 3'b000, joy2[4], joy2[5], joy2[6], joy2[7],
                            joy[10],  3'b000, joy[4],  joy[5],  joy[6],  joy[7]};
// 4 NFL Classic Football (MAME nflclsfb IN1): b0/b8 right side Choose L/R, b15 right side Decide (Player 2
//   Buttons 3/4/5), b1/b9 left side Choose L/R, b7 left side Decide (Player 1 Buttons 3/4/5), b3/b2 Select
//   Up/Down (Player 1 Up/Down), b4 Enter (Player 1 Button 6), b5/b6/b13/b14 Start 1P-4P; coins from all players
wire [31:0] in1_nfl = {joy[13] | joy2[13] | joy3[13] | joy4[13], test_sw, joy[11] | joy3[11], joy2[11] | joy4[11],
                       12'd0, joy2[8], joy4[10], joy3[10], 3'b000, joy[7], joy2[7],
                       joy[8], joy2[10], joy[10], joy[9], joy[3], joy[2], joy[6], joy2[6]};
// NFL EXIO_IN1 (active low): PASS 1 = Button 1 (bit 0 1P, 1 3P, 2 2P, 3 4P), PASS 2 = Button 2 (bits 4-7)
wire [15:0] nfl_exio_in1 = ~{8'd0, joy4[5], joy2[5], joy3[5], joy[5], joy4[4], joy2[4], joy3[4], joy[4]};

// NFL trackballs (the cabinet's control-panel board, see s10_exio): four free-running 8-bit X / Y counters.
// Trackball 1 = USB mouse / trackball (PS/2 Y is up-positive) and the Player 1 left analog stick, trackballs 2-4 =
// the Player 2-4 left analog sticks; a stick is a rate input (deadzone 12, ~2000 counts/s at full deflection, as
// the Konami GV core's Simpsons Bowling trackball). The game: X right = counter up, Y up = counter up.
// OSD: speed 1x / 2x / 4x / 1/2, invert X / Y, sticks on / off. Counters carry one fraction bit (for 1/2).
reg  [8:0] tbx [0:3];
reg  [8:0] tby [0:3];
initial for (int i = 0; i < 4; i++) begin tbx[i] = 0; tby[i] = 0; end
reg        tb_mtog = 0;
reg [15:0] tb_tick = 0;
reg signed [15:0] tb_ax [0:3];
reg signed [15:0] tb_ay [0:3];
initial for (int i = 0; i < 4; i++) begin tb_ax[i] = 0; tb_ay[i] = 0; end
function automatic [15:0] tb_stick(input [1:0] i);
	case (i)
		2'd0: tb_stick = joystick_analog_l0;
		2'd1: tb_stick = joystick_analog_l1;
		2'd2: tb_stick = joystick_analog_l2;
		default: tb_stick = joystick_analog_l3;
	endcase
endfunction
function automatic [8:0] tb_scale(input signed [9:0] d, input [1:0] s);   // counts -> half counts
	case (s)
		2'd0: tb_scale = 9'(d <<< 1);
		2'd1: tb_scale = 9'(d <<< 2);
		2'd2: tb_scale = 9'(d <<< 3);
		default: tb_scale = 9'(d);
	endcase
endfunction
always @(posedge clk_1x) begin : nfl_trackball
	reg signed [9:0]  dx [0:3];
	reg signed [9:0]  dy [0:3];
	reg signed [15:0] ax, ay;
	reg signed [9:0]  stx, sty;
	reg signed [7:0]  sx, sy;
	for (int i = 0; i < 4; i++) begin dx[i] = 0; dy[i] = 0; end
	if (mouse[24] != tb_mtog) begin
		tb_mtog <= mouse[24];
		dx[0] = 10'($signed({mouse[4], mouse[15:8]}));
		dy[0] = 10'($signed({mouse[5], mouse[23:16]}));
	end
	tb_tick <= (tb_tick == 16'd33867) ? 16'd0 : tb_tick + 1'd1;               // 1 ms at 33.8688 MHz
	if (tb_tick == 16'd33867 && !status[126]) begin
		for (int i = 0; i < 4; i++) begin
			sx = tb_stick(2'(i)) & 16'h00FF;
			sy = tb_stick(2'(i)) >> 8;
			ax = tb_ax[i];
			ay = tb_ay[i];
			if (sx > 8'sd12 || sx < -8'sd12) ax = ax + sx;
			if (sy > 8'sd12 || sy < -8'sd12) ay = ay + sy;
			stx = 10'(ax >>> 6);
			sty = 10'(ay >>> 6);
			tb_ax[i] <= ax - (16'(stx) <<< 6);
			tb_ay[i] <= ay - (16'(sty) <<< 6);
			dx[i] = dx[i] + stx;
			dy[i] = dy[i] - sty;                                            // stick down = Y down
		end
	end
	for (int i = 0; i < 4; i++) begin
		tbx[i] <= status[124] ? tbx[i] - tb_scale(dx[i], status[123:122]) : tbx[i] + tb_scale(dx[i], status[123:122]);
		tby[i] <= status[125] ? tby[i] - tb_scale(dy[i], status[123:122]) : tby[i] + tb_scale(dy[i], status[123:122]);
	end
end
wire [63:0] nfl_tb = {tby[3][8:1], tbx[3][8:1], tby[2][8:1], tbx[2][8:1],
                      tby[1][8:1], tbx[1][8:1], tby[0][8:1], tbx[0][8:1]};

wire [7:0]  in_p1 = b_exio_analog ?{joy[10], 2'b00, joy[6] | joy2[6], joy[3] | joy2[3], joy[2] | joy2[2], joy[4], joy[5]}
                                  : {joy[10],  joy[6],  joy[5],  joy[4],  joy[3],  joy[2],  joy[1],  joy[0]};
wire [7:0]  in_p2 = b_exio_analog ? {joy2[10], 5'b00000, joy2[4], joy2[5]}
                                  : {joy2[10], joy2[6], joy2[5], joy2[4], joy2[3], joy2[2], joy2[1], joy2[0]};
wire [31:0] in1_std  = {joy[13] | joy2[13],            // b31 SERVICE1
                        test_sw,                       // b30 TEST (slide)
                        joy[11],                       // b29 COIN1
                        joy2[11],                      // b28 COIN2
                        (b_in1_layout == 4'd1) ? ~scope : 1'b0, // b27 Golgo 13 scope sensor (active high)
                        3'b000,                        // b26-24 unused
                        joy2[9], joy2[8], joy2[7],     // b23-21 P2 buttons 6-4
                        1'b0,                          // b20 unused
                        joy[9], joy[8], joy[7],        // b19-17 P1 buttons 6-4
                        1'b0,                          // b16 unused
                        in_p2, in_p1};
wire [31:0] s10_in1  = ~((b_in1_layout == 4'd2) ? in1_nicetsuk : (b_in1_layout == 4'd3) ? in1_squizchs :
                         (b_in1_layout == 4'd4) ? in1_nfl : in1_std);
// DSW1 from the MRA <switches> (ioctl index 254): the byte is MAME's SYSTEM port bits 7-0 (active low,
// SW1:1 = bit 7 ... SW1:8 = bit 0); all off (0xFF) when the MRA has no switches
reg  [7:0] dsw_mra = 8'hFF;
always @(posedge clk_1x) if (ioctl_download && ioctl_index == 8'd254 && ioctl_wr && ioctl_addr == 0) dsw_mra <= ioctl_dout[7:0];
wire  [7:0] s10_dsw = ~dsw_mra;                        // s10_io: 1 = on

wire [23:0] h8_pc = 24'd0;                             // (System 12 debug probes, unused)
wire        h8_illegal = 1'b0;

// PSX video outputs (the loading-screen generator muxes in front of them, see VIDEO)
wire psx_hs, psx_vs, psx_hbl, psx_vbl, psx_ce_pix, psx_interlace;
wire [7:0] psx_r, psx_g, psx_b;

// ATAPI CD-ROM drive (Taiko no Tatsujin): disc image on hps_io slot 0, DMA channel 5 while it has a DMA read
wire [31:0] s10_cd_rdata, s10_exio_rdata;
wire        cd_intrq, cd_dma_pending, cd_rdma_valid;
wire [31:0] cd_rdma_data;
reg         cd_dma_sel = 1'b0;            // the current channel-5 transfer belongs to the drive (MAME m_is_cdrom_dma)
always @(posedge clk_1x) if (s12_rdma_start) cd_dma_sel <= cd_dma_pending;
wire        cd_dma_now = s12_rdma_start ? cd_dma_pending : cd_dma_sel;
wire        mem_rdma_valid;
wire [31:0] mem_rdma_data;
assign s12_rdma_valid = cd_dma_now ? cd_rdma_valid : mem_rdma_valid;
assign s12_rdma_data  = cd_dma_now ? cd_rdma_data  : mem_rdma_data;

s10_atapi s10_atapi
(
	.clk          (clk_1x),
	.reset        (reset),
	.enable       (b_cdrom),
	.addr         (s10_addr),
	.wdata        (s10_wdata),
	.wmask        (s10_wmask),
	.size         (s10_size),
	.rd           (s10_rd),
	.wr           (s10_wr),
	.rdata        (s10_cd_rdata),
	.intrq        (cd_intrq),
	.dma_pending  (cd_dma_pending),
	.rdma_valid   (cd_rdma_valid),
	.rdma_pop     (s12_rdma_pop & cd_dma_now),
	.rdma_data    (cd_rdma_data),
	.sd_lba       (cd_lba),
	.sd_blk_cnt   (cd_blk_cnt),
	.sd_rd        (cd_sd_rd),
	.sd_ack       (sd_ack[0] & ~b_memp3),
	.sd_buff_addr (sd_buff_addr),
	.sd_buff_dout (sd_buff_dout),
	.sd_buff_wr   (sd_buff_wr & ~b_memp3),
	.img_mounted  (img_mounted[0] & ~b_memp3),
	.img_size     (img_size)
);

// MiSTer analog axis (signed, -128..127, right/down positive) -> 10-bit ADC value 0..1023 (MAME EXIO_ANALOG
// PORT_MINMAX(0, 0x3ff); PORT_REVERSE where MAME has it)
function automatic [9:0] ax10(input [7:0] a, input rev);
	reg [7:0] u;
	begin
		u = a ^ 8'h80;                       // offset binary: 0 = full left/up, 255 = full right/down
		if (rev) u = ~u;
		ax10 = {u, u[7:6]};
	end
endfunction

// EXIO board with microcontroller (Taiko no Tatsujin drums), high-level. Drum zones from Buttons 2-5:
// Left Don = left surface, Right Don = right surface, Left Ka = left rim, Right Ka = right rim.
// Order = EXIO_ANALOG1-8: P1 right rim, P1 right surface, P1 left surface, P1 left rim, then P2.
s10_exio s10_exio
(
	.clk    (clk_1x),
	.reset  (reset),
	.enable (b_exio_mcu),
	.addr   (s10_addr),
	.wdata  (s10_wdata),
	.wmask  (s10_wmask),
	.size   (s10_size),
	.rd     (s10_rd),
	.wr     (s10_wr),
	.rdata  (s10_exio_rdata),
	.drum   ({joy2[7], joy2[5], joy2[6], joy2[8], joy[7], joy[5], joy[6], joy[8]}),
	.analog_en (b_exio_analog),
	.analog ({ax10(joystick_analog_r1[15:8], 0), ax10(joystick_analog_r1[7:0], 1),     // P2 right Y, X (X reversed)
	          ax10(joystick_analog_l1[15:8], 1), ax10(joystick_analog_l1[7:0], 0),     // P2 left Y (reversed), X
	          ax10(joystick_analog_r0[15:8], 0), ax10(joystick_analog_r0[7:0], 1),     // P1 right
	          ax10(joystick_analog_l0[15:8], 1), ax10(joystick_analog_l0[7:0], 0)}),   // P1 left
	.serial_en (b_nfl),
	.tb        (nfl_tb),
	.exio_in1  (b_nfl ? nfl_exio_in1 : 16'hFFFF)
);

// EXIO(G) light guns (Point Blank 3): aim from the MiSTer gun / analog stick or the mouse, trigger = button 1
wire [7:0] gun_p1x, gun_p1y, gun_p2x, gun_p2y;
wire [8:0] gun_x0, gun_y0, gun_x1, gun_y1;
s10_gun s10_gun
(
	.clk       (clk_1x),
	.src_mouse (status[120]),
	.joy_a0    (joystick_analog_l0),
	.joy_a1    (joystick_analog_l1),
	.ps2_mouse (mouse),
	.p1_x      (gun_p1x),
	.p1_y      (gun_p1y),
	.p2_x      (gun_p2x),
	.p2_y      (gun_p2y),
	.x0        (gun_x0),
	.y0        (gun_y0),
	.x1        (gun_x1),
	.y1        (gun_y1)
);

s10_io s10_io
(
	.clk        (clk_1x),
	.reset      (reset),
	.addr       (s10_addr),
	.wdata      (s10_wdata),
	.wmask      (s10_wmask),
	.size       (s10_size),
	.rd         (s10_rd),
	.wr         (s10_wr),
	.rdata      (s10_io_rdata),
	.dsw        (s10_dsw),
	.in1        (s10_in1),
	.exio_ident (b_exio_ident),
	.gun_x0     (gun_x0),
	.gun_y0     (gun_y0),
	.gun_x1     (gun_x1),
	.gun_y1     (gun_y1),
	.irq10_vbl  (status[65]),
	.vblank     (psx_vbl),
	.cd_intrq   (cd_intrq),
	.irq10      (s10_irq10)
);

// MEM(P3) board: MCU RAM window + high-level MCU / MP3 decoder (Golgo 13, Nice Tsukkomi, Seishun Quiz)
wire        p3_play, p3_stop, p3_stall, p3_wstall;
wire [23:0] p3_len;
wire [31:0] p3_c0, p3_c1, p3_c2, s10_p3_rdata;
wire  [6:0] p3_vol;
wire        p3_ddr_request, p3_ddr_ack, p3_ddr_we, p3_ddr_rd, p3_ddr_dout_ready;
wire  [7:0] p3_ddr_burstcnt, p3_ddr_be;
wire [27:0] p3_ddr_addr;
wire [63:0] p3_ddr_din;
wire        m_ddr_request, m_ddr_ack, m_ddr_we, m_ddr_rd, m_ddr_dout_ready;
wire  [7:0] m_ddr_burstcnt, m_ddr_be;
wire [27:0] m_ddr_addr;
wire [63:0] m_ddr_din;
wire        p3_win = b_memp3 && (s10_addr[23:18] == 6'b001100);   // 0x1F300000-0x1F33FFFF

s10_p3 s10_p3
(
	.clk            (clk_1x),
	.clk2           (clk_2x),
	.reset          (reset),
	.enable         (b_memp3),
	.mcu_base       (28'hF000000),                         // DDR3 0x3F000000
	.addr           (s10_addr),
	.wdata          (s10_wdata),
	.wmask          (s10_wmask),
	.size           (s10_size),
	.rd             (s10_rd),
	.wr             (s10_wr),
	.rdata          (s10_p3_rdata),
	.stall          (p3_stall),
	.wstall         (p3_wstall),
	.aim_x          ({gun_p1x, gun_p1x[7:6]}),                // Golgo 13 rifle: P1 gun / stick / mouse
	.aim_y          ({gun_p1y, gun_p1y[7:6]}),
	.play_req       (p3_play),
	.play_len       (p3_len),
	.play_c0        (p3_c0),
	.play_c1        (p3_c1),
	.play_c2        (p3_c2),
	.stop_req       (p3_stop),
	.volume         (p3_vol),
	.ddr_request    (p3_ddr_request),
	.ddr_ack        (p3_ddr_ack),
	.ddr_burstcnt   (p3_ddr_burstcnt),
	.ddr_addr       (p3_ddr_addr),
	.ddr_din        (p3_ddr_din),
	.ddr_be         (p3_ddr_be),
	.ddr_we         (p3_ddr_we),
	.ddr_rd         (p3_ddr_rd),
	.ddr_dout       (psx_ddram_dout),
	.ddr_dout_ready (p3_ddr_dout_ready)
);

s10_p3audio s10_p3audio
(
	.clk          (clk_1x),
	.reset        (reset),
	.enable       (b_memp3),
	.play_req     (p3_play),
	.play_len     (p3_len),
	.play_c0      (p3_c0),
	.play_c1      (p3_c1),
	.play_c2      (p3_c2),
	.stop_req     (p3_stop),
	.volume       (p3_vol),
	.audio_l      (p3_aud_l),
	.audio_r      (p3_aud_r),
	.sd_lba       (p3_lba),
	.sd_blk_cnt   (p3_blk_cnt),
	.sd_rd        (p3_sd_rd),
	.sd_ack       (sd_ack[0] & b_memp3),
	.sd_buff_addr (sd_buff_addr),
	.sd_buff_dout (sd_buff_dout),
	.sd_buff_wr   (sd_buff_wr & b_memp3),
	.img_mounted  (img_mounted[0]),                       // ungated: MiSTer may mount the remembered file before the record
	.img_size     (img_size)
);

s10_ddr_mux s10_ddr_mux
(
	.clk2           (clk_2x),
	.reset          (reset),
	.a_request      (m_ddr_request),
	.a_ack          (m_ddr_ack),
	.a_burstcnt     (m_ddr_burstcnt),
	.a_addr         (m_ddr_addr),
	.a_din          (m_ddr_din),
	.a_be           (m_ddr_be),
	.a_we           (m_ddr_we),
	.a_rd           (m_ddr_rd),
	.a_dout_ready   (m_ddr_dout_ready),
	.b_request      (p3_ddr_request),
	.b_ack          (p3_ddr_ack),
	.b_burstcnt     (p3_ddr_burstcnt),
	.b_addr         (p3_ddr_addr),
	.b_din          (p3_ddr_din),
	.b_be           (p3_ddr_be),
	.b_we           (p3_ddr_we),
	.b_rd           (p3_ddr_rd),
	.b_dout_ready   (p3_ddr_dout_ready),
	.ddr_request    (s10_ddr_request),
	.ddr_ack        (s10_ddr_ack),
	.ddr_burstcnt   (s10_ddr_burstcnt),
	.ddr_addr       (s10_ddr_addr),
	.ddr_din        (s10_ddr_din),
	.ddr_be         (s10_ddr_be),
	.ddr_we         (s10_ddr_we),
	.ddr_rd         (s10_ddr_rd),
	.ddr_dout_ready (psx_ddram_dout_ready)
);

s10_mem s10_mem
(
	.clk            (clk_1x),
	.clk2           (clk_2x),
	.reset          (reset),
	.board_memn     (b_memn),
	.crypt_type     (b_crypt),
	.nand_count     (b_nand_count),
	.nand_big       (b_nand_big),
	.data_xor       (b_data_xor),
	.perm           (b_perm),
	.img_base       (IMG_BASE),
	.save_base      (b_save_base),
	.t2_row_we      (b_t2_row_we),
	.t2_row_addr    (b_t2_row_addr),
	.t2_row_lane    (b_t2_row_lane),
	.t2_row_data    (b_t2_row_data),
	.t2_xmask       (b_t2_xmask),
	.t2_nl_out      (b_t2_nl_out),
	.t2_nterms      (b_t2_nterms),
	.t2_nl_table    (b_nl_table),
	.t2_nl_bits     (b_nl_bits),
	.nl_off         (NL_OFF),
	.addr           (s10_addr),
	.wdata          (s10_wdata),
	.wmask          (s10_wmask),
	.size           (s10_size),
	.rd             (s10_rd),
	.wr             (s10_wr & ~p3_win),
	.rdata          (s10_mem_rdata),
	.stall          (s10_stall),
	.rdma_start     (s12_rdma_start & ~cd_dma_pending),
	.rdma_valid     (mem_rdma_valid),
	.rdma_pop       (s12_rdma_pop & ~cd_dma_now),
	.rdma_want      (s12_rdma_want & ~cd_dma_now),
	.rdma_data      (mem_rdma_data),
	.sram_req       (s10_sram_req),
	.sram_addr      (s10_sram_addr),
	.sram_rnw       (s10_sram_rnw),
	.sram_be        (s10_sram_be),
	.sram_wdata     (s10_sram_wdata),
	.sram_rdata     (s10_sram_rdata),
	.sram_ready     (s10_sram_ready),
	.up_active      (ioctl_upload && ioctl_index == 8'd9),
	.up_rd          (ioctl_rd),
	.up_addr        (ioctl_addr),
	.up_din         (ioctl_din),
	.up_wait        (s10_up_wait),
	.save_req       (ioctl_upload_req),
	.ddr_request    (m_ddr_request),
	.ddr_ack        (m_ddr_ack),
	.ddr_burstcnt   (m_ddr_burstcnt),
	.ddr_addr       (m_ddr_addr),
	.ddr_din        (m_ddr_din),
	.ddr_be         (m_ddr_be),
	.ddr_we         (m_ddr_we),
	.ddr_rd         (m_ddr_rd),
	.ddr_dout       (psx_ddram_dout),
	.ddr_dout_ready (m_ddr_dout_ready)
);

wire [31:0] jtag_addr = 32'd0;
wire        dbg_reached_game;

psx_mister
psx
(
   .clk1x(clk_1x),
   .clk2x(clk_2x),
   .clk3x(clk_3x),
   .clkvid(clk_vid),
   .reset(reset),
   .isPaused(isPaused),
   // commands
   .pause(paused),
   .hps_busy(hps_busy),
   .loadExe(loadExe),
   .exe_initial_pc(exe_initial_pc),
   .exe_initial_gp(exe_initial_gp),
   .exe_load_address(exe_load_address),
   .exe_file_size(exe_file_size),
   .exe_stackpointer(exe_stackpointer),
   .fastboot(1'b0),
   .ram8mb(1'b1),
   .TURBO_MEM(TURBO_MEM),
   .TURBO_COMP(TURBO_COMP),
   .TURBO_CACHE(TURBO_CACHE),
   .TURBO_CACHE50(TURBO_CACHE50),
   .REPRODUCIBLEGPUTIMING(0),
   .INSTANTSEEK(1'b0),
   .FORCECDSPEED(3'd0),
   .LIMITREADSPEED(1'b0),
   .IGNORECDDMATIMING(1'b0),
   .ditherOff(status[22]),
   .interlaced480pHack(1'b0),   // Tenkomori is 240p; the 480i->480p hack only doubled VRAM writes
   .showGunCrosshairs(1'b0),
   .enableNeGconRumble(1'b0),
   .fpscountOn(1'b0),  // GITHUB template: FPS-counter debug overlay excluded
   .cdslowOn(1'b0),
   .testSeek(1'b0),
   .pauseOnCDSlow(1'b0),
   .errorOn(1'b0),
   .LBAOn(1'b0),         // debug readout (DMA channel + MIPS PC) disabled for release
   .PATCHSERIAL(0), //.PATCHSERIAL(status[54]),
   .noTexture(1'b0),
   .textureFilter(2'd0),
   .textureFilterStrength(2'd0),
   .textureFilter2DOff(1'b0),
   .dither24(1'b0),
   .render24(1'b0),
   .drawSlow(1'b0),
   .syncVideoOut(syncVideoOut),
   .syncInterlace(1'b0),
   .rotate180(orient_flip180),
   .fixedVBlank(1'b0),
   .vCrop(2'b00),
   .hCrop(b_edge_mask),  // Taiko 3: hide its scratch pixels right of the 320-wide frame buffer (display starts at x=2)
   .SPUon(1'b1),
   .SPUIRQTrigger(1'b0),
   .SPUSDRAM(1'b0),
   .REVERBOFF(0),
   .REPRODUCIBLESPUDMA(1'b0),
   .WIDESCREEN(2'b00),
   .oldGPU(1'b0),
   // RAM/BIOS interface
   .biosregion(biosregion),
   .ram_refresh(sdr_refresh),
   .ram_dataWrite(sdr_sdram_din),
   .ram_dataRead32(sdr_sdram_dout32),
   .ram_Adr(sdram_addr),
   .ram_cntDMA(sdram_cntDMA),
   .ram_be(sdram_be),
   .ram_rnw(sdram_rnw),
   .ram_ena(sdram_req),
   .ram_dma(sdram_dma),
   .ram_cache(sdram_cache),
   .ram_done(sdram_ack),
   .ram_dmafifo_adr  (sdram_dmafifo_adr),
   .ram_dmafifo_data (sdram_dmafifo_data),
   .ram_dmafifo_empty(sdram_dmafifo_empty),
   .ram_dmafifo_read (sdram_dmafifo_read),
   .cache_wr(cache_wr),
   .cache_data(cache_data),
   .cache_addr(cache_addr),
   .dma_wr(dma_wr),
   .dma_reqprocessed(dma_reqprocessed),
   .dma_data(dma_data),
   // vram/ddr3
   .DDRAM_BUSY      (psx_ddram_busy      ),
   .DDRAM_BURSTCNT  (psx_ddram_burstcnt  ),
   .DDRAM_ADDR      (psx_ddram_addr      ),
   .DDRAM_DOUT      (psx_ddram_dout      ),
   .DDRAM_DOUT_READY(psx_ddram_dout_ready),
   .DDRAM_RD        (psx_ddram_rd        ),
   .DDRAM_DIN       (psx_ddram_din       ),
   .DDRAM_BE        (psx_ddram_be        ),
   .DDRAM_WE        (psx_ddram_we        ),
   // cd (unused in ZN)
   .region          (2'b01),    // JP
   .region_out      (region_out),
   .hasCD           (1'b0),
   .LIDopen         (1'b0),
   .fastCD          (1'b0),
   .trackinfo_data  (32'h0),
   .trackinfo_addr  (9'h0),
   .trackinfo_write (1'b0),
   .resetFromCD     (resetFromCD),
   .cd_hps_req      (),
   .cd_hps_lba      (),
   .cd_hps_ack      (1'b0),
   .cd_hps_write    (1'b0),
   .cd_hps_data     (16'h0),
   // spuram
   .spuram_dataWrite(spuram_dataWrite),
   .spuram_Adr      (spuram_Adr      ),
   .spuram_be       (spuram_be       ),
   .spuram_rnw      (spuram_rnw      ),
   .spuram_ena      (spuram_ena      ),
   .spuram_dataRead (spuram_dataRead ),
   .spuram_done     (spuram_done     ),
   // memcard (unused in ZN)
   .memcard_changed (),
   .saving_memcard  (),
   .memcard1_load   (1'b0),
   .memcard2_load   (1'b0),
   .memcard_save    (1'b0),
   .memcard1_mounted   (1'b0),
   .memcard1_available (1'b0),
   .memcard1_rd     (),
   .memcard1_wr     (),
   .memcard1_lba    (),
   .memcard1_ack    (1'b0),
   .memcard1_write  (1'b0),
   .memcard1_addr   (9'h0),
   .memcard1_dataIn (16'h0),
   .memcard1_dataOut(),
   .memcard2_mounted   (1'b0),
   .memcard2_available (1'b0),
   .memcard2_rd     (),
   .memcard2_wr     (),
   .memcard2_lba    (),
   .memcard2_ack    (1'b0),
   .memcard2_write  (1'b0),
   .memcard2_addr   (9'h0),
   .memcard2_dataIn (16'h0),
   .memcard2_dataOut(),
   // video
   .videoout_on     (1'b1),
   .isPal           (isPal),
   .pal60           (1'b0),
   .hsync           (psx_hs),
   .vsync           (psx_vs),
   .hblank          (psx_hbl),
   .vblank          (psx_vbl),
   .DisplayWidth    (DisplayWidth),
   .DisplayHeight   (DisplayHeight),
   .DisplayOffsetX  (DisplayOffsetX),
   .DisplayOffsetY  (DisplayOffsetY),
   .video_ce        (psx_ce_pix),
   .video_interlace (psx_interlace),
   .video_r         (psx_r),
   .video_g         (psx_g),
   .video_b         (psx_b),
   .video_isPal     (video_isPal),
   .video_fbmode    (video_fbmode),
   .video_fb24      (video_fb24),
   .video_hResMode  (video_hResMode),
   .video_frameindex(frameindex),
   //Keys
   .DSAltSwitchMode(1'b0),
   .PadPortEnable1 (PadPortEnable1),
   .PadPortDigital1(PadPortDigital1),
   .PadPortAnalog1 (PadPortAnalog1),
   .PadPortMouse1  (PadPortMouse1 ),
   .PadPortGunCon1 (PadPortGunCon1),
   .PadPortNeGcon1 (PadPortNeGcon1),
   .PadPortWheel1  (PadPortWheel1),
   .PadPortDS1     (PadPortDS1),
   .PadPortJustif1 (PadPortJustif1),
   .PadPortStick1  (PadPortStick1),
   .PadPortPopn1   (PadPortPopn1),
   .PadPortEnable2 (PadPortEnable2),
   .PadPortDigital2(PadPortDigital2),
   .PadPortAnalog2 (PadPortAnalog2),
   .PadPortMouse2  (PadPortMouse2 ),
   .PadPortGunCon2 (PadPortGunCon2),
   .PadPortNeGcon2 (PadPortNeGcon2),
   .PadPortWheel2  (PadPortWheel2),
   .PadPortDS2     (PadPortDS2),
   .PadPortJustif2 (PadPortJustif2),
   .PadPortStick2  (PadPortStick2),
   .PadPortPopn2   (PadPortPopn2),
   .KeyTriangle({joy4[4], joy3[4], joy2[4], joy[4] }),
   .KeyCircle  ({joy4[5] ,joy3[5] ,joy2[5] ,joy[5] }),
   .KeyCross   ({joy4[6] ,joy3[6] ,joy2[6] ,joy[6] }),
   .KeySquare  ({joy4[7] ,joy3[7] ,joy2[7] ,joy[7] }),
   .KeySelect  ({joy4[8] ,joy3[8] ,joy2[8] ,joy[8] }),
   .KeyStart   ({joy4[9] ,joy3[9] ,joy2[9] ,joy[9] }),
   .KeyRight   ({joy4[0] ,joy3[0] ,joy2[0] ,joy[0] }),
   .KeyLeft    ({joy4[1] ,joy3[1] ,joy2[1] ,joy[1] }),
   .KeyUp      ({joy4[3] ,joy3[3] ,joy2[3] ,joy[3] }),
   .KeyDown    ({joy4[2] ,joy3[2] ,joy2[2] ,joy[2] }),
   .KeyR1      ({joy4[11],joy3[11],joy2[11],joy[11]}),
   .KeyR2      ({joy4[13],joy3[13],joy2[13],joy[13]}),
   .KeyR3      ({joy4[15],joy3[15],joy2[15],joy[15]}),
   .KeyL1      ({joy4[10],joy3[10],joy2[10],joy[10]}),
   .KeyL2      ({joy4[12],joy3[12],joy2[12],joy[12]}),
   .KeyL3      ({joy4[14],joy3[14],joy2[14],joy[14]}),
   .ToggleDS   (ToggleDS),
   .Analog1XP1(joy0_xmuxed),
   .Analog1YP1(joystick_analog_l0[15:8]),
   .Analog2XP1(joystick_analog_r0[7:0]),
   .Analog2YP1(joystick_analog_r0[15:8]),
   .Analog1XP2(joystick_analog_l1[7:0]),
   .Analog1YP2(joystick_analog_l1[15:8]),
   .Analog2XP2(joystick_analog_r1[7:0]),
   .Analog2YP2(joystick_analog_r1[15:8]),
   .Analog1XP3(joystick_analog_l2[7:0]),
   .Analog1YP3(joystick_analog_l2[15:8]),
   .Analog2XP3(joystick_analog_r2[7:0]),
   .Analog2YP3(joystick_analog_r2[15:8]),
   .Analog1XP4(joystick_analog_l3[7:0]),
   .Analog1YP4(joystick_analog_l3[15:8]),
   .Analog2XP4(joystick_analog_r3[7:0]),
   .Analog2YP4(joystick_analog_r3[15:8]),
   .RumbleDataP1(joystick1_rumble),
   .RumbleDataP2(joystick2_rumble),
   .RumbleDataP3(joystick3_rumble),
   .RumbleDataP4(joystick4_rumble),
   .padMode(padMode),
   .MouseEvent(mouse[24]),
   .MouseLeft(mouse[0]),
   .MouseRight(mouse[1]),
   .MouseX({mouse[4],mouse[15:8]}),
   .MouseY({mouse[5],mouse[23:16]}),
   .multitap(multitap),
   .multitapDigital(multitapDigital),
   .multitapAnalog(multitapAnalog),
   //snac
   .snacPort1(snacPort1),
   .snacPort2(snacPort2),
   .selectedPort1Snac(selectedPort1Snac),
   .selectedPort2Snac(selectedPort2Snac),
   .irq10Snac(irq10Snac),
   .transmitValueSnac(transmitValueSnac),
   .clk9Snac(clk9Snac),
   .receiveBufferSnac(receiveBufferSnac),
   .beginTransferSnac(beginTransferSnac),
   .actionNextSnac(actionNextSnac),
   .receiveValidSnac(receiveValidSnac),
   .ackSnac(~ack),//using real ack not the 1 cycle ack
   .snacMC(1'b0),

   //sound
	.sound_out_left(psx_aud_l),
	.sound_out_right(psx_aud_r),
   // savestates: off. A PlayStation savestate cannot hold the System 10 board (MEM board, ATAPI, EXIO, MEM(P3)),
   // so loading one would corrupt the game; tied off, the save/load logic is also removed by synthesis
   .increaseSSHeaderCount (1'b0),
   .save_state            (1'b0),
   .load_state            (1'b0),
   .savestate_number      (ss_slot),
   .state_loaded          (),
   .validSStates          (validSStates),
   .rewind_on             (0), //(status[27]),
   .rewind_active         (0), //(status[27] & joy[15]),
   //cheats
   .cheat_clear(gg_reset),
   .cheats_enabled(1'b0),
   .cheat_on(gg_valid),
   .cheat_in(gg_code),
   .cheats_active(gg_active),

   .Cheats_BusAddr(cheats_addr),
   .Cheats_BusRnW(cheats_rnw),
   .Cheats_BusByteEnable(cheats_be),
   .Cheats_BusWriteData(cheats_dout),
   .Cheats_Bus_ena(cheats_ena),
   .Cheats_BusReadData(cheats_din),
   .Cheats_BusDone(1'b0),

   // ZN-1 Arcade I/O
   .zn_p1_right   (joy[0]),
   .zn_p1_left    (joy[1]),
   .zn_p1_down    (joy[2]),
   .zn_p1_up      (joy[3]),
   .zn_p1_btn     (joy[9:4]),    // btn1-6 = joy[4..9]
   .zn_p1_start   (joy[10]),
   .zn_p1_coin    (joy[11]),
   .zn_p2_right   (joy2[0]),
   .zn_p2_left    (joy2[1]),
   .zn_p2_down    (joy2[2]),
   .zn_p2_up      (joy2[3]),
   .zn_p2_btn     (joy2[9:4]),
   .zn_p2_start   (joy2[10]),
   .zn_p2_coin    (joy2[11]),
   .zn_service    (1'b0),  // GITHUB template: OSD Service toggle excluded
   .zn_test_mode  (1'b0),  // GITHUB template: OSD Test toggle excluded
   .zn_dsw        (8'hFF),       // all DIP switches ON (normal/defaults)
   // CAT702 keys loaded dynamically via MRA rom index 4 (key_a=KN01/motherboard) and 5 (key_b=KN02/game)
   // CAT702 select is ACTIVE LOW: key_a used for 0x88 path (KN01), key_b used for 0x84 path (KN02)
   .zn_cat702_key  (64'd0),
   .zn_cat702_key_b(64'd0),
   .zn_platform    (4'd0),
   .zn_system11    (1'b1),               // Namco arcade memory map (System 10 board bus, see memorymux)
   .zn_gputype1_force(1'b0),             // CXD8561CQ = type-2 GPU (MAME gputype 2)
   .keycus_id      (8'd0),
   .s10_addr       (s10_addr),
   .s10_wdata      (s10_wdata),
   .s10_wmask      (s10_wmask),
   .s10_size       (s10_size),
   .s10_rd         (s10_rd),
   .s10_wr         (s10_wr),
   .s10_rdata      (s10_io_rdata | s10_mem_rdata | s10_cd_rdata | s10_exio_rdata | s10_p3_rdata),
   .s10_stall      (s10_stall | p3_stall),
   .s10_wstall     (p3_wstall),
   .s10_irq10      (s10_irq10),
   .s10_exio       (b_exio_ident != 8'hFF),
   .s10_gun_cross  ({b_light_gun & status[121] & ~b_memp3, b_light_gun & status[121]}),   // Golgo 13: P1 only
   .s10_gun1_x     (gun_p1x),
   .s10_gun1_y     (gun_p1y),
   .s10_gun2_x     (gun_p2x),
   .s10_gun2_y     (gun_p2y),
   .s10_ddr_request(s10_ddr_request),
   .s10_ddr_ack    (s10_ddr_ack),
   .s10_ddr_burstcnt(s10_ddr_burstcnt),
   .s10_ddr_addr   (s10_ddr_addr),
   .s10_ddr_din    (s10_ddr_din),
   .s10_ddr_be     (s10_ddr_be),
   .s10_ddr_we     (s10_ddr_we),
   .s10_ddr_rd     (s10_ddr_rd),
   .s12_rdma_start (s12_rdma_start),
   .s12_rdma_src   (s12_rdma_src),
   .s12_rdma_valid (s12_rdma_valid),
   .s12_rdma_pop   (s12_rdma_pop),
   .s12_rdma_want  (s12_rdma_want),
   .s12_rdma_data  (s12_rdma_data),
   .dbg_c76_in     (2'b00),
   .dbg_c76_pc     (24'd0),
   .dbg_reached_game(dbg_reached_game),          // MIPS reached game code -> overlay auto-hide
   .zn_debug_out   (zn_debug_out),
   .zn_debug_val   (zn_debug_val),
   .zn_dbg_a0      (zn_dbg_a0),
   .zn_dbg_a1      (zn_dbg_a1),
   .zn_dbg_eeprom_o(zn_dbg_eeprom_o),
   .zn_dbg_gpu     (zn_dbg_gpu),
   .zn_dbg_disp    (zn_dbg_disp),
   .zn_dbg_dma     (zn_dbg_dma),
   .zn_dbg_madr    (zn_dbg_madr),
   .zn_dbg_nextaddr(zn_dbg_nextaddr),
   .zn_dbg_gpustat (zn_dbg_gpustat),
   .zn_dbg_procst  (zn_dbg_procst),
   .zn_dbg_pv0     (zn_dbg_pv0),
   .zn_dbg_mipspc  (zn_dbg_mipspc),
   .zn_dbg_pause   (zn_dbg_pause),
   .zn_dbg_pv2     (zn_dbg_pv2),
   .dbg_vram_coord (jtag_addr),    // JTAG VRAM readback: write 0xF<Y><X> to read VRAM[x,y] via mode D

   .trace_flat     (trace_flat),
   .trace_meta     (trace_meta),
   .zn_debug_addr  (zn_debug_addr),
   .zn_debug_words (zn_debug_words)
);

////////////////////////////  MEMORY  ///////////////////////////////////

localparam ROM_START = (65536+131072)*4;

wire         sdr_refresh;
wire  [31:0] sdr_sdram_din;
wire  [31:0] sdr_sdram_dout32;
wire  [15:0] sdr_bram_din;
wire         sdr_sdram_ack;
wire         sdr_bram_ack;
wire  [26:0] sdram_addr;
wire   [1:0] sdram_cntDMA;
wire   [3:0] sdram_be;
wire         sdram_req;
wire         sdram_ack;
wire         sdram_readack;
wire         sdram_readack2;
wire         sdram_writeack;
wire         sdram_writeack2;
wire         sdram_rnw;
wire         sdram_dma;
wire         sdram_cache;
wire [ 3:0]  cache_wr;
wire [31:0]  cache_data;
wire [ 7:0]  cache_addr;
wire         dma_wr;
wire         dma_reqprocessed;
wire [31:0]  dma_data;

wire  [22:0] sdram_dmafifo_adr;
wire  [31:0] sdram_dmafifo_data;
wire         sdram_dmafifo_empty;
wire         sdram_dmafifo_read;


wire [20:0] cheats_addr;
wire cheats_rnw;
wire [3:0] cheats_be;
wire [31:0] cheats_dout;
wire cheats_ena;
wire [31:0] cheats_din;
wire sdramCh3_done;

wire [31:0] zn_dbg_a0, zn_dbg_a1;
wire [31:0] zn_dbg_eeprom_o;
wire [31:0] zn_dbg_gpu;
wire [31:0] zn_dbg_disp;
wire [31:0] zn_dbg_dma;
wire [31:0] zn_dbg_madr;
wire [31:0] zn_dbg_nextaddr;
wire [31:0] zn_dbg_gpustat;
wire [31:0] zn_dbg_procst;
wire [31:0] zn_dbg_pv0, zn_dbg_pv2;
wire [31:0] zn_dbg_mipspc;
wire [31:0] zn_dbg_pause;
wire [8:0]  dbg_sdram_fsm;
wire [7:0]  dbg_sdram_drd1;

// SDRAM channel 3: BIOS download writes, fills (BIOS 0x55, RAM clear), MEM(N) SRAM
wire [26:0] ch3_addr;
wire [31:0] ch3_din;
wire        ch3_req;
wire        ch3_rnw;
wire  [3:0] ch3_be;

s10_ch3 #(.SRAM_BASE(32'h0800000)) s10_ch3
(
	.clk         (clk_1x),
	.ch3_addr    (ch3_addr),
	.ch3_din     (ch3_din),
	.ch3_dout    (cheats_din),
	.ch3_req     (ch3_req),
	.ch3_rnw     (ch3_rnw),
	.ch3_be      (ch3_be),
	.ch3_ready   (sdramCh3_done),
	.dl_req      (ld_dl_req),
	.dl_addr     (ld_dl_addr),
	.dl_data     (ld_dl_data),
	.dl_done     (dl_done),
	.fill_start  (ld_fill_start | clr_start),
	.fill_base   (clr_start ? 27'd0 : ld_fill_base),
	.fill_words  (clr_start ? 21'h100000 : ld_fill_words),
	.fill_value  (clr_start ? 32'd0 : ld_fill_value),
	.fill_busy   (fill_busy),
	.sram_req    (s10_sram_req),
	.sram_addr   (s10_sram_addr),
	.sram_rnw    (s10_sram_rnw),
	.sram_be     (s10_sram_be),
	.sram_wdata  (s10_sram_wdata),
	.sram_rdata  (s10_sram_rdata),
	.sram_ready  (s10_sram_ready)
);

assign sdram_ack = sdram_readack | sdram_writeack;

sdram sdram
(
   .SDRAM_DQ   (SDRAM_DQ),
   .SDRAM_A    (SDRAM_A),
   .SDRAM_DQML (SDRAM_DQML),
   .SDRAM_DQMH (SDRAM_DQMH),
   .SDRAM_BA   (SDRAM_BA),
   .SDRAM_nCS  (SDRAM_nCS),
   .SDRAM_nWE  (SDRAM_nWE),
   .SDRAM_nRAS (SDRAM_nRAS),
   .SDRAM_nCAS (SDRAM_nCAS),
   .SDRAM_CKE  (SDRAM_CKE),
   .SDRAM_CLK  (SDRAM_CLK),

   .SDRAM_EN(1),
	.init(~pll_locked),
	.clk(clk_3x),       // STOCK ZN1 config: SDRAM on clk_3x=101.6MHz (proven-working in the ZN1 sibling core)
	.clk_sdramclk(clk_3x),     // SDRAM_CLK unshifted (stock write timing, matches sdram2/ZN1 baseline)
	.clk_dqcap(clk_3x),        // stock 0° capture (+90° A/B 2026-07-11: NO effect on T2 corruption, 620 vs 652 — not a DQ-margin fault)
	                           // corruption — root cause was the gpu.vhd fifoIn PIO/DMA write collision
	                           // (word drop), not DQ margin. Reverted to the proven ZN1 baseline.
	.clk_base(clk_1x),

	.refreshForce(sdr_refresh),
	.pagemode_en(1'b0),   // page-mode disabled: every read does ACTIVE (conservative stock behavior)

	.ch1_addr(sdram_addr),
	.ch1_din(),
	.ch1_dout(),
	.ch1_dout32(sdr_sdram_dout32),
	.ch1_req(sdram_req & sdram_rnw),
	.ch1_rnw(1'b1),
	.ch1_dma(sdram_dma),
	.ch1_cntDMA(sdram_cntDMA),
	.ch1_cache(sdram_cache),
	.ch1_ready(sdram_readack),
	.cache_wr(cache_wr),
	.cache_data(cache_data),
	.cache_addr(cache_addr),
	.dma_wr(dma_wr),
	.dma_reqprocessed(dma_reqprocessed),
	.dma_data(dma_data),

	.ch2_addr (sdram_addr),
	.ch2_din  (sdr_sdram_din),
	.ch2_dout (),
	.ch2_req  (sdram_req & ~sdram_rnw),
	.ch2_rnw  (1'b0),
	.ch2_be   (sdram_be),
	.ch2_ready(sdram_writeack),

	.ch3_addr (ch3_addr),
	.ch3_din  (ch3_din),
	.ch3_dout (cheats_din),
	.ch3_req  (ch3_req),
	.ch3_rnw  (ch3_rnw),
	.ch3_be   (ch3_be),
	.ch3_ready(sdramCh3_done),

	.dmafifo_adr  (sdram_dmafifo_adr),
	.dmafifo_data (sdram_dmafifo_data),
	.dmafifo_empty(sdram_dmafifo_empty),
	.dmafifo_read (sdram_dmafifo_read),
	.dbg_pm_hit   (),
	.dbg_pm_open  (),
	.dbg_pm_pre   (),
	.dbg_sdram    (dbg_sdram_fsm),
	.dbg_drd1     (dbg_sdram_drd1)
);
// SDRAM JTAG diagnostics removed with the revert-to-ZN1-stock; tie the probe wires off (read 0).
wire [31:0]  sdram_dbg_raw = 32'b0;

wire [31:0] spuram_dataWrite;
wire [18:0] spuram_Adr;
wire  [3:0] spuram_be;
wire        spuram_rnw;
wire        spuram_ena;
wire [31:0] spuram_dataRead;
wire        spuram_done;

assign spuram_done     = sdram_readack2 | sdram_writeack2;

`ifdef MISTER_DUAL_SDRAM

sdram sdram2
(
	.SDRAM_DQ   (SDRAM2_DQ),
   .SDRAM_A    (SDRAM2_A),
   .SDRAM_DQML (),
   .SDRAM_DQMH (),
   .SDRAM_BA   (SDRAM2_BA),
   .SDRAM_nCS  (SDRAM2_nCS),
   .SDRAM_nWE  (SDRAM2_nWE),
   .SDRAM_nRAS (SDRAM2_nRAS),
   .SDRAM_nCAS (SDRAM2_nCAS),
   .SDRAM_CKE  (),
   .SDRAM_CLK  (SDRAM2_CLK),
   .SDRAM_EN   (SDRAM2_EN),

	.init(~pll_locked),
	.clk(clk_3x),       // STOCK ZN1 config: SDRAM on clk_3x=101.6MHz
	.clk_sdramclk(clk_3x),  // sdram2 (SPU): SDRAM_CLK on clk_3x (unchanged)
	.clk_dqcap(clk_3x),     // sdram2 read-DQ capture clock (stock)
	.clk_base(clk_1x),

	.refreshForce(1'b0),
	.pagemode_en(1'b0),
	.ram_idle(),

	.ch1_addr(spuram_Adr),
	.ch1_din(),
	.ch1_dout(),
	.ch1_dout32(spuram_dataRead),
	.ch1_req(spuram_ena & spuram_rnw),
	.ch1_rnw(1'b1),
	.ch1_dma(1'b0),
   .ch1_cntDMA(2'b00),
	.ch1_cache(1'b0),
	.ch1_ready(sdram_readack2),

	.ch2_addr (spuram_Adr),
	.ch2_din  (spuram_dataWrite),
	.ch2_dout (),
	.ch2_req  (spuram_ena & ~spuram_rnw),
	.ch2_rnw  (1'b0),
   .ch2_be   (spuram_be),
	.ch2_ready(sdram_writeack2),

	.ch3_addr(0),
	.ch3_din(),
	.ch3_dout(),
	.ch3_req(1'b0),
	.ch3_rnw(1'b1),
	.ch3_ready(),

	.dmafifo_adr  (0),
	.dmafifo_data (0),
	.dmafifo_empty(1'b1),
	.dmafifo_read ()
);

`else

wire SDRAM2_EN = 0;

assign spuram_dataRead = '0;
assign sdram_readack2 = '0;
assign sdram_writeack2 = '0;

`endif


assign DDRAM_CLK = clk_2x;

// ---- DDR3 bridge sharing: PSX VRAM (priority) + screen_rotate frame buffer ----
// (owner's ZN1 core: rtl/ddram_rotate_arb.sv)
wire  [7:0] psx_ddram_burstcnt;
wire [28:0] psx_ddram_addr;
wire [63:0] psx_ddram_dout;
wire        psx_ddram_dout_ready;
wire        psx_ddram_rd;
wire [63:0] psx_ddram_din;
wire  [7:0] psx_ddram_be;
wire        psx_ddram_we;
wire        psx_ddram_busy;

// arbiter master 0: the PSX master, or the System 10 loader's DDR3 writer while ROM images / nvram arrive
// through ioctl (the PSX is held in reset during downloads, so its master is idle)
wire  [7:0] ap_ddram_burstcnt = ld_ddr_own ? 8'd1                       : psx_ddram_burstcnt;
wire [28:0] ap_ddram_addr     = ld_ddr_own ? {4'b0011, ld_ddr_addr[27:3]} : psx_ddram_addr;
wire        ap_ddram_rd       = ld_ddr_own ? 1'b0                       : psx_ddram_rd;
wire [63:0] ap_ddram_din      = ld_ddr_own ? ld_ddr_din                 : psx_ddram_din;
wire  [7:0] ap_ddram_be       = ld_ddr_own ? ld_ddr_be                  : psx_ddram_be;
wire        ap_ddram_we       = ld_ddr_own ? ld_ddr_we                  : psx_ddram_we;
wire [63:0] ap_ddram_dout;
wire        ap_ddram_dout_ready;
wire        ap_ddram_busy;
assign psx_ddram_busy       = ap_ddram_busy | ld_ddr_own;
assign psx_ddram_dout       = ap_ddram_dout;
assign psx_ddram_dout_ready = ap_ddram_dout_ready & ~ld_ddr_own;
assign ld_ddr_busy          = ap_ddram_busy;

wire        sr_ddram_we;
wire        sr_ddram_rd;
wire [28:0] sr_ddram_addr;
wire [63:0] sr_ddram_din;
wire  [7:0] sr_ddram_be;
wire  [7:0] sr_ddram_burstcnt;

ddram_rotate_arb ddram_rotate_arb
(
	.clk             (clk_2x),
	.DDRAM_BUSY      (DDRAM_BUSY      ),
	.DDRAM_BURSTCNT  (DDRAM_BURSTCNT  ),
	.DDRAM_ADDR      (DDRAM_ADDR      ),
	.DDRAM_DOUT      (DDRAM_DOUT      ),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD        (DDRAM_RD        ),
	.DDRAM_DIN       (DDRAM_DIN       ),
	.DDRAM_BE        (DDRAM_BE        ),
	.DDRAM_WE        (DDRAM_WE        ),
	.p_burstcnt      (ap_ddram_burstcnt   ),
	.p_addr          (ap_ddram_addr       ),
	.p_dout          (ap_ddram_dout       ),
	.p_dout_ready    (ap_ddram_dout_ready ),
	.p_rd            (ap_ddram_rd         ),
	.p_din           (ap_ddram_din        ),
	.p_be            (ap_ddram_be         ),
	.p_we            (ap_ddram_we         ),
	.p_busy          (ap_ddram_busy       ),
	.r_we            (sr_ddram_we   ),
	.r_addr          (sr_ddram_addr ),
	.r_din           (sr_ddram_din  ),
	.r_be            (sr_ddram_be   )
);

////////////////////////////  VIDEO  ////////////////////////////////////

assign CLK_VIDEO = clk_vid;

// Loading-screen sync (owner's ZN1 / Konami GV cores): the PSX core is held in reset during the
// ROM download, so the GPU produces no sync. A free-running black 240p NTSC raster keeps CRTs
// locked so the MiSTer OSD/progress is visible on analog outputs.
reg  [1:0] ld_sync = 0;
reg [11:0] ld_h = 0;
reg  [8:0] ld_v = 0;
reg  [2:0] ld_div = 0;
reg        ld_ce = 0, ld_hs = 0, ld_vs = 0, ld_hbl = 1, ld_vbl = 1;
always @(posedge clk_vid) begin
	ld_sync <= {ld_sync[0], rom_download};
	ld_div  <= (ld_h == 12'd3412) ? 3'd0 : ld_div + 1'd1;
	ld_ce   <= (ld_div == 3'd0);
	if (ld_h == 12'd3412) begin
		ld_h <= 12'd0;
		ld_v <= (ld_v == 9'd262) ? 9'd0 : ld_v + 1'd1;
	end else ld_h <= ld_h + 1'd1;
	ld_hs  <= (ld_h < 12'd252);
	ld_hbl <= (ld_h < 12'd504) || (ld_h >= 12'd3328);
	ld_vbl <= (ld_v >= 9'd240);
	ld_vs  <= (ld_v >= 9'd244) && (ld_v < 9'd247);
end
wire ld_active = ld_sync[1];

wire hs              = ld_active ? ld_hs  : psx_hs;
wire vs              = ld_active ? ld_vs  : psx_vs;
wire hbl             = ld_active ? ld_hbl : psx_hbl;
wire vbl             = ld_active ? ld_vbl : psx_vbl;
wire ce_pix          = ld_active ? ld_ce  : psx_ce_pix;
wire video_interlace = ld_active ? 1'b0   : psx_interlace;
wire [7:0] r         = ld_active ? 8'd0   : psx_r;
wire [7:0] g         = ld_active ? 8'd0   : psx_g;
wire [7:0] b         = ld_active ? 8'd0   : psx_b;

wire video_isPal, video_fbmode, video_fb24;
wire [2:0] video_hResMode;

// PSX diagnostic outputs (unused)
wire [6:0] zn_debug_out;
wire [31:0] zn_debug_val;
wire [2047:0] trace_flat;
wire [31:0]   trace_meta;
wire [31:0] zn_debug_addr;
wire [255:0] zn_debug_words;

typedef struct {
	logic [7:0] red;
	logic [7:0] green;
	logic [7:0] blue;
	logic       hs;
	logic       vs;
	logic       hb;
	logic       vb;
	logic       interlace;
} vid_info;

vid_info video_aspect;
// HDMI rotator window: a FIXED 320x240 raster window locked to the GPU syncs (lines counted from
// VSync, pixels from HSync), measured from a captured frame of the normal 320x240 mode. With
// the GPU's own blanking the rotator re-laid-out its frame buffer whenever a minigame changed
// the display range (the bee game shows 232 lines: one-frame scrambled picture and an HDMI
// frame-buffer reconfiguration). Pixels the game blanks inside the window are written black.
// The GPU blanking must not drive the video_mixer/scaler path in rotated mode either: raw
// hblank stays high through vblank, so the scandoubler never emitted VSync (sync loss).
localparam ROT_V0 = 19;                 // first active line of the 240-line modes (all System 10 games are ROT0)
reg  [8:0] rot_line = 0;

logic [11:0] aspect_x, aspect_y;

// Res  Div Padding
// 256  10  +25
// 320  8   +32
// 368  7   +37
// 512  5   +51
// 640  4   +64

localparam reg [23:0] aspect_ratio_lut_ntsc[128] = '{
    24'h37015B, 24'h2B4113, 24'h1A10A7, 24'hEB45EF, 24'hA00411, 24'hF8365B, 24'hA31435, 24'h6A42C3,
    24'h85D381, 24'hF8F691, 24'h581257, 24'h1860A7, 24'hFD56D4, 24'h6EF303, 24'h497202, 24'hDA1601,
    24'hF8D6E6, 24'h8513B7, 24'hB014F3, 24'h3C51B5, 24'h3971A3, 24'hC02583, 24'hD09606, 24'h4E1245,
    24'hFEF776, 24'hC555D0, 24'hBD559D, 24'hE686E1, 24'hF7C771, 24'hC4F5F4, 24'h655315, 24'hB5158B,
    24'h2C015B, 24'h1750B9, 24'hC74637, 24'hF857CB, 24'h89B459, 24'h800411, 24'hC87668, 24'hA21536,
    24'hFB3820, 24'h443238, 24'hE17761, 24'hFD3856, 24'h207113, 24'h204113, 24'h3941EB, 24'hE6F7C8,
    24'h28015B, 24'hD55745, 24'hD21733, 24'hE9F810, 24'hC0A6AD, 24'h99955A, 24'hA0359D, 24'h7FF482,
    24'hD5B792, 24'hE5C82F, 24'hF558C9, 24'h35D1F0, 24'h6EF404, 24'h93155A, 24'h5BF35D, 24'h9F75DD,
    24'h6E0411, 24'h2DF1B5, 24'h44D292, 24'h1160A7, 24'hB4F6D4, 24'hD49810, 24'hD057F1, 24'h91B595,
    24'hB006C7, 24'hF959A6, 24'hE338D6, 24'hC1378D, 24'hC557C0, 24'hF579B0, 24'h7E1500, 24'hABD6D9,
    24'hFE3A2E, 24'hD3D886, 24'h54736A, 24'hFF3A5E, 24'hE19935, 24'hF42A03, 24'h356233, 24'hFEBA8B,
    24'h957637, 24'hEFAA03, 24'h43F2DA, 24'hA6F70A, 24'h20015B, 24'h24D191, 24'h72E4E9, 24'hC1E853,
    24'hDC097D, 24'hD09909, 24'hFE8B13, 24'hD5E959, 24'hFEFB31, 24'h2B81EB, 24'h8A5620, 24'h2B91F0,
    24'h2AF1EB, 24'hD3F982, 24'hED9AB4, 24'h163101, 24'h724531, 24'hDCBA12, 24'hC50907, 24'hFB7B92,
    24'h580411, 24'hFDDBC7, 24'hAA77F1, 24'hD259D7, 24'h2ED233, 24'h2431B5, 24'hC1992B, 24'h20F191,
    24'h7665A7, 24'h42D334, 24'hD09A0A, 24'hF17BAB, 24'hFFFC6B, 24'h6B653B, 24'h5153FA, 24'hFD9C73
};

localparam reg [23:0] aspect_ratio_lut_pal[160] = '{
    24'hE8F4D9, 24'h41015D, 24'h40815D, 24'h8EB30A, 24'hF8D557, 24'h1C009B, 24'h1CB0A0, 24'h473190,
    24'h711280, 24'hCEF49C, 24'hD734D4, 24'hCAC495, 24'h4791A1, 24'hF695A7, 24'hC7549A, 24'hC31489,
    24'hAEB417, 24'hB8C45B, 24'hA2C3DD, 24'hBCF484, 24'hD2E513, 24'hC2A4B7, 24'hEFF5DA, 24'h85D349,
    24'h18809B, 24'h0C9050, 24'hF59626, 24'hE595C9, 24'h35C15D, 24'hF81655, 24'h0EC061, 24'hEA160D,
    24'h68D2BA, 24'hD735A2, 24'h4731E0, 24'hE9A631, 24'hDC35DF, 24'h6D12ED, 24'h96D412, 24'hB87502,
    24'hCFF5AE, 24'h73732C, 24'hF1D6AF, 24'h7CA377, 24'h30C15D, 24'hA7A4B7, 24'h5C629D, 24'h3941A1,
    24'h4A221F, 24'hF5B712, 24'hD5F631, 24'h8ED428, 24'h8BC417, 24'hE236A8, 24'hA854FB, 24'hEAE6FD,
    24'hD73670, 24'hD5666B, 24'hFD97AB, 24'hA8751F, 24'hCDA649, 24'hCE1655, 24'h5C92DC, 24'h3BC1DB,
    24'hAEB574, 24'hB5A5B3, 24'hFE8807, 24'h2B015D, 24'h13009B, 24'hB6F5DC, 24'hA5E557, 24'hC7D677,
    24'hD1A6D1, 24'h099050, 24'hEF37DB, 24'hB8C619, 24'h25B140, 24'h4FD2A9, 24'hE1978E, 24'hD7373E,
    24'h28515D, 24'hE437C1, 24'hD35737, 24'hF4D866, 24'hF97899, 24'h42724D, 24'h5572F9, 24'h27015D,
    24'hCF0745, 24'h6D83DD, 24'hFFB910, 24'hE35818, 24'hEB2869, 24'hB1565F, 24'hF3F8CE, 24'hE05822,
    24'h10A09B, 24'hEFF8C7, 24'h9E35D0, 24'h87B502, 24'hBAF6EE, 24'hD7D809, 24'hD7380C, 24'hF59939,
    24'h2E31BE, 24'hE0B883, 24'h6B8417, 24'h93F5A7, 24'h09E061, 24'hE3B8C6, 24'hBCE74F, 24'h2FC1DB,
    24'h22F15D, 24'h818513, 24'h5ED3BB, 24'hFF3A15, 24'h5AB399, 24'hB52737, 24'hF0199A, 24'hEE5992,
    24'hBDB7A6, 24'hC74811, 24'h3FD298, 24'h77F4E5, 24'h4552D7, 24'h1390CE, 24'hE4D973, 24'h25B190,
    24'h91960F, 24'hBBD7D9, 24'h20815D, 24'h788513, 24'h20415D, 24'h9BF69E, 24'h8EB614, 24'h8435A7,
    24'hF8DAAE, 24'h9B26AF, 24'h0E009B, 24'h8EA631, 24'h1CB140, 24'h1B112F, 24'hD05925, 24'hD1F940,
    24'h89060F, 24'hD7098B, 24'h88060F, 24'h4172ED, 24'hD739A8, 24'hDBE9E7, 24'h656495, 24'hFF8B97,
    24'hD1A98B, 24'hA6D79F, 24'hB4E84B, 24'hEC7AE1, 24'hFF1BC7, 24'h5C944A, 24'hC31912, 24'hEE8B21
};

logic [11:0] h_pos, v_pos, vb_pos, v_total;
logic [11:0] hb_start_lut[8];
logic [11:0] hb_end_lut[8];
logic [11:0] hb_start, hb_end;

assign hb_start_lut = '{12'd63,  12'd50,  12'd36,  12'd31,  12'd24,  12'd0, 12'd0, 12'd0};
assign hb_end_lut =   '{12'd767, 12'd613, 12'd441, 12'd383, 12'd305, 12'd0, 12'd0, 12'd0};

always_comb begin
	hb_start = hb_start_lut[video_hResMode];
	hb_end = hb_end_lut[video_hResMode];
end

always_ff @(posedge CLK_VIDEO) if (ce_pix) begin
	logic old_vb;
	old_vb <= vbl;
	video_aspect.hs <= hs;
	video_aspect.vs <= vs;
	video_aspect.vb <= vbl;
	video_aspect.interlace <= video_interlace;
	video_aspect.red <= (vbl || hbl) ? 8'd0 : r;
	video_aspect.green <= (vbl || hbl) ? 8'd0 : g;
	video_aspect.blue <= (vbl || hbl) ? 8'd0 : b;
	{aspect_x, aspect_y} <= video_isPal ? aspect_ratio_lut_pal[v_total] : aspect_ratio_lut_ntsc[v_total];

	VGA_DISABLE <= fast_forward;

	h_pos <= h_pos + 1'd1;
	if (~old_vb && vbl)
		vb_pos <= 0;

	if (video_aspect.hs && ~hs) begin
		h_pos <= 0;
		if (~vbl)
			v_pos <= v_pos + 1'd1;
		else
			vb_pos <= vb_pos + 1'd1;
	end

	if (~video_aspect.vs && vs) begin
		v_pos <= 0;
		if (v_pos < 128)
			v_total <= 6'd0;
		else if (video_isPal && v_pos > 287)
			v_total <= 8'd159;
		else if (~video_isPal && v_pos > 255)
			v_total <= 7'd127;
		else
			v_total <= v_pos - 8'd128;
	end

	if (vb_pos > (video_isPal ? 161 : 135))
		video_aspect.vb <= 0;

	if (h_pos == hb_start)
		video_aspect.hb <= 0;
	if (h_pos == hb_end)
		video_aspect.hb <= 1;
	if (video_aspect.hs && ~hs) rot_line <= rot_line + 1'd1;
	if (~video_aspect.vs && vs) rot_line <= 0;
end

// ---- CRT Adjust (owner's Konami GV core): H-Size resample + H-Position / V-Shift sync retiming,
// applied to the native 15 kHz stream ahead of the scandoubler.
wire [4:0]        crt_hs_idx = status[116:112];
wire signed [4:0] crt_hsize  = (crt_hs_idx <= 5'd10) ? crt_hs_idx : (crt_hs_idx - 5'd23);
wire              crt_hs_on;
wire [7:0]        crt_r, crt_g, crt_b;
wire              crt_hs, crt_vs;

gv_crt_hsize crt_hsize_i
(
	.clk(CLK_VIDEO),
	.ce_pix(ce_pix),
	.enable(status[96]),
	.hsize(crt_hsize),
	.hb(video_aspect.hb),
	.r_in(video_aspect.red),
	.g_in(video_aspect.green),
	.b_in(video_aspect.blue),
	.r_out(crt_r),
	.g_out(crt_g),
	.b_out(crt_b),
	.active(crt_hs_on)
);
wire [3:0] crt_vpos = (crt_hs_on && status[108:105] != 4'b1000) ? (status[108:105] - 4'd1) : status[108:105];
gv_crt_shift crt_shift_i
(
	.clk(CLK_VIDEO),
	.ce_pix(ce_pix),
	.enable(status[96]),
	.hpos(status[104:101]),
	.vpos(crt_vpos),
	.hs_in(video_aspect.hs),
	.vs_in(video_aspect.vs),
	.hs_out(crt_hs),
	.vs_out(crt_vs)
);

// ---- Scandoubler Fx + gamma (sys/video_mixer, as arcade_video does)
wire [1:0] sd_fx      = status[3:2];
wire       sd_hq2x    = (sd_fx == 2'd1);
wire       sd_enable  = (sd_fx != 2'd0) | forced_scandoubler;
wire [1:0] sd_sl      = (sd_fx >= 2'd2) ? sd_fx - 2'd1 : 2'd0;
wire       vm_de;


video_mixer #(.LINE_LENGTH(768), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.ce_pix(ce_pix),
	.scandoubler(sd_enable),
	.hq2x(sd_hq2x),
	.gamma_bus(gamma_bus),
	.R(crt_r),
	.G(crt_g),
	.B(crt_b),
	.HSync(crt_hs),
	.VSync(crt_vs),
	.HBlank(video_aspect.hb),
	.VBlank(video_aspect.vb),
	.HDMI_FREEZE(1'b0),
	.freeze_sync(),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(vm_de)
);
assign VGA_DE = vm_de;
// interlace field to the HDMI scaler, so it weaves 480i into 480 lines; the scandoubled
// signal is progressive, so no field then
assign VGA_F1 = sd_enable ? 1'b0 : video_aspect.interlace;
assign VGA_SL = sd_sl;

wire [1:0] ar = status[33:32];
// When the picture is rotated 90 degrees on HDMI it becomes portrait: swap the auto aspect.
wire        ar_swap = rot_en & ~(|ar);
video_freak video_freak
(
	.*,
	.VGA_DE_IN(VGA_DE),
	.VGA_DE(),
	.ARX((!ar) ? (ar_swap ? aspect_y : aspect_x) : (ar - 1'd1)),
	.ARY((!ar) ? (ar_swap ? aspect_x : aspect_y) : 12'd0),
	.CROP_SIZE(0),
	.CROP_OFF(0),
	.SCALE(status[35:34])
);

//////////////////////////  SCREEN ROTATE  //////////////////////////////
// sys/screen_rotate in the clk_2x (DDRAM) domain. It rotates the native picture: the exact
// 320x240 GPU raster (fixed window above; CRT Adjust is for the analog output), sampled on the
// native pixel enable rather than the video_mixer output, whose scandoubled stream carries
// 2x/4x the pixels for no benefit (the scaler applies no scanlines to a frame buffer).
// Scandoubler Fx still applies to the analog output and to unrotated HDMI. Each native pixel
// is latched in the CLK_VIDEO domain and held until the next one (>= 4 CLK_VIDEO); only a
// toggle crosses into clk_2x, so screen_rotate never samples data that is changing.
reg  [7:0] rot_r, rot_g, rot_b;
reg        rot_hs, rot_vs, rot_de, rot_tgl = 0;
always @(posedge CLK_VIDEO) if (ce_pix) begin
	rot_r   <= video_aspect.red;
	rot_g   <= video_aspect.green;
	rot_b   <= video_aspect.blue;
	rot_hs  <= video_aspect.hs;
	rot_vs  <= video_aspect.vs;
	rot_de  <= ~video_aspect.hb && (rot_line >= ROT_V0) && (rot_line < ROT_V0 + 240);   // fixed window (hb LUT per mode)
	rot_tgl <= ~rot_tgl;
end
reg rtg_s1, rtg_s2, rtg_s3;
always @(posedge clk_2x) begin
	rtg_s1 <= rot_tgl;
	rtg_s2 <= rtg_s1;
	rtg_s3 <= rtg_s2;
end
wire ce_pix_2x = rtg_s2 ^ rtg_s3;

tkm_screen_rotate u_screen_rotate
(
	.CLK_VIDEO   (clk_2x),
	.CE_PIXEL    (ce_pix_2x),
	.VGA_R       (rot_r),
	.VGA_G       (rot_g),
	.VGA_B       (rot_b),
	.VGA_HS      (rot_hs),
	.VGA_VS      (rot_vs),
	.VGA_DE      (rot_de),
	.rotate_ccw  (rot_ccw),
	.no_rotate   (~rot_en),
	.flip        (1'b0),
	.video_rotated(),
	.FB_EN       (sr_fb_en),
	.FB_FORMAT   (sr_fb_format),
	.FB_WIDTH    (sr_fb_width),
	.FB_HEIGHT   (sr_fb_height),
	.FB_BASE     (sr_fb_base),
	.FB_STRIDE   (sr_fb_stride),
	.FB_VBL      (FB_VBL),
	.FB_LL       (FB_LL),
	.DDRAM_CLK   (),
	.DDRAM_BUSY  (1'b0),
	.DDRAM_BURSTCNT(sr_ddram_burstcnt),
	.DDRAM_ADDR  (sr_ddram_addr),
	.DDRAM_DIN   (sr_ddram_din),
	.DDRAM_BE    (sr_ddram_be),
	.DDRAM_WE    (sr_ddram_we),
	.DDRAM_RD    (sr_ddram_rd)
);

////////////////////////////  CODES  ///////////////////////////////////

// Code layout:
// {code flags,     32'b address, 32'b compare, 32'b replace}
//  127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.
reg [127:0] gg_code;
reg gg_valid;
reg gg_reset;
reg code_download_1;
wire gg_active;
always_ff @(posedge clk_1x) begin

   gg_reset <= 0;
   code_download_1 <= code_download;
	if (code_download && ~code_download_1) begin
      gg_reset <= 1;
   end

   gg_valid <= 0;
	if (code_download & ioctl_wr) begin
		case (ioctl_addr[3:0])
			0:  gg_code[111:96]  <= ioctl_dout; // Flags Bottom Word
			2:  gg_code[127:112] <= ioctl_dout; // Flags Top Word
			4:  gg_code[79:64]   <= ioctl_dout; // Address Bottom Word
			6:  gg_code[95:80]   <= ioctl_dout; // Address Top Word
			8:  gg_code[47:32]   <= ioctl_dout; // Compare Bottom Word
			10: gg_code[63:48]   <= ioctl_dout; // Compare top Word
			12: gg_code[15:0]    <= ioctl_dout; // Replace Bottom Word
			14: begin
				gg_code[31:16]    <= ioctl_dout; // Replace Top Word
				gg_valid          <= 1;          // Clock it in
			end
		endcase
	end
end

wire clk8Snac;
wire clk9Snac;
wire oldClk8;
wire oldClk9;
wire selectedPort1Snac;
wire selectedPort2Snac;
wire oldselectedPort1;
wire oldselectedPort2;
wire [7:0]transmitValueSnac;
wire [7:0]receiveBufferSnac;
wire receiveValidSnac;
wire beginTransferSnac;
wire actionNextSnac;
wire actionNextPadSnac;
reg [7:0]Send;
reg [7:0]Receive;
wire Cmd;
wire Dat;
wire ack;
wire oldAck;
//wire ackSnac;
wire [15:0]ackTimer;
wire ackNone;
wire oneTime;
wire [3:0]bitCnt;
wire [8:0]byteCnt;
wire [8:0]bytesLeft;
wire [7:0]pad1ID;
wire [7:0]pad2ID;
wire [7:0]targetID;
wire irq10Snac;
wire csync;
wire MCtransfer;
wire PStransfer;
wire [7:0]PSdatalength;

reg USER_IN3_1;
reg USER_IN4_1;
reg USER_IN6_1;

reg USER_IN3_2;
reg USER_IN4_2;
reg USER_IN6_2;

reg USER_IN3_3;
reg USER_IN3_4;
reg ackglitch;

assign clk8Snac = bitCnt < 8 ? clk9Snac : 1'b1;

always @(posedge clk_1x)
begin

   USER_IN3_1 <= USER_IN[3];
   USER_IN4_1 <= USER_IN[4];
   USER_IN6_1 <= USER_IN[6];

   USER_IN3_2 <= USER_IN3_1;
   USER_IN4_2 <= USER_IN4_1;
   USER_IN6_2 <= USER_IN6_1;

   USER_IN3_3 <= USER_IN3_2;//glitch filter for ack
   USER_IN3_4 <= USER_IN3_3;
   ackglitch  <= ~USER_IN3_1 && ~USER_IN3_2 && ~USER_IN3_3 && ~USER_IN3_4 ? 1'b0 : 1'b1;

	if (snacPort1 || snacPort2) begin
		USER_OUT[0] <= ~selectedPort2Snac;
		USER_OUT[1] <= ~selectedPort1Snac;
		USER_OUT[2] <= Cmd;
		USER_OUT[3] <= 1'b1; //ACK
		USER_OUT[4] <= 1'b1; //DAT
		USER_OUT[5] <= oldClk8;
		ack         <= ~ackglitch ? USER_IN3_2 : 1'b1;
		Dat         <= USER_IN4_2;

		if ((pad1ID == 8'h63 || pad2ID == 8'h63) && (pad1ID != 8'h31 || pad2ID != 8'h31)) begin //quirk for guncon, irq is N/C in guncon. so using irq line and outputting csync on snac for g-con. only if justifier isn't connected
			USER_OUT[6] <= ~csync;
			irq10Snac   <= 1'b0;
			csync       <= VGA_HS ^ VGA_VS;//real csync shifts HSync during VSync, should be close enough to work	with guncon
		end
		else begin
			USER_OUT[6] <= 1'b1;
			irq10Snac   <= ~USER_IN6_2;
		end
	end
	else begin
		USER_OUT  <= '1;
		irq10Snac <= 1'b0;
		ack       <= 1'b1;
		Dat       <= 1'b1;
	end

	oldselectedPort1 <= selectedPort1Snac;
	oldselectedPort2 <= selectedPort2Snac;

	if ((~oldselectedPort1 && selectedPort1Snac) || (~oldselectedPort2 && selectedPort2Snac)) begin
		byteCnt   <= 9'd0;
		bytesLeft <= 9'd0;
	end

	if (beginTransferSnac) begin
		bitCnt  <= 4'd0;
		byteCnt <= byteCnt + 9'd1 ;
	end

	oldClk8 <= clk8Snac;
	oldClk9 <= clk9Snac;

	if (oldClk9 && ~clk9Snac) begin	//send on falling edge
		if (bitCnt < 8) begin
			if (bitCnt==0) begin
				Cmd  <= transmitValueSnac[0];
				Send <= {1'b1, transmitValueSnac[7:1]};
			end
			else begin
				Cmd  <= Send[0];
				Send <= {1'b1, Send[7:1]};
			end
		end
		else begin
			Cmd  <= 1'b1;
			Send <= Send;
		end
	end

	if(~oldClk8 && clk8Snac) begin //receive on rising edge
		Receive <= { Dat, Receive[7:1]};
		bitCnt <= bitCnt + 1'b1;
		if(bitCnt == 4'd7) begin//check for ack
			oneTime <= 1'b1;
			if (MCtransfer) ackTimer <= 16'd60000;//very late ack after 7th byte. around 56000 cycles (1.7ms) with a sony MC. 3rd party MCs don't seem to do this
			else begin
				if (byteCnt == bytesLeft + 3) ackTimer <= 16'd400;//only wait around 150 on last byte
				else ackTimer <= 16'd1800;//1st byte of multitap(1375) cycles to ack,digital(460),analog(350-400),ds2(250-400),mouse(120),guncon(270)
			end
		end
	end

	if (ackTimer > 0) begin
		ackTimer <= ackTimer - 16'd1;
	end

	oldAck <= ack;
	if(oldAck && ~ack) begin //ack received
		actionNextPadSnac <= 1'b1;
		ackTimer <= 16'd173;//16'd255;//a delay between ack and next action. too small might cause a hang. was using acktimer 1-255
	end
	else if(ackTimer == 1) begin //wait over
		actionNextPadSnac <= 1'b1;
		oneTime <= 1'b0;
	end
	else if (ackTimer == 16'd258) begin //no ack
		ackNone <= 1'b1;
		actionNextPadSnac <= 1'b1;
	end
	else if (ackTimer == 16'd256) begin //reset if no ack
		oneTime <= 1'b0;
		ackTimer <= 16'd0;
	end
	else begin
		actionNextPadSnac <= 1'b0;
		ackNone <= 1'b0;
	end

	if (actionNextPadSnac && ((snacPort1 && selectedPort1Snac) || (snacPort2 && selectedPort2Snac))) begin //logic for joypad.vhd
		if (oneTime) begin
			if (ackNone) begin
				if (byteCnt < (bytesLeft + 4)) begin // no ack on last byte of transfer
					receiveBufferSnac <= Receive;
					receiveValidSnac <= 1'b1;
					actionNextSnac <= 1'b1;
				end
				else
					actionNextSnac <= 1'b1;
				end
			else begin
				if (byteCnt < (bytesLeft + 4)) begin
					receiveBufferSnac <= Receive;
					receiveValidSnac <= 1'b1;
					//ackSnac <= 1'b1;
				end
				actionNextSnac <= 1'b1;
			end
		end
		else begin
			actionNextSnac <= 1'b1;
		end
	end
	else begin
		receiveBufferSnac <= 8'd0;
		receiveValidSnac <= 1'b0;
		actionNextSnac <= 1'b0;
		//ackSnac <= 1'b0;
	end

	if (receiveValidSnac) begin
		if (byteCnt == 1) begin
			targetID <= transmitValueSnac;
		end
		if (byteCnt == 2) begin
			if (targetID == 8'h81 || targetID == 8'h82 || targetID == 8'h83 || targetID == 8'h84) begin 	//memcard quirks
				MCtransfer <= 1'b1;
				if (transmitValueSnac == 8'h52) bytesLeft <= 9'd137;//read
				if (transmitValueSnac == 8'h57) bytesLeft <= 9'd135;//write
				if (transmitValueSnac == 8'h53) bytesLeft <= 9'd7;//ID Cmd
				//pocketstation
				if (transmitValueSnac == 8'h50) bytesLeft <= 9'd0;//Change a FUNC 03h related value
				if (transmitValueSnac == 8'h58) bytesLeft <= 9'd2;//Get an ID or Version value
				if (transmitValueSnac == 8'h59) bytesLeft <= 9'd6;//Prepare File Execution with Dir_index, and Parameter
				if (transmitValueSnac == 8'h5A) bytesLeft <= 9'd18;//Get Dir_index, ComFlags, F_SN, Date, and Time
				if (transmitValueSnac == 8'h5D) bytesLeft <= 9'd3;//Execute Custom Download Notification
				if (transmitValueSnac == 8'h5E) bytesLeft <= 9'd3;//Get-and-Send ComFlags.bit1,3,2
				if (transmitValueSnac == 8'h5F) bytesLeft <= 9'd1;//Get-and-Send ComFlags.bit0
				if (transmitValueSnac == 8'h5B) begin//Execute Function and transfer data from Pocketstation to PSX--variable length
					bytesLeft <= 9'd3;
					PStransfer <= 1'b1;
				end
				if (transmitValueSnac == 8'h5C) begin//Execute Function and transfer data from PSX to Pocketstation--variable length
					bytesLeft <= 9'd3;
					PStransfer <= 1'b1;
				end
			end
			else begin //joypad quirks
				MCtransfer <= 1'b0;
				if (selectedPort1Snac) pad1ID <= Receive;
				if (selectedPort2Snac) pad2ID <= Receive;

				if (Receive == 8'h80) bytesLeft <= 9'd32; //for multitap
				else bytesLeft <= {5'd0, (Receive[3:0] + Receive[3:0])};
			end
		end
		if (byteCnt == 4 && PStransfer == 1) begin //for pocketstation
			bytesLeft <= bytesLeft + Receive;
			PSdatalength <=  Receive;
		end
		if ((byteCnt == PSdatalength + 5) && PStransfer == 1) begin
			bytesLeft <= bytesLeft + Receive;
			PStransfer <= 1'b0;
		end
	end
end

endmodule
