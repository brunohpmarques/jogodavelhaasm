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
##############  INFORMAÇÕES DO DISPLAY  ########################
# 							       #		
# endereÃ§o base do display: 		0x10000000(global data)#
# Dimenções do display:			256 x 256 pixel	       #  
# unidade de pixel:			4 x 4 pixel	       #								
# corFundo: 				0x00004010             #
# corBranco: 				0x00FFFFFF             #
# corVerde: 				0x0000A600             #
# corVermelho:				0x00B20000             #
# corAmarelo:				0x00FFFF26             #
#							       #	
################################################################
.macro setPixel($x, $y, $cor)		#procedimento para setar um pixel no display onde $x é coluna e $y é a linha 
	sll	$t4, $y, 6		#multiplica o $y por 64 e setar em $t4 para percorrer as linhas
	addu	$t4, $t4, $x		#adiciona em $t4 a soma de $t4 com $x
	sll	$t4, $t4, 2		# multiplica por 4 para setar na memoria  
	addi	$t4, $t4, 0x10000000	# soma o $t4 com o endereÃ§o do primeiro pixel
	sw	$cor, 0($t4)		# grava a $cor em $t4
.end_macro

.macro linhaH(%x, $y, %n, $cor)		#procedimento para criar linha horizontal a partir de uma posição %x é a coluna e $y é a linhan %n é o número de pixel
	addi	$t6, $zero, %x		#$t6 recebe o valor passado a %x	
	addi	$t8, $t6, %n		#$t8 recebe o valor da soma de $t6 com %n, neste caso $t8 terá o valor da soma da posição da coluna  com o número de pixel
loop:	beq	$t6, $t8, sair		#esse loop pinta n pixel na horizontal a partir de apartir de uma posição(x,y), enquanto $t6 for igual a $t8 então sai do loop  
	setPixel($t6, $y, $cor)		#setPixel é chamada para para pintar os pixel, neste caso só o eixo x(coluna) é incrementado em 1 para pintar o próximo pixel
	addi	$t6, $t6, 1		#incrementa $t6 em 1 até ser igual $t8
	j	loop			#dá um salta para loop
sair:
.end_macro

.macro linhaV(%x, $y, %n, $cor)		#procedimento para criar linha vertical a partir de uma posição %x é a coluna e $y é a linhan %n é o número de pixel
	addi	$t6, $zero, %x		#$t6 recebe o valor passado a %x
	addi	$t8, $y, %n		#$t8 recebe o valor da soma de $y com %n, neste caso $t8 terá o valor da soma da posição da linha com o número de pixel
loop:	beq	$y, $t8, sair		#esse loop pinta n pixel na vertical a partir de apartir de uma posição(x,y), enquanto $y for igual a $t8 então sai do loop  
	setPixel($t6, $y, $cor)		#setPixel é chamada para para pintar os pixel, neste caso só o eixo y(linha) é incrementado em 1 para pintar o próximo pixel
	addi	$y, $y, 1		#incrementa $y em 1 até ser igual $ty
	j	loop			#dá um salta para loop
sair:
.end_macro

.macro pintarTudo(%cor)			#procedimento para preencher todo o display com uma cor
	addi	$t5, $zero, %cor	#$t5 recebe um cor passado em %cor
	move	$t6, $zero 		#$t6 recebe zero prara iniciar o contado
loop:	beq	$t6, 4096, sair		#Desvia para sair se o contador($t6) for igual a 4096(numero total de pixel 256/4 x 256/4 ) 
	sll	$t4, $t6, 2		#multiplica $t6 por 4 para saltar de uma posição de mémoria para outra 
	addi	$t4, $t4, 0x10000000	#somar o valor do endereço da primeira posição do pixel ao $t4
	sw	$t5, 0($t4)		#grava na posição passada em $t4 a cor guardada em $t5
	addi	$t6, $t6, 1		#incrementa $t6 em 1
	j	loop			
sair:				
.end_macro

