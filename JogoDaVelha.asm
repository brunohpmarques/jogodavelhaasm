##################################################################
#	
#	Este código foi desenvolvido pelo alunos:
#	Bruno Marques
#	Carlos Ferraz
#	Jeremias Leite
#
#	Universidade Federal Rural de Pernambuco
#	Arquitetura e Organização de Computadores 2015.2
#
##############  MANUAL DE EXECUÇÃO  ##############
#
#	1. Simular o Bitmap Display nas configurações:
#		Pixel: 4x4
#		Resolução: 256x256
#		Endereço: 0x10000000 (global data)
#
#	2. Simular o Keyboard and Display MMIO
#	
#	3. Montar o código do arquivo "JogoDaVelha.asm"
#
#	4. Utilizar as teclas W, A, S, D para mover e Enter para
#		jogar 
#
##############  DICIONARIO DE REGISTRADORES USADOS  ##############
#
# -- CONSTANTES ---------------------------------------------------
#	$s0	Jogadas da maquina
#	$s1	Jogadas do usuario
#	$s2	Jogador atual (0 = maquina; 1 = usuario)
#	$s3	Ponteiro no inicio do vetor jogadas_possiveis
#	$s4	Tamanho do vetor jogadas_possiveis
#	$s5	Posicao atual do seletor da interface do usuario
#	$s6	Ponteiro para monitorar teclas
#	$s7	Posicao atual da jogada no display
#
##############  CASOS DE VITORIA OU EMPATE  ##############
#
# -- VITORIAS NA VERTICAL -----------------------------------------
# 1) 0x00008888		# 0b0000 0000 0000 0000 1000 1000 1000 1000
# 2) 0x00004444		# 0b0000 0000 0000 0000 0100 0100 0100 0100
# 3) 0x00002222		# 0b0000 0000 0000 0000 0010 0010 0010 0010
# 4) 0x00001111		# 0b0000 0000 0000 0000 0001 0001 0001 0001
# 
# -- VITORIAS NA HORIZONTAL ---------------------------------------
# 5) 0x0000F000		# 0b0000 0000 0000 0000 1111 0000 0000 0000
# 6) 0x00000F00		# 0b0000 0000 0000 0000 0000 1111 0000 0000
# 7) 0x000000F0		# 0b0000 0000 0000 0000 0000 0000 1111 0000
# 8) 0x0000000F		# 0b0000 0000 0000 0000 0000 0000 0000 1111
#
# -- VITORIAS NAS DIAGONAIS ---------------------------------------
# 9) 0x00008421		# 0b0000 0000 0000 0000 1000 0100 0010 0001
# 10) 0x00001248	# 0b0000 0000 0000 0000 0001 0010 0100 1000
#
# -- EMPATE -------------------------------------------------------
# 11) 0x0000FFFF	# 0b0000 0000 0000 0000 FFFF FFFF FFFF FFFF
#
##############  CORES USADAS  ##############
#
# corFundo: 	0x00004010
# corBranco: 	0x00FFFFFF
# corVerde: 	0x0000A600
# corVermelho:	0x00B20000
# corAmarelo:	0x00FFFF26
#
###################################################################

.data
jogadas_possiveis:	.space 64			# Vetor com jogadas possíveis (64 bytes = 16 palavras)
nivel:			.space 1			# Byte que guarda a dificuldade (1 bytes = 4 bits)
endereco_teclado: .word 0xFFFF0004			# Endereco da memoria para monitoramento de teclas 0xFFFF0004

bitmap_address:	.word 0x10000000
bitmap_size:	.word 4096				# 256x256 pixels a 4x4

.text
.include "interface.asm"				# Importa arquivo com codigo da interface do usuario
.include "inteligencia.asm"				# Importa arquivo com codigo da inteligencia da maquina
.globl main

# Procedimento para inicializar vetor de jogadas possiveis. Preenche as 16 casas com valores de 0 a 15
.macro inicia_vetor_jogadas_possiveis($ponteiro, $tamanho_vetor)
	move $a0, $ponteiro				# Define o ponteiro do vetor
	move $s4, $tamanho_vetor			# Define limite do laço
	li $a1, 0					# Inicia contador	
