

-- Criação das tabelas
CREATE TABLE pedido_transp (
	id_pedido					  NUMBER(7,0) NOT NULL,
	data_registo				TIMESTAMP NOT NULL,
	data_limite					TIMESTAMP,
	peso_pedido					NUMBER(4,2) NOT NULL,
	volume_pedido				NUMBER(4,2) NOT NULL,
	morada_origem				VARCHAR2(80) NOT NULL,
	morada_destino			VARCHAR2(80) NOT NULL,
	armazem_id_recolha	NUMBER(3,0) NOT NULL,
	armazem_id_entrega	NUMBER(3,0) NOT NULL,
	tipo_mercadoria_id	NUMBER(2,0) NOT NULL,
	tipo_servico_id			NUMBER(2,0) NOT NULL,
	cliente_id					NUMBER(4,0) NOT NULL,
	PRIMARY KEY(id_pedido)
);

CREATE TABLE viagem (
	id_viagem					  NUMBER(8,0) NOT NULL,
	tipo_viagem					VARCHAR2(15) NOT NULL,
	volume_transp				NUMBER(8,2) NOT NULL,
	peso_transp					NUMBER(8,2) NOT NULL,
	cheg_prevista				TIMESTAMP,
	part_prevista				TIMESTAMP,
	motorista_id				NUMBER(3,0) NOT NULL,
	veiculo_id					NUMBER(3,0) NOT NULL,
	troco_id					  NUMBER(3,0) NOT NULL,
	PRIMARY KEY(id_viagem)
);

CREATE TABLE troco (
	id_troco					  NUMBER(3,0) NOT NULL,
	distancia					  NUMBER(4,2) NOT NULL,
	tempomedio				  NUMBER(4,2) NOT NULL,
	tempomax					  NUMBER(4,2) NOT NULL,
	armazem_id_part		  NUMBER(4,0) NOT NULL,
	armazem_id_cheg		  NUMBER(4,0) NOT NULL,
  descricao           VARCHAR2(50) NOT NULL,
	PRIMARY KEY(id_troco)
);

CREATE TABLE armazem (
	id_armazem					NUMBER(4,0),
	codigo					  	VARCHAR2(25) NOT NULL,
	localizacao					VARCHAR2(80) NOT NULL,
	tipo_armazem				VARCHAR2(15) NOT NULL,
	cap_total					  NUMBER(6,2) NOT NULL,
	cap_disponivel			NUMBER(8,2) NOT NULL,
	latitude					  NUMBER(2,6) NOT NULL,
	longitude					  NUMBER(2,6) NOT NULL,
	PRIMARY KEY(id_armazem)
);

CREATE TABLE veiculo (
	id_veiculo					NUMBER(3,0) NOT NULL,
	tipo_veiculo				VARCHAR2(20) NOT NULL,
	capacidade_tara			NUMBER(4,2) NOT NULL,
	volume_max					NUMBER(4,2) NOT NULL,
	matricula					  VARCHAR2(8) NOT NULL,
	marca						    VARCHAR2(15) NOT NULL,
	modelo						  VARCHAR2(20) NOT NULL,
	tipo_merc_id		    NUMBER(2,0) NOT NULL,
	PRIMARY KEY (id_veiculo)
);

CREATE TABLE cliente (
	id_cliente			    NUMBER(4,0) NOT NULL,
	nome						    VARCHAR2(40) NOT NULL,
	morada					    VARCHAR2(80) NOT NULL,
	telefone				    VARCHAR2(15) NOT NULL,
	email						    VARCHAR2(30) NOT NULL,
	PRIMARY KEY(id_cliente)
);

