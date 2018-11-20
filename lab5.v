`define tamanho_barramento 70

// flag no barramento_entrada
`define modo_cache        	  0
`define modo_memoria     	 10
`define modo_cpu         	 20
`define modo_snooping_tx     62
`define modo_snooping_rx     63
`define modo_diretorio_tx    64
`define modo_diretorio_rx    65
`define rfo             	 59
`define place_on_bus    	 60
`define write_back       	 70
`define modo_diretorio   	 80
`define modo_cache_diretorio 90

// estado do bloco de cache
`define INVALIDO_CACHE      2'b00
`define COMPARTILHADO_CACHE 2'b01
`define EXCLUSIVO_CACHE     2'b10

// estados do diretorio
`define FORA_DA_CACHE_DIRETORIO  2'b00
`define COMPARTILHADO_DIRETORIO	 2'b01
`define EXCLUSIVO_DIRETORIO      2'b10

// resultado de operacao da CPU
`define CPU_READ_MISS  2'b00
`define CPU_READ_HIT   2'b01
`define CPU_WRITE_MISS 2'b10
`define CPU_WRITE_HIT  2'b11

// mensagens para o diretorio raiz
`define PERDA_DE_ESCRITA          2'b00
`define PERDA_DE_LEITURA          2'b01

// 	mensagens do diretorio raiz para a cache individual
`define BUSCA_DE_DADOS		2'b00;
`define INVALIDACAO			2'b01;

// 	mensagens do diretorio raiz para a cache com diretorio
`define ZERAR_COMPARTILHADORES	   2'b00;
`define COMPARTILHADORES	 	   2'b01;
`define INCREMENTA_COMPARTILHADORES	   2'b10;
`define RESPOSTA_DO_VALOR_DE_DADOS  1'b1;


/* MODULO TOP-LEVEL*/
module lab5();

    reg  [`tamanho_barramento:0]barramento_entrada;
	reg  [`tamanho_barramento:0]barramento_saida;
    
	initial begin
		#1 
			/* o bloco esta no estado invalido*/
			barramento_entrada[4:3] = `INVALIDO_CACHE		/* resultado escrito pela cache no barramento */
			barramento_entrada[`modo_cache] = 1'b1;
			/* a cache retorna para o barramento um CPU READ MISS */
			barramento_entrada[2:1] = `CPU_READ_MISS;
			$display("%b",barramento_entrada);
			barramento_saida = executa(barramento_entrada);
			$display("%b",barramento_saida);
			$finish;
    end
endmodule


/************modulo que implementa a maquina diretorio para bloco de caches***********************/
module diretorio_cache(mensagem_do_diretorio_raiz,mensagem_para_diretorio_raiz,barramento_entrada,barramento_saida);
	
	output reg [`tamanho_barramento:0] barramento_saida;
	output reg [1:0]mensagem_para_diretorio_raiz;
	
	input 	   [`tamanho_barramento:0]barramento_entrada;
	input	   [1:0]mensagem_do_diretorio_raiz;	
	
	reg		   [1:0]buffer_mensagem_para_diretorio;
	reg        [`tamanho_barramento:0]buffer;
	
	always begin
		/* verifica se a mensagem no barramento esta em modo de cache */
		buffer = barramento_entrada;
		if(barramento_entrada[`modo_cache] == 1'b1)begin
			/* o case avalia em qual estado o bloco da cache esta */
			case(barramento_entrada[4:3])
				`INVALIDO_CACHE				
					begin
						if(barramento_entrada[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `READ_MISS_ON_BUS;
						end else if(barramento_entrada[2:1] ==   = `CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] =  `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `WRITE_MISS_ON_BUS;
						end


						/*  
							zeramos os outros modos     
						*/
						
						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
						buffer[`write_back]		= 1'b0;

					end

				`COMPARTILHADO_CACHE:
					begin
						if(barramento_entrada[2:1] === `CPU_READ_MISS)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `READ_MISS_ON_BUS;
						end else if(barramento_entrada[2:1] === `CPU_READ_HIT)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
						end else if(barramento_entrada[2:1] =   == `CPU_WRITE_HIT)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `INVALIDATE_ON_BUS;
						end else if(barramento_entrada[2:1] =   == `CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `WRITE_MISS_ON_BUS;
						end

						/*  
							zeramos os outros modos     
						*/
						
						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
						buffer[`write_back]		= 1'b0;

					end
   

				`EXCLUSIVO_CACHE :
					begin
						if(barramento_entrada[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO_CACHE;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							buffer_mensagem_para_diretorio = `READ_MISS_ON_BUS;
							/* indica o write back */
							buffer[`write_back] = 1'b1;
						end else if(barramento_entrada[2:1] =   == `CPU_READ_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							/* zera a flag de write back */
							buffer[`write_back] = 1'b0;
						end else if(barramento_entrada[2:1] =   == `CPU_WRITE_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador diretorio*/
							buffer[50] = 1'b1;
							/* cache foco do diretorio*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							/* seta flag de write back */
							buffer[`write_back] = 1'b0;
						end else if(barramento_entrada[2:1] =   == `CPU_WRITE_MISS)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `EXCLUSIVO_CACHE ;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* cache foco do snooping*/
							buffer[54] = buffer[5];
							/* endereco de bloco*/
							buffer[67:65] = buffer[48:46];
							/* seta flag de write back */
							buffer[`write_back] = 1'b0;
						end

						/*  
								zeramos os outros modos     
						*/
						
						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
					end
				default:
					begin 
						/* faz nada */

						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
					end
			endcase	
		end

		if(buffer[60] === 1'b1)begin
			case(mensagem_do_diretorio_raiz)
				`BUSCA_DE_DADOS			
					begin

					end

		end 

		barramento_saida = buffer;
	end
endmodule

module diretorio_cache_escuta(barramento_entrada,barramento_saida);

	input [`tamanho_barramento:0]barramento_entrada;
	output [`tamanho_barramento:0]barramento_saida;

	reg [1:0]atual_estado;
	reg [1:0]proximo_estado;
	reg [`tamanho_barramento:0]buffer;

	always begin

		if(buffer[60] === 1'b1)begin
			proximo_estado = escuta(atual_estado);
			buffer[60] = 1; 
		end
		barramento_saida = buffer;
	end

	function [1:0] escuta;
        input [1:0]estado;
        reg [`tamanho_barramento:0]retorno;
        begin
			case(mensagem_do_diretorio_raiz)
				`BUSCA_DE_DADOS			
					begin
						if(estado === `EXCLUSIVO_CACHE)begin
							retorno = `COMPARTILHADO_CACHE;
						end else if(estado === `INVALIDO_CACHE)begin
							retorno = `INVALIDO_CACHE;
						end

					end

				`INVALIDACAO
					begin
						if(estado === `COMPARTILHADO_CACHE)begin
							retorno = `INVALIDO_CACHE;
						end
					end
			endcase
			escuta = retorno;
		end
	endfunction

endmodule


/****************************************modulo que implementa a maquina snooping que escuta****************************************/
module diretorio_raiz(mensagem_da_cache,mensagem_para_cache,estado_inicial,estado_final,barramento_entrada,barramento_saida);
	
	output reg [`tamanho_barramento:0] barramento_saida;
	output reg [1:0]estado_final;
	output reg [1:0]mensagem_para_cache
	
	input [`tamanho_barramento:0]barramento_entrada;
	input [1:0]estado_inicial;
	input [1:0]mensagem_da_cache;

	reg [`tamanho_barramento:0]buffer;
	reg [1:0]buffer_de_estado;
	reg [1:0]buffer_de_mensagem_para_cache;

	always begin
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
						buffer_de_estado = `EXCLUSIVO;
						buffer[65:64] = `COMPARTILHADORES;
					end
				end


			`COMPARTILHADO_DIRETORIO:
				begin
					if(mensagem_da_cache === `PERDA_DE_ESCRITA)begin
						buffer_de_estado = `EXCLUSIVO;
						buffer_de_mensagem_para_cache = `BUSCA_DE_DADOS;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `INCREMENTA_COMPARTILHADORES;
					end else if(mensagem_da_cache === `PERDA_DE_LEITURA )begin
						buffer_de_estado = `COMPARTILHADO_DIRETORIO;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `INCREMENTA_COMPARTILHADORES;
					end 
				end


			`EXCLUSIVO:
				begin
					if(mensagem_da_cache === `PERDA_DE_ESCRITA)begin
						buffer_de_estado = `EXCLUSIVO_DIRETORIO;
						buffer[66] = `RESPOSTA_DO_VALOR_DE_DADOS;
						buffer[65:64] = `COMPARTILHADORES
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
				end
			default:
				begin
					/* faz nada*/
					buffer[`modo_snooping]  = 1'b0;
					buffer[`modo_cpu]  = 1'b0;
					buffer[`modo_memoria]  = 1'b0;
					buffer[`modo_cache]   = 1'b0;
				end
		endcase
		estado_final = buffer_de_estado;
		barramento_saida = buffer;
	end
endmodule