Loop:
	beq $a1, $s4, sair				# Desvia se chegou no fim do vetor
	sw $a1, 0($a0)					# Armazena posicoes possiveis no vetor
	addi $a1, $a1, 1				# Incrementa contador
	addi $a0, $a0, 4				# Incrementa ponteiro do vetor para a proxima palavra
	j Loop
sair:
.end_macro 

# Procedimento para remover do vetor o valor de uma jogada, passando como parametro um index do vetor
.macro remove_jogada_por_posicao($ponteiro, $tamanho_vetor, $posicao)
	move $t2, $posicao				
	sll $t0, $posicao, 2				# Ajusta o valor da posicao para saltar $posicao x 4 bytes
	add $a0, $ponteiro, $t0				# Posiciona ponteiro na posicao desejada
	subi $a1, $tamanho_vetor, 1			# Ajusta tamanho do vetor para o range 0-15
	
	lw $t3, ($a0)					# Guarda valor da jogada desejada
	beq $posicao, $a1, sair				# Se a posicao que sera removida for a ultima, entao salte para sair
							# Se nao, recua os proximos valores para preencher a vaga do anterior
	move $t0, $t2					# Inicia contador a partir da posicao desejada
	addi $a0, $a0, 4				# Avanca ponteiro do vetor para a proxima palavra
Loop:
	beq $t0, $a1, sair				# Desvia se chegou no fim do vetor
	lw $t1, ($a0)					# Guarda o valor na posicao $a0 do vetor
	subi $a0, $a0, 4				# Volta ponteiro do vetor
	sw $t1, ($a0)					# Substitui o valor da posicao anterior pelo valor da proxima posicao
	addi $a0, $a0, 8				# Avanca duas palavras do vetor
	addi $t0, $t0, 1				# Incrementa contador
	j Loop
sair:	
	subi $a0, $a0, 4				# Volta ponteiro do vetor em uma casa
	sw $zero, ($a0)					# Substitui com 0 o último valor do vetor
	subi $tamanho_vetor, $tamanho_vetor, 1		# Retorna posicao da jogada em $t3
.end_macro

# Procedimento para remover do vetor o valor de uma jogada, passando como parametro um valor entre 0-15
.macro remove_jogada_por_valor($ponteiro, $tamanho_vetor, $valor)
	move $t2, $valor				# Guarda o valor a ser removido
	subi $a1, $tamanho_vetor, 1			# Seta limite do vetor entre 0 a 15
	move $a0, $ponteiro				# Seta ponteiro do vetor
	li $t0, 0					# Seta contador
Loop1:							# LOOP1: percorre o vetor procurando o valor passado como parametro
	lw $t3, ($a0)					# Guarda valor da jogada
	beq $t3, $t2, proximo				# Verifica se eh o valor desejado
	addi $t0, $t0, 1				# Incrementa contador
	addi $a0, $a0, 4				# Proxima posicao do vetor
	j Loop1
proximo:			
	addi $a0, $a0, 4				# Avanca ponteiro do vetor para a proxima palavra
Loop2:							# LOOP2: percorre o vetor, de onde parou, substituindo o valor atual pelo proximo
	beq $t0, $a1, sair				# Desvia se chegou no fim do vetor
	lw $t1, ($a0)					# Guarda o valor na posicao $a0 do vetor
	subi $a0, $a0, 4				# Volta ponteiro do vetor
	sw $t1, ($a0)					# Substitui o valor da posicao anterior pelo valor da proxima posicao
	addi $a0, $a0, 8				# Avanca duas palavras do vetor
	addi $t0, $t0, 1				# Incrementa contador
	j Loop2
sair:	
	subi $a0, $a0, 4				# Volta ponteiro do vetor em uma casa
	sw $zero, ($a0)					# Substitui com 0 o último valor do vetor
	subi $tamanho_vetor, $tamanho_vetor, 1		# Retorna posicao da jogada em $t3
.end_macro

