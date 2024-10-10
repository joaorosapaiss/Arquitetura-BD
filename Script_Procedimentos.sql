-- PROCEDIMENTOS PEDIDOS (ENUNCIADO)

-- ALINEA F)
create or replace procedure cria_viagem_regular (cod_armazem_origem number, cod_armazem_destino number)
as
  v_prox_horario number;
  v_troco_id number;
  v_veiculo_id number;
  v_motorista_id number;
  tp_merc_id number;
  v_viagem_id number;
  
  armazem_inexistente exception;
  troco_inexistente exception;
  motorista_inexistente exception;
  horario_inexistente exception;
  sem_viagens exception;
  sem_capacidade exception;
  
  pragma exception_init(armazem_inexistente, -20806);
  pragma exception_init(troco_inexistente, -20808);
  pragma exception_init(motorista_inexistente, -20813);
  pragma exception_init(horario_inexistente, -20814);
  pragma exception_init(sem_viagens, -20801);
  pragma exception_init(sem_capacidade, -20802);
  
begin
  verifica_armazem(cod_armazem_origem);
  verifica_armazem(cod_armazem_destino);
  
  v_troco_id := obtem_id_troco(cod_armazem_origem, cod_armazem_destino);
  
  tp_merc_id := obtem_tp_merc_mais_existente(cod_armazem_origem);
      
  v_veiculo_id := veiculo_disponivel(cod_armazem_origem, 30);
  
  v_motorista_id := seleciona_motorista(cod_armazem_origem);
  
  v_prox_horario := obtem_proximo_horario(tp_merc_id, v_troco_id);
  
  select seq_viagem.nextval into v_viagem_id from dual;
  
  insert into viagem values (v_viagem_id, 'regular', 0, 0, null, null, v_motorista_id, v_veiculo_id, v_troco_id);
  insert into horario_viagem values (v_prox_horario, v_viagem_id);
  
  update motorista set disponivel = 0 where id_motorista = v_motorista_id;

exception
  when armazem_inexistente then 
    raise_application_error(-20806, 'Codigo de armazem inexistente');
  when troco_inexistente then 
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when motorista_inexistente then
    raise_application_error(-20813, 'Nao ha motoristas disponiveis neste armazem');
  when horario_inexistente then
    raise_application_error(-20814, 'Nenhum horario disponivel encontrado');
    when sem_viagens then
    raise_application_error(-20801, 'Nao estao previstas viagens para esse troco');
  when sem_capacidade then 
    raise_application_error(-20802, 'Nao existe uma viagem para esse troco com capacidade para transportar o pedido');
  when others then raise;
end;
/


-- ALINEA G)
create or replace procedure aloca_pedidos_a_viagem (cod_viagem number)
is
  arm_inicio number;
  tp_estado_id number;
  tpserv_id number;
  vol_disponivel number;
  peso_disponivel number;
  
  viagem_inexistente exception;
  pragma exception_init(viagem_inexistente, -20804);
  
  cursor c1 is
    select pt.id_pedido, pt.volume_pedido, pt.peso_pedido
    from pedido_transp pt
    join em_armazem ea on ea.pedido_transp_id = pt.id_pedido 
      and ea.armazem_id = arm_inicio
    left join viagem_pedido_transp vpt on vpt.pedido_transp_id = pt.id_pedido
    where obtem_id_tipo_estado_atual(pt.id_pedido) = tp_estado_id
      and vpt.pedido_transp_id is null
    order by (case when pt.tipo_servico_id = tpserv_id then 0 else 1 end), pt.data_limite;
    
begin
  verifica_viagem(cod_viagem);

  select t.armazem_id_part into arm_inicio
  from viagem v
  join troco t on t.id_troco = v.troco_id
  where v.id_viagem = cod_viagem;
  
  tp_estado_id := obtem_id_tipo_estado('em_armazem');
  tpserv_id := obtem_id_tipo_servico('urgente');
  vol_disponivel := volume_disponivel(cod_viagem);
  peso_disponivel := peso_disponivel_viagem(cod_viagem);
  
  for p in c1 loop
    if (vol_disponivel > p.volume_pedido and peso_disponivel > p.peso_pedido) then
      insert into viagem_pedido_transp values (cod_viagem, p.id_pedido);
      vol_disponivel := vol_disponivel - p.volume_pedido;
      peso_disponivel := peso_disponivel - p.peso_pedido;
    end if;
  end loop;
  
  commit;
