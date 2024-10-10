-- FUNCOES PEDIDAS (ENUNCIADO)
-- META 3


-- ALINEA A
create or replace function proxima_viagem_com_espaco(cod_pedido number, cod_troco number) return number
is
  v_peso_pedido number;
  v_volume_pedido number;
  v_id_viagem number;
  troco number;
  
  pedido_nao_encontrado exception;
  pragma exception_init(pedido_nao_encontrado, -20805);
  troco_inexistente exception;
  pragma exception_init (troco_inexistente, -20808);

begin
  verifica_pedido(cod_pedido);
  verifica_troco(cod_troco);
  
  select peso_pedido, volume_pedido into v_peso_pedido, v_volume_pedido
  from pedido_transp
  where id_pedido = cod_pedido;
  
  begin
    select troco_id into troco -- pode rebentar se 
    from viagem
    where troco_id = cod_troco
    and part_prevista > sysdate;
  exception
    when no_data_found then 
      raise_application_error(-20801, 'Nao estao previstas viagens para esse troco');
  end;
    
  select min(v.id_viagem) into v_id_viagem
  from viagem v
  join veiculo ve on v.veiculo_id = ve.id_veiculo
  where v.troco_id = cod_troco
    and (ve.capacidade_tara - v.peso_transp) >= v_peso_pedido
    and (ve.volume_max - v.volume_transp) >= v_volume_pedido
    and v.part_prevista > sysdate;
  
  return v_id_viagem;

exception
  when pedido_nao_encontrado then
    raise_application_error(-20805, 'Codigo de pedido transporte inexistente');
  when troco_inexistente then
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when no_data_found then
      raise_application_error(-20802, 'Nao existe uma viagem para esse troco com capacidade para transportar o pedido');
  when others then raise;
end;
/


-- ALINEA B
create or replace function veiculo_disponivel(cod_armazem number, volume_minimo number) return number
is
  v_id_veiculo number;
  armazem_inexistente exception;
  pragma exception_init(armazem_inexistente, -20806);
begin
  -- Encontrar ve�culo dispon�vel com a capacidade necess�ria e localizado no armaz�m especificado
  select veiculo_id into v_id_veiculo
  from (
    select ve.id_veiculo as veiculo_id
    from veiculo ve
    join veiculo_armazem va on ve.id_veiculo = va.veiculo_id
    where va.armazem_id = cod_armazem
      and ve.volume_max >= volume_minimo
    order by va.data_hora 
  ) where rownum = 1;

  return v_id_veiculo;

exception
  when armazem_inexistente then 
    raise_application_error(-20806, 'Codigo de armazem inexistente');
  when no_data_found then
    raise_application_error(-20809, 'N�o h� veiculos disponiveis no armazem');
  when others then raise;
end;
/


-- ALINEA C)
create or replace function volume_disponivel (cod_viagem number) return number 
is
  total_volume number;
  usado_volume number;
  disponivel number;
  
  viagem_inexistente exception;
  pragma exception_init(viagem_inexistente, -20804);
  
begin
  verifica_viagem(cod_viagem);
  
  select ve.volume_max into total_volume
  from veiculo ve 
  join viagem v on v.veiculo_id = ve.id_veiculo
  where v.id_viagem = cod_viagem;
  
  select nvl(sum(pt.volume_pedido), 0) into usado_volume
  from pedido_transp pt
  join viagem_pedido_transp vpt on pt.id_pedido = vpt.pedido_transp_id
    and vpt.viagem_id = cod_viagem;
  
  disponivel := total_volume - usado_volume;
  
  return disponivel;

exception
  when viagem_inexistente then 
    raise_application_error(-20804, 'Codigo de viagem inexistente');
  when others then raise;
end;
/


-- ALINEA D)
create or replace function tem_capacidade_para_armazenar (cod_pedido number, cod_armazem number) return number
is
  vol_pedido number;
  cap_disp number;
  
  pedido_inexistente exception;
  armazem_inexistente exception;
  pragma exception_init(pedido_inexistente, -20805);
  pragma exception_init(armazem_inexistente, -20806);
  