# Procedimento para ler do teclado DURANTE o jogo (A=esquerda, W=cima, S=baixo, D=direita)
.macro ler_teclado($memoria_teclado)			
inicio:
	li $t0, 0
	#sw $t0, 0xFFFF0000				# Zera tecla no simulador (Deve fazer isto pois a primeira tecla que fosse pressionada, iria ficar pra sempre ativa)
	seletorModura($s5)				# Pinta moldura na tela para destacar a posicao onde o usuario quer jogar
Loop:							
	#pausar(100)					# Pausa para evitar travadas
	
	lw $t0, 0xFFFF0000				# Carrega valor do simulador para saber se a telca foi pressionada
	beq $t0, 1, case				# Verifica se a tecla foi pressionada
	j Loop	
case:
	lw $t0, ($memoria_teclado)			# Guarda o valor da tecla pressionada
	beq $t0, 0x0000000A, lblTeclaEnter		# Desvia se o usuario apertou ENTER (0x0000000A)
	beq $t0, 0x00000077, lblTeclaW			# Desvia se o usuario apertou W (0x00000077)
	beq $t0, 0x00000073, lblTeclaS			# Desvia se o usuario apertou S (0x00000073)
	beq $t0, 0x00000061, lblTeclaA			# Desvia se o usuario apertou A (0x00000061)
	beq $t0, 0x00000064, lblTeclaD			# Desvia se o usuario apertou D (0x00000064)
	j Loop
lblTeclaW:
	addi $s5, $s5, 4				# Move para cima
	bge $s5, 16 subtraiQuatroDeVolta		# Em caso de overflow de posicao, subtrai 4 de volta
	j inicio
lblTeclaS:
	subi $s5, $s5, 4				# Move para baixo
	ble $s5, -1, somaQuatroDeVolta			# Em caso de underflow de posicao, some 4 de volta
	j inicio
lblTeclaA:
	addi $s5, $s5, 1				# Move para esquerda
	bge $s5, 16 subtraiUmDeVolta			# Em caso de overflow de posicao, subtrai 1 de volta
	j inicio
lblTeclaD:
	subi $s5, $s5, 1				# Move para direita
	ble $s5, -1, somaUmDeVolta			# Em caso de underflow de posicao, some 1 de volta
	j inicio
subtraiQuatroDeVolta:
	subi $s5, $s5, 4
	j inicio
somaQuatroDeVolta:
	addi $s5, $s5, 4
	j inicio
subtraiUmDeVolta:
	subi $s5, $s5, 1
	j inicio
somaUmDeVolta:
	addi $s5, $s5, 1
	j inicio	
lblTeclaEnter:
	converte_posicao($s5)				# Retorna em $a0 a posicao representativa
	move $a3, $a0					# Guarda em $a3 a posicao representativa
	confere_jogada($a0)				# Confere se ja jogaram na posicao desejada
	bnez $a0, inicio				# Se ja jogaram nessa posicao, volte para ler do teclado
	j sair
sair:
.end_macro 

# Procedimento para ler do teclado na tela inicial (A=esquerda, W=direita, S=esquerda, D=direita)
.macro ler_tecladoInicio($memoria_teclado)
inicio:
	li $t0, 0
	#sw $t0, 0xFFFF0000				# Zera tecla no simulador (Deve fazer isto pois a primeira tecla que fosse pressionada, iria ficar pra sempre ativa)
	selecaoJogador($s5)				# Pinta moldura na tela para destacar a posicao onde o usuario quer jogar
Loop:
	#pausar(100)					# Pausa para evitar travadas
	
	lw $t0, 0xFFFF0000				# Carrega valor do simulador para saber se a telca foi pressionada
	beq $t0, 1, case				# Verifica se a tecla foi pressionada
	j Loop	
