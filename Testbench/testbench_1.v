// NeoGeo logic definition (simulation only)
// Copyright (C) 2018 Sean Gonsalves
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

`timescale 1ns/1ns
// `default_nettype none

// SIMULATION ONLY
// TB = Test Board

module testbench_1();
	reg nRESET_BTN;			// AES reset button
	reg [9:0] P1_IN;			// Joypad inputs
	reg [9:0] P2_IN;
	reg nTEST_BTN;				// MVS test button
	reg [7:0] DIPSW;			// MVS dipswitches
	
	wire [15:0] M68K_DATA;
	wire [23:1] M68K_ADDR;
	
	wire [2:0] LED_LATCH;	// MVS credit board outputs
	wire [7:0] LED_DATA;
	
	wire [23:0] PBUS;
	
	wire [7:0] FIXD_CART;

	wire [2:0] P1_OUT;		// Joypad outputs
	wire [2:0] P2_OUT;
	
	wire [4:0] CDA_U;			// Memory card upper address lines
	wire [15:0] CDD;			// TODO: is this a register ?

	wire [3:0] EL_OUT;		// MVS marquee board outputs

	wire [7:0] SDRAD;			// ADPCM
	wire [9:8] SDRA_L;
	wire [23:20] SDRA_U;
	wire [7:0] SDPAD;
	wire [11:8] SDPA;

	wire [15:0] SDA;			// Z80
	wire [7:0] SDD;
	
	wire [31:0] CR;			// Sprite graphics data
	wire [3:0] GAD, GBD;
	
	wire [6:0] VIDEO_R;		// TB specific
	wire [6:0] VIDEO_G;
	wire [6:0] VIDEO_B;

	neogeo NG(
		nRESET_BTN,
		
		P1_IN, P2_IN,
		
		DIPSW,
		
		M68K_DATA, M68K_ADDR,
		M68K_RW,	nAS, nLDS, nUDS,								// 4
		LED_LATCH, LED_DATA,										// 2
		
		CLK_68KCLKB,
		CLK_8M,
		CLK_4MB,

		nROMOE, nSLOTCS,											// 2
		nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,					// 4
		nPORTOEL, nPORTOEU, nPORTWEL, nPORTWEU,
		nPORTADRS,
		
		SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,				// 7 + 2 + 4 + 2
		SDPAD, SDPA, SDPMPX, nSDPOE,							// 7 + 4 + 2
		nSDROM, nSDMRD,											// 1
		SDA, SDD,													// 16 + 8
		
		PBUS,															// 24
		nVCS,															// 1
		S2H1, CA4,													// 2
		PCK1B, PCK2B,												// 2
		
		CLK_12M, EVEN, LOAD, H,									// 4		Get CLK_12M from MCLK ? -1
		GAD, GBD, 													// 8
		FIXD_CART,													// 8
		
		CDA_U,														// 5
		nCRDC, nCRDO,												// 2
		CARD_PIN_nWE, CARD_PIN_nREG,							// 2
		nCD1, nCD2, nWP,											// 3		nCD1 | nCD2 in CPLD ? -1

		VIDEO_R,
		VIDEO_G,
		VIDEO_B,
		VIDEO_SYNC
	);
	
	// MVS cartridge
	mvs_cart MVSCART(nRESET, CLK_24M, CLK_12M, CLK_8M, CLK_68KCLKB, CLK_4MB, nAS, M68K_RW, M68K_ADDR[19:1], M68K_DATA,
					nROMOE, nROMOEL, nROMOEU, nPORTADRS, nPORTOEL, nPORTOEU,	nPORTWEL, nPORTWEU, nROMWAIT, nPWAIT0, nPWAIT1,
					PDTACK, nSLOTCS, PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,
					SDPAD, SDPA, SDPMPX, nSDPOE, SDRD0, SDRD1, nSDROM, nSDMRD, SDA, SDD);
	
	// AES cartridge
	/*aes_cart AESCART(PBUS, CA4, S2H1, PCK1B, PCK2B, GAD, GBD, EVEN, H, LOAD, FIXD_CART, M68K_ADDR[19:1], M68K_DATA,
					nROMOE, nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK, SDRAD, SDRA_L, SDRA_U,
					SDRMPX, nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE, nSDROM, SDA, SDD);*/

	// Memory card
	memcard MC({CDA_U, M68K_ADDR[19:1]}, CDD, nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP);
	assign M68K_DATA = (M68K_RW & ~nCRDC) ? CDD : 16'bzzzzzzzzzzzzzzzz;
	assign CDD = (~M68K_RW | nCRDC) ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;
	
	// TODO TB: Put the following in the CPLD
	// DOTA and DOTB are not used, done in NG from GAD and GBD (saves 2 lines)
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, , );
	
	
	initial
	begin
		nRESET_BTN = 1;
		P1_IN = 10'b1111111111;		// Idle joypads
		P2_IN = 10'b1111111111;
		
		nTEST_BTN = 1;
		DIPSW = 8'b11111111;			// Test mode DISABLED
		
		// Apply reset
		#30
		nRESET_BTN = 0;		// Press reset button during 1us
		#1000
		nRESET_BTN = 1;
	end
	
	always @(negedge nAS)
	begin
		// These addresses are only valid for the patched SP-S2.SP1 system ROM !
		if ({M68K_ADDR, 1'b0} == 24'hC16ADA)
		begin
/*			if (NG.M68KCPU.REG_D6 == 15'h0000)
				$display("0 WORK RAM ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0001)
				$display("1 BACKUP RAM ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0002)
				$display("2 COLOR RAM BANK0 ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0003)
				$display("3 COLOR RAM BANK1 ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0004)
				$display("4 VIDEO RAM ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0005)
				$display("5 CALENDAR ERROR ! (A)");
			else if (NG.M68KCPU.REG_D6 == 15'h0006)
				$display("6 SYSTEM ROM ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0007)
				$display("7 MEMORY CARD ERROR !");
			else if (NG.M68KCPU.REG_D6 == 15'h0008)
				$display("8 Z80 ERROR !");*/
			$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'hC12038)
		begin
			// Disabled to let the patched SP-S2.SP1 work
			//$display("Z80 ERROR !");
			//$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'hC11D46)
		begin
			$display("SYSTEM ROM ERROR !");
			$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'hC11D8C)
		begin
			$display("CALENDAR ERROR ! (B)");
			$stop;
		end
		
		
		if ({M68K_ADDR, 1'b0} == 24'hC17E26)
		begin
			$display("VICTOLY ! Going to eyecatcher.");
			//$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'h000122)
		begin
			$display("VICTOLY ! Jump to game entry point.");
			//$stop;
		end
	end
	
endmodule
