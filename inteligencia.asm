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
##################################################################

# Procedimendo para sortear jogada a partir de uma semente
.macro sorteia_int($semente)
	move $a1, $semente				# Seta semente	
	li $v0, 42      				# Argumento 42, random int a partir de uma semente    
    	syscall         				# Gera random int retornando em $a0
.end_macro

# Procedimento para converter int em binario (apenas para representar a posicao da jogada)
.macro converte_posicao($posicao)
	move $a0, $posicao				# Guarda posicao em $a0
	addi $t0, $zero, 1				# 
	sllv $a0, $t0, $a0				# Retorna em $a0
.end_macro 

# Procedimento para converter o valor binario (representacao) de uma jogada que falta para ganhar ou perder em um valor int (de 0 a 15)
.macro converte_representacao($representacao, %sentido)	
	li $t3, -1					# Seta retorno -1 (Caso nao entre em nenhum dos padroes)
	li $t9, %sentido				# Seta sentido (0=Horizontal, 1=Vertical ou 2=Diagonal)
	beq $t9, 0, horizontal				# Verifica se é horizontal
	beq $t9, 1, vertical				# Verifica se é vertical
diagonal:
	beq $representacao, 0x00008420, R0		# Verifica se falta a jogada em 0 para ganhar ou perder
	beq $representacao, 0x00001240, R3		# Verifica se falta a jogada em 3 para ganhar ou perder
	beq $representacao, 0x00008401, R5		# Verifica se falta a jogada em 5 para ganhar ou perder
	beq $representacao, 0x00001208, R6		# Verifica se falta a jogada em 6 para ganhar ou perder
	beq $representacao, 0x00001048, R9		# Verifica se falta a jogada em 9 para ganhar ou perder
	beq $representacao, 0x00008021, R10		# Verifica se falta a jogada em 10 para ganhar ou perder
	beq $representacao, 0x00000248, R12		# Verifica se falta a jogada em 12 para ganhar ou perder
	beq $representacao, 0x00000421, R15		# Verifica se falta a jogada em 15 para ganhar ou perder
	j sair
vertical:
	beq $representacao, 0x00001110, R0		# Verifica se falta a jogada em 0 para ganhar ou perder
	beq $representacao, 0x00002220, R1		# Verifica se falta a jogada em 1 para ganhar ou perder
	beq $representacao, 0x00004440, R2		# Verifica se falta a jogada em 2 para ganhar ou perder
	beq $representacao, 0x00008880, R3		# Verifica se falta a jogada em 3 para ganhar ou perder
	beq $representacao, 0x00001101, R4		# Verifica se falta a jogada em 4 para ganhar ou perder
	beq $representacao, 0x00002202, R5		# Verifica se falta a jogada em 5 para ganhar ou perder
	beq $representacao, 0x00004404, R6		# Verifica se falta a jogada em 6 para ganhar ou perder
	beq $representacao, 0x00008808, R7		# Verifica se falta a jogada em 7 para ganhar ou perder
	beq $representacao, 0x00001011, R8		# Verifica se falta a jogada em 8 para ganhar ou perder
	beq $representacao, 0x00002022, R9		# Verifica se falta a jogada em 9 para ganhar ou perder
	beq $representacao, 0x00004044, R10		# Verifica se falta a jogada em 10 para ganhar ou perder
	beq $representacao, 0x00008088, R11		# Verifica se falta a jogada em 11 para ganhar ou perder
	beq $representacao, 0x00000111, R12		# Verifica se falta a jogada em 12 para ganhar ou perder
	beq $representacao, 0x00000222, R13		# Verifica se falta a jogada em 13 para ganhar ou perder
	beq $representacao, 0x00000444, R14		# Verifica se falta a jogada em 14 para ganhar ou perder
	beq $representacao, 0x00000888, R15		# Verifica se falta a jogada em 15 para ganhar ou perder
	j sair
