
module image_cntrl #( 
    parameter BRAM1_BW =8, 
    parameter BRAM1_AMAX= 10404, 
    parameter BRAM1_ADR = $clog2(BRAM1_AMAX), 
    parameter BRAM2_BW =8, 
    parameter BRAM2_AMAX= 10000, 
    parameter BRAM2_ADR = $clog2(BRAM2_AMAX)

    )(
    input wire clk, 
    input wire resetn, 
    input wire start, 
    output reg done, 
    
    output reg bram1_en,
    output reg bram2_en,
    output reg bram2_we,
    output reg [BRAM1_ADR-1:0] bram1_addr,
    output reg [BRAM2_ADR-1:0] bram2_addr,
    input  wire [BRAM1_BW-1:0] bram1_dout,
    output reg [BRAM2_BW-1:0] bram2_din,
    
    output reg [BRAM1_BW-1:0] p00,p01,p02, 
    output reg [BRAM1_BW-1:0] p10,p11,p12,
    output reg [BRAM1_BW-1:0] p20,p21,p22,
    input wire [BRAM2_BW-1:0] sobel_result
    );
    
    localparam IDLE         = 3'd0;
    localparam READ_ADDR    = 3'd1;
    localparam READ_DATA  = 3'd2;
   
    localparam WRITE_RESULT = 3'd3;
    localparam NEXT_PIXEL   = 3'd4;
    localparam DONE         = 3'd5;
    localparam EXTRA_READ = 3'd6; 
    
    reg [2:0] state;
    reg [6:0] row; // 0 to 99 
    reg [6:0] col; 
    reg [3:0] read_count; //0 to 8 
    
    always @(posedge clk or negedge resetn) begin 
         if (!resetn) begin 
           row <=0; col <=0; read_count<=0; 
           state <=IDLE; p00 <= 0; p01 <= 0; p02 <= 0;
           p10 <= 0; p11 <= 0; p12 <= 0;
           p20 <= 0; p21 <= 0; p22 <= 0;
           bram1_en<=0; bram2_en<=0; 
           bram2_we<=0; bram1_addr<=0; 
           bram2_addr<=0; bram2_din<=0; 
           done<=0; 
        end 
        else begin 
        
        case (state) 
         IDLE: begin 
            done <=0; bram2_we<=0; bram2_en<=0; bram1_en<=0; 
            row<=0; col<=0; read_count<=0; 
             if (start) 
               state <=READ_ADDR; 
             else 
               state <=IDLE; 
         end 
         
        READ_ADDR: begin 
           bram1_en <=1; 
             case(read_count) 
               0: bram1_addr <= row*102 +col; 
               1: bram1_addr <=row*102 +(col+1); 
               2: bram1_addr <= row*102 + (col+2);
               3: bram1_addr <= (row+1)*102 + col;
               4: bram1_addr <= (row+1)*102 + (col+1);
               5: bram1_addr <= (row+1)*102 + (col+2);
               6: bram1_addr <= (row+2)*102 + col;
               7: bram1_addr <= (row+2)*102 + (col+1);
               8: bram1_addr <= (row+2)*102 + (col+2);
             endcase
             
          state <=EXTRA_READ; 
      end
      EXTRA_READ: begin 
         state <=READ_DATA;
      end
      
      READ_DATA: begin 
         case(read_count)
            0: p00 <= bram1_dout;
            1: p01 <= bram1_dout;
            2: p02 <= bram1_dout;
            3: p10 <= bram1_dout;
            4: p11 <= bram1_dout;
            5: p12 <= bram1_dout;
            6: p20 <= bram1_dout;
            7: p21 <= bram1_dout;
            8: p22 <= bram1_dout;
          endcase

          if(read_count == 8)
            begin
              read_count <= 0;
              bram1_en<=0;
              state <= WRITE_RESULT;
            end
            else
            begin
                read_count <= read_count + 1;
                state <= READ_ADDR;
            end

        end
        
        WRITE_RESULT: begin 
           bram2_en<=1; 
           bram2_we<=1; 
           bram2_addr <= row*100 +col; 
           bram2_din<=sobel_result; 
           state <=NEXT_PIXEL;
        end 
        
        NEXT_PIXEL: begin 
            bram2_we<=0; 
            bram2_en<=0;
            
            if(col==99) begin 
              col<=0; 
              if(row==99) begin 
                state <=DONE; 
              end else begin 
                row <=row+1; 
                state <=READ_ADDR; 
              end 
            end else begin 
            col <=col+1; 
            state <=READ_ADDR; 
            end
        end
      DONE:begin
           done <= 1;
           bram1_en <= 0;
           bram2_en <= 0;
           bram2_we <= 0;
           state <= DONE;

        end
        default:
            state <= IDLE;
        endcase

    end
  end
endmodule