.macro criarMatriz()			#procedimento para criar as três linhas horizontal e as três vertical do tabuleiro
	addi	$t5, $zero, 0x00FFFFFF	#seta em $t5 a cor branca
	addi	$t7, $zero, 0		
	linhaV(15, $t7, 64, $t5)	#cria a primeira linha vertical	
	addi	$t7, $zero, 0
	linhaV(31, $t7, 64, $t5)	#cria a segunda linha vertical
	addi	$t7, $zero, 0
	linhaV(47, $t7, 64, $t5)	#cria a terceira linha vertical
	addi	$t7, $zero, 15
	linhaH(0, $t7, 64, $t5)		#cria a primeira linha horizontal
	addi	$t7, $zero, 31
	linhaH(0, $t7, 64, $t5)		#cria a segunda linha horizontal
	addi	$t7, $zero, 47
	linhaH(0, $t7, 64, $t5)		#cria a terceira linha horizontal
.end_macro

.macro quadrado(%x, %y, $cor)		#procedimento para criar o quadrado 8x8 pixel para as jogadas onde %x é a coluna %y a linha
	addi	$t7, $zero, %y		#seta em $t7 que é um contador o valor de %y
	addi	$t9, $t7, 8		#seta em $t9 o valor do produto de $t7 por 256 que o número de pixel por linha
loop:	beq	$t9, $t7, exit		#se $t9 for igual a $t7 encerra o loop
	linhaH(%x, $t7, 8, $cor)	#chama a função linhaH e cria várias linhas como o mesmo número de pixel só alterando o valor de linha
	addi	$t7, $t7, 1		#incrementa em 1 $t7
	j	loop
exit:	
.end_macro

.macro quadradoEmpate()			# procedimento para criar um quadrado com uma letra "E" no final de um jogo com resultado de empate
	addi	$t7, $zero, 16		#contador iniciando na posição 16
	addi	$t9, $zero, 0x00000000	#seta em $t9 a cor preta
loop:	beq	$t7, 47, exit		#se $t7 for igual a 47 que é o número de necessário para percorre 31 loop
	linhaH(16, $t7, 31, $t9)	#chama o procedimento linhaH para criar 31 linhas horizotais
	addi	$t7, $t7, 1		#incrementa em 1
	j	loop
exit:	
	addi	$t9, $zero, 0x00FFFF26	#desta linha até o final do macro desenha a letra "E"
	addi	$t7, $zero, 19
	linhaH(19, $t7, 25, $t9)	#cria uma linha horizontal na posição x=19 e y=19 com comprimento de 25 pixel 
	addi	$t7, $zero, 43
	linhaH(19, $t7, 25, $t9)	#cria uma linha horizontal na posição x=19 e y=43 com comprimento de 25 pixel 
	addi	$t7, $zero, 31
	linhaH(19, $t7, 13, $t9)	#cria uma linha horizontal na posição x=19 e y=31 com comprimento de 13 pixel 
	addi	$t7, $zero, 19
	linhaV(19, $t7, 25, $t9)	#cria uma linha vertical na posição x=19 e y=19 com comprimento de 25 pixel 	
.end_macro			

.macro seletor($p,$cor)			# procedimento para pintar um quadrado da jogada em uma das 16 posições do tabuleiro   
	beq	$p, 0, case15		#se posição for igual a 0 salta para case 15
	beq   	$p, 1, case14		#se posição for igual a 1 salta para case 14
	beq  	$p, 2, case13		#se posição for igual a 2 salta para case 13
	beq   	$p, 3, case12		#se posição for igual a 3 salta para case 12
	beq   	$p, 4, case11		#se posição for igual a 4 salta para case 11
	beq   	$p, 5, case10		#se posição for igual a 5 salta para case 10
	beq   	$p, 6, case9		#se posição for igual a 6 salta para case 9
	beq   	$p, 7, case8		#se posição for igual a 7 salta para case 8
	beq   	$p, 8, case7		#se posição for igual a 8 salta para case 7
	beq   	$p, 9, case6		#se posição for igual a 9 salta para case 6
	beq   	$p, 10, case5		#se posição for igual a 10 salta para case 5
	beq   	$p, 11, case4		#se posição for igual a 11 salta para case 4
	beq   	$p, 12, case3		#se posição for igual a 12 salta para case 3
	beq   	$p, 13, case2		#se posição for igual a 13 salta para case 2
	beq   	$p, 14, case1		#se posição for igual a 14 salta para case 1
	beq   	$p, 15, case0		#se posição for igual a 15 salta para case 0

