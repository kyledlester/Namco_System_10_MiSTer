// Namco System 10 main-board I/O CPLD (MAME 0.289 namcos10.cpp namcos10_state::namcos10_map_inner).
// Copyright (C) 2026 Kyle Lester. SPDX-License-Identifier: GPL-3.0-or-later
//
// Board-bus address = CPU address bits 23..0 (0x1FBA0000 -> 0xBA0000). All registers are 16 bit wide on
// the 32-bit bus: a word access covers the register at addr and the one at addr+2 (MAME splits it into two
// 16-bit handler calls). Reads return the full aligned word; the memory mux picks the bytes.
//
//   BA0000 R   SYSTEM: DSW1 (active low) in bits 7-0, everything else 1 (bit 10 = JVS sense, idle)
//   BA0002 R/W EXIO ident shifter: a write restarts it; with no expansion board (ident 0xFF) reads return 3
//   BA0004 R   IN1 bits 15-0     BA0006 R  IN1 bits 31-16  (32-bit JAMMA inputs, active low)
//   BA0008 R/W I2C clock          BA000A R/W I2C data  (bit-banged; the device ACKs every byte, as in MAME)
//   BA0012/14/16/18 W  interrupt acknowledge, bit 0/1/2/3
//   BA001A R   interrupt status: bit 3 = I/O update (100 Hz or 2x VBlank), bit 2 = CD-ROM, bit 1 = EXIO
//   BF0000 R   CD-ROM present probe: 1
// EXIO(G) light-gun board (exio_ident != 0xFF; MAME namcos10_map_exio_inner, mirrored at 0x1FE00000):
//   E80000/E88000 R  P1 X bits 5-0 / 21-6     E90000/E98000 R  P1 Y bits 5-0 / 21-6
//   EA0000/EA8000 R  P2 X                     EB0000/EB8000 R  P2 Y
//   E50000/E58000 R  EXIO_IN1/2 (all unused: 0xFFFF); other EXIO addresses read 0, writes are ignored
//   (lamps / coin counters at E40000-E48000, gun re-arm at EC0000/EC8000).
//   B20000, B60000 (watchdog), BC0000 (ATA): ignored / read 0
// A 100 Hz timer sets status bit 3 and pulses IRQ10 (MAME io_update_interrupt_callback).
// Optional (OSD IRQ10 = 2xVBlank): the same pulse at 1/4 and 3/4 of the last frame length after each VBlank,
// two per frame (~119.88/s). The real-board IRQ10 source is unknown (MAME: TODO); Mr. Driller 2/G store IN1
// on every other IRQ10, so 2x VBlank gives one input sample per frame (100 Hz: 50 samples/s).
module s10_io #(
    parameter int CLK_HZ = 33_868_800
) (
    input  wire        clk,
    input  wire        reset,

    input  wire [23:0] addr,
    input  wire [31:0] wdata,
    input  wire  [3:0] wmask,
    input  wire  [1:0] size,            // 00 byte, 01 half, 10 word
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] rdata = 0,      // registered, zero when not selected (OR-ed board bus)

    input  wire  [7:0] dsw,             // DIP switches, 1 = on
    input  wire [31:0] in1,             // IN1, active low, MAME bit layout
    input  wire  [7:0] exio_ident,      // 0xFF = no expansion board
    input  wire  [8:0] gun_x0, gun_y0,  // light-gun positions (MAME EXIO_LIGHTGUN ports: X 0..319, Y 0..239)
    input  wire  [8:0] gun_x1, gun_y1,
    input  wire        irq10_vbl,        // IRQ10 source: 0 = 100 Hz timer (MAME), 1 = 2x VBlank
    input  wire        vblank,           // PSX VBlank (clk domain), rising edge = frame start
    input  wire        cd_intrq,         // ATAPI INTRQ (level): status bit 2 + IRQ10 (MAME cdrom_interrupt)

    output reg         irq10 = 1'b0     // IRQ10 request (one clock pulse)
);
    // ------------------------------------------------------------------ 100 Hz I/O interrupt
    localparam int TICK = CLK_HZ / 100;
    reg [21:0] tcnt = 0;
    reg  [3:0] intst = 0;
    reg        cd_q = 1'b0;

    // 2x VBlank: IRQ10 at 1/4 and 3/4 of the last frame length after each VBlank rising edge
    localparam int FRAME_NOM = (CLK_HZ / 2997) * 50;   // 59.94 Hz, used until the first frame is measured
    reg        vbl_q = 1'b0;
    reg [21:0] fcnt = 0, fper = FRAME_NOM[21:0];
    wire       vbl_rise = vblank & ~vbl_q;
    wire       vbl_tick = (fcnt == {2'b00, fper[21:2]}) || (fcnt == {2'b00, fper[21:2]} + {1'b0, fper[21:1]});

    // ------------------------------------------------------------------ EXIO ident shifter
    reg  [2:0] exio_bit  = 3'd7;
    reg  [5:0] exio_byte = 0;
    wire [1:0] exio_val  = (exio_byte >= 6'h20) ? 2'd3 : {2{exio_ident[exio_bit]}};

    // ------------------------------------------------------------------ I2C (MAME i2c_update)
    localparam [1:0] I2C_IDLE = 2'd0, I2C_BYTE = 2'd1, I2C_ACK1 = 2'd2, I2C_ACK0 = 2'd3;
    reg       host_clk = 1'b1, host_dat = 1'b1, dev_clk = 1'b1, dev_dat = 1'b1;
    reg       prev_clk = 1'b1, prev_dat = 1'b1;
    reg [1:0] i2c_mode = I2C_IDLE;
    reg [3:0] i2c_bit  = 0;            // 7..0, then "negative"
    wire      bus_clk  = dev_clk & host_clk;
    wire      bus_dat  = dev_dat & host_dat;

    task automatic i2c_update(input logic hc, input logic hd);
        logic c, d, dd;
        c  = dev_clk & hc;
        d  = dev_dat & hd;
        dd = dev_dat;
        if (!(prev_dat == d && prev_clk == c)) begin
            case (i2c_mode)
                I2C_IDLE: if (c && !d) begin i2c_bit <= 4'd7; i2c_mode <= I2C_BYTE; end
                I2C_BYTE:
                    if (c && d && !prev_dat) i2c_mode <= I2C_IDLE;
                    else if (c && !prev_clk) begin
                        if (i2c_bit == 4'd0) begin
                            i2c_mode <= I2C_ACK1;
                            dd = 1'b0;          // device pulls SDA low for the ACK
                            d  = 1'b0;
                        end else i2c_bit <= i2c_bit - 1'd1;
                    end
                I2C_ACK1: if (c && !prev_clk) i2c_mode <= I2C_ACK0;
                I2C_ACK0: if (!c && prev_clk) begin
                    dd = 1'b1;
                    d  = hd;
                    i2c_bit  <= 4'd7;
                    i2c_mode <= I2C_BYTE;
                end
            endcase
            prev_dat <= d;
            prev_clk <= c;
        end
        dev_dat <= dd;
    endtask

    // ------------------------------------------------------------------ register file
    function automatic [15:0] rd16(input [23:0] a);
        case (a)
            24'hBA0000: rd16 = {8'hFF, ~dsw};
            24'hBA0002: rd16 = {14'd0, exio_val};
            24'hBA0004: rd16 = in1[15:0];
            24'hBA0006: rd16 = in1[31:16];
            24'hBA0008: rd16 = {15'd0, bus_clk};
            24'hBA000A: rd16 = {15'd0, bus_dat};
            24'hBA001A: rd16 = {12'd0, intst};
            24'hBF0000: rd16 = 16'h0001;
            24'hE50000, 24'hE50002, 24'hE58000, 24'hE58002: rd16 = 16'hFFFF;
            24'hE80000, 24'hE80002: rd16 = {10'd0, gun_x0[5:0]};
            24'hE88000, 24'hE88002: rd16 = {13'd0, gun_x0[8:6]};
            24'hE90000, 24'hE90002: rd16 = {10'd0, gun_y0[5:0]};
            24'hE98000, 24'hE98002: rd16 = {13'd0, gun_y0[8:6]};
            24'hEA0000, 24'hEA0002: rd16 = {10'd0, gun_x1[5:0]};
            24'hEA8000, 24'hEA8002: rd16 = {13'd0, gun_x1[8:6]};
            24'hEB0000, 24'hEB0002: rd16 = {10'd0, gun_y1[5:0]};
            24'hEB8000, 24'hEB8002: rd16 = {13'd0, gun_y1[8:6]};
            default:    rd16 = 16'h0000;
        endcase
    endfunction

    wire [23:0] a_lo = {addr[23:2], 2'b00};
    wire [23:0] a_hi = {addr[23:2], 2'b10};
    wire        sel  = (addr[23:16] == 8'hBA) || (addr[23:16] == 8'hBF) || (addr[23:16] == 8'hB2) ||
                       (addr[23:16] == 8'hB6) || (addr[23:16] == 8'hBC) ||
                       // EXIO window 0xE00000-0xFFFFFF: EXIO(G) only; the EXIO board with the microcontroller (ident
                       // 0x30: Taiko, GAHAHA, NFL) is s10_exio's, whose EXIO_IN1 (NFL PASS buttons) this must not mask
                       (addr[23:21] == 3'b111 && exio_ident == 8'h32);

    always @(posedge clk) begin
        irq10 <= 1'b0;
        rdata <= 0;

        if (reset) begin
            tcnt      <= 0;
            intst     <= 0;
            fcnt      <= 0;
            fper      <= FRAME_NOM[21:0];
            vbl_q     <= 1'b0;
            exio_bit  <= 3'd7;
            exio_byte <= 0;
            host_clk  <= 1'b1; host_dat <= 1'b1;
            dev_clk   <= 1'b1; dev_dat  <= 1'b1;
            prev_clk  <= 1'b1; prev_dat <= 1'b1;
            i2c_mode  <= I2C_IDLE;
            i2c_bit   <= 0;
        end else begin
            if (tcnt == TICK - 1) begin
                tcnt     <= 0;
                if (!irq10_vbl) begin
                    intst[3] <= 1'b1;
                    irq10    <= 1'b1;
                end
            end else tcnt <= tcnt + 1'd1;
            // 2x VBlank: IRQ10 at 1/4 and 3/4 of the last frame length after each VBlank rising edge
            vbl_q <= vblank;
            if (vbl_rise) begin fcnt <= 0; fper <= fcnt; end else if (~&fcnt) fcnt <= fcnt + 1'd1;
            if (irq10_vbl && vbl_tick && !vbl_rise) begin intst[3] <= 1'b1; irq10 <= 1'b1; end
            // CD-ROM interrupt: bit 2 follows INTRQ (set on assert, cleared on deassert or ack), IRQ10 on assert
            cd_q <= cd_intrq;
            if (cd_intrq && !cd_q) begin intst[2] <= 1'b1; irq10 <= 1'b1; end
            if (!cd_intrq && cd_q) intst[2] <= 1'b0;

            if (rd && sel) begin
                rdata <= {rd16(a_hi), rd16(a_lo)};
                // EXIO ident: every 16-bit read of BA0002 shifts one bit (a word read at BA0000 covers it)
                if ((a_hi == 24'hBA0002) && (addr[1] || size == 2'b10)) begin
                    if (exio_bit == 3'd0) begin exio_bit <= 3'd7; exio_byte <= exio_byte + 1'd1; end
                    else exio_bit <= exio_bit - 1'd1;
                end
            end

            if (wr && sel) begin
                // low half (addr+0) then high half (addr+2), as MAME's 16-bit handlers
                if (wmask[1:0] != 2'b00) begin
                    case (a_lo)
                        24'hBA0008: begin host_clk <= wdata[0]; i2c_update(wdata[0], host_dat); end
                        24'hBA0014: intst[1] <= 1'b0;
                        24'hBA0018: intst[3] <= 1'b0;
                        default: ;
                    endcase
                end
                if (wmask[3:2] != 2'b00) begin
                    case (a_hi)
                        24'hBA0002: begin exio_bit <= 3'd7; exio_byte <= 0; end
                        24'hBA000A: begin host_dat <= wdata[16]; i2c_update(host_clk, wdata[16]); end
                        24'hBA0012: intst[0] <= 1'b0;
                        24'hBA0016: intst[2] <= 1'b0;
                        default: ;
                    endcase
                end
            end
        end
    end
endmodule
