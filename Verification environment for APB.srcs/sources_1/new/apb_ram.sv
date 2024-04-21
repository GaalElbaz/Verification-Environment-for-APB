`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: apb_ram
//////////////////////////////////////////////////////////////////////////////////


module apb_ram (
  input presetn,
  input pclk,
  input psel,
  input penable,
  input pwrite,
  input [31:0] paddr, pwdata,
  output logic [31:0] prdata,
  output logic pready, pslverr
);
  
  reg [31:0] mem [32];
  
  typedef enum {idle = 0, setup = 1, access = 2, transfer = 3} state_type;
 
  state_type state = idle;
  state_type nextstate;
  
  always_ff @(posedge pclk) begin
      //active low 
    if(presetn == 1'b0) begin
        state <= idle;
        prdata <= 32'h00000000;
        pready <= 1'b0;
        pslverr <= 1'b0;
        // initallizing memory elements to zero
        for(int i = 0; i < 32; i++) begin
          mem[i] <= 0;
        end
    end
    else begin
        state <= nextstate;
    end  
  end 
  always_comb begin    
    case(state)
        idle : begin
            prdata = 32'h00000000;
            pready = 1'b0;
            pslverr = 1'b0;
            if((psel == 1'b0) && (penable == 1'b0)) begin
                nextstate = setup;
            end
            else begin
                nextstate = idle;
            end
        end
        
        ///start of transaction
        setup: begin
            if((psel == 1'b1) && (penable == 1'b0)) begin
                if(paddr < 32) begin 
                    nextstate = access;
                    pready = 1'b1;
                end
            else begin
                nextstate = access;
                pready = 1'b0;
            end
            end
                else
                    nextstate = setup;
        end
        
        access: begin 
            if(psel && pwrite && penable) begin
                if(paddr < 32) begin
                    mem[paddr] = pwdata;
                    nextstate = transfer;
                    pslverr = 1'b0;
                end
            else begin
                nextstate = transfer;
                pready = 1'b1;
                pslverr = 1'b1;
            end
            end
            else if ( psel && !pwrite && penable) begin
                if(paddr < 32) begin
                    prdata = mem[paddr];
                    nextstate = transfer;
                    pready = 1'b1;
                    pslverr = 1'b0;
                end
                else begin
                    nextstate = transfer;
                    pready = 1'b1;
                    pslverr = 1'b1;
                    prdata = 32'hxxxxxxxx;
                end
            end
        end      
        transfer: begin
            nextstate = setup;
            pready = 1'b0;
            pslverr = 1'b0;
        end      
      
      default : nextstate = idle;   
      endcase
      
    end  
  
endmodule

