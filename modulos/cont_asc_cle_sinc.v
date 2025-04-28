// Code your design here
//coded for dacostaca
//last update 24/04/2025
module contador_ascendente_con_clr (
    input wire clk,
    input wire EN,
    input wire CLR,
    output reg [3:0] Q
);

always @(posedge clk) begin
    if (CLR) begin
        Q <= 4'b0000;      // Limpiado síncrono
    end else if (EN) begin
        Q <= Q + 1;        // Contar si está habilitado
    end
end

endmodule
