// ======================================================
// Testbench COMPLETO para PWM Peripheral (CORREGIDO)
// ======================================================
`timescale 1ns / 1ps

module pwm_peripheral_tb;

    // Parámetros de simulación
    localparam CLK_PERIOD = 10;  // 100 MHz
    localparam BASE_ADDR = 32'h4000_0000;

    // Señales del bus
    reg        clk;
    reg        rst;
    reg [31:0] add;
    reg [31:0] din;
    wire [31:0] dout;
    reg        wr;
    reg        rd;
    wire       wr_busy;
    wire       rd_busy;
    reg        wr_strobe;
    reg        rd_strobe;
    reg [3:0]  mask;
    wire       pwm_out;

    // Instancia del PWM
    pwm_peripheral uut (
        .clk(clk), .rst(rst), .add(add), .din(din), .dout(dout),
        .wr(wr), .rd(rd), .wr_busy(wr_busy), .rd_busy(rd_busy),
        .wr_strobe(wr_strobe), .rd_strobe(rd_strobe), .mask(mask),
        .pwm_out(pwm_out)
    );

    // Generación de reloj
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Tarea para escritura de registros
    task write_reg(input [31:0] address, input [31:0] data);
        begin
            @(posedge clk);
            add = address;
            din = data;
            wr = 1;
            @(posedge clk);
            wr = 0;
            #(CLK_PERIOD*2) wr_strobe = 1;
            @(posedge clk);
            wr_strobe = 0;
            #(CLK_PERIOD*10);
            $display("[%0t] WRITE: Addr=0x%h Data=0x%h", $time, address, data);
        end
    endtask

    // Tarea para lectura de registros
    task read_reg(input [31:0] address);
        begin
            @(posedge clk);
            add = address;
            rd = 1;
            @(posedge clk);
            rd = 0;
            #(CLK_PERIOD*2) rd_strobe = 1;
            @(posedge clk);
            rd_strobe = 0;
            #(CLK_PERIOD*2);
            $display("[%0t] READ: Addr=0x%h Data=0x%h", $time, address, dout);
        end
    endtask

    // Secuencia de pruebas CORREGIDA
    initial begin
        // Inicialización
        rst = 1;
        add = 0;
        din = 0;
        wr = 0;
        rd = 0;
        wr_strobe = 0;
        rd_strobe = 0;
        mask = 4'b1111;
        
        // Configuración de dumpfile para GTKWave
        $dumpfile("pwm_wave.vcd");
        $dumpvars(0, pwm_peripheral_tb);
        
        // Reset inicial
        #(CLK_PERIOD*2) rst = 0;
        
        // ---------------------------------------------------------------------
        // Prueba 1: Comportamiento normal con diferentes alineaciones
        // ---------------------------------------------------------------------
        $display("\n=== PRUEBA 1: Comportamiento normal ===");
        
        // Configuración inicial
        write_reg(BASE_ADDR + 32'h0000, 32'd100);  // div_counter = 100
        
        // Caso 1.1: Alineación izquierda (HABILITAR PWM: bit 31 = 1)
        $display("\nCaso 1.1: Alineación izquierda");
        write_reg(BASE_ADDR + 32'h0008, 32'h80000000);  // ¡Enable + Alineación izquierda!
        write_reg(BASE_ADDR + 32'h0004, 32'd25);        // Duty 25%
        #(CLK_PERIOD * 500);
        
        write_reg(BASE_ADDR + 32'h0004, 32'd75);        // Duty 75%
        #(CLK_PERIOD * 500);
        
        // Caso 1.2: Alineación centrada (HABILITAR PWM: bit 31 = 1)
        $display("\nCaso 1.2: Alineación centrada");
        write_reg(BASE_ADDR + 32'h0008, 32'h80000001);  // ¡Enable + Alineación centro!
        write_reg(BASE_ADDR + 32'h0004, 32'd30);        // Duty 30%
        #(CLK_PERIOD * 500);
        
        write_reg(BASE_ADDR + 32'h0004, 32'd70);        // Duty 70%
        #(CLK_PERIOD * 500);
        
        // Caso 1.3: Alineación derecha (HABILITAR PWM: bit 31 = 1)
        $display("\nCaso 1.3: Alineación derecha");
        write_reg(BASE_ADDR + 32'h0008, 32'h80000002);  // ¡Enable + Alineación derecha!
        write_reg(BASE_ADDR + 32'h0004, 32'd10);        // Duty 10%
        #(CLK_PERIOD * 500);
        
        write_reg(BASE_ADDR + 32'h0004, 32'd90);        // Duty 90%
        #(CLK_PERIOD * 500);
        
        // ---------------------------------------------------------------------
        // Prueba 2: Casos límite (TODOS CON PWM HABILITADO)
        // ---------------------------------------------------------------------
        $display("\n=== PRUEBA 2: Casos límite ===");
        
        // Caso 2.1: Duty cycle 0% y 100%
        $display("\nCaso 2.1: Duty 0%% y 100%%");
        write_reg(BASE_ADDR + 32'h0004, 32'd0);         // 0% duty
        #(CLK_PERIOD * 300);
        write_reg(BASE_ADDR + 32'h0004, 32'd100);       // 100% duty
        #(CLK_PERIOD * 300);
        
        // Caso 2.2: Duty cycle >100%
        $display("\nCaso 2.2: Duty 150%% (debe limitarse a 100%%)");
        write_reg(BASE_ADDR + 32'h0004, 32'd150);       // 150% duty
        #(CLK_PERIOD * 300);
        
        // Caso 2.3: Cambio dinámico de alineación (HABILITAR PWM EN TODOS)
        $display("\nCaso 2.3: Cambio dinámico de alineación");
        write_reg(BASE_ADDR + 32'h0008, 32'h80000000);  // Enable + Izquierda
        #(CLK_PERIOD * 200);
        write_reg(BASE_ADDR + 32'h0008, 32'h80000001);  // Enable + Centro
        #(CLK_PERIOD * 200);
        write_reg(BASE_ADDR + 32'h0008, 32'h80000002);  // Enable + Derecha
        #(CLK_PERIOD * 200);
        
        // Caso 2.4: Divisor de frecuencia mínimo/máximo
        $display("\nCaso 2.4: Divisor mínimo (2) y máximo (65535)");
        write_reg(BASE_ADDR + 32'h0000, 32'd2);         // Divisor mínimo
        #(CLK_PERIOD * 50);
        write_reg(BASE_ADDR + 32'h0000, 32'h0000FFFF);  // Divisor máximo
        #(CLK_PERIOD * 50);
        
        // Caso 2.5: Escritura simultánea (YA TIENE ENABLE)
        $display("\nCaso 2.5: Escritura simultánea");
        write_reg(BASE_ADDR + 32'h0000, 32'd100);       // Restaurar divisor
        write_reg(BASE_ADDR + 32'h0004, 32'd50);        // Duty 50%
        // Ya incluye enable (bit 31=1)
        write_reg(BASE_ADDR + 32'h0008, 32'h80000001);  // Enable + alineación centro
        #(CLK_PERIOD * 300);
        
        // ---------------------------------------------------------------------
        // Verificación final
        // ---------------------------------------------------------------------
        $display("\n=== Verificación final ===");
        read_reg(BASE_ADDR + 32'h0000);  // Leer divisor
        read_reg(BASE_ADDR + 32'h0004);  // Leer duty cycle
        read_reg(BASE_ADDR + 32'h0008);  // Leer registro de control
        
        // Finalizar simulación
        #(CLK_PERIOD * 100);
        $display("\nSimulación completada exitosamente");
        $finish;
    end

    // Monitorización adicional
    always @(posedge clk) begin
        if (uut.pwm_tick) begin
            $display("[%0t] PWM: Counter=%0d, Out=%b, Duty=%0d%%, Align=%s", 
                    $time, uut.pwm_counter, pwm_out, 
                    uut.safe_duty_cycle,
                    uut.pwm_align == 2'b00 ? "Left" : 
                    uut.pwm_align == 2'b01 ? "Center" : "Right");
        end
    end

endmodule
