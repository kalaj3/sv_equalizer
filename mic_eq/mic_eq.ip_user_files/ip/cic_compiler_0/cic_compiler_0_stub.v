// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Nov 22 11:26:29 2024
// Host        : Jakes_ZenBook running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/jkali/ece385/final_project/mic_eq/mic_eq.gen/sources_1/ip/cic_compiler_0/cic_compiler_0_stub.v
// Design      : cic_compiler_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "cic_compiler_v4_0_16,Vivado 2022.2" *)
module cic_compiler_0(aclk, s_axis_data_tdata, s_axis_data_tvalid, 
  s_axis_data_tready, m_axis_data_tdata, m_axis_data_tvalid)
/* synthesis syn_black_box black_box_pad_pin="aclk,s_axis_data_tdata[7:0],s_axis_data_tvalid,s_axis_data_tready,m_axis_data_tdata[23:0],m_axis_data_tvalid" */;
  input aclk;
  input [7:0]s_axis_data_tdata;
  input s_axis_data_tvalid;
  output s_axis_data_tready;
  output [23:0]m_axis_data_tdata;
  output m_axis_data_tvalid;
endmodule