CREATE TABLE estado (
	data_hora_inicio		TIMESTAMP NOT NULL,
	tipo_estado_id			NUMBER(2,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL
);

CREATE TABLE tipo_servico (
	id_tiposervico		  NUMBER(2,0) NOT NULL,
	descricao					  VARCHAR2(25),
	prazo_maximo			  NUMBER(2,0) NOT NULL,
	PRIMARY KEY(id_tiposervico)
);

CREATE TABLE motorista (
	id_motorista		    NUMBER(3,0) NOT NULL,
	nome						    VARCHAR2(40) NOT NULL,
	morada					    VARCHAR2(80) NOT NULL,
	telefone				    VARCHAR2(15) NOT NULL,
	email						    VARCHAR2(30) NOT NULL,
	nif							    NUMBER(9,0) NOT NULL,
  disponivel          NUMBER(1,0) DEFAULT 1 NOT NULL,
	PRIMARY KEY(id_motorista)
);

CREATE TABLE tipo_mercadoria (
	id_tpmercadoria     NUMBER(2,0) NOT NULL,
	descricao					  VARCHAR2(20) NOT NULL,
	PRIMARY KEY(id_tpmercadoria)
);

CREATE TABLE horario (
	id_horario				  NUMBER(3,0) NOT NULL,
	dia_semana					NUMBER(1,0) NOT NULL,
	hora_marcada				VARCHAR2(9) NOT NULL,
	troco_id			      NUMBER(3,0) NOT NULL,
  tipo_merc_id        NUMBER(2,0) NOT NULL,
	PRIMARY KEY (id_rota)
);

CREATE TABLE tipo_estado (
	id_tipo_estado			NUMBER(3,0) NOT NULL,
	descricao					  VARCHAR2(20) NOT NULL,
	PRIMARY KEY(id_tipo_estado)
);

CREATE TABLE entrega (
	id_entrega					NUMBER(7,0) NOT NULL,
	data_entrega				TIMESTAMP NOT NULL,
	armazem_id					NUMBER(4,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL,
	PRIMARY KEY(id_entrega)
);

CREATE TABLE recolha (
	id_recolha					NUMBER(7,0) NOT NULL,
	data_recolha				TIMESTAMP NOT NULL,
	armazem_id					NUMBER(4,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL,
	PRIMARY KEY(id_recolha)
);

CREATE TABLE cancelamento (
	id_cancelamento			NUMBER(7,0) NOT NULL,
	data_cancel					TIMESTAMP NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL,
	PRIMARY KEY(id_cancelamento)
);

CREATE TABLE partida (
	id_partida					NUMBER(8,0) NOT NULL,
	datahora_inicio			TIMESTAMP NOT NULL,
	viagem_id					  NUMBER(8,0) NOT NULL,
	PRIMARY KEY(id_partida)
);

CREATE TABLE chegada (
	id_chegada					NUMBER(8,0) NOT NULL,
	datahora_fim				TIMESTAMP NOT NULL,
	total_kms					  NUMBER(8,2),
	viagem_id					  NUMBER(8,0) NOT NULL,
	PRIMARY KEY(id_chegada)
);

CREATE TABLE em_armazem (
	datahora					  TIMESTAMP NOT NULL,
	armazem_id					NUMBER(8,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL
);

CREATE TABLE fora_armazem (
	data_hora				  	TIMESTAMP NOT NULL,
	armazem_id					NUMBER(4,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL
);

CREATE TABLE viagem_pedido_transp (
	viagem_id					  NUMBER(8,0) NOT NULL,
	pedido_transp_id		NUMBER(7,0) NOT NULL,
	PRIMARY KEY(pedido_transp_id)
);

CREATE TABLE horario_viagem (
	horario_id        	NUMBER(3,0) NOT NULL,
	viagem_id					  NUMBER(8,0) NOT NULL,
	PRIMARY KEY(viagem_id)
);

CREATE TABLE veiculo_armazem (
	veiculo_id					NUMBER(3,0) NOT NULL,
	armazem_id					NUMBER(4,0) NOT NULL,
  data_hora           TIMESTAMP NOT NULL,
	PRIMARY KEY(veiculo_id)
);

-- Definições de chave estrangeira
-- ALTER TABLE pedido_transp ADD UNIQUE (armazem_id_recolha, armazem_id_entrega);
ALTER TABLE pedido_transp ADD CONSTRAINT pt_fk1 FOREIGN KEY (armazem_id_recolha) REFERENCES armazem(id_armazem);
ALTER TABLE pedido_transp ADD CONSTRAINT pt_fk2 FOREIGN KEY (armazem_id_entrega) REFERENCES armazem(id_armazem);
ALTER TABLE pedido_transp ADD CONSTRAINT pt_fk3 FOREIGN KEY (tipo_mercadoria_id) REFERENCES tipo_mercadoria(id_tpmercadoria);
ALTER TABLE pedido_transp ADD CONSTRAINT pt_fk4 FOREIGN KEY (tipo_servico_id) REFERENCES tipo_servico(id_tiposervico);
ALTER TABLE pedido_transp ADD CONSTRAINT pt_fk5 FOREIGN KEY (cliente_id) REFERENCES cliente(id_cliente);

ALTER TABLE viagem ADD CONSTRAINT viagem_fk1 FOREIGN KEY (motorista_id) REFERENCES motorista(id_motorista);
ALTER TABLE viagem ADD CONSTRAINT viagem_fk2 FOREIGN KEY (veiculo_id) REFERENCES veiculo(id_veiculo);
ALTER TABLE viagem ADD CONSTRAINT viagem_fk3 FOREIGN KEY (troco_id) REFERENCES troco(id_troco);

ALTER TABLE troco ADD CONSTRAINT troco_fk1 FOREIGN KEY (armazem_id_part) REFERENCES armazem(id_armazem);
ALTER TABLE troco ADD CONSTRAINT troco_fk2 FOREIGN KEY (armazem_id_cheg) REFERENCES armazem(id_armazem);

ALTER TABLE veiculo ADD CONSTRAINT veic_fk1 FOREIGN KEY (tipo_merc_id) REFERENCES tipo_mercadoria(id_tpmercadoria);

ALTER TABLE motorista ADD CONSTRAINT chk_disponivel CHECK (disponivel IN (0,1));

ALTER TABLE estado ADD CONSTRAINT est_fk1 FOREIGN KEY (tipo_estado_id) REFERENCES tipo_estado(id_tipo_estado);
ALTER TABLE estado ADD CONSTRAINT est_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE horario ADD CONSTRAINT hor_fk1 FOREIGN KEY (troco_id) REFERENCES troco(id_troco);
ALTER TABLE horario ADD CONSTRAINT hor_tp_mer_fk2 FOREIGN KEY (tipo_merc_id) REFERENCES tipo_mercadoria(id_tpmercadoria);

ALTER TABLE entrega ADD CONSTRAINT ent_fk1 FOREIGN KEY (armazem_id) REFERENCES armazem(id_armazem);
ALTER TABLE entrega ADD CONSTRAINT ent_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE recolha ADD CONSTRAINT rec_fk1 FOREIGN KEY (armazem_id) REFERENCES armazem(id_armazem);
ALTER TABLE recolha ADD CONSTRAINT rec_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE cancelamento ADD CONSTRAINT can_fk1 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE partida ADD UNIQUE (viagem_id);
ALTER TABLE partida ADD CONSTRAINT part_fk1 FOREIGN KEY (viagem_id) REFERENCES viagem(id_viagem);

ALTER TABLE chegada ADD UNIQUE (viagem_id);
ALTER TABLE chegada ADD CONSTRAINT cheg_fk1 FOREIGN KEY (viagem_id) REFERENCES viagem(id_viagem);

ALTER TABLE em_armazem ADD CONSTRAINT em_arm_fk1 FOREIGN KEY (armazem_id) REFERENCES armazem(id_armazem);
ALTER TABLE em_armazem ADD CONSTRAINT em_arm_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE fora_armazem ADD CONSTRAINT for_arm_fk1 FOREIGN KEY (armazem_id) REFERENCES armazem(id_armazem);
ALTER TABLE fora_armazem ADD CONSTRAINT for_arm_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE viagem_pedido_transp ADD CONSTRAINT vpt_fk1 FOREIGN KEY (viagem_id) REFERENCES viagem(id_viagem);
ALTER TABLE viagem_pedido_transp ADD CONSTRAINT vpt_fk2 FOREIGN KEY (pedido_transp_id) REFERENCES pedido_transp(id_pedido);

ALTER TABLE horario_viagem ADD CONSTRAINT hv_fk1 FOREIGN KEY (horario_id) REFERENCES horario(id_horario);
ALTER TABLE horario_viagem ADD CONSTRAINT hv_fk2 FOREIGN KEY (viagem_id) REFERENCES viagem(id_viagem);

ALTER TABLE veiculo_armazem ADD UNIQUE (veiculo_id);
ALTER TABLE veiculo_armazem ADD CONSTRAINT va_fk1 FOREIGN KEY (veiculo_id) REFERENCES veiculo(id_veiculo);
ALTER TABLE veiculo_armazem ADD CONSTRAINT va_fk2 FOREIGN KEY (armazem_id) REFERENCES armazem(id_armazem);