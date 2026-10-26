-- ============================================================================
-- tb_s10 -- full-system NVC testbench for the Namco System 10 core
-- (generated from tb_s10.template.vhd by gen_tb10.py - edit the template)
-- ----------------------------------------------------------------------------
-- psx_mister + s10_io + s10_mem + s10_ch3, with the memories as the MiSTer loader leaves them:
--   sdram.bin  SDRAM: main RAM (zero) + the descrambled BIOS at 0x400000   (scripts/s10tool.py images)
--   ddr.bin    DDR3 0x32000000: the MEM board image
--   record.bin board record, fed through s10_loader's ioctl port (MRA index 1) before reset ends
-- Outputs in the run directory:
--   gra_fb_out_vga.gra  video (sim/system/gra2png.py)    mips_pc.log  PC every 100 us
--   gp1.log             GP1 writes                        s10_events.log  board-register traffic
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library psx;
library tb;

entity tb_s10 is
   generic (
      SDRAM_IMG : string := "sdram.bin";
      DDR_IMG   : string := "ddr.bin";
      REC_IMG   : string := "record.bin";
      FULLRESET : std_logic := '0';
      FB_EVERY  : integer := 1;
      LOGVRAM   : std_logic := '0';
      EVLIMIT   : integer := 20000          -- s10_events.log line limit
   );
end entity;

