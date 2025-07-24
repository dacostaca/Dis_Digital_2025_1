// ======================================================
// Módulo PWM para RISC-V con bus paralelo
// Características:
// - Configuración de frecuencia (divisor)
// - Duty cycle ajustable (0-100%)
// - Tres modos de alineación: izquierda, centro, derecha
// ======================================================
`timescale 1ns / 1ps

module pwm_peripheral (
    input            clk,
    input            rst,
    input     [31:0] add,
    input     [31:0] din,
    output reg [31:0] dout,
    input            wr,
    input            rd,
    output reg       wr_busy,
    output reg       rd_busy,
    input            wr_strobe,
    input            rd_strobe,
    input      [3:0] mask,
    output reg       pwm_out  // Salida PWM añadida
);

    // Direcciones de registros
    parameter BASE_ADDR = 32'h4000_0000;
    parameter REG_DIV   = 32'h0000_0000;
    parameter REG_DUTY  = 32'h0000_0004;
    parameter REG_CTRL  = 32'h0000_0008;

    // Registros de configuración
    reg [31:0] div_counter;
    reg [31:0] duty_cycle;
    reg [1:0]  pwm_align;
    reg        pwm_enable;
    
    // Registros sombra
    reg [31:0] div_counter_shadow;
    reg [31:0] duty_cycle_shadow;
    reg [1:0]  pwm_align_shadow;
    reg        pwm_enable_shadow;
    reg        update_pending;

    // Generación PWM
    reg [31:0] pwm_counter;
    wire       pwm_tick;
    reg [31:0] safe_duty_cycle;

    // Máquina de estados
    localparam [2:0] 
        IDLE        = 3'b000,
        WRITE_START = 3'b001,
        WRITE_HOLD  = 3'b010,
        READ_START  = 3'b011,
        READ_HOLD   = 3'b100,
        UPDATE_REG  = 3'b101;
    
    reg [2:0] state, next_state;

    // Lógica de actualización
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            div_counter  <= 32'd100;
            duty_cycle   <= 32'd50;
            pwm_align    <= 2'b00;
            pwm_enable   <= 1'b1;
            safe_duty_cycle <= 50;
            wr_busy <= 0;
            rd_busy <= 0;
            dout <= 0;
            update_pending <= 0;
            pwm_out <= 0;
        end else begin
            state <= next_state;
            
            // Actualización directa en UPDATE_REG
            if (state == UPDATE_REG) begin
                div_counter <= div_counter_shadow;
                duty_cycle <= duty_cycle_shadow;
                pwm_align <= pwm_align_shadow;
                pwm_enable <= pwm_enable_shadow;
                safe_duty_cycle <= (duty_cycle_shadow > 100) ? 100 : 
                                  (duty_cycle_shadow < 0) ? 0 : duty_cycle_shadow[31:0];
            end
        end
    end

    // Máquina de estados del bus
    always @(*) begin
        next_state = state;
        wr_busy = 0;
        rd_busy = 0;
        
        case (state)
            IDLE: begin
                if (wr && ((add == BASE_ADDR + REG_DIV) || 
                          (add == BASE_ADDR + REG_DUTY) || 
                          (add == BASE_ADDR + REG_CTRL))) begin
                    next_state = WRITE_START;
                end
                else if (rd && ((add == BASE_ADDR + REG_DIV) || 
                               (add == BASE_ADDR + REG_DUTY) || 
                               (add == BASE_ADDR + REG_CTRL))) begin
                    next_state = READ_START;
                end
            end
            
            WRITE_START: begin
                wr_busy = 1;
                if (wr_strobe) next_state = UPDATE_REG;
                else next_state = WRITE_HOLD;
            end
            
            WRITE_HOLD: begin
                wr_busy = 1;
                if (wr_strobe) next_state = UPDATE_REG;
            end
            
            READ_START: begin
                rd_busy = 1;
                next_state = READ_HOLD;
            end
            
            READ_HOLD: begin
                rd_busy = 1;
                if (rd_strobe) next_state = IDLE;
            end
            
            UPDATE_REG: begin
                next_state = IDLE;
            end
        endcase
    end

    // Escritura de registros
    always @(posedge clk) begin
        if (rst) begin
            div_counter_shadow  <= 32'd100;
            duty_cycle_shadow   <= 32'd50;
            pwm_align_shadow    <= 2'b00;
            pwm_enable_shadow   <= 1'b1;
            update_pending <= 0;
        end else if (state == WRITE_START) begin
            case (add)
                BASE_ADDR + REG_DIV:  div_counter_shadow <= din;
                BASE_ADDR + REG_DUTY: duty_cycle_shadow  <= din;
                BASE_ADDR + REG_CTRL: begin
                    pwm_align_shadow  <= din[1:0];
                    pwm_enable_shadow <= din[31];
                end
            endcase
            update_pending <= 1;
        end
    end

    // Lectura de registros
    always @(negedge clk) begin
        if (state == READ_START) begin
            case (add)
                BASE_ADDR + REG_DIV:  dout <= div_counter;
                BASE_ADDR + REG_DUTY: dout <= duty_cycle;
                BASE_ADDR + REG_CTRL: dout <= {29'b0, pwm_align, pwm_enable};
                default: dout <= 32'hDEAD_BEEF;
            endcase
        end
    end

    // Generación de señal PWM
    assign pwm_tick = (pwm_counter == div_counter);

    // Cálculo de umbrales para cada alineación
    wire [31:0] rising_threshold, falling_threshold;
    assign rising_threshold = (pwm_align == 2'b00) ? 0 :                           // Izquierda
                             (pwm_align == 2'b01) ? (div_counter/2) - (div_counter*safe_duty_cycle/200) :  // Centro
                             div_counter - (div_counter*safe_duty_cycle/100);      // Derecha

    assign falling_threshold = (pwm_align == 2'b00) ? (div_counter*safe_duty_cycle/100) :  // Izquierda
                              (pwm_align == 2'b01) ? (div_counter/2) + (div_counter*safe_duty_cycle/200) : // Centro
                              div_counter;                                           // Derecha

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_out <= 0;
            pwm_counter <= 0;
        end else begin
            if (pwm_counter >= div_counter) begin
                pwm_counter <= 0;
            end else begin
                pwm_counter <= pwm_counter + 1;
            end
            
            if (pwm_enable) begin
                if ((pwm_counter >= rising_threshold) && 
                    (pwm_counter < falling_threshold)) begin
                    pwm_out <= 1;
                end else begin
                    pwm_out <= 0;
                end
            end else begin
                pwm_out <= 0;
            end
        end
    end

    // Monitorización para GTKWave
    // synthesis translate_off
    always @(posedge clk) begin
        if (state == WRITE_START) begin
            $display("[%0t] WRITE: Addr=0x%h Data=0x%h", $time, add, din);
        end
        else if (state == READ_START) begin
            $display("[%0t] READ: Addr=0x%h Data=0x%h", $time, add, dout);
        end
        
        if (pwm_tick) begin
            $display("[%0t] PWM: Period | FreqDiv=%0d Duty=%0d%% Align=%s Out=%b", 
                    $time, div_counter, safe_duty_cycle, 
                    pwm_align == 2'b00 ? "Left" : 
                    pwm_align == 2'b01 ? "Center" : "Right",
                    pwm_out);
        end
    end
    // synthesis translate_on

endmodule
