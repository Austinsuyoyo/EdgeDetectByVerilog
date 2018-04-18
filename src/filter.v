// --------------------------------------------------------------------
// Copyright (c) 2017 by Austin Su. 
// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Major Functions: Image Edge Detection Project Main File
//
// --------------------------------------------------------------------
//                     Email: avui67224307@gmail.com
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Austin Su         :| 2017/07/10:| Initial Revision
// -------------------------------------------------------------------
module filter (
	input wire 				clk,
	input wire 				rst_n,
	input wire 				fc_valid,
	input 		 	[7:0] 	working_pixel,
	input signed 	[7:0]	fc,
	input wire 				start,
	output reg 		[7:0] 	out_pixel,
	output reg 				out_valid,
	output reg 		[15:0] 	addr,
	output wire 			wen,
	output wire 	[7:0] 	d
);
//===========================================================================
// PARAMETER declarations
//===========================================================================
	parameter 		[2:0] 	IDLE = 3'b000;		
	parameter 		[2:0] 	COEF = 3'b001;
	parameter 		[2:0] 	READ = 3'b010;
	parameter 		[2:0] 	CONV = 3'b011;
	parameter 		[2:0] 	OUT  = 3'b100;
	assign 					wen = 1;
	assign 					d = 0;
//=======================================================
//  REG/WIRE declarations
//=======================================================
	reg				[2:0] 	rState,rState_next;
	reg 			[4:0] 	rCounter=0;								//counting filter load in times (25)
	reg			 	[4:0] 	rPixCounter=0; 							//counting pixel  load in times (25)
	reg			 	[2:0] 	rCounter_proc=0; 						//delay counter for process
	reg			 	[2:0] 	rCounter_out=0; 						//delay counter for output
	reg signed 		[7:0]	rCoeff [0:24];							//restore the coefficient
	reg signed 		[8:0] 	rUsingPixel [0:24];						//restore the 25 pixels
	reg signed 		[10:0] 	rResult; 								//CONV result
	reg 			[15:0] 	rPixProcess;							//pixel pointer
	reg						rReadPix=-1;							//signal
	reg						rSentAddr;								//signal
	reg						rOutDone;								//signal

//=============================================================================
// Structural coding
//=============================================================================
//rState=rState_next
always@(posedge clk,negedge rst_n)begin
	if(rst_n==0)begin
		rState=IDLE;
	end 
	else begin
		rState<=rState_next;
	end
end
//assign fc to flip-flop
always@(posedge clk)begin
	if(fc_valid==1)begin
		rCoeff[rCounter]<=$signed(fc);
		rCounter <= rCounter+1;	
	end
	else 
		rCounter <= 0;
end
//move Pixel pointer
always@(posedge rReadPix or posedge start)begin
	if(rState==IDLE)begin
		rPixProcess<=0; //initial value
	end
	else
		rPixProcess<=rPixProcess+1;