horizontal:
	beq $representacao, 0x0000000E, R0		# Verifica se falta a jogada em 0 para ganhar ou perder
	beq $representacao, 0x0000000D, R1		# Verifica se falta a jogada em 1 para ganhar ou perder
	beq $representacao, 0x0000000B, R2		# Verifica se falta a jogada em 2 para ganhar ou perder
	beq $representacao, 0x00000007, R3		# Verifica se falta a jogada em 3 para ganhar ou perder
	beq $representacao, 0x000000E0, R4		# Verifica se falta a jogada em 4 para ganhar ou perder
	beq $representacao, 0x000000D0, R5		# Verifica se falta a jogada em 5 para ganhar ou perder
	beq $representacao, 0x000000B0, R6		# Verifica se falta a jogada em 6 para ganhar ou perder
	beq $representacao, 0x00000070, R7		# Verifica se falta a jogada em 7 para ganhar ou perder
	beq $representacao, 0x00000E00, R8		# Verifica se falta a jogada em 8 para ganhar ou perder
	beq $representacao, 0x00000D00, R9		# Verifica se falta a jogada em 9 para ganhar ou perder
	beq $representacao, 0x00000B00, R10		# Verifica se falta a jogada em 10 para ganhar ou perder
	beq $representacao, 0x00000700, R11		# Verifica se falta a jogada em 11 para ganhar ou perder
	beq $representacao, 0x0000E000, R12		# Verifica se falta a jogada em 12 para ganhar ou perder
	beq $representacao, 0x0000D000, R13		# Verifica se falta a jogada em 13 para ganhar ou perder
	beq $representacao, 0x0000B000, R14		# Verifica se falta a jogada em 14 para ganhar ou perder
	beq $representacao, 0x00007000, R15		# Verifica se falta a jogada em 15 para ganhar ou perder
	j sair
R0:
	li $t3, 0
	j sair
R1:
	li $t3, 1
	j sair
R2:
	li $t3, 2
	j sair
R3:
	li $t3, 3
	j sair
R4:
	li $t3, 4
	j sair
R5:
	li $t3, 5
	j sair
R6:
	li $t3, 6
	j sair
R7:
	li $t3, 7
	j sair
R8:
	li $t3, 8
	j sair
R9:
	li $t3, 9
	j sair
R10:
	li $t3, 10
	j sair
R11:
	li $t3, 11
	j sair
R12:
	li $t3, 12
	j sair
R13:
	li $t3, 13
	j sair
R14:
	li $t3, 14
	j sair
R15:
	li $t3, 15
sair:							# Retorna em $t3 -1 se nao tiver no padrao ou 0-15
.end_macro

# Procedimento para conferir vencedor
.macro confere_vencedor($jogador)			

	move $s2, $jogador				# Seta jogador atual
	beqz $s2, maquina				# Verifica quem jogou por ultimo (0 = maquina, 1 = usuario)
	j usuario

maquina:
	move $a0, $s0					# Seta mascara de jogadas da maquina
	j confere
usuario:
	move $a0, $s1					# Seta mascara de jogadas do usuario
	j confere	
confere:
	# Verifica combinacoes na vertical
	li $t1, 0x00008888				# 0b0000 0000 0000 0000 1000 1000 1000 1000
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x00004444				# 0b0000 0000 0000 0000 0100 0100 0100 0100
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x00002222				# 0b0000 0000 0000 0000 0010 0010 0010 0010
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x00001111				# 0b0000 0000 0000 0000 0001 0001 0001 0001
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	# Verifica combinacoes na horizontal
	li $t1, 0x0000F000				# 0b0000 0000 0000 0000 1111 0000 0000 0000
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x00000F00				# 0b0000 0000 0000 0000 0000 1111 0000 0000
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x000000F0				# 0b0000 0000 0000 0000 0000 0000 1111 0000
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x0000000F				# 0b0000 0000 0000 0000 0000 0000 0000 1111
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	# Verifica combinacoes nas diagonais
	li $t1, 0x00008421				# 0b0000 0000 0000 0000 1000 0100 0010 0001
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	li $t1, 0x00001248				# 0b0000 0000 0000 0000 0001 0010 0100 1000
	and $a1, $t1, $a0				# Faz and com as duas mascaras para verificar padrao de vitoria
	beq $a1, $t1, moveUm
	
	# Verifica caso de empate
	or $a1, $s0, $s1				# Mescla jogadas da maquina com as do usuario
	li $t1,	0x0000FFFF				# Caso de empate: merge das jogadas da maquina com as jogadas do usuario igual a 0b0000 0000 0000 0000 1111 1111 1111 1111
	beq $a1, $t1, menosUm				# Se for 0x0000FFFF, o jogo empatou.
	j moveZero
	