exception
  when viagem_inexistente then 
    raise_application_error(-20804, 'Codigo de viagem inexistente');
  when others then raise;
end;
/


-- ALINEA H)
create or replace procedure cancela_pedido (cod_pedido number)
is
  entregue exception;
  recolhido exception;
  
  pragma exception_init(entregue, -20810);
  pragma exception_init(recolhido, -20816);
  
begin
  verifica_entrega(cod_pedido);
  verifica_recolha(cod_pedido);
  insert into cancelamento values (seq_cancelamento.nextval, sysdate, cod_pedido);
  
exception
  when entregue then 
    raise_application_error(-20810, 'Pedido ja entregue');
  when recolhido then 
    raise_application_error(-20816, 'Pedido ja recolhido!');
  when others then null;
end;
/


-- ALINEA I)
create or replace procedure altera_rota (cod_viagem number, codigo_armazem_destino number)
is
  troco1 number;
  troco2 number;
  codigo_armazem_origem number;
  codigo_armazem_final number;
  motorista number;
  veiculo number;
  chegada_prevista1 number;
  partida_prevista2 number;
  viagem_id number;
  chegada_prevista timestamp;
  partida_prevista timestamp;
  
  viagem_inexistente exception;
  armazem_inexistente exception;
  troco_inexistente exception;
  pragma exception_init(viagem_inexistente, -20804);
  pragma exception_init(armazem_inexistente, -20806);
  pragma exception_init(troco_inexistente, -20808);
  
  cursor c1 is
    select pedido_transp_id as idp
    from viagem_pedido_transp 
    where viagem_id = cod_viagem;
    
begin
  verifica_viagem(cod_viagem);
  verifica_armazem(codigo_armazem_destino);
  
  select t.armazem_id_part, t.armazem_id_cheg, v.motorista_id, v.veiculo_id, v.cheg_prevista
    into codigo_armazem_origem, codigo_armazem_final, motorista, veiculo, chegada_prevista
  from viagem v 
  join troco t on v.troco_id = t.id_troco
  where v.id_viagem = cod_viagem;
  
  troco1 := obtem_id_troco(codigo_armazem_origem, codigo_armazem_destino);
  
  update viagem 
  set troco_id = troco1
  where id_viagem = cod_viagem;
  
  troco2 := obtem_id_troco(codigo_armazem_destino, codigo_armazem_final);
  partida_prevista := chegada_prevista + (1/24);
  select seq_viagem.nextval into viagem_id from dual;
  
  insert into viagem values (viagem_id, 'pontual', 0, 0, partida_prevista, null, motorista, veiculo, troco2);
  
  for x in c1 loop
    insert into viagem_pedido_transp values (viagem_id, x.idp);
  end loop;

exception 
  when viagem_inexistente then
    raise_application_error(-20804, 'Codigo de viagem inexistente');
  when armazem_inexistente then
    raise_application_error(-20806, 'Codigo de armazem inexistente');
  when troco_inexistente then
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when others then raise;
end;
/


-- ALINEA J)
create or replace procedure devolve_pedido (cod_pedido number)
is
  vtroco number;
  nova_viagem number;
  estado_id number;
  ultima timestamp := null;
  
  pedido_inexistente exception;
  troco_inexistente exception;
  sem_viagens exception;
  sem_capacidade exception;
  
  pragma exception_init(pedido_inexistente, -20805);
  pragma exception_init (troco_inexistente, -20808);
  pragma exception_init(sem_viagens, -20801);
  pragma exception_init(sem_capacidade, -20802);
  
  cursor c1 is 
    select v.id_viagem, v.troco_id, p.viagem_id as partida_viagem, c.viagem_id as chegada_viagem, v.cheg_prevista
    from viagem v
    join viagem_pedido_transp vpt on vpt.viagem_id = v.id_viagem
    left join partida p on v.id_viagem = p.viagem_id
    left join chegada c on v.id_viagem = c.viagem_id
    where vpt.pedido_transp_id = cod_pedido
    order by v.id_viagem desc;
    