case0:	quadrado(4, 4, $cor)	# pintar quadrado na posição 0
	j sair
case1:	quadrado(20, 4, $cor)	# pintar quadrado na posição 1
	j sair
case2:	quadrado(36, 4, $cor)	# pintar quadrado na posição 2
	j sair
case3:	quadrado(52, 4, $cor)	# pintar quadrado na posição 3
	j sair
case4:	quadrado(4, 20, $cor)	# pintar quadrado na posição 4
	j sair
case5:	quadrado(20, 20, $cor)	# pintar quadrado na posição 5
	j sair
case6:	quadrado(36, 20, $cor)	# pintar quadrado na posição 6
	j sair
case7:	quadrado(52, 20, $cor)	# pintar quadrado na posição 7
	j sair
case8:	quadrado(4, 36, $cor)	# pintar quadrado na posição 8
	j sair
case9:	quadrado(20, 36, $cor)	# pintar quadrado na posição 9
	j sair
case10:	quadrado(36, 36, $cor)	# pintar quadrado na posição 10
	j sair
case11:	quadrado(52, 36, $cor)	# pintar quadrado na posição 11
	j sair
case12:	quadrado(4, 52, $cor)	# pintar quadrado na posição 12
	j sair
case13:	quadrado(20, 52, $cor)	# pintar quadrado na posição 13
	j sair
case14:	quadrado(36, 52, $cor)	# pintar quadrado na posição 14
	j sair
case15:	quadrado(52, 52, $cor)	# pintar quadrado na posição 15
		
sair:
.end_macro

.macro modura($p, $cor)			# procedimento para criar uma modura para selecao da posição no tabuleiro onde $p é uma das 16 posições	
	beq	$p, 0, case15		#se posição for igual a 0 salta para case 15
	beq   	$p, 1, case14		#se posição for igual a 1 salta para case 14
	beq  	$p, 2, case13		#se posição for igual a 2 salta para case 13
	beq   	$p, 3, case12		#se posição for igual a 3 salta para case 12
	beq   	$p, 4, case11		#se posição for igual a 4 salta para case 11
	beq   	$p, 5, case10		#se posição for igual a 5 salta para case 10
	beq   	$p, 6, case9		#se posição for igual a 6 salta para case 9
	beq   	$p, 7, case8		#se posição for igual a 7 salta para case 8
	beq   	$p, 8, case7		#se posição for igual a 8 salta para case 7
	beq   	$p, 9, case6		#se posição for igual a 9 salta para case 6
	beq   	$p, 10, case5		#se posição for igual a 10 salta para case 5
	beq   	$p, 11, case4		#se posição for igual a 11 salta para case 4
	beq   	$p, 12, case3		#se posição for igual a 12 salta para case 3
	beq   	$p, 13, case2		#se posição for igual a 13 salta para case 2
	beq   	$p, 14, case1		#se posição for igual a 14 salta para case 1
	beq   	$p, 15, case0		#se posição for igual a 15 salta para case 0
		
case0:	add	$t7, $zero, 3		# pintar modura na posição 0
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=3 com comprimento de 10 pixel
	add	$t7, $zero, 4
	linhaV(3, $t7, 8, $cor)		#cria uma linha vertical na posição x=3 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 4
	linhaV(12, $t7, 8, $cor)	#cria uma linha vertical na posição x=12 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 12
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=12 com comprimento de 10 pixel
	j	sair

case1:	add	$t7, $zero, 3		# pintar modura na posição 1
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=3 com comprimento de 10 pixel
	add	$t7, $zero, 4
	linhaV(19, $t7, 8, $cor)	#cria uma linha vertical na posição x=19 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 4
	linhaV(28, $t7, 8, $cor)	#cria uma linha vertical na posição x=28 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 12
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=12 com comprimento de 10 pixel
	j	sair
	
