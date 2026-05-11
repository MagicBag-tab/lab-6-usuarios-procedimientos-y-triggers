# Laboratorio 6: Usuarios, Procedimientos y Triggers

En este laboratorio se busca completar 14 misiones para poder practicar el uso de Usuarios, Roles, Procedimientos y Triggers.

## Usuarios y Roles

### Misión 1
*Problema:* Los vendedores están modificando productos por error, alterando precios.

*Misión:* Crear un rol para vendedores que permita consultar productos e insertar pedidos y
detalles, pero que no pueda modificar productos. Asignar al menos dos usuarios vendedores
a este rol.

### Misión 2
*Problema:* La empresa contrata a un auditor externo que debe revisar todos los datos sin
modificar nada. El contrato es por 2 meses.

*Misión:* Crear el usuario auditor con los permisos mínimos necesarios para que pueda realizar su trabajo durante el tiempo indicado (2 meses). 

### Misión 3
*Problema:* Los vendedores han contactado a clientes de manera excesiva, generando quejas.

*Misión:* Revocar a los vendedores el acceso a los campos de contacto del cliente (email y telefono).

### Misión 4
*Problema:* Los vendedores trabajan con clientes inactivos, generando errores en pedidos.

*Misión:* Crear una vista que exponga únicamente los clientes activos, y otorgar acceso a esa vista a los vendedores en lugar de a la tabla directa.

### Misión 5
*Problema:* Los vendedores insertan pedidos manualmente sin ninguna validación.

*Misión:* Revocar a los vendedores el permiso de insertar directamente en la tabla pedido.

## Procedimientos

### Misión 6
*Problema:* El sistema muestra productos sin unidades disponibles, generando frustración en
ventas.

*Misión:* Crear una función o procedimiento que devuelva únicamente los productos con al menos una unidad en inventario.

### Misión 7
*Problema:* Algunos clientes deben reactivarse manualmente de forma inconsistente.

*Misión:*  Crear una función o procedimiento que reciba un identificador de cliente y lo active
si existe y si actualmente está inactivo.

### Misión 8
*Problema:* Se insertan pedidos con productos no disponibles o clientes inactivos.

*Misión:* Crear una función o procedimiento que verifique la disponibilidad del producto y el estado del cliente antes de insertar el pedido. Debe usar transacciones explícitas.

### Misión 9
*Problema:* Existen dos formas de ingresar pedidos: directamente en la tabla o a través del
procedimiento almacenado.

*Misión:* Hacer lo más segura posible la creación de pedidos, combinando los permisos del Bloque 1 con el procedimiento del bloque anterior.

## Triggers

### Misión 10
*Problema:* 

*Misión:* Crear un trigger que impida insertar un detalle de pedido si el producto no tiene unidades en inventario.

### Misión 11
*Problema:* El inventario no se actualiza correctamente después de las ventas.

*Misión:* Crear un trigger que descuente automáticamente las unidades del inventario al insertar un detalle de pedido.

### Misión 12
*Problema:* Los totales de pedidos no coinciden con los productos registrados.

*Misión:* Crear un trigger que calcule y actualice automáticamente el campo total del pedido al insertar un detalle.

### Misión 13
*Problema:* La empresa no sabe cuándo ni cómo cambia el inventario.

*Misión:* Crear un trigger que registre en la tabla auditoria_inventario cada cambio en las unidades de un producto.

### Misión 14
*Problema:* Se han registrado pagos que no coinciden con el total del pedido.

*Misión:* Crear un trigger que valide que el monto de un pago coincida con el total del pedido antes de permitir la inserción.