/*
 * Laboratorio 6: Usuarios, Procedimientos y Triggers
 * Sarah Rachel Estrada Bonilla 24347
*/


---------------------------------
-- Bloque 1: Usuarios y Rolers --
---------------------------------

-- Misión 1
-- Crear un rol para vendedores que permita consultar productos e insertar pedidos y detalles, pero que no pueda modificar productos. Asignar al menos dos usuarios vendedores a este rol.

	-- 1. Crear Grupo
	CREATE ROLE vendedores;
	
	-- 2. Crear privilegios y asignarlos al grupo
	GRANT SELECT ON TABLE productos TO vendedores;
	GRANT INSERT ON TABLE pedidos TO vendedores;
	GRANT INSERT ON TABLE detalle_pedido TO vendedores;
	
	-- 3. Permiso en el squema
	GRANT USAGE ON SCHEMA public TO vendedores;
	
	-- 4. Crear a los Usuarios
	CREATE ROLE Marie LOGIN PASSWORD 'vendedor_0001';
	CREATE ROLE Sheldon LOGIN PASSWORD 'vendedor_0002';	
	
	-- 5. Asignar los usuarios al grupo
	GRANT vendedores TO Marie;
	GRANT vendedores TO Sheldon;
	
	-- 6. Verificar que se hayan creado correctamente
	SELECT rolname FROM pg_roles WHERE rolname = 'vendedores';
	SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee = 'vendedores';
	
	-- 7. Conectar a base de datos
	GRANT CONNECT ON DATABASE tienda_db TO vendedores;


-- Misión 2
-- Crear el usuario auditor con los permisos mínimos necesarios para que pueda realizar su trabajo durante el tiempo indicado 
	
	-- 1. Crear usuario con la fecha de dos meses
	CREATE ROLE auditor LOGIN PASSWORD 'auditor_0001' VALID UNTIL '2026-07-10';
	
	-- 2. Crea el privilegio de que el auditor pueda ver todas las tablas 
	GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;
	
	-- 3. Verificación de rol creado y sus privilegios
	SELECT rolname, rolcanlogin, rolsuper FROM pg_roles ORDER BY rolname;
	SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee = 'auditor';
	
	-- 4. Conectar a base de datos 
	GRANT CONNECT ON DATABASE tienda_db TO auditor;
	
-- Misión 3
-- Revocar a los vendedores el acceso a los campos de contacto del cliente (email y telefono).

	-- 1. Los vendedores necesitan permiso para ver la tabla de clientes
	--GRANT SELECT ON TABLE clientes TO vendedores;
	
	-- 2. Remover el que pueda ver el email, el teléfono no existe en la base de datos de Tienda-1
	--REVOKE SELECT (email) ON TABLE clientes FROM vendedores;
	
	-- 1.2 Se pueden otorgar los permisos de una vez sin incluir email
	GRANT SELECT (id_cliente, nombre, activo) ON TABLE clientes TO vendedores;
	
	-- 3. Verificación de permisos
	SELECT grantee, table_name, column_name, privilege_type FROM information_schema.column_privileges  WHERE grantee = 'vendedores';

-- Misión 4
-- Crear una vista que exponga únicamente los clientes activos, y otorgar acceso a esa vista a los vendedores en lugar de a la tabla directa.

	-- 1. Revocar los permisos de la tabla clientes a los vendedores
	REVOKE SELECT (id_cliente, nombre, activo) ON TABLE clientes FROM vendedores;
	
	-- 2. Crear Vista para ver solamente los clientes activos
	CREATE VIEW clientes_activos AS 
	SELECT id_cliente,nombre FROM clientes WHERE activo = TRUE;
	
	-- 3. Asignar al grupo de vendedores que pueda ver la vista
	GRANT SELECT ON clientes_activos TO vendedores;
	
	-- 4. Verificación 
	SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee = 'vendedores';

-- Misión 5
-- Revocar a los vendedores el permiso de insertar directamente en la tabla pedido

	-- 1. Revocar el permiso de insertar en la tabla directamente
	REVOKE INSERT ON TABLE pedidos FROM vendedores;
	
	-- 2. Verificación 
	SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee = 'vendedores';
	

