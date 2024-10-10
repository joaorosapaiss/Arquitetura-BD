
-- TRIGGERS 

-- Triggers Pedidos (do Enunciado)

-- ALINEA L)
create or replace trigger upstatus_entrega 
after insert on entrega
for each row
declare 
  tpestado_id number;

begin
  tpestado_id := obtem_id_tipo_estado('entregue');
  
  insert into estado values (sysdate, tpestado_id, :new.pedido_transp_id);
  insert into fora_armazem values (sysdate, :new.armazem_id, :new.pedido_transp_id);
end;
/


-- ALINEA M)
create or replace trigger descarrega_no_armazem
after insert on chegada
for each row
declare
  tpestado_id number;
  armazem_chegada number;
  cursor c1 is 
    select vpt.pedido_transp_id as pedido_id
    from viagem_pedido_transp vpt 
    where vpt.viagem_id = :new.viagem_id;
    
begin
  tpestado_id := obtem_id_tipo_estado('em_armazem');
  
  select t.armazem_id_cheg into armazem_chegada
  from viagem v 
  join troco t on t.id_troco = v.troco_id
  where v.id_viagem = :new.viagem_id;
  
  for x in c1 loop
    insert into estado values (sysdate, tpestado_id, x.pedido_id);
    insert into em_armazem values (sysdate, armazem_chegada, x.pedido_id);
  end loop;
end;
/


-- ALINEA N)
create or replace trigger descarrega_de_armazem
after insert on partida 
for each row 
declare 
  tpestado_id number;
  armazem_partida number;
  cursor c1 is 
    select vpt.pedido_transp_id as pedido_id
    from viagem_pedido_transp vpt 
    where vpt.viagem_id = :new.viagem_id;
  
begin
  tpestado_id := obtem_id_tipo_estado('em_transito');
  
  select t.armazem_id_part into armazem_partida
  from viagem v
  join troco t on t.id_troco = v.troco_id
  where v.id_viagem = :new.viagem_id; 
  
  for x in c1 loop
    insert into estado values (sysdate, tpestado_id, x.pedido_id);
    insert into fora_armazem values (sysdate, armazem_partida, x.pedido_id);
  end loop;
end;
/
  
  
-- ALINEA O)
create or replace trigger altera_veiculo
after update of peso_transp, volume_transp
on viagem 
for each row
declare
-- acabar este e depois
  peso_maximo number;
  vol_maximo number;
  arm_origem number;
  novo_veiculo number;
    
begin 
  select volume_max, capacidade_tara 
    into vol_maximo, peso_maximo
  from veiculo
  where id_veiculo = :new.veiculo_id;
  
  if (:new.volume_transp / vol_maximo > 0.95 or :new.peso_transp / peso_maximo > 0.95) then
    begin
      select armazem_id_part into arm_origem
      from troco 
      where id_troco = :new.troco_id;
      
      select id_veiculo into novo_veiculo
      from ( 
        select v.id_veiculo
        from veiculo v
        join veiculo_armazem va on va.veiculo_id = v.id_veiculo
          and va.armazem_id = arm_origem
        where (:new.peso_transp/v.capacidade_tara) < 0.8 
        and (:new.volume_transp/v.volume_max) < 0.8
        order by va.data_hora
      ) where rownum = 1; 
        
      update viagem set veiculo_id = novo_veiculo
      where id_viagem = :new.id_viagem;
    exception
      when no_data_found then 
        raise_application_error(-20809, 'N�o h� ve�culos dispon�veis no armaz�m');
    end;
  end if;
end;
/


create or replace trigger R_TRIG_2020131717
after insert on fora_armazem
for each row
declare
  vol_pedido number;

begin

  select volume_pedido into vol_pedido
  from pedido_transp
  where id_pedido = :new.pedido_transp_id;
  
  update armazem 
  set cap_disponivel = cap_disponivel + vol_pedido
  where id_armazem = :new.armazem_id;
  
end;
/









-- Triggers Opcionais (Consistencia)

-- Trigger para atualizar a descricao do troco
create or replace trigger troco_descricao
before insert on troco
for each row
declare
  arm1_desc varchar2(25);
  arm2_desc varchar2(25);
  arm1_ident varchar2(25);
  arm2_ident varchar2(25);
begin 
  arm1_desc := substr(:new.armazem_id_arm1, 1, instr(:new.armazem_id_arm1, ' ') - 1);
  arm1_ident := substr(:new.armazem_id_arm1, instr(:new.armazem_id_arm1, ' ') + 1);
  
  arm2_desc := substr(:new.armazem_id_arm2, 1, instr(:new.armazem_id_arm2, ' ') - 1);
  arm2_ident := substr(:new.armazem_id_arm2, instr(:new.armazem_id_arm2, ' ') + 1);

  
  :new.descricao := arm1_desc || ' (' || arm1_ident || ')' || ' - ' || arm2_desc || ' (' || arm2_ident || ')';
end;
/




-- trigger para definir armazem de recolha e entrega
create or replace trigger arm_recolha_entrega
after insert on pedido_transporte
for each row
declare
  cidade_recolha varchar(20);
  arm_recolha varchar2(20);
  cidade_entrega varchar2(20);
  arm_entrega varchar2(20);
