//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Tue Aug 27 16:15:25 2024
//Host        : lap-inf133 running 64-bit Ubuntu 24.04 LTS
//Command     : generate_target bd_top_wrapper.bd
//Design      : bd_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bd_top_wrapper
   (HBM_CATTRIP_LS,
    PCIE_PERST_LS_65,
    PCIE_REFCLK1_N,
    PCIE_REFCLK1_P,
    SYSCLK2_N,
    SYSCLK2_P,
    pci_exp_rxn,
    pci_exp_rxp,
    pci_exp_txn,
    pci_exp_txp);
  output [0:0]HBM_CATTRIP_LS;
  input PCIE_PERST_LS_65;
  input [0:0]PCIE_REFCLK1_N;
  input [0:0]PCIE_REFCLK1_P;
  input [0:0]SYSCLK2_N;
  input [0:0]SYSCLK2_P;
  input [15:0]pci_exp_rxn;
  input [15:0]pci_exp_rxp;
  output [15:0]pci_exp_txn;
  output [15:0]pci_exp_txp;

  wire [0:0]HBM_CATTRIP_LS;
  wire PCIE_PERST_LS_65;
  wire [0:0]PCIE_REFCLK1_N;
  wire [0:0]PCIE_REFCLK1_P;
  wire [0:0]SYSCLK2_N;
  wire [0:0]SYSCLK2_P;
  wire [15:0]pci_exp_rxn;
  wire [15:0]pci_exp_rxp;
  wire [15:0]pci_exp_txn;
  wire [15:0]pci_exp_txp;

  bd_top bd_top_i
       (.HBM_CATTRIP_LS(HBM_CATTRIP_LS),
        .PCIE_PERST_LS_65(PCIE_PERST_LS_65),
        .PCIE_REFCLK1_N(PCIE_REFCLK1_N),
        .PCIE_REFCLK1_P(PCIE_REFCLK1_P),
        .SYSCLK2_N(SYSCLK2_N),
        .SYSCLK2_P(SYSCLK2_P),
        .pci_exp_rxn(pci_exp_rxn),
        .pci_exp_rxp(pci_exp_rxp),
        .pci_exp_txn(pci_exp_txn),
        .pci_exp_txp(pci_exp_txp));
endmodule