------------------------------
-- Bloque 2: Procedimientos --
------------------------------

-- Misión 6
-- Crear una función o procedimiento que devuelva únicamente los productos con al menos una unidad en inventario.
	
	-- 1. Crear una función, ya que esta devuelve valores, para obtener productos con al menos una unidad en inventario
	CREATE OR REPLACE FUNCTION verificar_productos_con_mas_de_una_unidad()
	RETURNS TABLE(id_producto INT, nombre VARCHAR, precio NUMERIC, stock INT) AS $$
	BEGIN
		RETURN QUERY 
		SELECT productos.id_producto, productos.nombre, productos.precio, productos.stock FROM productos
		WHERE productos.stock >= 1
		ORDER BY productos.id_producto;
	END;
	$$ LANGUAGE plpgsql;
	
	-- 2. Verificación
	SELECT * FROM verificar_productos_con_mas_de_una_unidad();

-- Misión 7
-- Crear una función o procedimiento que reciba un identificador de cliente y lo active si existe y si actualmente está inactivo.

	-- 1. Crear un procedimiento, ya que estamos realizando un update a una fila de cliente
	CREATE OR REPLACE PROCEDURE activar_cliente(p_id_cliente INT)
	LANGUAGE plpgsql AS $$
	DECLARE
	    v_activo BOOLEAN;
	BEGIN
	    -- 1.1 Verificar si el cliente existe y obtener su estado
	    SELECT activo INTO v_activo 
	    FROM clientes 
	    WHERE id_cliente = p_id_cliente;
	    
	    IF NOT FOUND THEN
	        RAISE EXCEPTION 'Cliente % no existe', p_id_cliente;
	    ELSIF v_activo = TRUE THEN
	        RAISE EXCEPTION 'El cliente % ya está activo', p_id_cliente;
	    END IF;
	    
	    -- 1.2 Activar el cliente
	    UPDATE clientes
	    SET activo = TRUE 
	    WHERE id_cliente = p_id_cliente;
	    
	    RAISE NOTICE 'Cliente % activado exitosamente', p_id_cliente;
	END;
	$$;

	-- 2. Verificación con cliente inactivo
	SELECT * FROM clientes WHERE activo = FALSE;
	CALL activar_cliente(6);

-- Misión 8
-- Crear una función o procedimiento que verifique la disponibilidad del producto y el estado del cliente antes de insertar el pedido. Debe usar transacciones explícitas.

	-- 1. Crear un procedimiento, el cual permite controlar transacciones.
	CREATE OR REPLACE PROCEDURE insertar_pedido(p_id_cliente INT, p_id_producto INT, p_cantidad INT)
	LANGUAGE plpgsql AS $$
	DECLARE
	    v_stock INT;
	    v_activo BOOLEAN;
	    v_precio DECIMAL(10,2);
	    v_subtotal DECIMAL(10,2);
	    v_id_pedido INT;
	BEGIN
	    -- 1.1 Transacción 
	    BEGIN
	        -- 1.1.1 Verificar si el cliente existe y está activo
	        SELECT activo INTO v_activo
	        FROM clientes
	        WHERE id_cliente = p_id_cliente;
	
	        IF NOT FOUND THEN
	            RAISE EXCEPTION 'Cliente % no existe', p_id_cliente;
	        END IF;
	
	        IF v_activo = FALSE THEN
	            RAISE EXCEPTION 'El cliente % no está activo', p_id_cliente;
	        END IF;
	
	        -- 1.1.2 Verificar disponibilidad del producto
	        SELECT stock, precio INTO v_stock, v_precio
	        FROM productos
	        WHERE id_producto = p_id_producto;
	
	        IF NOT FOUND THEN
	            RAISE EXCEPTION 'Producto % no existe', p_id_producto;
	        END IF;
	
	        IF v_stock < p_cantidad THEN
	            RAISE EXCEPTION 'Stock insuficiente para producto %', p_id_producto;
	        END IF;
	
	        -- 1.1.3 Calcular subtotal
	        v_subtotal := v_precio * p_cantidad;
	
	        -- 1.1.4 Insertar pedido
	        INSERT INTO pedidos (id_cliente, total)
	        VALUES (p_id_cliente, v_subtotal)
	        RETURNING id_pedido INTO v_id_pedido;
	
	        -- 1.1.5 Insertar detalle del pedido
	        INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal)
	        VALUES (v_id_pedido, p_id_producto, p_cantidad, v_subtotal);
	
	        RAISE NOTICE 'Pedido % insertado correctamente', v_id_pedido;
		
		-- 1.2.1 ROLLBACK si algo falla para que no exista ninguna modificación
	    EXCEPTION
	        WHEN OTHERS THEN
	            RAISE NOTICE 'Error: %, realizando ROLLBACK', SQLERRM;
	            ROLLBACK;
	    END;
	END;
	$$;
	
	-- 2. Verificación con cliente activo y producto con stock
	CALL insertar_pedido(1, 2, 3);
	