begin 
  -- Verifica se o ID do armazem e nullo
  if :new.id_armazem_recolha is null then
    -- extrai a cidade de recolha da morada de origem
    cidade_recolha := upper(substr(:new.morada_origem, instr(:new.morada_origem, ',', - 1) + 2));
    
    -- selecionar o armazem de recolha com a maior capacidade disponivel na cidade de recolha
    select id_armazem into arm_recolha
    from armazem 
    where upper(substr(id_armazem, 1, instr(id_armazem, ' ') - 1)) = cidade_entrega
    and cap_disponivel = (select max(cap_disponivel) from armazem);
    
    -- atualiza o ID do armazem de recolha no pedido de transporte
    update pedido_transporte 
    set id_armazem_recolha = arm_recolha;
  
  end if;
  
  -- Igual mas para o de entrega
  if :new.id_armazem_entrega is null then 
    cidade_entrega := upper(substr(:new.morada_destino, instr(:new.morada_destino, ',', - 1) + 2));
    
    select id_armazem into arm_entrega
    from armazem 
    where upper(substr(id_armazem, 1, instr(id_armazem, ' ') - 1)) = cidade_entrega
    and cap_disponivel = (select max(cap_disponivel) from armazem);
    -- adicionar verificaao se armazem tem espaco para pedido
    
    update pedido_transporte 
    set id_armazem_entrega = arm_entrega;
  end if;
end;
/


-- trigger para tratar da primeira entrada em armazem 
create or replace trigger primeira_entrada_armazem
before insert on em_armazem
for each row
declare
  conta number;
  arm_recolha varchar2(20);
  prazo number;
  v_data_limite date;
begin 
  -- conta o numero de entradas na tabela em_armazem para o mesmo pedido
  select count(*) into conta
  from em_armazem 
  where pedido_trans_id_pedido = :new.pedido_trans_id_pedido;
  
  -- verifica se é a primeira entrada do pedido na tabela em_armazem
  if conta = 0 then 
    -- obtem o ID do armazem de recolha previsto para o pedido
    select id_armazem_recolha into arm_recolha 
    from pedido_transporte 
    where id_pedido = :new.pedido_trans_id_pedido;
    
    -- verifica se o armazem de entrada coincide com o armazem de recolha
    if :new.armazem_id_armazem = arm_recolha then
      select prazo_maximo into prazo 
      from tipo_servico 
      where id_tiposervico = (select tipo_serv_id_tserv
                              from pedido_transporte
                              where id_pedido = :new.pedido_trans_id_pedido);
      -- calcular data_limite
      v_data_limite := :new.datahora + prazo;
      
      -- atualiza a data limite no pedido de transporte
      update pedido_transporte 
      set data_limite = v_data_limite
      where id_pedido = :new.pedido_trans_id_pedido;
    else 
      raise_application_error(-20813, 'id_armazem nao coincide com armazem de recolha previsto');
    end if;
  end if;
end;
/  


-- criacao do trigger entradas_armazem
create or replace trigger entradas_armazem
after insert on em_armazem
for each row
declare 
  arm_destino varchar2(20);
  conta number;
  
begin 
  -- conta o numero de entradas na tabela em_armazem para o mesmo pedido
  select count(*) into conta
  from em_armazem 
  where pedido_trans_id_pedido = :new.pedido_trans_id_pedido;
  
  -- verifica se e a primeira entrada do pedido na tabela
  if conta = 1 then 
    -- se for insere na tabela recolha
    insert into recolha values (seq_recolha.nextval, :new.datahora, :new.pedido_trans_id_pedido);
  end if;

  -- obtem o ID do armazem de entrega previsto para o pedido  
  select id_armazem_entrega into arm_destino
  from pedido_transporte 
  where id_pedido = :new.pedido_trans_id_pedido;

  -- verifica se coincide com o armazem de entrega previsto
  if :new.armazem_id_armazem = arm_destino then
    insert into estado values(seq_estado.nextval, :new.datahora, obtem_id_tipo_estado('a_aguardar_entrega'), :new.pedido_trans_id_pedido);
  else 
    insert into estado values(seq_estado.nextval, :new.datahora, obtem_id_tipo_estado('em_armazem'), :new.pedido_trans_id_pedido);
  end if;
end;
/
    
    
    

-- Triggers atualizar estados
create or replace trigger aguardar_recolha
before insert on pedido_transporte
for each row
begin 
  insert into estado values (seq_estado.nextval, :new.data_registo, obtem_id_tipo_estado('a_aguardar_recolha'), :new.id_pedido);
end;
/ -- este trigger esta ao contrario dos outros para prevenir estouro 
-- devido a funcao obtem_id_estado_atual


create or replace trigger devolvido
after insert on cancelamento 
for each row
begin
  insert into estado values (seq_estado.nextval, :new.data_cancel, obtem_id_tipo_estado('devolvido'), :new.pedido_trans_id_pedido);
end;
/

create or replace trigger em_transito
after insert on fora_armazem 
for each row
begin
  insert into estado values (seq_estado.nextval, :new.data_hora, obtem_id_tipo_estado('em_transito'), :new.pedido_trans_id_pedido);
end;
/

create or replace trigger entregue 
after insert on entrega
for each row 
begin 
  insert into estado values (seq_estado.nextval, :new.data_entrega, obtem_id_tipo_estado('entregue'), :new.pedido_trans_id_pedido);
end;
/   

create or replace trigger atualiza_tipo_viagem
after insert on horario_viagem
for each row
begin 
  update viagem 
  set tipo_viagem = 'regular'
  where id_viagem = :new.viagem__id_viagem;
end;
/


