case2:	add	$t7, $zero, 3		# pintar modura na posição 2
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=3 com comprimento de 10 pixel
	add	$t7, $zero, 4		
	linhaV(35, $t7, 8, $cor)	#cria uma linha vertical na posição x=35 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 4
	linhaV(44, $t7, 8, $cor)	#cria uma linha vertical na posição x=44 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 12
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=12 com comprimento de 10 pixel
	j	sair
	
case3:	add	$t7, $zero, 3		# pintar modura na posição 3
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=3 com comprimento de 10 pixel
	add	$t7, $zero, 4
	linhaV(51, $t7, 8, $cor)	#cria uma linha vertical na posição x=51 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 4
	linhaV(60, $t7, 8, $cor)	#cria uma linha vertical na posição x=60 e y=4 com comprimento de 8 pixel
	add	$t7, $zero, 12
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=12 com comprimento de 10 pixel
	j	sair

case4:	add	$t7, $zero, 19		# pintar modura na posição 4
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=19 com comprimento de 10 pixel
	add	$t7, $zero, 20		
	linhaV(3, $t7, 8, $cor)		#cria uma linha vertical na posição x=3 e y=19 com comprimento de 8 pixel
	add	$t7, $zero, 20
	linhaV(12, $t7, 8, $cor)	#cria uma linha vertical na posição x=12 e y=19 com comprimento de 8 pixel
	add	$t7, $zero, 28
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=19 com comprimento de 10 pixel
	j	sair
case5:	add	$t7, $zero, 19		# pintar modura na posição 5
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=19 com comprimento de 10 pixel
	add	$t7, $zero, 20
	linhaV(19, $t7, 8, $cor)	#cria uma linha vertical na posição x=19 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 20
	linhaV(28, $t7, 8, $cor)	#cria uma linha vertical na posição x=28 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 28
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=28 com comprimento de 10 pixel
	j	sair
case6:	add	$t7, $zero, 19		# pintar modura na posição 6
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=19 com comprimento de 10 pixel
	add	$t7, $zero, 20
	linhaV(35, $t7, 8, $cor)	#cria uma linha vertical na posição x=35 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 20
	linhaV(44, $t7, 8, $cor)	#cria uma linha vertical na posição x=44 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 28
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=28 com comprimento de 10 pixel
	j	sair
case7:	add	$t7, $zero, 19		# pintar modura na posição 7
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=19 com comprimento de 10 pixel
	add	$t7, $zero, 20		
	linhaV(51, $t7, 8, $cor)	#cria uma linha vertical na posição x=51 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 20
	linhaV(60, $t7, 8, $cor)	#cria uma linha vertical na posição x=60 e y=20 com comprimento de 8 pixel
	add	$t7, $zero, 28
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=28 com comprimento de 10 pixel
	j	sair
case8:	add	$t7, $zero, 35		# pintar modura na posição 8
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=35 com comprimento de 10 pixel
	add	$t7, $zero, 36
	linhaV(3, $t7, 8, $cor)		#cria uma linha vertical na posição x=3 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 36
	linhaV(12, $t7, 8, $cor)	#cria uma linha vertical na posição x=12 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 44
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=44 com comprimento de 10 pixel
	j	sair
case9:	add	$t7, $zero, 35		# pintar modura na posição 9
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=35 com comprimento de 10 pixel
	add	$t7, $zero, 36
	linhaV(19, $t7, 8, $cor)	#cria uma linha vertical na posição x=19 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 36
	linhaV(28, $t7, 8, $cor)	#cria uma linha vertical na posição x=19 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 44
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=44 com comprimento de 10 pixel
	j	sair
case10:	add	$t7, $zero, 35		# pintar modura na posição 10
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=35 com comprimento de 10 pixel
	add	$t7, $zero, 36
	linhaV(35, $t7, 8, $cor)	#cria uma linha vertical na posição x=35 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 36
	linhaV(44, $t7, 8, $cor)	#cria uma linha vertical na posição x=44 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 44
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=44 com comprimento de 10 pixel
	j	sair
