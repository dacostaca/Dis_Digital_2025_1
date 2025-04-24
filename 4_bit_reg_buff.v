// Code your design here
//coded for dacostaca
//last update 24/04/2025
module registro_d_4bits_con_buffer (
    input wire clk,
    input wire EN,          // Habilitador de escritura
    input wire OE,          // Habilitador de salida (Output Enable)
    input wire [3:0] D,
    output wire [3:0] Q     // Salida triestado
);

    reg [3:0] Q_reg;

    // Captura el valor de D en el flanco de subida cuando EN está activo
    always @(posedge clk) begin
        if (EN)
            Q_reg <= D;
    end

    // Salida triestado controlada por OE
    assign Q = (OE) ? Q_reg : 4'bz;

endmodule

