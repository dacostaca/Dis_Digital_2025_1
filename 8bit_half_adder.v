// Code your design here
// 8 Bit half adder
//coded for dacostaca
//last update 24/04/2025

module hadder8bit(input wire [7:0] A,
                 input wire [7:0] B,
                  output wire [7:0] O,
                  output wire cout);
  
 				 assign {cout, O} = A + B;

endmodule