begin
  verifica_pedido(cod_pedido);
  verifica_armazem(cod_armazem);
  
  select volume_pedido into vol_pedido
  from pedido_transp
  where id_pedido = cod_pedido;

  select cap_disponivel into cap_disp
  from armazem 
  where id_armazem = cod_armazem;
  
  if cap_disp >= vol_pedido then
    return 1;
  else 
    return 0;
  end if;
  
exception 
  when pedido_inexistente then
    raise_application_error(-20805, 'Codigo de pedido de transporte inexistente');
  when armazem_inexistente then 
    raise_application_error(-20806, 'Codigo de armazem inexistente');
  when others then raise;
end;
/


-- ALINEA E)
create or replace function volume_tipo_dos_pedidos (cod_viagem number, cod_tipo_servico number) return number
is
  total_vol number;
  idv number;
  idts number;
  
  viagem_inexistente exception;
  servico_inexistente exception;
  pragma exception_init(viagem_inexistente, -20804);
  pragma exception_init(servico_inexistente, -20807);
begin 
  verifica_viagem(cod_viagem);
  verifica_tipo_servico(cod_tipo_servico);
  
  select nvl(sum(pt.volume_pedido), 0) into total_vol
  from pedido_transp pt
  join viagem_pedido_transp vpt on vpt.pedido_transp_id = pt.id_pedido
  where vpt.viagem_id = cod_viagem  
    and pt.tipo_servico_id = cod_tipo_servico;
    
  return total_vol; 
exception 
  when viagem_inexistente then
    raise_application_error(-20804, 'Codigo de viagem inexistente');
  when servico_inexistente then
    raise_application_error(-20807, 'Codigo de tipo de servico inexistente');
  when others then raise;
end;
/



-- ALINEA P
create or replace function P_FUNC_2020131717 (cod_pedido number) return number 
is
  armazem_atual NUMBER;
  estado_atual number;
  estado_armazem number;

  pedido_inexistente exception;
  pragma exception_init(pedido_inexistente, -20810);
begin
  verifica_pedido(cod_pedido);
  
  estado_armazem := obtem_id_tipo_estado('em_armazem'); 
  
  estado_atual := obtem_id_tipo_estado_atual(cod_pedido);
  
  if estado_armazem = estado_atual then
    select armazem_id into armazem_atual
    from (
      select armazem_id
      from em_armazem
      order by data_hora desc
    ) where rownum = 1;
  else 
    raise_application_error(-20819, 'Pedido em transito, nao se encontra em nenhum armazem');  
  end if;
  
  return armazem_atual;
exception
  when pedido_inexistente then 
    raise_application_error(-20805, 'Codigo de pedido transporte inexistente');
  when others then raise;
end;
/












-- FUNCOES AUXILIARES

create or replace function obtem_id_tipo_servico (descr varchar2) return number
is
  tpserv_id number;
begin
  select id_tiposervico into tpserv_id
  from tipo_servico
  where lower(descricao) like lower(descr);
  
  return tpserv_id;
exception 
  when no_data_found then 
    return null;
end;
/ 


create or replace function obtem_id_tipo_estado (descr varchar2) return number
is
  tipoestado_id number;
begin 
  select id_tipo_estado into tipoestado_id
  from tipo_estado
  where lower(descricao) like lower(descr);
  
  return tipoestado_id;
exception 
  when no_data_found then 
    return null;
--    raise_application_error(-20813, 'Tipo de estado inexistente');
end;
/

create or replace function obtem_id_tipo_estado_atual (pedido_id number) return number
is 
  tipoestado_id number;
begin
  select tipo_estado_id into tipoestado_id 
  from estado 
  where pedido_transp_id = pedido_id
  and data_hora_inicio = (select max(est.data_hora_inicio) from estado est
                          where est.pedido_transp_id = pedido_id);
                          
  return tipoestado_id;
exception
  when no_data_found then 
    return null;
--    raise_application_error(-20805, 'Codigo de pedido de transporte inexistente');
end;
/