case11:add	$t7, $zero, 35		# pintar modura na posição 11
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=35 com comprimento de 10 pixel
	add	$t7, $zero, 36		
	linhaV(51, $t7, 8, $cor)	#cria uma linha vertical na posição x=51 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 36
	linhaV(60, $t7, 8, $cor)	#cria uma linha vertical na posição x=60 e y=36 com comprimento de 8 pixel
	add	$t7, $zero, 44
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=44 com comprimento de 10 pixel
	j	sair
case12:	add	$t7, $zero, 51		# pintar modura na posição 12
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=51 com comprimento de 10 pixel
	add	$t7, $zero, 52
	linhaV(3, $t7, 8, $cor)		#cria uma linha vertical na posição x=3 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 52
	linhaV(12, $t7, 8, $cor)	#cria uma linha vertical na posição x=12 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 60
	linhaH(3, $t7, 10, $cor)	#cria uma linha horizontal na posição x=3 e y=60 com comprimento de 10 pixel
	j	sair
case13:	add	$t7, $zero, 51		# pintar modura na posição 13
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=51 com comprimento de 10 pixel
	add	$t7, $zero, 52
	linhaV(19, $t7, 8, $cor)	#cria uma linha vertical na posição x=19 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 52
	linhaV(28, $t7, 8, $cor)	#cria uma linha vertical na posição x=28 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 60
	linhaH(19, $t7, 10, $cor)	#cria uma linha horizontal na posição x=19 e y=60 com comprimento de 10 pixel
	j	sair
case14:	add	$t7, $zero, 51		# pintar modura na posição 14
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=51 com comprimento de 10 pixel
	add	$t7, $zero, 52
	linhaV(35, $t7, 8, $cor)	#cria uma linha vertical na posição x=35 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 52
	linhaV(44, $t7, 8, $cor)	#cria uma linha vertical na posição x=44 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 60
	linhaH(35, $t7, 10, $cor)	#cria uma linha horizontal na posição x=35 e y=60 com comprimento de 10 pixel
	j	sair
case15:	add	$t7, $zero, 51		# pintar modura na posição 15
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=51 com comprimento de 10 pixel
	add	$t7, $zero, 52
	linhaV(51, $t7, 8, $cor)	#cria uma linha vertical na posição x=51 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 52
	linhaV(60, $t7, 8, $cor)	#cria uma linha vertical na posição x=60 e y=52 com comprimento de 8 pixel
	add	$t7, $zero, 60
	linhaH(51, $t7, 10, $cor)	#cria uma linha horizontal na posição x=51 e y=60 com comprimento de 10 pixel
	
sair:
.end_macro

.macro seletorModura($p)		# procedimento para criar uma modura para selecao da posição no tabuleiro onde $p é uma das 16 posições	mas repintado a posição anterior com a cor do fundo
	addi	$t9, $zero, 0x00004010	#cor de fundo
	modura($s7, $t9)		#pinta a modura anterior
	
	addi	$t5, $zero, 0x00FFFF26	#cor amarela
	modura($p, $t5)			#pinta a modura atual
	
	move	$s7, $p			#o $s7 recebe o a ultima posição da modura para a mesma ser repintada na cor do fundo	
.end_macro

.macro seletorModura2($p)		# procedimento para criar uma modura para selecao da posição no tabuleiro onde $p é uma das 16 posições na cor amarela
	addi	$t5, $zero, 0x00FFFF26	#cor amarela
	modura($p, $t5)			#pinta a modura atual
.end_macro