begin
  verifica_pedido(cod_pedido);

  for x in c1 loop
    if x.partida_viagem is not null and x.chegada_viagem is null then
      select id_troco into vtroco
      from troco 
      where armazem_id_part = (select armazem_id_cheg from troco where id_troco = x.troco_id)
        and armazem_id_cheg = (select armazem_id_part from troco where id_troco = x.troco_id); 
        
      nova_viagem := proxima_viagem_com_espaco_data(cod_pedido, vtroco, x.cheg_prevista); 
      
    elsif x.partida_viagem is null then
      delete from viagem_pedido_transp
      where viagem_id = x.id_viagem
      and pedido_transp_id = cod_pedido;
    
    else 
      select id_troco into vtroco
      from troco 
      where armazem_id_part = (select armazem_id_cheg from troco where id_troco = x.troco_id)
        and armazem_id_cheg = (select armazem_id_part from troco where id_troco = x.troco_id);
        
      if ultima is null then
        nova_viagem := proxima_viagem_com_espaco(cod_pedido, vtroco);
      else 
        nova_viagem := proxima_viagem_com_espaco_data(cod_pedido, vtroco, ultima);
      end if;
      
    end if;
      
    -- if nova_viagem is null then
    --   chamar procedimento auxiliar que crie uma viagem pontual com mais pedidos desse armazem
    -- end if;
    
    insert into viagem_pedido_transp values (nova_viagem, cod_pedido);
    
    select cheg_prevista into ultima from viagem where id_viagem = nova_viagem;
  end loop;
  
  estado_id := obtem_id_tipo_estado('devolvido');
  insert into estado values (sysdate, estado_id, cod_pedido);
exception
  when pedido_inexistente then
    raise_application_error(-20805, 'Codigo de pedido transporte inexistente');
  when troco_inexistente then 
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when sem_viagens then
    raise_application_error(-20801, 'Nao estao previstas viagens para esse troco');
  when sem_capacidade then 
    raise_application_error(-20802, 'Nao existe uma viagem para esse troco com capacidade para transportar o pedido');
  when others then raise;
end;
/


-- ALINEA K)
create or replace procedure cria_viagem_pontual (cod_armazem number) 
is  
  vp_pedido_id number;
  armazem_entrega number;
  volume_pedido number;
  troco number;
  veiculo number;
  motorista number;
  viagem_id number;
  
  armazem_inexistente exception;
  troco_inexistente exception;
  motorista_inexistente exception;
  sem_viagens exception;
  sem_capacidade exception;
  
  pragma exception_init(armazem_inexistente, -20806);
  pragma exception_init(troco_inexistente, -20808);
  pragma exception_init(motorista_inexistente, -20813);
  pragma exception_init(sem_viagens, -20801);
  pragma exception_init(sem_capacidade, -20802);
  
begin 
  select pedido_id, arm_entrega, vol_pedido 
  into vp_pedido_id, armazem_entrega, volume_pedido
  from (
    select pt.id_pedido as pedido_id,
      pt.armazem_id_entrega as arm_entrega,
      pt.volume_pedido as vol_pedido
    from pedido_transp pt
    join recolha r on r.pedido_transp_id = pt.id_pedido
    where r.armazem_id = cod_armazem
    and r.data_recolha < trunc(sysdate) - 6
    and not exists (
      select 1 
      from viagem_pedido_transp vpt 
      where vpt.pedido_transp_id = pt.id_pedido
    )
    order by r.data_recolha
  ) where rownum = 1;
  
  troco := obtem_id_troco(cod_armazem, armazem_entrega);
  veiculo := veiculo_disponivel(cod_armazem, volume_pedido);
  motorista := seleciona_motorista(cod_armazem);
  
  select seq_viagem.nextval into viagem_id from dual;
  
  insert into viagem values (viagem_id, 'pontual', 0, 0, null, null, motorista, veiculo, troco);
  insert into viagem_pedido_transp values (viagem_id, vp_pedido_id);
  