create or replace function obtem_tp_merc_mais_existente (cod_armazem number) return number
is
  tp_merc_id number;
  id_tp_estado_em_armazem number;
begin 
  id_tp_estado_em_armazem := obtem_id_tipo_estado('em_armazem');
  
  select tpm into tp_merc_id
  from (
    select pt.tipo_mercadoria_id as tpm, 
      count(*) as qtd
    from pedido_transp pt
    join em_armazem ea on ea.pedido_transp_id = pt.id_pedido
    where ea.armazem_id = cod_armazem
      and obtem_id_tipo_estado_atual(pt.id_pedido) = id_tp_estado_em_armazem
    group by pt.tipo_mercadoria_id
    order by qtd desc
  ) where rownum = 1;
  
  return tp_merc_id;
exception
  when no_data_found then
    return 1;
end;
/

create or replace function obtem_id_troco (cod_armazem_origem number, cod_armazem_destino number) return number 
is
  troco_id number;
  arm_origem number;
  arm_destino number;
begin 

  select tid into troco_id
  from (
    select id_troco as tid
    from troco
    where armazem_id_part = cod_armazem_origem 
      and armazem_id_cheg = cod_armazem_destino
    order by tempomax 
  ) where rownum = 1;
  
  return troco_id;
exception
  when no_data_found then
    raise_application_error(-20808, 'Codigo de troco inexistente');
end;
/


create or replace function seleciona_motorista (cod_armazem_origem number) return number
is
  motorista number;
begin 
  select mid into motorista
  from (
    select v.motorista_id as mid
    from viagem v
    join veiculo_armazem va on va.veiculo_id = v.veiculo_id
    join chegada c on c.viagem_id = v.id_viagem
    where va.armazem_id = cod_armazem_origem
    and disponivel = 1
    order by c.datahora_fim 
  )
  where rownum = 1;
  /*
    a ordenacao � feita pela data de chegada ao inv�s da data da tabela veiculo_armazem 
      pois nesse caso estariamos a apanhar qualquer condutor que tivesse conduzido aquele 
      veiculo com destino naquele armazem a qualquer altura
    assim estamos a ordenar corretamente pois estamos a usar a data da propria viagem 
    */
    
exception 
  when no_data_found then
    raise_application_error(-20813, 'Nao ha motoristas disponiveis neste armazem');
end;
/


create or replace function obtem_proximo_horario (tipo_mercadoria number, cod_troco number) return number
is
  horario_id number;
  dia_atual number := to_char(sysdate, 'D');
  hora_atual varchar2(8) := to_char(sysdate, 'hh:mm:ss');
  
begin
  begin
    select id_horario into horario_id
    from (
      select id_horario 
      from horario
      where tipo_merc_id = tipo_mercadoria
        and troco_id = cod_troco
        and dia_semana = dia_atual
        and hora_marcada > hora_atual
      order by hora_marcada
    ) where rownum = 1;
    
    return horario_id;
  exception
    when no_data_found then null;
  end;
  
  for i in 1..6 loop
    begin 
      select id_horario into horario_id
      from (
        select id_horario
        from horario
        where tipo_merc_id = tipo_mercadoria
          and troco_id = cod_troco 
          and dia_semana = mod(dia_atual - 1 + i, 7) + 1
        order by hora_marcada
      ) where rownum = 1;
      return horario_id;
    exception 
      when no_data_found then null;
    end;
  end loop;
  
  raise_application_error(-20814, 'Nenhum horario disponivel encontrado');

end;
/


create or replace function peso_disponivel_viagem (cod_viagem number) return number
is 
  total_peso number;
  usado_peso number;
  disponivel number;
begin
  select ve.capacidade_tara into total_peso
  from veiculo ve 
  join viagem v on v.veiculo_id = ve.id_veiculo
  where v.id_viagem = cod_viagem;
  
  select nvl(sum(pt.peso_pedido), 0) into usado_peso
  from pedido_transp pt
  join viagem_pedido_transp vpt on vpt.pedido_transp_id = pt.id_pedido
    and vpt.viagem_id = cod_viagem;
    
  disponivel := total_peso - usado_peso;
  
  return disponivel;
