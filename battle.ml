

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

(* Função para responder a um ataque do inimigo *)
let responder_ao_tiro estado cmd =
  (* TODO: Implementar lógica para processar o comando de tiro *)
  ("OK", estado)

  (*Loop que alterna entre atacar e se defender*)

let rec loop_jogo estado =
  match ler_comando () with
  | Some cmd ->
      if String.starts_with ~prefix:"tiro" cmd then
        (* O inimigo atacou-nos! *)
        let resposta, novo_estado = responder_ao_tiro estado cmd in
        print_endline resposta;
        flush stdout;
        loop_jogo novo_estado
      | Some "perdi" -> () (* Fim de jogo*)
      | _ -> loop_jogo estado
  | None -> ()


(*Estado de jogo - como o agente se lembra do que está a acontecer*)

(* Representa uma célula no tabuleiro de ataque *)
type estado_casa = Desconhecido | Agua | Acerto | Afundado

type estado_jogo = {
  mutable tamanho : int;
  mutable barcos_defesa : (string * (int * int) list ref) list; (* Nome e lista de coordenadas vivas *)
  tabuleiro_ataque : estado_casa array array;
  mutable proximos_tiros : (int * int) list; (* Fila para o Modo Caça *)
  mutable ja_tentados : (int * int) list; (* Para não repetir tiros *)
}

(* Estado inicial padrão (8x8) *)
let criar_estado n = {
  tamanho = n;
  barcos_defesa = [];
  tabuleiro_ataque = Array.make_matrix n n Desconhecido;
  proximos_tiros = [];
  ja_tentados = [];
}


(*Lógica de Defesa (Receber Tiro) - Quando o inimigo diz tiro L C, 
precisamos de verificar se ele acertou em algum dos nossos barcos.*)

let processar_tiro_recebido estado l c =
  let acertou = ref None in
  (* Verifica em cada barco se a coordenada (l, c) existe *)
  List.iter (fun (nome, coords) ->
    if List.mem (l, c) !coords then (
      acertou := Some (nome, coords);
      (* Remove a coordenada atingida (o "cano" do barco)  *)
      coords := List.filter (fun p -> p <> (l, c)) !coords
    )
  ) estado.barcos_defesa;

  match !acertou with
  | None -> "agua" 
  | Some (nome, coords) ->
      if !coords = [] then (
        (* Se não restam coordenadas, o barco afundou  *)
        estado.barcos_defesa <- List.filter (fun (n, _) -> n <> nome) estado.barcos_defesa;
        if estado.barcos_defesa = [] then "perdi" else "afundado " ^ nome
      ) else "tiro " ^ nome 

(*Lógica de Ataque (Estratégia de Caça) - Se não temos alvos na 
lista, atiramos ao acaso. Se acertámos antes, verificamos as 
vizinhanças.*)

let escolher_tiro estado =
  match estado.proximos_tiros with
  | (l, c) :: resto -> 
      estado.proximos_tiros <- resto; (l, c)
  | [] -> 
      (* Estratégia simples: procura a próxima casa Desconhecida *)
      let rec procurar l c =
        if l >= estado.tamanho then (0, 0) (* Falha de segurança *)
        else if c >= estado.tamanho then procurar (l + 1) 0
        else if not (List.mem (l, c) estado.ja_tentados) then (l, c)
        else procurar l (c + 1)
      in procurar 0 0

let adicionar_vizinhos estado l c =
  let vizinhos = [(l-1, c); (l+1, c); (l, c-1); (l, c+1)] in
  let validos = List.filter (fun (nl, nc) ->
    nl >= 0 && nl < estado.tamanho && nc >= 0 && nc < estado.tamanho &&
    not (List.mem (nl, nc) estado.ja_tentados)
  ) vizinhos in
  estado.proximos_tiros <- estado.proximos_tiros @ validos 

(*O Ciclo de Comunicação (Protocolo) - O agente precisa de ler do 
stdin e escrever no stdout continuamente*)

let executar_agente () =
  let estado = criar_estado 8 in
  let continuar = ref true in
  while !continuar do
    let linha = read_line () in
    let partes = String.split_on_char ' ' linha in
    match partes with
    | ["init"; n] -> estado.tamanho <- int_of_string n
    | ["barco"; nome; l; c; _] -> 
        (* Simplificação: adiciona o barco à defesa  *)
        let coords = ref [(int_of_string l, int_of_string c)] in 
        estado.barcos_defesa <- (nome, coords) :: estado.barcos_defesa
    | ["random"] -> () (* Aqui você implementaria a colocação automática *)
    | ["vou"; "eu"] | ["tiro"; _; _] as cmd ->
        if List.hd cmd = "tiro" then (
          let l, c = int_of_string (List.nth partes 1), int_of_string (List.nth partes 2) in
          print_endline (processar_tiro_recebido estado l c);
          flush stdout
        );
        (* Agora é a nossa vez de atacar *)
        let (al, ac) = escolher_tiro estado in
        estado.ja_tentados <- (al, ac) :: estado.ja_tentados;
        Printf.printf "tiro %d %d\n" al ac;
        flush stdout
    | ["agua"] -> ()
    | ["tiro"; nome] -> 
        (* Se acertámos, entramos no Modo Caça  *)
        let (l, c) = List.hd estado.ja_tentados in
        adicionar_vizinhos estado l c
    | ["afundado"; _] -> 
        estado.proximos_tiros <- [] (* Parar de procurar este barco *)
    | ["perdi"] -> continuar := false 
    | _ -> ()
  done

let () = executar_agente ()