moveZero:
	li $a0, 0					
	j sair
moveUm:
	resultado($t1)
	li $a0, 1
	j sair
menosUm:
	resultado($t1)
	li $a0, -1
	j sair
sair: 							# Retorna em $a0 o valor -1 se empatou ou 0 se NÃO ganhou ou 1 se ganhou
.end_macro 

# Procedimento para conferir se a jogada em uma posicao é permitida
.macro confere_jogada($representacao)
	move $a1, $representacao			# Guarda representacao em $a0
	or $v1, $s0, $s1				# Mescla jogadas da maquina ($s0) com as do usuario ($s1)
	and $v1, $v1, $a1				# Verifica se alguem ja jogou na posicao
	beqz $v1, moveZero				# Se for 0, nao jogaram
	j moveUm
moveZero:
	li $a0, 0
	j sair
moveUm:
	li $a0, 1
	j sair
sair:							# Retorna em $a0, 0 se nao jogaram na posicao ou 1 se ja jogaram	
.end_macro 

# 
.macro cerebro_maquina($jogadas)
	# Verifica combinacoes na vertical
	li $t2, 0x00008888				# 0b0000 0000 0000 0000 1000 1000 1000 1000
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 1)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L2					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair		
	
L2:	
	li $t2, 0x00004444				# 0b0000 0000 0000 0000 0100 0100 0100 0100
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 1)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L3					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L3:	li $t2, 0x00002222				# 0b0000 0000 0000 0000 0010 0010 0010 0010
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 1)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L4					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L4:	li $t2, 0x00001111				# 0b0000 0000 0000 0000 0001 0001 0001 0001
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 1)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L5					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
	# Verifica combinacoes na horizontal
L5:	li $t2, 0x0000F000				# 0b0000 0000 0000 0000 1111 0000 0000 0000
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 0)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L6					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L6:	li $t2, 0x00000F00				# 0b0000 0000 0000 0000 0000 1111 0000 0000
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 0)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L7					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L7:	li $t2, 0x000000F0				# 0b0000 0000 0000 0000 0000 0000 1111 0000
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 0)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L8					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L8:	li $t2, 0x0000000F				# 0b0000 0000 0000 0000 0000 0000 0000 1111
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 0)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L9					# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
	# Verifica combinacoes nas diagonais
L9:	li $t2, 0x00008421				# 0b0000 0000 0000 0000 1000 0100 0010 0001
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 2)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L10				# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	beqz $a0, sair	
	
L10:	li $t2, 0x00001248				# 0b0000 0000 0000 0000 0001 0010 0100 1000
	and $t2, $t2, $jogadas				# Verifica padrao de vitoria com a mascara de jogadas
	converte_representacao($t2, 2)			# Retorna em $t3 o valor -1 se nao existe conversao ou 0-15
	beq $t3, -1, L11				# Verifica se existe uma jogada final
	converte_posicao($t3)				# Retorna em $a0
	confere_jogada($a0)				# Retorna em $a0 o valor 0 se pode jogar nessa posicao, se nao, retorna 1
	j sair	
L11:	
	li $a0, 1			
sair: 							# Retonar em $a0 o valor 0 se pode jogar ou 1 se nao pode e em $t3 o int com a jogada
.end_macro 

# Procedimento para jogar na casa que falta pra ganhar ou pra nao perder
.macro pensar_jogada_maquina()

defender:
	move $t1, $s1					# Guarda mascara de jogadas do usuario
	cerebro_maquina($t1)				# Pensa numa posicao que impede o usuario de ganhar
	beqz $a0, sair					# Se tiver uma jogada, saia para executar a jogada
atacar:
	move $t1, $s0					# Guarda mascara de jogadas da maquina
	cerebro_maquina($t1)				# Pensa numa posicao que faça a maquina ganhar
sair:
.end_macro 