case:
	lw $t0, ($memoria_teclado)			# Guarda o valor da tecla pressionada
	beq $t0, 0x0000000A, lblTeclaEnter		# Desvia se o usuario apertou ENTER (0x0000000A)
	beq $t0, 0x00000077, lblTeclaD			# Desvia se o usuario apertou W (0x00000077)
	beq $t0, 0x00000073, lblTeclaA			# Desvia se o usuario apertou S (0x00000073)
	beq $t0, 0x00000061, lblTeclaA			# Desvia se o usuario apertou A (0x00000061)
	beq $t0, 0x00000064, lblTeclaD			# Desvia se o usuario apertou D (0x00000064)
	j Loop
	
lblTeclaA:
	subi $s5, $s5, 1
	ble $s5, -1 somaUmDeVolta			# Em caso de underflow de posicao, subtrai 1 de volta
	j inicio
lblTeclaD:
	addi $s5, $s5, 1
	bge $s5, 2, subtraiUmDeVolta			# Em caso de overflow de posicao, some 1 de volta
	j inicio
subtraiUmDeVolta:
	subi $s5, $s5, 1
	j inicio
somaUmDeVolta:
	addi $s5, $s5, 1
	j inicio	
lblTeclaEnter:
	move $a0, $s5					# Retorna em $a0 o jogador escolhido
.end_macro

# Procedimento para pausar tela por milessegundos %time
.macro pausar(%time)
	ori $v0, $zero, 32				# Seta parametro do syscall
	ori $a0, $zero, %time				# %time milessegundos
	syscall						# Executa chamando syscall
.end_macro

# USASDO PRA FACILITAR OS TESTES. LEMBRAR DE REMOVER.
# Procedimento para imprimir o inteiro
.macro print_int($int)
	li $v0, 1
	move $a0, $int
	syscall
.end_macro
 
main:							# Corpo do jogo
	move $s7, $zero					# Zera posicao atual da jogada no display
	la $s3, jogadas_possiveis			# Guarda ponteiro do vetor de jogadas possiveis
	li $s4, 16					# Define o tamanho do vetor de jogadas possiveis com 16 (de 0 a 15)
	sll $t0, $s4, 2					# Calcula quantidade de bytes do vetor de jogadas 16 x 4 bytes
	sub $s3, $s3, $t0				# Recua ponteiro do vetor de jogadas possiveis para a primeira posicao
	inicia_vetor_jogadas_possiveis($s3, $s4)	# Guarda todas as jogadas possiveis no vetor
	li $s0, 0					# Seta mascara de jogadas da maquina para 0
	li $s1, 0					# Seta mascara de jogadas do usuario para 0
	li $s6, 0xFFFF0004				# Carrega endereco da memoria onde sera monitorado o teclado
	
dificuldade:	
	li $s5, 0					# Seta posicicao do seletor na primeira posicao da tela inicial (level)
	pintarTudo(0x00004010)				# Pinta tudo de verde escuro
	pintarLevel()					# Pinta tela Level
	ler_tecladoInicio($s6)				# Seleciona dificuldade do jogo (0 = facil; 1 = dificil)
	beqz $a0, facil					# Verifica nivel escolhido
	j dificil
facil:
	li $a0, 0
	la $t8, nivel
	sb $a0, ($t8)					# Salva nivel facil na memoria (facil = 0)
	j ordemJogada

dificil:
	li $a0, 1
	la $t8, nivel
	sb $a0, ($t8)					# Salva nivel dificil na memoria (dificil = 1)
	
ordemJogada:
	li $s5, 0					# Seta posicicao do seletor na primeira posicao da tela inicial (player)
	pintarTudo(0x00004010)				# Pinta tudo de verde escuro
	telaInicial()					# Pinta tela inicial (Player)
	ler_tecladoInicio($s6)				# Seleciona ordem de jogada do usuario (0 = desvia pra vez usuario; 1 = vez maquina)
	
	pintarTudo(0x00004010)				# Pinta tudo de verde escuro
	criarMatriz()					# Pinta tabuleiro
	li $s5, 15					# Seta posicao do seletor na primeira posicao do tabuleiro
	
	beqz $a0, vez_usuario				# Verifica quem comeca a jogar
	