end
//border process
always@(posedge clk)begin
	if(rState==READ)begin
		if(rPixProcess<256&&rPixCounter<10)begin
			//$display ("CASE 1");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess<512&&rPixCounter<5)begin
			//$display ("CASE 2");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess>65023&&rPixCounter>19)begin
			//$display ("CASE 3");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess>65279&&rPixCounter>14)begin
			//$display ("CASE 4");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess%256==0&&rPixCounter%5<2)begin
			//$display ("CASE 5");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
			else if(rPixProcess%256==1&&rPixCounter%5==0)begin
			//$display ("CASE 6");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess%256==254&&rPixCounter%5==4)begin
			//$display ("CASE 7");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else if(rPixProcess%256==255&&rPixCounter%5>2)begin
			//$display ("CASE 8");
			rUsingPixel[rPixCounter]<=0;
			rPixCounter <= rPixCounter+1;
			rCounter_proc<=0;
		end
		else begin
			if(rCounter_proc>2)begin
				//$display ("CASE addr");
				rUsingPixel[rPixCounter]<={1'b0,working_pixel[7:0]};
				rPixCounter <= rPixCounter+1;
				rCounter_proc<=0;
				rSentAddr<=0;
			end
			else begin
				//$display ("CASE sent address");
				rSentAddr<=1;
				rCounter_proc<=rCounter_proc+1;
			end
			rSentAddr<=0;
		end
	end
	else 
		rPixCounter <= 0;
end
//address process
always@(posedge rSentAddr or posedge start)begin
	if(rState==IDLE)begin
		addr<=0; //initial value
	end
	else begin
		case(rPixCounter)
				0:addr<=rPixProcess-512-2;
				1:addr<=rPixProcess-512-1;
				2:addr<=rPixProcess-512;
				3:addr<=rPixProcess-512+1;
				4:addr<=rPixProcess-512+2;
				5:addr<=rPixProcess-256-2;
				6:addr<=rPixProcess-256-1;
				7:addr<=rPixProcess-256;
				8:addr<=rPixProcess-256+1;
				9:addr<=rPixProcess-256+2;
				10:addr<=rPixProcess-2;
				11:addr<=rPixProcess-1;
				12:addr<=rPixProcess;
				13:addr<=rPixProcess+1;
				14:addr<=rPixProcess+2;
				15:addr<=rPixProcess+256-2;
				16:addr<=rPixProcess+256-1;
				17:addr<=rPixProcess+256;
				18:addr<=rPixProcess+256+1;
				19:addr<=rPixProcess+256+2;
				20:addr<=rPixProcess+512-2;
				21:addr<=rPixProcess+512-1;
				22:addr<=rPixProcess+512;
				23:addr<=rPixProcess+512+1;
				24:addr<=rPixProcess+512+2;
		endcase
	end
end
//===============================
//MAIN:change of State 
//===============================
 always@*begin
	case(rState)
		IDLE:begin
			if(start==1)
				rState_next=COEF;
			else
				rState_next=IDLE;
		 end
		COEF:begin
			if(rCounter==25)begin
				$display ("SHOW COEF BELOW :");
				$display ("%d,%d,%d,%d,%d",rCoeff[0],rCoeff[1],rCoeff[2],rCoeff[3],rCoeff[4]);
				$display ("%d,%d,%d,%d,%d",rCoeff[5],rCoeff[6],rCoeff[7],rCoeff[8],rCoeff[9]);
				$display ("%d,%d,%d,%d,%d",rCoeff[10],rCoeff[11],rCoeff[12],rCoeff[13],rCoeff[14]);
				$display ("%d,%d,%d,%d,%d",rCoeff[15],rCoeff[16],rCoeff[17],rCoeff[18],rCoeff[19]);
				$display ("%d,%d,%d,%d,%d",rCoeff[20],rCoeff[21],rCoeff[22],rCoeff[23],rCoeff[24]);	
				rState_next=READ;
			end
			else 
				rState_next=COEF;
		end	
		READ:begin
			if(rPixCounter==25)begin
				//$display("rUsingPixel[00-04]=%d,%d,%d,%d,%d",rUsingPixel[0],rUsingPixel[1],rUsingPixel[2],rUsingPixel[3],rUsingPixel[4]);
				//$display("rUsingPixel[05-09]=%d,%d,%d,%d,%d",rUsingPixel[5],rUsingPixel[6],rUsingPixel[7],rUsingPixel[8],rUsingPixel[9]);
				//$display("rUsingPixel[10-14]=%d,%d,%d,%d,%d",rUsingPixel[10],rUsingPixel[11],rUsingPixel[12],rUsingPixel[13],rUsingPixel[14]);
				//$display("rUsingPixel[15-19]=%d,%d,%d,%d,%d",rUsingPixel[15],rUsingPixel[16],rUsingPixel[17],rUsingPixel[18],rUsingPixel[19]);
				//$display("rUsingPixel[20-24]=%d,%d,%d,%d,%d",rUsingPixel[20],rUsingPixel[21],rUsingPixel[22],rUsingPixel[23],rUsingPixel[24]);
				//$display("======================================");
				rState_next<=CONV;
				rReadPix=0;
			end
			else begin
				rReadPix=1;
				rState_next<=READ;
			end
		end
		CONV:begin
			if(rPixProcess<=65535)begin
				rResult<=rCoeff[0]*rUsingPixel[0]+rCoeff[1]*rUsingPixel[1]+rCoeff[2]*rUsingPixel[2]+rCoeff[3]*rUsingPixel[3]+rCoeff[4]*rUsingPixel[4]+
						rCoeff[5]*rUsingPixel[5]+rCoeff[6]*rUsingPixel[6]+rCoeff[7]*rUsingPixel[7]+rCoeff[8]*rUsingPixel[8]+rCoeff[9]*rUsingPixel[9]+
						rCoeff[10]*rUsingPixel[10]+rCoeff[11]*rUsingPixel[11]+rCoeff[12]*rUsingPixel[12]+rCoeff[13]*rUsingPixel[13]+rCoeff[14]*rUsingPixel[14]+
						rCoeff[15]*rUsingPixel[15]+rCoeff[16]*rUsingPixel[16]+rCoeff[17]*rUsingPixel[17]+rCoeff[18]*rUsingPixel[18]+rCoeff[19]*rUsingPixel[19]+
						rCoeff[20]*rUsingPixel[20]+rCoeff[21]*rUsingPixel[21]+rCoeff[22]*rUsingPixel[22]+rCoeff[23]*rUsingPixel[23]+rCoeff[24]*rUsingPixel[24];
				if(!rOutDone)begin
					if(rResult<0)begin
						//$display ("rResult<0");
						out_pixel<=0;
						rOutDone<=1;
					end
					else if(rResult>255)begin
						//$display ("rResult>255");
						out_pixel<=255;
						rOutDone<=1;
					end
					else begin
						//$display ("rResult good");
						out_pixel<=rResult;
						rOutDone<=1;
					end
				end
				else begin
					rState_next=OUT;
					rOutDone=0;
				end
			end	
			else 
				rState_next<=CONV;
		end
		OUT:begin
			if(!out_valid)begin
				out_valid=1;
				rState_next=READ;
			end
			else begin
				out_valid<=0;
				rState_next<=OUT;
			end
		end
	endcase
end
endmodule
