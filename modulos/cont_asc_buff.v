// Code your design here
//coded for dacostaca
//last update 24/04/2025
module contador_con_carga_y_salida (
    input wire clk,            // Reloj
    input wire EN,             // Habilitador de conteo
    input wire LOAD,           // Carga paralela
    input wire OE,             // Habilitador de salida
    input wire [3:0] D,        // Datos a cargar
    output wire [3:0] Q        // Salida triestado
);

    reg [3:0] Q_reg;

    always @(posedge clk) begin
        if (LOAD) begin
            Q_reg <= D;              // Carga de valor
        end else if (EN) begin
            Q_reg <= Q_reg + 1;      // Conteo ascendente
        end
    end

    // Salida triestado controlada por OE
    assign Q = (OE) ? Q_reg : 4'bz;

endmodule