vez_maquina:
	li $s2, 0					# Seta o jogador atual para 0 (maquina)
	la $t8, nivel
	lb $v1, ($t8)					# Carrega nivel do jogo
	beqz $v1, sortear				# Se for facil (0) desvie para sortear jogadas, se nao pense numa jogada
	pensar_jogada_maquina()				# Pensa numa jogada pra ganhar ou nao perder
	beqz $a0, jogar					# Se conseguiu pensar numa jogada, jogue
							# Se nao, sorteie uma jogada
sortear:
	sorteia_int($s4)				# Sorteia um index do vetor de jogadas
	remove_jogada_por_posicao($s3, $s4, $a0)	# Guarda o valor sorteado e remove ele das jogadas possiveis
	converte_posicao($t3)				# Converte posicao sorteada para mascara
	confere_jogada($a0)				# Confere se a maquina ganhou utilizando a mascara
	beqz $a0, registrar_jogada_maquina		# Se nao jogaram nessa posicao ($a0 = 0), entao registre a jogada
	j vez_maquina					# Se nao, sorteie outro valor ($a0 = 1)

jogar:
	print_int($t3)					# Apenas adicionado para mostrar a posição que a máquina pensou em jogar				
	remove_jogada_por_valor($s3, $s4, $t3)		# Guarda o valor sorteado e remove ele das jogadas possiveis
	converte_posicao($t3)				# Converte posicao sorteada (int) para mascara (representacao em bin)
	confere_jogada($a0)				# Confere se alguem ja jogou nessa posicao
	beqz $a0, registrar_jogada_maquina		# Se nao jogaram nessa posicao ($a0 = 0), entao registre a jogada
	j vez_maquina					# Se nao, pense ou sorteie de novo

registrar_jogada_maquina:			
	addi	$t5, $zero, 0x00B20000 			# $t5 recebe vermelho
	seletor($t3, $t5)				# Marca no display a jogada
	
	or $s0, $s0, $a1				# Mescla mascara da jogada atual com todas as jogadas da maquina
	confere_vencedor($s2)				# Confere se a maquina ganhou (0 = nao, 1 = sim)
	beq $a0, 1, maquinaVenceu			# Desvia se a maquina ganhou ($a0 = 1)
	beq $a0, -1, empatou				# Desvia se o jogo empatou ($a0 = -1)
	j vez_usuario					# Salta para a vez do usuario se a maquina nao ganhou ($a0 = 0)
	
vez_usuario:
	li $s2, 1					# Seta o jogador atual para 1 (usuario)
	ler_teclado($s6)				# Monitora teclado para as letras A(esquerda), W(cima), S(baixo) e D(direita)
	remove_jogada_por_valor($s3, $s4, $s5)		# Remove jogada do vetor de jogadas possiveis
	j registrar_jogada_usuario
	
registrar_jogada_usuario:
	addi	$t5, $zero, 0x0000A600 			# $t5 recebe verde claro
	seletor($s5, $t5)				# Marca no display a jogada do usuario
	
	or $s1, $s1, $a3				# Mescla mascara da jogada do usuario 
	confere_vencedor($s2)				# Confere se o usuario ganhou (0 = nao, 1 = sim)
	beq $a0, 1, usuarioVenceu			# Desvia se o usuario ganhou ($a0 = 1)
	beq $a0, -1, empatou				# Desvia se o jogo empatou ($a0 = -1)
	j vez_maquina					# Salta para vez da maquina se o usuario nao ganhou ou o nao empatou
	
maquinaVenceu:
	pausar(2000)					# Pausa 2 segundos para mostrar resultado
	pintarTudo(0x00B20000)  			# Pinta tudo de vermelho
	j fim
usuarioVenceu:
	pausar(2000)					# Pausa 2 segundos para mostrar resultado
	pintarTudo(0x0000A600)  			# Pinta tudo de verde claro
	j fim
empatou:
	pausar(2000)					# Pausa 2 segundos para mostrar resultado
	pintarTudo(0x00FFFF26)  			# Pinta tudo de amarelo
	j fim
fim:	
	pausar(750)					# Pausa para efeito de transicao
	j main						# Comeca nova partida