-- Misión 9
-- Hacer lo más segura posible la creación de pedidos, combinando los permisos del Bloque 1 con el procedimiento del bloque anterior.

	-- 1. Revocar el permiso de insertar en la tabla de detalle_pedido
	REVOKE INSERT ON TABlE detalle_pedido FROM vendedores;
	
	-- 2. Dar el permiso a los vendedores de poder utilizar el procedimiento de insertar_pedido
	GRANT EXECUTE ON PROCEDURE insertar_pedido(INT, INT, INT) TO vendedores;
	
	-- 3. Verificación de permiso otorgado.
	SELECT routine_name, grantee, privilege_type FROM information_schema.role_routine_grants WHERE grantee = 'vendedores';
	
------------------------
-- Bloque 3: Triggers --
------------------------

-- Misión 10
-- Crear un trigger que impida insertar un detalle de pedido si el producto no tiene unidades en inventario.

	-- 1. Utilizamos nuestra función para verificar unidades dentro de un pedido 
	CREATE OR REPLACE FUNCTION verificar_stock_antes_de_insertar()
	RETURNS TRIGGER AS $$
	DECLARE
	    v_stock INT;
	BEGIN
	    -- 1.1 Obtener el stock actual del producto que se intenta insertar
	    SELECT stock INTO v_stock
	    FROM productos
	    WHERE id_producto = NEW.id_producto;
	
	    -- 1.2 Si no tiene unidades, no se puede insertar
	    IF v_stock <= 0 THEN
	        RAISE EXCEPTION 'No se puede insertar el detalle: producto % sin stock', NEW.id_producto;
	    END IF;
	
	    -- 1.3 Si tiene stock, permitir que se inserte
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;

	-- 2. Creamos Trigger
	CREATE TRIGGER no_insertar_detalle_pedido
		BEFORE INSERT
		ON detalle_pedido
		FOR EACH ROW
		EXECUTE FUNCTION verificar_stock_antes_de_insertar();
		
	-- 3. Verificación si tiene las unidades
	INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal)
	VALUES (1, 8, 1, 400.00);
	
	-- 4. Si no tiene las unidades
	UPDATE productos SET stock = 0 WHERE id_producto = 2;
	INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal)
	VALUES (1, 2, 1, 25.00);

-- Misión 11
-- Crear un trigger que descuente automáticamente las unidades del inventario al insertar un detalle de pedido.
	
	-- 1. Crear función que haga los descuentos
	CREATE OR REPLACE FUNCTION descontar_stock()
	RETURNS TRIGGER AS $$
	BEGIN
	    UPDATE productos
	    SET stock = stock - NEW.cantidad
	    WHERE id_producto = NEW.id_producto;
	
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	-- 2. Crear trigger que realice el descuento luego de insertar un detalle pedido
	CREATE OR REPLACE TRIGGER trigger_descontar_stock
	    AFTER INSERT
	    ON detalle_pedido
	    FOR EACH ROW
	    EXECUTE FUNCTION descontar_stock();
    
    -- 3. Verificación
    SELECT stock FROM productos WHERE id_producto = 3;
	INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal)
	VALUES (1, 3, 3, 75.00);
	SELECT stock FROM productos WHERE id_producto = 3;