.macro resultado($p)			# procedimento para selecionar com uma modura amarela as posições que forma uma vitória 
	addi	$t9, $zero, 0x00004010	#cor de fundo
	modura($s7, $t9)		#pinta a modura anterior pra apagar a selecao
	
	beq	$p, 0x00008421, diagonalP	#caso a posição passa em $p seja igual padrão de vitória 0x00008421 então ele imprimi uma diagonal primária
	beq	$p, 0x00001248, diagonalS	#caso a posição passa em $p seja igual padrão de vitória 0x00001248 então ele imprimi uma diagonal secundária
	beq	$p, 0X00008888, linhaV0		#caso a posição passa em $p seja igual padrão de vitória 0X00008888 então ele imprimi uma linha vertical na coluna 0
	beq	$p, 0X00004444, linhaV1		#caso a posição passa em $p seja igual padrão de vitória 0X00004444 então ele imprimi uma linha vertical na coluna 1
	beq	$p, 0X00002222, linhaV2		#caso a posição passa em $p seja igual padrão de vitória 0X00002222 então ele imprimi uma linha vertical na coluna 2
	beq	$p, 0X00001111, linhaV3		#caso a posição passa em $p seja igual padrão de vitória 0X00001111 então ele imprimi uma linha vertical na coluna 3
	beq	$p, 0X0000F000, linhaH0		#caso a posição passa em $p seja igual padrão de vitória 0X0000F000 então ele imprimi uma linha horizontal na linha 0
	beq	$p, 0X00000F00, linhaH1		#caso a posição passa em $p seja igual padrão de vitória 0X00000F00 então ele imprimi uma linha horizontal na linha 1
	beq	$p, 0X000000F0, linhaH2		#caso a posição passa em $p seja igual padrão de vitória 0X000000F0 então ele imprimi uma linha horizontal na linha 2
	beq	$p, 0X0000000F, linhaH3		#caso a posição passa em $p seja igual padrão de vitória 0X0000000F então ele imprimi uma linha horizontal na linha 3
	beq	$p, 0x0000FFFF, empate		#caso a posição passa em $p seja igual padrão de vitória 0x0000FFFF então ele imprimi um quadrado preto com a lentra "E"
	
	
diagonalP:	addi	$t9, $zero, 15	# vitória na diagonal primária
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 10
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 5
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 0
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
diagonalS:	addi	$t9, $zero, 12	# vitória na diagonal secundária
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 9
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 6
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 3
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaV0:	addi	$t9, $zero, 15	# vitória na coluna 0
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 11
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 7
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 3
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaV1:	addi	$t9, $zero, 14	# vitória na coluna 1
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 10	
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 6
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 2
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaV2:	addi	$t9, $zero, 13 	# vitória na coluna 2
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 9
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 5
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 1
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaV3:	addi	$t9, $zero, 12	# vitória na coluna 3
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 8
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 4
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 0
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaH0:	addi	$t9, $zero, 15	#vitória na linha 0
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 14
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 13
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 12
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaH1:	addi	$t9, $zero, 11	#vitória na linha 1
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 10
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 9
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 8
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9	
		j	sair
linhaH2:	addi	$t9, $zero, 7	#vitória na linha 2
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 6
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 5
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 4
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		j	sair
linhaH3:	addi	$t9, $zero, 3	#vitória na linha 3
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 2
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 1
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9
		addi	$t9, $zero, 0
		seletorModura2($t9)	#pinta uma moldura na posição armazenada em $t9	
		j	sair
empate:		quadradoEmpate()	#caso ocorra o empate é chamada o procedimento quadradoEmpate que pinta um quadrado com uma letra "E"
sair:	
.end_macro