exception
  when armazem_inexistente then 
    raise_application_error(-20806, 'Codigo de armazem inexistente');
  when troco_inexistente then 
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when motorista_inexistente then
    raise_application_error(-20813, 'Nao ha motoristas disponiveis neste armazem');
  when sem_viagens then
    raise_application_error(-20801, 'Nao estao previstas viagens para esse troco');
  when sem_capacidade then 
    raise_application_error(-20802, 'Nao existe uma viagem para esse troco com capacidade para transportar o pedido');
  when no_data_found then
    raise_application_error(-20817, 'Nenhum pedido pendente ha mais de 6 dias');
  when others then raise;
end;
/



-- ALINEA Q
create or replace procedure Q_PROC_2020131717 (cod_viagem number)
is
  v_motorista_id number;
  v_veiculo_id number;
  v_pedido_id number;
  verificacao number;
  arm_partida number;

  viagem_inexistente exception;
  pragma exception_init(viagem_inexistente, -20804);

  cursor c1 is
    select pedido_transp_id
    from viagem_pedido_transp
    where viagem_id = cod_viagem;

begin
  verifica_viagem(cod_viagem);
  
  begin 
    select id_partida into verificacao
    from partida where viagem_id = cod_viagem;
  exception 
    when no_data_found then
      raise_application_error(-20818, 'Viagem j� realizada. Nao � possivel cancelar');
  end;

  select v.motorista_id, v.veiculo_id, t.armazem_id_part
  into v_motorista_id, v_veiculo_id, arm_partida
  from viagem v
  join troco t on t.id_troco = v.troco_id
  where id_viagem = cod_viagem;
  
  insert into veiculo_armazem values (v_veiculo_id, arm_partida, sysdate);

  update motorista set disponivel = 1 where id_motorista = v_motorista_id;

  delete from viagem_pedido_transp where viagem_id = cod_viagem;
  
  delete from viagem where id_viagem = cod_viagem;
  
exception
  when viagem_inexistente then
    raise_application_error(-20804, 'C�digo de viagem inexistente');
  when others then raise;
end;
/
















-- PROCEDIMENTOS AUXILIARES

create or replace procedure verifica_pedido (cod_pedido number)
is
  pedido_id number;
begin 
  select id_pedido into pedido_id 
  from pedido_transp 
  where id_pedido = cod_pedido;
exception
  when no_data_found then 
    raise_application_error(-20805, 'Codigo de pedido transporte inexistente');
end;
/


create or replace procedure verifica_troco (cod_troco number)
is
  troco_id number;
begin 
  select id_troco into troco_id 
  from troco 
  where id_troco = cod_troco;
exception
  when no_data_found then 
    raise_application_error(-20808, 'Codigo de troco inexistente');
end;
/

create or replace procedure verifica_armazem (cod_armazem number)
is 
  armazem_id number;
begin 
  select id_armazem into armazem_id 
  from armazem 
  where id_armazem = cod_armazem;
exception
  when no_data_found then 
    raise_application_error(-20806, 'Codigo de armazem inexistente');
end;
/

create or replace procedure verifica_viagem (cod_viagem number)
is 
  viagem_id number;
begin
  select id_viagem into viagem_id 
  from viagem 
  where id_viagem = cod_viagem;
exception
  when no_data_found then 
    raise_application_error(-20804, 'Codigo de viagem inexistente');
end;
/

create or replace procedure verifica_tipo_servico (cod_tservico number) 
is 
  tpserv_id number;
begin 
  select id_tiposervico into tpserv_id 
  from tipo_servico
  where id_tiposervico = cod_tservico;
exception
  when no_data_found then 
    raise_application_error(-20807, 'Codigo de tipo de servico inexistente');
end;
/

create or replace procedure verifica_entrega (cod_pedido number)
is 
  entrega_id number;
begin 
  select id_entrega into entrega_id
  from entrega 
  where pedido_transp_id = cod_pedido;
  
  raise_application_error(-20810, 'Pedido ja entregue');
exception
  when no_data_found then null;
end;
/
  
create or replace procedure verifica_recolha (cod_pedido number)
is 
  recolha_id number;
begin 
  select id_recolha into recolha_id
  from recolha 
  where pedido_transp_id = cod_pedido;
  
  raise_application_error(-20816, 'Pedido ja recolhido!');
exception
  when no_data_found then null;
end;
/
