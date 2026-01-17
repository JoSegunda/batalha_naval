

(*print_string "Hello World\n";;*)

(*1. Definição de Tipos e Estruturas de Dados*)

(* Representa uma coordenada (Linha, Coluna) *)
type pos = int * int

(* Representa o estado de uma célula no tabuleiro de ataque *)
type cell_status = 
  | Desconhecido 
  | Agua 
  | Acerto of string (* Nome do barco atingido *)
  | Afundado of string

(* Estrutura de um barco no tabuleiro de defesa *)
type barco = {
  nome : string;
  posicoes : pos list;      (* Todas as células que o barco ocupa *)
  atingidas : pos list;     (* Células que já foram atingidas pelo inimigo *)
}

(* Estado global do agente *)
type estado = {
  tamanho : int;
  defesa : barco list;
  ataque : cell_status array array; (* Matriz para o tabuleiro de ataque *)
  proximos_alvos : pos list;         (* Lista de tiros planeados (Modo Caça) *)
}