.macro telaInicial()			# procedimento para pintar a tela inicial com o texto player e numero 1 e 2
	
	addi	$t9, $zero, 0x00FFFFFF	#seta a cor branca em $t9	
	#Letra p
	addi	$t7, $zero, 17
	linhaH(9, $t7, 6, $t9)		#cria uma linha horizontal na posição x=9 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(9, $t7, 6, $t9)		#cria uma linha horizontal na posição x=9 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(9, $t7, 10, $t9)		#cria uma linha vertical na posição x=9 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 18
	linhaV(14, $t7, 3, $t9)		#cria uma linha vertical na posição x=14 e y=18 com comprimento de 3 pixel
	#Letra L
	addi	$t7, $zero, 26
	linhaH(17, $t7, 6, $t9)		#cria uma linha horizontal na posição x=17 e y=26 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(17, $t7, 10, $t9)	#cria uma linha vertical na posição x=17 e y=17 com comprimento de 10 pixel
	#Letra A
	addi	$t7, $zero, 17
	linhaH(25, $t7, 6, $t9)		#cria uma linha horizontal na posição x=25 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(25, $t7, 6, $t9)		#cria uma linha horizontal na posição x=25 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(25, $t7, 10, $t9)	#cria uma linha vertical na posição x=25 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 18
	linhaV(30, $t7, 9, $t9)		#cria uma linha vertical na posição x=30 e y=18 com comprimento de 9 pixel
	#Letra Y
	addi	$t7, $zero, 26
	linhaH(33, $t7, 6, $t9)		#cria uma linha horizontal na posição x=33 e y=26 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(33, $t7, 6, $t9)		#cria uma linha horizontal na posição x=33 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(33, $t7, 4, $t9)		#cria uma linha vertical na posição x=33 e y=17 com comprimento de 4 pixel
	addi	$t7, $zero, 17
	linhaV(38, $t7, 9, $t9)		#cria uma linha vertical na posição x=38 e y=17 com comprimento de 9 pixel
	#Letra E
	addi	$t7, $zero, 17
	linhaH(41, $t7, 6, $t9)		#cria uma linha horizontal na posição x=41 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(41, $t7, 6, $t9)		#cria uma linha horizontal na posição x=41 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(41, $t7, 10, $t9)	#cria uma linha vertical na posição x=41 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 26
	linhaH(41, $t7, 6, $t9)		#cria uma linha horizontal na posição x=41 e y=26 com comprimento de 6 pixel
	#Letra R
	addi	$t7, $zero, 17
	linhaH(49, $t7, 6, $t9)		#cria uma linha horizontal na posição x=49 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(49, $t7, 10, $t9)	#cria uma linha vertical na posição x=49 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 18
	linhaV(54, $t7, 3, $t9)		#cria uma linha vertical na posição x=54 e y=18 com comprimento de 3 pixel
	
	#Letra 1
	addi	$t7, $zero, 37
	linhaH(23, $t7, 2, $t9)		#cria uma linha horizontal na posição x=23 e y=37 com comprimento de 2 pixel
	addi	$t7, $zero, 37
	linhaV(24, $t7, 5, $t9)		#cria uma linha vertical na posição x=24 e y=37 com comprimento de 5 pixel
	addi	$t7, $zero, 42
	linhaH(22, $t7, 4, $t9)		#cria uma linha horizontal na posição x=22 e y=42 com comprimento de 4 pixel
	#Letra 2
	addi	$t7, $zero, 37
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=37 com comprimento de 4 pixel
	addi	$t7, $zero, 39
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=39 com comprimento de 4 pixel
	addi	$t7, $zero, 39
	linhaV(38, $t7, 3, $t9)		#cria uma linha vertical na posição x=38 e y=39 com comprimento de 3 pixel
	addi	$t7, $zero, 37
	linhaV(41, $t7, 3, $t9)		#cria uma linha vertical na posição x=41 e y=37 com comprimento de 3 pixel
	addi	$t7, $zero, 42
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=42 com comprimento de 4 pixel
.end_macro

.macro selecaoJogador($j)		#procedimento para criar um modura para seleção da tela inicial nos número 1 e 2 e também é usado na tela de level
	
	addi	$t9, $zero, 0x00004010	#cor de fundo
	modura($s7, $t9)		#pinta a modura anterior	
	beq	$j, 0, jogador1		#se seleção($j) for igual a zero desvia para jogador1
	beq	$j, 1, jogador2		#se seleção($j) for igual a zero desvia para jogador2
	
jogador1:				
	addi	$t5, $zero, 6		#$t5 recebe o valor da posição 6
	j	sair
jogador2:
	addi	$t5, $zero, 5		#$t5 recebe o valor da posição 5
	j	sair
sair:		
	addi	$t9, $zero, 0x00FFFF26	#seta em $t9 a cor amarela
	modura($t5, $t9)		#pinta a modura atual na posição armazenada em $t5 na cor $t9
	move	$s7, $t5		#o $s7 recebe o a ultima posição da modura para a mesma ser repintada na cor do fundo
.end_macro