architecture sim of tb_s10 is

   component s10_io is
      port (
         clk : in std_logic; reset : in std_logic;
         addr : in std_logic_vector(23 downto 0); wdata : in std_logic_vector(31 downto 0);
         wmask : in std_logic_vector(3 downto 0); size : in std_logic_vector(1 downto 0);
         rd : in std_logic; wr : in std_logic; rdata : out std_logic_vector(31 downto 0);
         dsw : in std_logic_vector(7 downto 0); in1 : in std_logic_vector(31 downto 0);
         exio_ident : in std_logic_vector(7 downto 0);
         gun_x0 : in std_logic_vector(8 downto 0); gun_y0 : in std_logic_vector(8 downto 0);
         gun_x1 : in std_logic_vector(8 downto 0); gun_y1 : in std_logic_vector(8 downto 0);
         irq10_vbl : in std_logic; vblank : in std_logic;
         cd_intrq : in std_logic; irq10 : out std_logic
      );
   end component;

   component s10_exio is
      port (
         clk : in std_logic; reset : in std_logic; enable : in std_logic;
         addr : in std_logic_vector(23 downto 0); wdata : in std_logic_vector(31 downto 0);
         wmask : in std_logic_vector(3 downto 0); size : in std_logic_vector(1 downto 0);
         rd : in std_logic; wr : in std_logic; rdata : out std_logic_vector(31 downto 0);
         drum : in std_logic_vector(7 downto 0); analog_en : in std_logic;
         analog : in std_logic_vector(79 downto 0)
      );
   end component;

   component s10_mem is
      port (
         clk : in std_logic; clk2 : in std_logic; reset : in std_logic;
         board_memn : in std_logic; crypt_type : in std_logic_vector(1 downto 0);
         nand_count : in std_logic_vector(4 downto 0); nand_big : in std_logic;
         data_xor : in std_logic_vector(15 downto 0); perm : in std_logic_vector(63 downto 0);
         img_base : in std_logic_vector(27 downto 0); save_base : in std_logic_vector(27 downto 0);
         t2_row_we : in std_logic; t2_row_addr : in std_logic_vector(5 downto 0);
         t2_row_lane : in std_logic_vector(2 downto 0); t2_row_data : in std_logic_vector(15 downto 0);
         t2_xmask : in std_logic_vector(15 downto 0); t2_nl_out : in std_logic_vector(15 downto 0);
         t2_nterms : in std_logic_vector(2 downto 0);
         t2_nl_table : in std_logic; t2_nl_bits : in std_logic_vector(20 downto 0);
         nl_off : in std_logic_vector(27 downto 0);
         addr : in std_logic_vector(23 downto 0); wdata : in std_logic_vector(31 downto 0);
         wmask : in std_logic_vector(3 downto 0); size : in std_logic_vector(1 downto 0);
         rd : in std_logic; wr : in std_logic; rdata : out std_logic_vector(31 downto 0); stall : out std_logic;
         rdma_start : in std_logic; rdma_valid : out std_logic; rdma_pop : in std_logic; rdma_want : in std_logic;
         rdma_data : out std_logic_vector(31 downto 0);
         sram_req : out std_logic; sram_addr : out std_logic_vector(19 downto 0); sram_rnw : out std_logic;
         sram_be : out std_logic_vector(3 downto 0); sram_wdata : out std_logic_vector(31 downto 0);
         sram_rdata : in std_logic_vector(31 downto 0); sram_ready : in std_logic;
         up_active : in std_logic; up_rd : in std_logic; up_addr : in std_logic_vector(26 downto 0);
         up_din : out std_logic_vector(15 downto 0); up_wait : out std_logic; save_req : out std_logic;
         ddr_request : out std_logic; ddr_ack : in std_logic; ddr_burstcnt : out std_logic_vector(7 downto 0);
         ddr_addr : out std_logic_vector(27 downto 0); ddr_din : out std_logic_vector(63 downto 0);
         ddr_be : out std_logic_vector(7 downto 0); ddr_we : out std_logic; ddr_rd : out std_logic;
         ddr_dout : in std_logic_vector(63 downto 0); ddr_dout_ready : in std_logic
      );
   end component;

   component s10_loader is
      port (
         clk : in std_logic; clk2 : in std_logic;
         ioctl_download : in std_logic; ioctl_index : in std_logic_vector(7 downto 0);
         ioctl_wr : in std_logic; ioctl_addr : in std_logic_vector(26 downto 0);
         ioctl_dout : in std_logic_vector(15 downto 0); ioctl_wait : out std_logic;
         board_memn : out std_logic; crypt_type : out std_logic_vector(1 downto 0);
         nand_count : out std_logic_vector(4 downto 0); nand_big : out std_logic;
         data_xor : out std_logic_vector(15 downto 0); perm : out std_logic_vector(63 downto 0);
         exio_ident : out std_logic_vector(7 downto 0); save_base : out std_logic_vector(27 downto 0);
         t2_row_we : out std_logic; t2_row_addr : out std_logic_vector(5 downto 0);
         t2_row_lane : out std_logic_vector(2 downto 0); t2_row_data : out std_logic_vector(15 downto 0);
         t2_xmask : out std_logic_vector(15 downto 0); t2_nl_out : out std_logic_vector(15 downto 0);
         t2_nterms : out std_logic_vector(2 downto 0); record_ok : out std_logic;
         nl_table : out std_logic; light_gun : out std_logic; cdrom : out std_logic; exio_mcu : out std_logic; exio_analog : out std_logic; memp3 : out std_logic; in1_layout : out std_logic_vector(3 downto 0);
         nl_bits : out std_logic_vector(20 downto 0);
         dl_req : out std_logic; dl_addr : out std_logic_vector(26 downto 0); dl_data : out std_logic_vector(31 downto 0);
         dl_done : in std_logic; fill_start : out std_logic; fill_base : out std_logic_vector(26 downto 0);
         fill_words : out std_logic_vector(20 downto 0); fill_value : out std_logic_vector(31 downto 0);
         fill_busy : in std_logic; ddr_own : out std_logic; ddr_we : out std_logic;
         ddr_addr : out std_logic_vector(27 downto 0); ddr_din : out std_logic_vector(63 downto 0);
         ddr_be : out std_logic_vector(7 downto 0); ddr_busy : in std_logic
      );
   end component;

   signal clk1x  : std_logic := '1';
   signal clk2x  : std_logic := '1';
   signal clk3x  : std_logic := '1';
   signal clkvid : std_logic := '1';
   signal reset  : std_logic := '1';
   signal psx_reset : std_logic := '1';

   signal ram_refresh        : std_logic;
   signal ram_dataWrite      : std_logic_vector(31 downto 0);
   signal ram_dataRead32     : std_logic_vector(31 downto 0);
   signal ram_Adr            : std_logic_vector(26 downto 0);
   signal ram_cntDMA         : std_logic_vector(1 downto 0);
   signal ram_be             : std_logic_vector(3 downto 0);
   signal ram_rnw            : std_logic;
   signal ram_ena            : std_logic;
   signal ram_dma            : std_logic;
   signal ram_iscache        : std_logic;
   signal ram_done           : std_logic;
   signal ram_dmafifo_adr    : std_logic_vector(22 downto 0);
   signal ram_dmafifo_data   : std_logic_vector(31 downto 0);
   signal ram_dmafifo_empty  : std_logic;
   signal ram_dmafifo_read   : std_logic;
   signal cache_wr           : std_logic_vector(3 downto 0);
   signal cache_data         : std_logic_vector(31 downto 0);
   signal cache_addr         : std_logic_vector(7 downto 0);
   signal dma_wr             : std_logic;
   signal dma_reqprocessed   : std_logic;
   signal dma_data           : std_logic_vector(31 downto 0);

   signal DDRAM_BUSY         : std_logic;
   signal DDRAM_BURSTCNT     : std_logic_vector(7 downto 0);
   signal DDRAM_ADDR         : std_logic_vector(28 downto 0);
   signal DDRAM_DOUT         : std_logic_vector(63 downto 0);
   signal DDRAM_DOUT_READY   : std_logic;
   signal DDRAM_RD           : std_logic;
   signal DDRAM_DIN          : std_logic_vector(63 downto 0);
   signal DDRAM_BE           : std_logic_vector(7 downto 0);
   signal DDRAM_WE           : std_logic;

   signal hsync, vsync, hblank, vblank, video_ce, video_interlace : std_logic;
   signal video_r, video_g, video_b : std_logic_vector(7 downto 0);
   signal audio_l, audio_r : std_logic_vector(15 downto 0);

   -- System 10 board bus
   signal s10_addr   : std_logic_vector(23 downto 0);
   signal s10_wdata  : std_logic_vector(31 downto 0);
   signal s10_wmask  : std_logic_vector(3 downto 0);
   signal s10_size   : std_logic_vector(1 downto 0);
   signal s10_rd, s10_wr, s10_stall, s10_irq10 : std_logic;
   signal s10_rdata, io_rdata, mem_rdata : std_logic_vector(31 downto 0);
   signal s10_ddr_request, s10_ddr_ack, s10_ddr_we, s10_ddr_rd : std_logic;
   signal s10_ddr_burstcnt, s10_ddr_be : std_logic_vector(7 downto 0);
   signal s10_ddr_addr : std_logic_vector(27 downto 0);
   signal s10_ddr_din  : std_logic_vector(63 downto 0);
   signal rdma_start, rdma_valid, rdma_pop, rdma_want : std_logic;
   signal rdma_data : std_logic_vector(31 downto 0);
   signal sram_req, sram_rnw, sram_ready : std_logic;
   signal sram_addr  : std_logic_vector(19 downto 0);
   signal sram_be    : std_logic_vector(3 downto 0);
   signal sram_wdata, sram_rdata : std_logic_vector(31 downto 0);

   signal ch3_addr  : std_logic_vector(26 downto 0);
   signal ch3_din, ch3_dout : std_logic_vector(31 downto 0);
   signal ch3_req, ch3_rnw, ch3_ready : std_logic;
   signal ch3_be    : std_logic_vector(3 downto 0);

   -- board record (loader)
   signal ioctl_download, ioctl_wr : std_logic := '0';
   signal ioctl_index : std_logic_vector(7 downto 0) := x"01";
   signal ioctl_addr  : std_logic_vector(26 downto 0) := (others => '0');
   signal ioctl_dout  : std_logic_vector(15 downto 0) := (others => '0');
   signal rec_done    : std_logic := '0';
   signal b_memn, b_nand_big, b_record_ok : std_logic;
   signal b_crypt : std_logic_vector(1 downto 0);
   signal b_nand_count : std_logic_vector(4 downto 0);
   signal b_data_xor, b_t2_xmask, b_t2_nl_out : std_logic_vector(15 downto 0);
   signal b_nl_table, b_light_gun, s10_exio_on, b_exio_mcu, b_exio_analog : std_logic;
   -- analog sticks centred (0x200 per channel)
   signal exio_adc : std_logic_vector(79 downto 0) := (x"80200802008020080200");
   signal exio_rdata : std_logic_vector(31 downto 0);
   signal b_nl_bits : std_logic_vector(20 downto 0);
   signal b_perm : std_logic_vector(63 downto 0);
   signal b_t2_row_we : std_logic;
   signal b_t2_row_addr : std_logic_vector(5 downto 0);
   signal b_t2_row_lane, b_t2_nterms : std_logic_vector(2 downto 0);
   signal b_t2_row_data : std_logic_vector(15 downto 0);
   signal b_exio : std_logic_vector(7 downto 0);
   signal b_save_base : std_logic_vector(27 downto 0);

   signal tb_in1 : std_logic_vector(31 downto 0) := (others => '1');
   signal exe_dummy : unsigned(31 downto 0);
   signal vbl_cnt, exc_cnt, stall_cyc, ev_lines : integer := 0;