exception 
  when no_data_found then 
    return null;
end;
/


-- ALINEA A
create or replace function proxima_viagem_com_espaco_data(cod_pedido number, cod_troco number, data_partida timestamp) return number
is
  v_peso_pedido number;
  v_volume_pedido number;
  v_id_viagem number;
  troco number;
  
  pedido_nao_encontrado exception;
  pragma exception_init(pedido_nao_encontrado, -20805);
  troco_inexistente exception;
  pragma exception_init (troco_inexistente, -20808);

begin
  verifica_pedido(cod_pedido);
  verifica_troco(cod_troco);
  
  select peso_pedido, volume_pedido into v_peso_pedido, v_volume_pedido
  from pedido_transp
  where id_pedido = cod_pedido;
  
  begin
    select troco_id into troco
    from viagem
    where troco_id = cod_troco
    and part_prevista > data_partida;
  exception
    when no_data_found then 
      raise_application_error(-20801, 'Nao estao previstas viagens para esse troco');
  end;
    
  select min(v.id_viagem) into v_id_viagem
  from viagem v
  join veiculo ve on v.veiculo_id = ve.id_veiculo
  where v.troco_id = cod_troco
    and (ve.capacidade_tara - v.peso_transp) >= v_peso_pedido
    and (ve.volume_max - v.volume_transp) >= v_volume_pedido
    and v.part_prevista > data_partida;
  
  return v_id_viagem;

exception
  when pedido_nao_encontrado then
    raise_application_error(-20805, 'Codigo de pedido transporte inexistente');
  when troco_inexistente then
    raise_application_error(-20808, 'Codigo de troco inexistente');
  when no_data_found then
      raise_application_error(-20802, 'Nao existe uma viagem para esse troco com capacidade para transportar o pedido');
  when others then raise;
end;
/




-- funcao que devolve o id do estado atual
create or replace function obtem_id_estado_atual (pedido_id number) return number
is
  -- Declara��o de vari�vel local para armazenar o ID do estado atual
  estado_atual number;
begin
  -- In�cio do bloco de tratamento
  -- Seleciona o ID do estado mais recente para o pedido espec�fico
  select id_estado into estado_atual
  from estado 
  where pedido_trans_id_pedido = pedido_id
  and data_hora_inicio = (select max(data_hora_inicio) from estado
                          where pedido_trans_id_pedido = pedido_id);
  
  -- Retorna o ID do estado atual
  return estado_atual;
  
exception
  -- Tratamento de exce��o para o caso em que n�o h� dados encontrados
  when no_data_found then 
    -- Retorna NULL se n�o houver dados encontrados
    return null;
--    raise_application_error(-20805, 'Codigo de pedido de transporte inexistente');
end;
/

  

-- funcao para obter armazem atual
create or replace function obtem_armazem_atual (pedido_id number) return varchar2
is
  -- Declara��o de vari�vel local para armazenar o ID do armaz�m atual
  armazem_atual varchar2(30);
begin 
    -- In�cio do bloco de tratamento
    -- Seleciona o ID do armaz�m onde o pedido est� atualmente
    select em.armazem_id_armazem into armazem_atual
    from pedido_transporte pt
    join em_armazem em on pt.id_pedido = em.pedido_trans_id_pedido
    join estado e on pt.id_pedido = e.pedido_trans_id_pedido
    where em.pedido_trans_id_pedido = pedido_id
    and e.tipo_estado_id_tipo_est = obtem_id_tipo_estado('em_armazem')
    and e.data_hora_inicio = (select max(data_hora_inicio)
                              from estado
                              where pedido_trans_id_pedido = pedido_id)
    and datahora = (select max(datahora)
                    from em_armazem
                    where pedido_trans_id_pedido = pedido_id);
    
    -- Retorna o ID do armaz�m atual
    return armazem_atual;
    
exception
  -- Tratamento de exce��o para o caso em que n�o h� dados encontrados
  when no_data_found then 
    -- Retorna NULL se n�o houver dados encontrados
    return null;
