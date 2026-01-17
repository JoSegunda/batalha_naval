

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

(*2. Configuração Inicial e Protocolo*)

let ler_comando () =
  try Some (read_line ()) with End_of_file -> None

(* Função para colocar um barco no estado de defesa *)
let adicionar_barco estado nome coords =
  let novo_barco = { nome; posicoes = coords; atingidas = [] } in
  { estado with defesa = novo_barco :: estado.defesa }

(*
coordenadas para um Porta-aviões centralizado em (L, C) na 
vertical seriam:
Corpo: (L, C-1), (L, C), (L, C+1)
Braço: (L-1, C), (L-2, C)


*)

(* Modo caça Se acertarmos num barco (tiro <barco>), 
devemos adicionar as células adjacentes à nossa lista de 
proximos_alvos.*)

let obter_adjacentes (l, c) n =
  [(l-1, c); (l+1, c); (l, c-1); (l, c+1)]
  |> List.filter (fun (nl, nc) -> nl >= 0 && nl < n && nc >= 0 && nc < n)

(* Quando recebemos 'tiro fragata' em (L, C) *)
let atualizar_caça estado (l, c) =
  let novos_alvos = obter_adjacentes (l, c) estado.tamanho in
  { estado with proximos_alvos = novos_alvos @ estado.proximos_alvos }