.macro pintarLevel()			#procedimento para pintar a tela de level com o texto LEVEL e os números 1 e 2
	addi	$t9, $zero, 0x00FFFFFF	#seta a cor branca em $t9
	
	#Letra L
	addi	$t7, $zero, 26
	linhaH(13, $t7, 6, $t9)		#cria uma linha horizontal na posição x=13 e y=26 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(13, $t7, 10, $t9)	#cria uma linha vertical na posição x=13 e y=17 com comprimento de 10 pixel
	#Letra E
	addi	$t7, $zero, 17
	linhaH(21, $t7, 6, $t9)		#cria uma linha horizontal na posição x=21 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(21, $t7, 6, $t9)		#cria uma linha horizontal na posição x=21 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(21, $t7, 10, $t9)	#cria uma linha vertical na posição x=21 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 26
	linhaH(21, $t7, 6, $t9)		#cria uma linha horizontal na posição x=21 e y=26 com comprimento de 6 pixel
	#Letra V
	addi	$t7, $zero, 17
	linhaV(29, $t7, 7, $t9)		#cria uma linha vertical na posição x=29 e y=17 com comprimento de 7 pixel
	addi	$t7, $zero, 17
	linhaV(35, $t7, 7, $t9)		#cria uma linha vertical na posição x=35 e y=17 com comprimento de 7 pixel
	addi	$t7, $zero, 24
	linhaV(30, $t7, 1, $t9)		#cria uma linha vertical na posição x=30 e y=24 com comprimento de 1 pixel
	addi	$t7, $zero, 25
	linhaV(31, $t7, 1, $t9)		#cria uma linha vertical na posição x=31 e y=25 com comprimento de 1 pixel
	addi	$t7, $zero, 24
	linhaV(34, $t7, 1, $t9)		#cria uma linha vertical na posição x=34 e y=24 com comprimento de 1 pixel
	addi	$t7, $zero, 25
	linhaV(33, $t7, 1, $t9)		#cria uma linha vertical na posição x=33 e y=25 com comprimento de 1 pixel
	addi	$t7, $zero, 26
	linhaV(32, $t7, 1, $t9)		#cria uma linha vertical na posição x=32 e y=26 com comprimento de 1 pixel
	#Letra E
	addi	$t7, $zero, 17
	linhaH(38, $t7, 6, $t9)		#cria uma linha horizontal na posição x=38 e y=17 com comprimento de 6 pixel
	addi	$t7, $zero, 21
	linhaH(38, $t7, 6, $t9)		#cria uma linha horizontal na posição x=38 e y=21 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(38, $t7, 10, $t9)	#cria uma linha vertical na posição x=38 e y=17 com comprimento de 10 pixel
	addi	$t7, $zero, 26
	linhaH(38, $t7, 6, $t9)		#cria uma linha horizontal na posição x=38 e y=26 com comprimento de 6 pixel
	#Letra L
	addi	$t7, $zero, 26
	linhaH(46, $t7, 6, $t9)		#cria uma linha horizontal na posição x=46 e y=26 com comprimento de 6 pixel
	addi	$t7, $zero, 17
	linhaV(46, $t7, 10, $t9)	#cria uma linha vertical na posição x=46 e y=17 com comprimento de 10 pixel
	#Letra 1
	addi	$t7, $zero, 37
	linhaH(22, $t7, 3, $t9)		#cria uma linha horizontal na posição x=22 e y=37 com comprimento de 3 pixel
	addi	$t7, $zero, 37
	linhaV(24, $t7, 5, $t9)		#cria uma linha horizontal na posição x=24 e y=37 com comprimento de 5 pixel
	addi	$t7, $zero, 42
	linhaH(22, $t7, 4, $t9)		#cria uma linha horizontal na posição x=22 e y=42 com comprimento de 4 pixel
	#Letra 2
	addi	$t7, $zero, 37
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=37 com comprimento de 4 pixel
	addi	$t7, $zero, 39
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=39 com comprimento de 4 pixel
	addi	$t7, $zero, 39
	linhaV(38, $t7, 3, $t9)		#cria uma linha vertical na posição x=38 e y=39 com comprimento de 3 pixel
	addi	$t7, $zero, 37
	linhaV(41, $t7, 3, $t9)		#cria uma linha vertical na posição x=41 e y=37 com comprimento de 3 pixel
	addi	$t7, $zero, 42
	linhaH(38, $t7, 4, $t9)		#cria uma linha horizontal na posição x=38 e y=42 com comprimento de 4 pixel
.end_macro
