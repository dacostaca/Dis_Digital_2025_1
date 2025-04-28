// Code your design here
module registro_d_4bits (
    input wire clk,             // Reloj
    input wire EN,              // Habilitador
    input wire [3:0] D,         // Entrada de datos
    output reg [3:0] Q          // Salida
);

always @(posedge clk) begin
    if (EN) begin
        Q <= D; // Solo carga cuando EN está en alto
    end
end

endmodule
