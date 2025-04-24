// Code your design here
// 8 Bit MUX con 2 input channels.
//coded for dacostaca
//last update 24/04/2025

module muxe8_2ch(input wire sel,
                 input wire [7:0] A,
                 input wire [7:0] B,
                 output wire [7:0] O);
  
  				assign O = sel ? B : A;

endmodule
