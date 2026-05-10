-- =========================================
-- BASE DE DATOS
-- =========================================

DROP DATABASE IF EXISTS tienda_db;
CREATE DATABASE tienda_db;


-- =========================================
-- TABLAS
-- =========================================

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    precio DECIMAL(10,2),
    stock INT
);

CREATE TABLE pedidos (
    id_pedido SERIAL PRIMARY KEY,
    id_cliente INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_pedido (
    id_detalle SERIAL PRIMARY KEY,
    id_pedido INT,
    id_producto INT,
    cantidad INT,
    subtotal DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE pagos (
    id_pago SERIAL PRIMARY KEY,
    id_pedido INT,
    monto DECIMAL(10,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

CREATE TABLE auditoria_stock (
    id_auditoria SERIAL PRIMARY KEY,
    id_producto INT,
    stock_anterior INT,
    stock_nuevo INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- DATOS
-- =========================================

INSERT INTO clientes (nombre, email, activo) VALUES
('Ana Torres', 'ana@mail.com', TRUE),
('Luis Pérez', 'luis@mail.com', TRUE),
('María Gómez', 'maria@mail.com', TRUE),
('Carlos Ruiz', 'carlos@mail.com', TRUE),
('Sofía Díaz', 'sofia@mail.com', TRUE),
('Pedro Castillo', 'pedro@mail.com', FALSE),
('Lucía Herrera', 'lucia@mail.com', TRUE),
('Jorge Mendoza', 'jorge@mail.com', TRUE),
('Valentina Rojas', 'vale@mail.com', TRUE),
('Diego Silva', 'diego@mail.com', TRUE);

INSERT INTO productos (nombre, precio, stock) VALUES
('Laptop', 1200.00, 10),
('Mouse', 25.00, 50),
('Teclado', 45.00, 30),
('Monitor', 300.00, 15),
('Auriculares', 80.00, 25),
('Webcam', 60.00, 20),
('Silla Gamer', 250.00, 8),
('Escritorio', 400.00, 5),
('USB 64GB', 15.00, 100),
('Disco SSD 1TB', 150.00, 12);

INSERT INTO pedidos (id_cliente, fecha, total) VALUES
(1, CURRENT_TIMESTAMP, 1250.00),
(2, CURRENT_TIMESTAMP, 70.00),
(3, CURRENT_TIMESTAMP, 300.00),
(4, CURRENT_TIMESTAMP, 95.00),
(5, CURRENT_TIMESTAMP, 1500.00);

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal) VALUES
(1, 1, 1, 1200.00),
(1, 2, 2, 50.00),
(2, 3, 1, 45.00),
(2, 2, 1, 25.00),
(3, 4, 1, 300.00),
(4, 5, 1, 80.00),
(4, 9, 1, 15.00),
(5, 1, 1, 1200.00),
(5, 7, 1, 250.00),
(5, 2, 2, 50.00);

INSERT INTO pagos (id_pedido, monto) VALUES
(1, 1250.00),
(2, 70.00),
(3, 300.00),
(4, 95.00),
(5, 1500.00);

INSERT INTO auditoria_stock (id_producto, stock_anterior, stock_nuevo) VALUES
(1, 12, 10),
(2, 60, 50),
(3, 35, 30);

-- =========================================
-- USUARIOS (POSTGRESQL)
-- =========================================

CREATE USER app_user WITH PASSWORD '1234';
CREATE USER analista WITH PASSWORD '1234';

GRANT CONNECT ON DATABASE tienda_db TO app_user;
GRANT CONNECT ON DATABASE tienda_db TO analista;

GRANT USAGE ON SCHEMA public TO app_user, analista;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista;

GRANT SELECT, INSERT ON pedidos TO app_user;
GRANT SELECT, INSERT ON detalle_pedido TO app_user;