begin

   -- exact 1:2:3 ratios (one PLL on hardware)
   clk1x  <= not clk1x  after 14763 ps;   -- 33.8688 MHz
   clk2x  <= not clk2x  after  7381.5 ps;
   clk3x  <= not clk3x  after  4921 ps;   -- 101.6 MHz
   clkvid <= not clkvid after  9311 ps;   -- 53.7 MHz

   reset     <= '1', '0' after 400 ns;
   psx_reset <= reset or not rec_done;

   -- MRA index 1 (board record) through the loader's ioctl port, as hps_io delivers it
   process
      type cfile is file of character;
      file f : cfile;
      variable st : file_open_status;
      variable c0, c1 : character;
      variable a : integer := 0;
   begin
      wait until rising_edge(clk1x);
      file_open(st, f, REC_IMG, read_mode);
      assert st = open_ok report "cannot open " & REC_IMG severity failure;
      ioctl_index <= x"01";
      ioctl_download <= '1';
      wait until rising_edge(clk1x); wait until rising_edge(clk1x);
      while not endfile(f) loop
         read(f, c0);
         if endfile(f) then c1 := nul; else read(f, c1); end if;
         ioctl_addr <= std_logic_vector(to_unsigned(a, 27));
         ioctl_dout <= std_logic_vector(to_unsigned(character'pos(c1), 8)) & std_logic_vector(to_unsigned(character'pos(c0), 8));
         ioctl_wr <= '1';
         wait until rising_edge(clk1x);
         ioctl_wr <= '0';
         wait until rising_edge(clk1x);
         a := a + 2;
      end loop;
      file_close(f);
      ioctl_download <= '0';
      wait until rising_edge(clk1x); wait until rising_edge(clk1x);
      assert b_record_ok = '1' report "board record not accepted" severity failure;
      rec_done <= '1';
      report "board record loaded: memn=" & std_logic'image(b_memn) & " crypt=" & integer'image(to_integer(unsigned(b_crypt)));
      wait;
   end process;

   ipsx : entity psx.psx_mister
      generic map (is_simu => '1', ss_fullreset => FULLRESET)
      port map (
@@PSX_PORTMAP@@
      );

   s10_rdata <= io_rdata or mem_rdata or exio_rdata;

   iexio : s10_exio
      port map (clk => clk1x, reset => psx_reset, enable => b_exio_mcu, addr => s10_addr, wdata => s10_wdata,
                wmask => s10_wmask, size => s10_size, rd => s10_rd, wr => s10_wr, rdata => exio_rdata, drum => x"00",
                analog_en => b_exio_analog, analog => exio_adc);
   s10_exio_on <= '1' when b_exio /= x"FF" else '0';

   iio : s10_io
      port map (
         clk => clk1x, reset => psx_reset,
         addr => s10_addr, wdata => s10_wdata, wmask => s10_wmask, size => s10_size,
         rd => s10_rd, wr => s10_wr, rdata => io_rdata,
         dsw => x"00", in1 => tb_in1, exio_ident => b_exio,
         gun_x0 => '0' & x"A0", gun_y0 => '0' & x"78", gun_x1 => '0' & x"A0", gun_y1 => '0' & x"78",
         irq10_vbl => '0', vblank => '0', cd_intrq => '0', irq10 => s10_irq10
      );

   imem : s10_mem
      port map (
         clk => clk1x, clk2 => clk2x, reset => psx_reset,
         board_memn => b_memn, crypt_type => b_crypt, nand_count => b_nand_count, nand_big => b_nand_big,
         data_xor => b_data_xor, perm => b_perm, img_base => x"0800000", save_base => b_save_base,
         t2_row_we => b_t2_row_we, t2_row_addr => b_t2_row_addr, t2_row_lane => b_t2_row_lane,
         t2_row_data => b_t2_row_data, t2_xmask => b_t2_xmask, t2_nl_out => b_t2_nl_out, t2_nterms => b_t2_nterms,
         t2_nl_table => b_nl_table, t2_nl_bits => b_nl_bits, nl_off => x"F000000",
         addr => s10_addr, wdata => s10_wdata, wmask => s10_wmask, size => s10_size,
         rd => s10_rd, wr => s10_wr, rdata => mem_rdata, stall => s10_stall,
         rdma_start => rdma_start, rdma_valid => rdma_valid, rdma_pop => rdma_pop, rdma_want => rdma_want,rdma_data => rdma_data,
         sram_req => sram_req, sram_addr => sram_addr, sram_rnw => sram_rnw, sram_be => sram_be,
         sram_wdata => sram_wdata, sram_rdata => sram_rdata, sram_ready => sram_ready,
         up_active => '0', up_rd => '0', up_addr => (others => '0'), up_din => open, up_wait => open, save_req => open,
         ddr_request => s10_ddr_request, ddr_ack => s10_ddr_ack, ddr_burstcnt => s10_ddr_burstcnt,
         ddr_addr => s10_ddr_addr, ddr_din => s10_ddr_din, ddr_be => s10_ddr_be, ddr_we => s10_ddr_we,
         ddr_rd => s10_ddr_rd, ddr_dout => DDRAM_DOUT, ddr_dout_ready => DDRAM_DOUT_READY
      );

   ildr : s10_loader
      port map (
         clk => clk1x, clk2 => clk2x,
         ioctl_download => ioctl_download, ioctl_index => ioctl_index, ioctl_wr => ioctl_wr,
         ioctl_addr => ioctl_addr, ioctl_dout => ioctl_dout, ioctl_wait => open,
         board_memn => b_memn, crypt_type => b_crypt, nand_count => b_nand_count, nand_big => b_nand_big,
         data_xor => b_data_xor, perm => b_perm, exio_ident => b_exio, save_base => b_save_base,
         t2_row_we => b_t2_row_we, t2_row_addr => b_t2_row_addr, t2_row_lane => b_t2_row_lane,
         t2_row_data => b_t2_row_data, t2_xmask => b_t2_xmask, t2_nl_out => b_t2_nl_out, t2_nterms => b_t2_nterms, record_ok => b_record_ok,
         nl_table => b_nl_table, light_gun => b_light_gun, cdrom => open, exio_mcu => b_exio_mcu, exio_analog => b_exio_analog, memp3 => open, in1_layout => open, nl_bits => b_nl_bits,
         dl_req => open, dl_addr => open, dl_data => open, dl_done => '0',
         fill_start => open, fill_base => open, fill_words => open, fill_value => open, fill_busy => '0',
         ddr_own => open, ddr_we => open, ddr_addr => open, ddr_din => open, ddr_be => open, ddr_busy => '0'
      );

   ich3 : entity psx.s10_ch3
      generic map (SRAM_BASE => 16#0800000#)
      port map (
         clk => clk1x,
         ch3_addr => ch3_addr, ch3_din => ch3_din, ch3_dout => ch3_dout, ch3_req => ch3_req,
         ch3_rnw => ch3_rnw, ch3_be => ch3_be, ch3_ready => ch3_ready,
         sram_req => sram_req, sram_addr => sram_addr, sram_rnw => sram_rnw, sram_be => sram_be,
         sram_wdata => sram_wdata, sram_rdata => sram_rdata, sram_ready => sram_ready
      );

   isdram : entity tb.sdram_model_s12
      generic map (DOREFRESH => '1', INITFILE => SDRAM_IMG, FILELOADING => '1')
      port map (
         clk                  => clk1x,
         clk3x                => clk3x,
         refresh              => ram_refresh,
         addr                 => ram_Adr,
         req                  => ram_ena,
         ram_dma              => ram_dma,
         ram_dmacnt           => ram_cntDMA,
         ram_iscache          => ram_iscache,
         rnw                  => ram_rnw,
         be                   => ram_be,
         di                   => ram_dataWrite,
         do                   => open,
         do32                 => ram_dataRead32,
         done                 => ram_done,
         cache_wr             => cache_wr,
         cache_data           => cache_data,
         cache_addr           => cache_addr,
         dma_wr               => dma_wr,
         dma_data             => dma_data,
         reqprocessed         => dma_reqprocessed,
         ram_idle             => open,
         ram_dmafifo_adr      => ram_dmafifo_adr,
         ram_dmafifo_data     => ram_dmafifo_data,
         ram_dmafifo_empty    => ram_dmafifo_empty,
         ram_dmafifo_read     => ram_dmafifo_read,
         fileSize             => open,
         exe_initial_pc       => exe_dummy,
         exe_initial_gp       => open,
         exe_load_address     => open,
         exe_file_size        => open,
         exe_stackpointer     => open,
         ch3_addr             => ch3_addr,
         ch3_din              => ch3_din,
         ch3_dout             => ch3_dout,
         ch3_req              => ch3_req,
         ch3_rnw              => ch3_rnw,
         ch3_be               => ch3_be,
         ch3_ready            => ch3_ready
      );

   iddrram : entity tb.ddrram_model
      generic map (SLOWTIMING => 0, RANDOMTIMING => '0', LOGVRAM => LOGVRAM, INITFILE => DDR_IMG, INITOFFSET => 16#0800000#)
      port map (
         DDRAM_CLK        => clk2x,
         DDRAM_BUSY       => DDRAM_BUSY,
         DDRAM_BURSTCNT   => DDRAM_BURSTCNT,
         DDRAM_ADDR       => DDRAM_ADDR,
         DDRAM_DOUT       => DDRAM_DOUT,
         DDRAM_DOUT_READY => DDRAM_DOUT_READY,
         DDRAM_RD         => DDRAM_RD,
         DDRAM_DIN        => DDRAM_DIN,
         DDRAM_BE         => DDRAM_BE,
         DDRAM_WE         => DDRAM_WE
      );

   ifb : entity tb.framebuffer
      generic map (EVERY => FB_EVERY)
      port map (
         clk             => clkvid,
         hblank          => hblank,
         vblank          => vblank,
         video_ce        => video_ce,
         video_interlace => video_interlace,
         video_r         => video_r,
         video_g         => video_g,
         video_b         => video_b
      );

   -- scripted inputs: inputs.txt lines "<time_ms> <IN1 hex>" (active low, MAME namcos10 IN1 layout)
   process
      file f : text;
      variable st : file_open_status;
      variable l : line;
      variable t : integer;
      variable v : std_logic_vector(31 downto 0);
   begin
      file_open(st, f, "inputs.txt", read_mode);
      if st /= open_ok then wait; end if;
      while not endfile(f) loop
         readline(f, l);
         read(l, t);
         hread(l, v);
         if now < t * 1 ms then wait for t * 1 ms - now; end if;
         tb_in1 <= v;
      end loop;
      wait;
   end process;

   -- counters
   process (clk1x)
      variable vd : std_logic := '0';
      variable ed : unsigned(4 downto 0) := (others => '0');
   begin
      if rising_edge(clk1x) then
         if << signal .tb_s10.ipsx.ipsx_top.irq_VBLANK : std_logic >> = '1' and vd = '0' then vbl_cnt <= vbl_cnt + 1; end if;
         vd := << signal .tb_s10.ipsx.ipsx_top.irq_VBLANK : std_logic >>;
         if << signal .tb_s10.ipsx.ipsx_top.icpu.exception : unsigned(4 downto 0) >> /= 0 and ed = 0 then exc_cnt <= exc_cnt + 1; end if;
         ed := << signal .tb_s10.ipsx.ipsx_top.icpu.exception : unsigned(4 downto 0) >>;
         if s10_stall = '1' then stall_cyc <= stall_cyc + 1; end if;
      end if;
   end process;

   -- GP1 writes
   process (clk1x)
      file f : text open write_mode is "gp1.log";
      variable l : line;
      variable d : std_logic_vector(31 downto 0);
   begin
      if rising_edge(clk1x) then
         if << signal .tb_s10.ipsx.ipsx_top.bus_gpu_write : std_logic >> = '1' then
            d := << signal .tb_s10.ipsx.ipsx_top.bus_gpu_dataWrite : std_logic_vector(31 downto 0) >>;
            if << signal .tb_s10.ipsx.ipsx_top.bus_gpu_addr : unsigned(3 downto 0) >> = x"4" then
               write(l, now / 1 us); write(l, string'(" us GP1 ")); hwrite(l, d); writeline(f, l); flush(f);
            end if;
         end if;
      end if;
   end process;

   -- MIPS PC every 100 us
   process
      file f : text open write_mode is "mips_pc.log";
      variable l : line;
   begin
      loop
         wait for 100 us;
         write(l, now / 1 us); write(l, string'(" us MIPS "));
         hwrite(l, std_logic_vector(<< signal .tb_s10.ipsx.ipsx_top.icpu.PC : unsigned(31 downto 0) >>));
         write(l, string'(" ISTAT "));
         hwrite(l, "0" & std_logic_vector(<< signal .tb_s10.ipsx.ipsx_top.iirq.I_STATUS : unsigned(10 downto 0) >>));
         write(l, string'(" IMASK "));
         hwrite(l, std_logic_vector(<< signal .tb_s10.ipsx.ipsx_top.iirq.I_MASK : unsigned(31 downto 0) >>));
         write(l, string'(" vbl ")); write(l, vbl_cnt);
         write(l, string'(" exc ")); write(l, exc_cnt);
         write(l, string'(" stall ")); write(l, stall_cyc);
         writeline(f, l); flush(f);
      end loop;
   end process;

   -- System 10 board-bus traffic (writes, reads of the MEM board region), first EVLIMIT lines
   process
      file f : text;
      variable st : file_open_status;
      variable l : line;
      variable ra : std_logic_vector(23 downto 0);
      variable rp : std_logic := '0';
   begin
      file_open(st, f, "s10_events.log", write_mode);
      assert st = open_ok report "cannot open s10_events.log: " & file_open_status'image(st) severity failure;
      loop
         wait until rising_edge(clk1x);
         if ev_lines < EVLIMIT then
            if s10_wr = '1' then
               write(l, now / 1 us); write(l, string'(" us W "));
               hwrite(l, s10_addr); write(l, string'(" = ")); hwrite(l, s10_wdata);
               write(l, string'(" m")); hwrite(l, s10_wmask);
               writeline(f, l); flush(f); ev_lines <= ev_lines + 1;
            end if;
            if s10_rd = '1' then ra := s10_addr; rp := '1'; end if;
            if rp = '1' and s10_rd = '0' and s10_stall = '0' then
               rp := '0';
               if ra(23 downto 20) /= x"B" then
                  write(l, now / 1 us); write(l, string'(" us R "));
                  hwrite(l, ra); write(l, string'(" = ")); hwrite(l, s10_rdata);
                  writeline(f, l); flush(f); ev_lines <= ev_lines + 1;
               end if;
            end if;
         end if;
      end loop;
   end process;

end architecture;
