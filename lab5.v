`define tamanho_barramento 70

// flag no barramento_entrada
`define modo_cache        	  		0
`define modo_memoria     	 	   10
`define modo_cpu         	 	   20
`define rfo             	 	   51
`define write_back       	 	   70
`define modo_diretorio_raiz  	   60
`define modo_diretorio_individual  50

// estado do bloco de cache individual
`define INVALIDO_CACHE      2'b00
`define COMPARTILHADO_CACHE 2'b01
`define EXCLUSIVO_CACHE     2'b10

// estados da cache com diretorio
`define FORA_DA_CACHE_DIRETORIO  2'b00
`define COMPARTILHADO_DIRETORIO	 2'b01
`define EXCLUSIVO_DIRETORIO      2'b10

// resultado de operacao da CPU
`define CPU_READ_MISS  2'b00
`define CPU_READ_HIT   2'b01
`define CPU_WRITE_MISS 2'b10
`define CPU_WRITE_HIT  2'b11

// mensagens PARA o diretorio raiz
`define PERDA_DE_ESCRITA          2'b00
`define PERDA_DE_LEITURA          2'b01
`define INVALIDACAO				  2'b01

// 	mensagens DO diretorio raiz para a cache individual
`define BUSCA_DE_DADOS		2'b00
`define INVALIDACAO			2'b01

// 	mensagens DO diretorio raiz para a cache com diretorio
`define ZERAR_COMPARTILHADORES	       2'b00
`define COMPARTILHADORES	 	   	   2'b01
`define INCREMENTA_COMPARTILHADORES	   2'b10
`define RESPOSTA_DO_VALOR_DE_DADOS     1'b1


/* MODULO TOP-LEVEL*/
module lab5();

    reg  [`tamanho_barramento:0]barramento_entrada;
	wire  [`tamanho_barramento:0]barramento_saida;

	wire [1:0]mensagem_para_diretorio_raiz;
    
	initial begin
		#1 
			/* 
				CPU WRITE MISS
				estado invalido do bloco
			 */
			barramento_entrada[6:0] = {2'b01,2'b01,1'b1,1'b0,1'b1};	
			$display("input :%b",barramento_entrada);
		#1
			$display("##messagem to diretorio:%b##",barramento_saida);
			$display("output:%b\n",barramento_saida);
		
		$finish;
    end

	diretorio_cache maq1(mensagem_para_diretorio_raiz,barramento_entrada,barramento_saida);
endmodule


/************modulo que implementa a maquina diretorio para bloco de caches individuais***********************/
module diretorio_cache(mensagem_para_diretorio_raiz,barramento_entrada,barramento_saida);
	
	output reg [`tamanho_barramento:0] barramento_saida;
	output reg [1:0]mensagem_para_diretorio_raiz;
	
	input 	   [`tamanho_barramento:0]barramento_entrada;
	
	reg		   [1:0]buffer_mensagem_para_diretorio;
	reg        [`tamanho_barramento:0]buffer;
	
	always@(barramento_entrada)begin
		/* verifica se a mensagem no barramento esta em modo de cache */
		buffer = barramento_entrada;
		if(buffer[`modo_cache] == 1'b1)begin
			/* o case avalia em qual estado o bloco da cache esta */
			case(buffer[4:3])
				`INVALIDO_CACHE:				
					begin
						if(buffer[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `PERDA_DE_LEITURA;
						end else if(buffer[2:1] ===`CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] =  `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `PERDA_DE_ESCRITA;
						end
						/* retira referencia da cpu */
						buffer[`modo_cpu]       = 1'b0;
					end

				`COMPARTILHADO_CACHE:
					begin
						if(buffer[2:1] === `CPU_READ_MISS)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `PERDA_DE_LEITURA;
						end else if(buffer[2:1] === `CPU_READ_HIT)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
						end else if(buffer[2:1] === `CPU_WRITE_HIT)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `INVALIDACAO;
						end else if(buffer[2:1] === `CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `PERDA_DE_ESCRITA;
						end
						/* retira referencia da cpu */
						buffer[`modo_cpu]  = 1'b0;
					end
   

				`EXCLUSIVO_CACHE:
					begin
						if(buffer[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `PERDA_DE_LEITURA;
							/* indica o write back */
							buffer[`write_back] = 1'b1;
						end else if(buffer[2:1] === `CPU_READ_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
						end else if(buffer[2:1] === `CPU_WRITE_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
						end else if(buffer[2:1] === `CPU_WRITE_MISS)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
						end
						/* retira referencia da cpu */
						buffer[`modo_cpu]       = 1'b0;
					end
				default:
					begin 
						/* retirar todas as referencias*/
						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
						buffer[`modo_diretorio_raiz] = 1'b0;
						buffer[`modo_diretorio_individual] = 1'b0;
					end
			endcase	
		end
		barramento_saida = buffer;
	end
endmodule

module diretorio_cache_escuta(mensagem_do_diretorio_raiz,barramento_entrada,barramento_saida);

	input [`tamanho_barramento:0]barramento_entrada;
	/* essa entrada  sera utilizado quando estiver implementada dentro da cache individual */
	input [1:0]mensagem_do_diretorio_raiz;

	output reg [`tamanho_barramento:0]barramento_saida;

	reg [1:0]atual_estado;
	reg [1:0]proximo_estado;
	reg [`tamanho_barramento:0]buffer;

	initial begin

		if(buffer[60] === 1'b1)begin
			proximo_estado = escuta(atual_estado);
		end
	end

	function [1:0] escuta;
        input [1:0]estado;
        reg [`tamanho_barramento:0]retorno;
        begin
			case(mensagem_do_diretorio_raiz)
				`BUSCA_DE_DADOS:			
					begin
						if(estado === `EXCLUSIVO_CACHE)begin
							retorno = `COMPARTILHADO_CACHE;
						end else if(estado === `INVALIDO_CACHE)begin
							retorno = `INVALIDO_CACHE;
						end
						/* retira a referencia do controlador diretorio raiz*/
						buffer[`modo_diretorio_raiz] = 1'b1;
					end

				`INVALIDACAO:
					begin
						if(estado === `COMPARTILHADO_CACHE)begin
							retorno = `INVALIDO_CACHE;
						end
						/* retira a referencia do controlador diretorio raiz*/
						buffer[`modo_diretorio_raiz] = 1'b1;
					end
			endcase
			escuta = retorno;
		end
	endfunction

endmodule


/*****************modulo que implementa a maquina para a cache com diretorio**************************/
module diretorio_raiz(mensagem_da_cache,mensagem_para_cache,estado_inicial,estado_final,barramento_entrada,barramento_saida);
	
	output reg [`tamanho_barramento:0] barramento_saida;
	output reg [1:0]estado_final;
	output reg [1:0]mensagem_para_cache;
	
	input [`tamanho_barramento:0]barramento_entrada;
	input [1:0]estado_inicial;
	input [1:0]mensagem_da_cache;

	reg [`tamanho_barramento:0]buffer;
	reg [1:0]buffer_de_estado;
	reg [1:0]buffer_de_mensagem_para_cache;

	always@(mensagem_da_cache)begin
		buffer = barramento_entrada;
		/* o case avalia em qual estado o bloco da cache esta */
		case(estado_inicial)
			`FORA_DA_CACHE_DIRETORIO:
				begin
					if(mensagem_da_cache === `PERDA_DE_ESCRITA)begin
						buffer_de_estado = `COMPARTILHADO_CACHE;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `COMPARTILHADORES;
					end else if(mensagem_da_cache === `PERDA_DE_LEITURA)begin
						buffer_de_estado = `EXCLUSIVO_DIRETORIO;
						buffer[65:64] = `COMPARTILHADORES;
					end
					/* retirar referencia do controlador diretorio cache individual*/
					buffer[`modo_diretorio_individual] = 1'b0;
					/* coloca referencia no controlador diretorio raiz*/
					buffer[`modo_diretorio_raiz] = 1'b1;
				end


			`COMPARTILHADO_DIRETORIO:
				begin
					if(mensagem_da_cache === `PERDA_DE_ESCRITA)begin
						buffer_de_estado = `EXCLUSIVO_DIRETORIO;
						buffer_de_mensagem_para_cache = `BUSCA_DE_DADOS;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `INCREMENTA_COMPARTILHADORES;
					end else if(mensagem_da_cache === `PERDA_DE_LEITURA )begin
						buffer_de_estado = `COMPARTILHADO_DIRETORIO;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `INCREMENTA_COMPARTILHADORES;
					end 
					/* retirar referencia do controlador diretorio cache individual*/
					buffer[`modo_diretorio_individual] = 1'b0;
					/* coloca referencia no controlador diretorio raiz*/
					buffer[`modo_diretorio_raiz] = 1'b1;
				end


			`EXCLUSIVO_DIRETORIO:
				begin
					if(mensagem_da_cache === `PERDA_DE_ESCRITA)begin
						buffer_de_estado = `EXCLUSIVO_DIRETORIO;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `COMPARTILHADORES;
					end else if(mensagem_da_cache === `PERDA_DE_LEITURA)begin
						buffer_de_estado = `COMPARTILHADO_DIRETORIO;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `INCREMENTA_COMPARTILHADORES;
						buffer_de_mensagem_para_cache = `BUSCA_DE_DADOS;
						buffer[63:61] = buffer[48:46];
					end
					
					if(barramento_entrada[70] === 1'b1)begin
						buffer_de_estado = `FORA_DA_CACHE_DIRETORIO;
						buffer[66] = 1'b0;
						buffer[65:64] = `ZERAR_COMPARTILHADORES;
					end
					/* retirar referencia do controlador diretorio cache individual*/
					buffer[`modo_diretorio_individual] = 1'b0;
					/* coloca referencia no controlador diretorio raiz*/
					buffer[`modo_diretorio_raiz] = 1'b1;

				end

			default:
				begin
					/* retirar todas as referencias */
					buffer[`modo_cpu]  = 1'b0;
					buffer[`modo_memoria]  = 1'b0;
					buffer[`modo_cache]   = 1'b0;
					buffer[`modo_diretorio_individual] = 1'b0;
					buffer[`modo_diretorio_raiz] = 1'b0;
				end
		endcase
		estado_final = buffer_de_estado;
		barramento_saida = buffer;
	end
endmodule