-- Misión 12
-- Crear un trigger que calcule y actualice automáticamente el campo total del pedido al insertar un detalle.

	-- 1. Crear función que realice el calculo y el update en el total del pedido al insertar un detalle pedido
	CREATE OR REPLACE FUNCTION actualizar_total_pedido()
	RETURNS TRIGGER AS $$
	BEGIN
	    UPDATE pedidos
	    SET total = total + NEW.subtotal
	    WHERE id_pedido = NEW.id_pedido;
	
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	-- 2. Crear el trigger que realice la operación luego de la inserción
	CREATE OR REPLACE TRIGGER trigger_actualizar_total
	    AFTER INSERT
	    ON detalle_pedido
	    FOR EACH ROW
	    EXECUTE FUNCTION actualizar_total_pedido();
    
    -- 3. Verificación
    SELECT total FROM pedidos WHERE id_pedido = 1;
	INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal)
	VALUES (1, 3, 1, 45.00);
	SELECT total FROM pedidos WHERE id_pedido = 1;

-- Misión 13
-- Crear un trigger que registre en la tabla auditoria_inventario cada cambio en las unidades de un producto.

	-- 1. Función para que se registre automáticamente cada cambio de unidades en la tabla de auditoria_inventario
	CREATE OR REPLACE FUNCTION registrar_auditoria_stock()
	RETURNS TRIGGER AS $$
	BEGIN
	    -- 1.1 Solo registrar si el stock realmente cambió
	    IF OLD.stock <> NEW.stock THEN
	        INSERT INTO auditoria_stock (id_producto, stock_anterior, stock_nuevo)
	        VALUES (NEW.id_producto, OLD.stock, NEW.stock);
	    END IF;
	
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	-- 2. Crear el trigger para ejecutar la función cada vez que cambie el stock de un producto
	CREATE OR REPLACE TRIGGER trigger_auditoria_stock
	    AFTER UPDATE
	    ON productos
	    FOR EACH ROW
	    EXECUTE FUNCTION registrar_auditoria_stock();
	    
	-- 3. Verificación
	SELECT * FROM auditoria_stock;
	UPDATE productos SET stock = 5 WHERE id_producto = 1;
	SELECT * FROM auditoria_stock;
	
-- Misión 14
-- Crear un trigger que valide que el monto de un pago coincida con el total del pedido antes de permitir la inserción.

	-- 1. Crear función que valide que el monto de pago sea igual al total del pedido antes de la inserción
	CREATE OR REPLACE FUNCTION validar_monto_pago()
	RETURNS TRIGGER AS $$
	DECLARE
	    v_total DECIMAL(10,2);
	BEGIN
	    -- 1.1 Obtener el total del pedido
	    SELECT total INTO v_total
	    FROM pedidos
	    WHERE id_pedido = NEW.id_pedido;
	
	    IF NOT FOUND THEN
	        RAISE EXCEPTION 'Pedido % no existe', NEW.id_pedido;
	    END IF;
	
	    -- 1.2 Validar que el monto coincida con el total
	    IF NEW.monto <> v_total THEN
	        RAISE EXCEPTION 'El monto % no coincide con el total del pedido %', 
	        NEW.monto, v_total;
	    END IF;
	
	    RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;

	-- 2. Creación del trigger antes de la inserción
	CREATE OR REPLACE TRIGGER trigger_validar_pago
	    BEFORE INSERT
	    ON pagos
	    FOR EACH ROW
	    EXECUTE FUNCTION validar_monto_pago();

	-- 3. Verificación si es correcta la inserción 
	INSERT INTO pagos (id_pedido, monto)
	VALUES (1, 1295.00);
	
	-- 4. Verificación si es incorrecto 
	INSERT INTO pagos (id_pedido, monto)
	VALUES (1, 500.00);