--    raise_application_error(-20811, 'Pedido nao est� no armaz�m');
end;
/



create or replace function obtem_id_tipo_estado (descr varchar2) return number
is
  tipoestado_id number;
begin 
  select id_tipo_estado into tipoestado_id
  from tipo_estado
  where lower(descricao) = lower(descr);
  
  return tipoestado_id;
exception 
  when no_data_found then 
    return null;
--    raise_application_error(-20813, 'Tipo de estado inexistente');
end;
/
  
-- obtem id de tipo de mercadoria passado 
create or replace function obtem_id_tp_mercadoria (descr varchar2) return number
is 
  tpmercadoria_id number;
begin
  select id_tpmercadoria into tpmercadoria_id
  from tipo_mercadoria
  where lower(descricao) = lower(descr);
  
  return tpmercadoria_id;
exception
  when no_data_found then 
    return null;
--    raise_application_error(-20803, 'Tipo mercadoria inexistente');
end;
/


-- calcula a duracao de uma viagem dado o seu id
create or replace function calcula_duracao_viagem (viagem_id number) return number
is
  duracao number;
begin 
  select round(to_number(to_char(c.datahora_fim - p.datahora_inicio)) * 24 * 60, 0) into duracao
  from viagem v
  join partida p on v.id_viagem = p.viagem__id_viagem
  join chegada c on v.id_viagem = c.viagem__id_viagem
  where v.id_viagem = viagem_id;
  
  return duracao;
exception 
  when no_data_found then 
    raise_application_error(-20812, 'A viagem ainda nao foi efetuada');
end;
/

-- funcao para verificar se viagem ja terminou
create or replace function viagem_concluida (viagem_id number) return number
is 
  concluida number;
begin 
  select 1 into concluida 
  from viagem v
  join partida p on v.id_viagem = p.viagem__id_viagem
  join chegada c on v.id_viagem = c.viagem__id_viagem 
  where v.id_viagem = viagem_id;
  
  return concluida;
exception 
  when no_data_found then 
    return 0;
end;
/


-- funcao para verificar se pedido est� concluido
create or replace function pedido_concluido (pedido_id number) return number
is
  concluido number;
begin 
  select count(*) into concluido
  from pedido_transporte pt
  join estado e on pt.id_pedido = e.pedido_trans_id_pedido
  where pt.id_pedido = pedido_id
  and e.tipo_estado_id_tipo_est in (obtem_id_tipo_estado('entregue'), 
    obtem_id_tipo_estado('cancelado')); 
  
  return concluido;
exception 
  when no_data_found then 
    return 0;
end;
/


-- funcao conta n de viagens de um pedido cujo id � passado por argumento
create or replace function conta_viagens_pedido (pedido_id number) return number
is  
  num_viagens number;
begin
  if pedido_concluido(pedido_id) > 0 then
    select count(*) into num_viagens 
    from viagem__pedido_transporte 
    where pedido_trans_id_pedido = pedido_id;
    
    return num_viagens;
  end if;
exception 
  when no_data_found then
    return 0;
--    raise_application_error(-20814, 'Pedido por concluir');
end;
/ 


-- obtem a descricao de um tipo de mercadoria passado por argumento
create or replace function obtem_descricao_tpmerc (tpmerc_id number) return varchar2
is 
  descr varchar2(20);
begin 
  select descricao into descr 
  from tipo_mercadoria 
  where id_tpmercadoria = tpmerc_id;
   
  return descr;
exception 
  when no_data_found then 
    raise_application_error(-20803, 'codigo tipo de mercadoria inexistente');
end;
/


-- devolve o n de transportes de um determinado tipo de mercadoria
create or replace function n_transportes_tpmercadoria(tpmerc_id number) return number
is 
  n number;
begin 
  select count(*) into n
  from pedido_transporte
  where tipo_merc_id_tpmerc = tpmerc_id;
  
  return n;
exception
  when no_data_found then 
    return null;
--    raise_application_error(-20817, 'Nao existe nenhum pedido desse tipo');
end;
/























