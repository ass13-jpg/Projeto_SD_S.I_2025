module safecrack_fsm (
    input  logic       clk,
    input  logic       rstn,
    input  logic [2:0] btn,   // buttons inputs (BTN[3:0])
    output logic        LEDG1, // output: LED verde1
    output logic        LEDG2, // output: LED verde2
    output logic        LEDG3, // output: LED verde3
    output logic        LEDG4, // output: LED verde4
    output logic        LEDG5, // output: LED verde5
    output logic        LEDG6, // output: LED verde6
    output logic        LEDG7, // output: LED verde7
    output logic        LEDG8, // output: LED verde8
    output logic        LEDV1  // output: LED vermelha1
);
    // one-hot encoding
    typedef enum logic [4:0] { 
        S0      = 5'b00001,  // initial state
        S1      = 5'b00010,  // BTN = 1 right
        S2      = 5'b00100,  // BTN = 2 right
        WAIT    = 5'b01000,  // BTN = 3 right -> unlock ON
        ERRO    = 5'b10000   // unlock OFF
    } state_t;

    state_t state, next_state;
    logic [2:0] btn_prev, btn_edge, btn_pos;
    logic       any_btn_edge;

    localparam int BLINK_DELAY = 250_000_000;    // 5 second delay at 50MHz clock
    logic [$clog2(BLINK_DELAY)-1:0] delay_cnt, next_delay_cnt;
     
    // Logic for detecting edges of the buttons (active-high)
    always_comb begin
        btn_pos      = ~btn;                // invert buttons to active high
        btn_edge     = btn_pos & ~btn_prev; // get 0 -> 1 edges
        any_btn_edge = (|btn_edge);         // any button edge detected
    end 
     
    // Sequential logic (state transitions and delay counter)
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_prev    <= 3'b000;
            delay_cnt   <= BLINK_DELAY;
            state       <= S0;
        end
        else begin
            btn_prev    <= btn_pos;
            delay_cnt   <= next_delay_cnt;
            state       <= next_state;
        end
    end

    // State transition logic
    always_comb begin
        // default assignments
        next_state     = state;
        next_delay_cnt = delay_cnt;

        unique case (state)
            S0: begin
                if (btn_edge == 3'b001) next_state = S1;  // button 0 pressed -> correct input
                else if (any_btn_edge) next_state = ERRO; // any other invalid input -> restart
                else next_state = S0;  // no button pressed -> stay
            end
            S1: begin
                if (btn_edge == 3'b010) next_state = S2;  // button 1 pressed -> correct input
                else if (any_btn_edge) next_state = ERRO; // any other invalid input -> restart
                else next_state = S1;  // no button pressed -> stay
            end
            S2: begin
                if (btn_edge == 3'b100) next_state = WAIT;  // button 2 pressed -> correct input
                else if (any_btn_edge) next_state = ERRO; // any other invalid input -> restart
                else next_state = S2;  // no button pressed -> stay
            end
            WAIT: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0;
                    next_delay_cnt = BLINK_DELAY;  // reset delay counter
                end
            end
            ERRO: begin
                if (delay_cnt > 100_000_000) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0;
                    next_delay_cnt = BLINK_DELAY;  // reset delay counter
                end
            end
            default: next_state = S0;  // In case of undefined state, return to S0
        endcase
    end

    // Output logic (LED control)
    always_comb begin
        // Default assignments (turn off all LEDs before assigning specific values)
        LEDG1 = 0;
        LEDG2 = 0;
        LEDG3 = 0;
        LEDG4 = 0;
        LEDG5 = 0;
        LEDG6 = 0;
        LEDG7 = 0;
        LEDG8 = 0;
        LEDV1 = 0;

        // Switch case for LED control based on the current state
        case (state)
            S0: begin
                LEDG1 = 1; // Only LEDG1 turned on
            end
            S1: begin
                LEDG1 = 1; // LEDG1 turned on
                LEDG2 = 1; // LEDG2 turned on
            end
            S2: begin
                LEDG1 = 1; // LEDG1 turned on
                LEDG2 = 1; // LEDG2 turned on
                LEDG3 = 1; // LEDG3 turned on
            end
            WAIT: begin
                LEDG1 = 1; // All green LEDs turned on
                LEDG2 = 1;
                LEDG3 = 1;
                LEDG4 = 1;
                LEDG5 = 1;
                LEDG6 = 1;
                LEDG7 = 1;
                LEDG8 = 1;
            end
            ERRO: begin
                LEDV1 = 1; // Red LED turned on in case of error
            end
            default: begin
                // Default case (should not happen if states are well defined)
                LEDG1 = 0;
                LEDG2 = 0;
                LEDG3 = 0;
                LEDG4 = 0;
                LEDG5 = 0;
                LEDG6 = 0;
                LEDG7 = 0;
                LEDG8 = 0;
                LEDV1 = 0;
            end
        endcase
    end

endmodule
