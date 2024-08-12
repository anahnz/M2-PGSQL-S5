	1. CREATE OR REPLACE FUNCTION crear_cuenta(
	cliente_id int,
	tipo_cuenta varchar,
	saldo decimal(15,2),
	fecha_apertura date,
	estado varchar,
	sucursal_id int
) returns void
as $$
   DECLARE 
   numero_cuenta VARCHAR(40);
   begin
       numero_cuenta := 'ACCT' || LPAD(nextval('seq_numero_cuenta')::TEXT, 10, '0');
       INSERT INTO Cuentas(cliente_id,numero_cuenta,tipo_cuenta,saldo,fecha_apertura,estado, sucursal_id)
       VALUES(cliente_id,numero_cuenta,tipo_cuenta,saldo,fecha_apertura,estado, sucursal_id);
   end;
$$ language plpgsql;

select crear_cuenta('3', 'AHORROS', 850000, '20240722', 'ACTIVO', 1);
CREATE SEQUENCE seq_numero_cuenta START 1;
SELECT * FROM Clientes
SELECT pg_get_serial_sequence('cuentas', 'cuenta_id')
SELECT setval('public.cuentas_cuenta_id_seq', 10)
SELECT pg_get_serial_sequence('cuentas', 'numero_cuenta')

	2. CREATE OR REPLACE FUNCTION actualizar_cliente(
		p_cliente_id int,
		p_direccion varchar,
		p_telefono varchar,
		p_correo varchar
	) returns void
	as $$
	   begin
	       update clientes 
		   set direccion = p_direccion,  
		       telefono = p_telefono, 
			   correo_eletronico = p_correo
		   where cliente_id = p_cliente_id;
		   IF NOT FOUND THEN
	        RAISE NOTICE 'Cliente con ID % no encontrado.', p_cliente_id;
	       END IF;
	   end;
	$$ language plpgsql;
	
	select * from clientes
	select actualizar_cliente(3, 'Calle 40a', '2177462', 'ana_hnz@hotmail.com');
	
	3. CREATE OR REPLACE FUNCTION eliminar_cuenta(
		p_cuenta_id int
	) returns void
	as $$
	   begin
	       delete from cuentas 
		   where cuenta_id = p_cuenta_id;
		   IF NOT FOUND THEN
	        RAISE NOTICE 'Cuenta con ID % no encontrado.', p_cuenta_id;
		   else
		   delete from transacciones 
		   where cuenta_id = p_cuenta_id;
	       END IF;
	   end;
	$$ language plpgsql;
	
	select * from transacciones
	select * from cuentas
	
	select eliminar_cuenta(2)
	
	4. CREATE OR REPLACE FUNCTION transferir_saldo(
		p_numero_cuenta_env varchar,
		p_numero_cuenta_rec varchar,
		p_monto decimal,
		p_fecha timestamp 
	) returns void
	as $$
	   declare
	     w_cuenta_id int;
		 w_tipo_transaccion constant varchar(15) := 'TRANSFERENCIA';
		 w_descripcion constant varchar(50) := 'TRANSFERENCIA DE FONDOS';
	   begin
	     IF NOT EXISTS (SELECT 1 FROM cuentas WHERE numero_cuenta = p_numero_cuenta_env) THEN
	        RAISE EXCEPTION 'Cuenta de envio % no existe.', p_numero_cuenta_env;
	     END IF;
		 
		 SELECT cuenta_id into w_cuenta_id FROM cuentas WHERE numero_cuenta = p_numero_cuenta_rec;
		 if not found then
	        RAISE EXCEPTION 'Cuenta de recepcion % no existe.', p_numero_cuenta_rec;
	     END IF;
	   
	    begin
	     If (select saldo from cuentas where numero_cuenta = p_numero_cuenta_env) < p_monto then
		   RAISE NOTICE 'Cuenta % con saldo insuficiente para enviar dinero.', p_numero_cuenta_env;
		 end if;
		 
		 update cuentas set saldo = saldo + p_monto
		 where numero_cuenta = p_numero_cuenta_rec;
		 
		 update cuentas set saldo = saldo - p_monto
		 where numero_cuenta = p_numero_cuenta_env;
		 
		 INSERT INTO Transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
		 VALUES(w_cuenta_id, w_tipo_transaccion, p_monto, p_fecha, w_descripcion);
	   
	    end;
	   end;	
	$$ language plpgsql;
	
	select * from transacciones
	select * from cuentas
	
	select transferir_saldo('00642831509','00342831509', 50000, '20240811') 
	
	5. CREATE OR REPLACE FUNCTION agregar_transaccion(
		p_numero_cuenta varchar,
		p_tipo_transaccion varchar,
		p_monto decimal,
		p_fecha timestamp,
		p_descripcion varchar
	) returns void
	as $$
	   declare
	     w_cuenta_id int;  
	   begin
	     IF p_tipo_transaccion <> 'RETIRO' AND p_tipo_transaccion <> 'DEPOSITO' THEN 
		   RAISE EXCEPTION 'Tipo de transaccion  % no valida.', p_tipo_transaccion;
		 END IF;
		 SELECT cuenta_id into w_cuenta_id FROM cuentas WHERE numero_cuenta = p_numero_cuenta;
		 IF not found then
		   RAISE EXCEPTION 'Cuenta % no existe.', p_numero_cuenta;
		 END IF;
	   
	     begin 
		   if p_tipo_transaccion = 'RETIRO' then
		     if (select saldo from cuentas where numero_cuenta = p_numero_cuenta) < p_monto then
			   RAISE EXCEPTION 'Cuenta % con saldo insuficiente.', p_numero_cuenta;
			 else   
		       update cuentas set saldo = saldo - p_monto
		       where numero_cuenta = p_numero_cuenta;
			   INSERT INTO Transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
		       VALUES(w_cuenta_id, p_tipo_transaccion, p_monto, p_fecha, p_descripcion);
			 end if;
		   end if;
		 
		   if p_tipo_transaccion = 'DEPOSITO' then
		     update cuentas set saldo = saldo + p_monto
	         where numero_cuenta = p_numero_cuenta;
			 INSERT INTO Transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
		     VALUES(w_cuenta_id, p_tipo_transaccion, p_monto, p_fecha, p_descripcion);
		   end if;
		 end;  
	   end;	
	$$ language plpgsql;
	
	select * from transacciones
	select * from cuentas
	
	select agregar_transaccion('00442831520', 'PAGO', 1850000, '20240811', 'RETIRO PAGO CUOTA APTO')
	
	6. CREATE OR REPLACE FUNCTION saldo_total(
		p_cliente_id int 
	) returns decimal(15,2)
	as $$
	   declare
	     w_saldo decimal;  
	   begin
		 SELECT 1 FROM cuentas WHERE cliente_id = p_cliente_id;
		 IF not found then
		   RAISE EXCEPTION 'Cliente % sin cuentas.', p_cliente_id;
		 else
		   select sum(saldo) into w_saldo from cuentas where cliente_id = p_cliente_id;
		   
		 END IF;
		 return w_saldo;
	   end;	
	$$ language plpgsql;
	
	select * from transacciones
	select * from cuentas
	select * from 
	
	select saldo_total(2)
	
	7. CREATE OR REPLACE FUNCTION reporte_transacciones(
	    p_fecha_inicio TIMESTAMP,
	    p_fecha_fin TIMESTAMP
	)
	RETURNS TABLE (
	    t_transaccion_id INT,
	    t_cuenta_id INT,
	    t_tipo_transaccion VARCHAR(15),
	    t_monto DECIMAL(15, 2),
	    t_fecha_transaccion TIMESTAMP
	) AS $$
	BEGIN
	    RETURN QUERY
	    SELECT transaccion_id, cuenta_id, tipo_transaccion, monto, fecha_transaccion
	    FROM transacciones
	    WHERE fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin
	    ORDER BY fecha_transaccion;
	END;
	$$ LANGUAGE plpgsql;
	
	select reporte_transacciones('20000101', '20240811')
