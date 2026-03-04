-- =============================================
-- CALZADO APP v2.0 - Base de Datos
-- Control de Inventario Multi-Sucursal
-- Versión empresarial con auditoría y compras
-- =============================================

-- =============================================
-- TABLAS BASE
-- =============================================

CREATE TABLE sucursales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255),
    telefono VARCHAR(20),
    activa TINYINT(1) DEFAULT 1,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion TEXT,
    rif VARCHAR(20),
    activo TINYINT(1) DEFAULT 1,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin','gerente','vendedor') DEFAULT 'vendedor',
    sucursal_id INT,
    activo TINYINT(1) DEFAULT 1,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id)
);

-- =============================================
-- PRODUCTOS E INVENTARIO
-- =============================================

CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    categoria_id INT,
    proveedor_id INT,
    descripcion TEXT,
    imagen_url VARCHAR(255),
    activo TINYINT(1) DEFAULT 1,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
);

CREATE TABLE producto_variantes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    talla VARCHAR(10) NOT NULL,
    color VARCHAR(50) NOT NULL,
    costo DECIMAL(10,2) DEFAULT 0,
    precio_venta DECIMAL(10,2) DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
);

CREATE TABLE inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variante_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    stock_actual INT DEFAULT 0,
    stock_minimo INT DEFAULT 5,
    ultimo_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_variante_sucursal (variante_id, sucursal_id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id)
);

-- =============================================
-- HISTORIAL DE PRECIOS (2.3)
-- Registra cada cambio de precio para auditoría
-- =============================================

CREATE TABLE historial_precios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variante_id INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    costo_anterior DECIMAL(10,2),
    costo_nuevo DECIMAL(10,2),
    motivo VARCHAR(255),
    usuario_id INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- =============================================
-- MOVIMIENTOS DE INVENTARIO
-- =============================================

CREATE TABLE movimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variante_id INT NOT NULL,
    sucursal_origen_id INT,
    sucursal_destino_id INT,
    tipo ENUM('entrada','salida','ajuste','transferencia','devolucion_cliente','devolucion_proveedor') NOT NULL,
    cantidad INT NOT NULL,
    motivo VARCHAR(255),
    referencia VARCHAR(100),
    usuario_id INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (sucursal_origen_id) REFERENCES sucursales(id),
    FOREIGN KEY (sucursal_destino_id) REFERENCES sucursales(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- =============================================
-- MÓDULO DE COMPRAS (2.1)
-- Trazabilidad formal de ingresos de inventario
-- =============================================

CREATE TABLE compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    numero_factura VARCHAR(50),
    fecha DATE NOT NULL,
    subtotal DECIMAL(10,2) DEFAULT 0,
    impuesto DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) DEFAULT 0,
    estado ENUM('pendiente','recibida','parcial','anulada') DEFAULT 'pendiente',
    observaciones TEXT,
    usuario_id INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE compra_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    compra_id INT NOT NULL,
    variante_id INT NOT NULL,
    cantidad INT NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    cantidad_recibida INT DEFAULT 0,
    FOREIGN KEY (compra_id) REFERENCES compras(id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
);

-- =============================================
-- CLIENTES Y VENTAS
-- =============================================

CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    cedula VARCHAR(20),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sucursal_id INT NOT NULL,
    cliente_id INT,
    usuario_id INT,
    subtotal DECIMAL(10,2) DEFAULT 0,
    descuento DECIMAL(10,2) DEFAULT 0,
    impuesto DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) DEFAULT 0,
    metodo_pago ENUM('efectivo','transferencia','tarjeta','mixto') DEFAULT 'efectivo',
    estado ENUM('completada','anulada','pendiente') DEFAULT 'completada',
    caja_id INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE venta_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    variante_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento_item DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES ventas(id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
);

-- =============================================
-- DEVOLUCIONES (2.2)
-- =============================================

CREATE TABLE devoluciones_clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    variante_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    cantidad INT NOT NULL,
    motivo VARCHAR(255),
    tipo_resolucion ENUM('reembolso','cambio','credito') DEFAULT 'cambio',
    monto_devuelto DECIMAL(10,2) DEFAULT 0,
    estado ENUM('pendiente','aprobada','rechazada') DEFAULT 'pendiente',
    usuario_id INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venta_id) REFERENCES ventas(id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE devoluciones_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    compra_id INT,
    proveedor_id INT NOT NULL,
    variante_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    cantidad INT NOT NULL,
    motivo VARCHAR(255),
    costo_unitario DECIMAL(10,2) DEFAULT 0,
    monto_total DECIMAL(10,2) DEFAULT 0,
    estado ENUM('pendiente','enviada','confirmada') DEFAULT 'pendiente',
    usuario_id INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (compra_id) REFERENCES compras(id),
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- =============================================
-- CONTROL DE CAJA (3.5)
-- =============================================

CREATE TABLE cajas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sucursal_id INT NOT NULL,
    usuario_apertura_id INT NOT NULL,
    usuario_cierre_id INT,
    monto_apertura DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_cierre_sistema DECIMAL(10,2) DEFAULT 0,
    monto_cierre_fisico DECIMAL(10,2),
    diferencia DECIMAL(10,2),
    estado ENUM('abierta','cerrada') DEFAULT 'abierta',
    fecha_apertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMP NULL,
    observaciones TEXT,
    FOREIGN KEY (sucursal_id) REFERENCES sucursales(id),
    FOREIGN KEY (usuario_apertura_id) REFERENCES usuarios(id),
    FOREIGN KEY (usuario_cierre_id) REFERENCES usuarios(id)
);

-- =============================================
-- AUDITORÍA INTERNA (2.5)
-- =============================================

CREATE TABLE logs_sistema (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    accion VARCHAR(100) NOT NULL,
    tabla_afectada VARCHAR(50),
    id_registro INT,
    datos_anteriores JSON,
    datos_nuevos JSON,
    ip VARCHAR(45),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- =============================================
-- ÍNDICES PARA ESCALABILIDAD (2.4)
-- Optimización para 100.000+ registros
-- =============================================

CREATE INDEX idx_productos_categoria     ON productos(categoria_id);
CREATE INDEX idx_productos_proveedor     ON productos(proveedor_id);
CREATE INDEX idx_variantes_producto      ON producto_variantes(producto_id);
CREATE INDEX idx_inventario_sucursal     ON inventario(sucursal_id);
CREATE INDEX idx_inventario_variante     ON inventario(variante_id);
CREATE INDEX idx_ventas_fecha            ON ventas(creado_en);
CREATE INDEX idx_ventas_sucursal         ON ventas(sucursal_id);
CREATE INDEX idx_ventas_cliente          ON ventas(cliente_id);
CREATE INDEX idx_movimientos_fecha       ON movimientos(creado_en);
CREATE INDEX idx_movimientos_variante    ON movimientos(variante_id);
CREATE INDEX idx_compras_proveedor       ON compras(proveedor_id);
CREATE INDEX idx_compras_fecha           ON compras(fecha);
CREATE INDEX idx_logs_usuario            ON logs_sistema(usuario_id);
CREATE INDEX idx_logs_fecha              ON logs_sistema(fecha);
CREATE INDEX idx_historial_precios_var   ON historial_precios(variante_id);

-- =============================================
-- DATOS INICIALES
-- =============================================

INSERT INTO sucursales (nombre, direccion, telefono) VALUES
('Caracas',      '', ''),
('Valencia',     '', ''),
('Barquisimeto', '', ''),
('Maracaibo',    '', '');

INSERT INTO categorias (nombre) VALUES
('Damas'), ('Caballeros'), ('Niños'), ('Deportivo'), ('Formal');

-- Usuario administrador inicial (password debe hashearse en PHP)
INSERT INTO usuarios (nombre, email, password_hash, rol, sucursal_id) VALUES
('Administrador', 'admin@calzado.com', 'CAMBIAR_POR_HASH_BCRYPT', 'admin', 1);

-- =============================================
-- NOTAS DE IMPLEMENTACIÓN PHP
-- =============================================
-- 1. Usar PDO con prepared statements para prevenir SQL Injection
-- 2. Hashear passwords con password_hash($pass, PASSWORD_BCRYPT)
-- 3. Verificar con password_verify($pass, $hash)
-- 4. Usar sesiones PHP con session_regenerate_id() al login
-- 5. Validar rol del usuario en cada endpoint antes de procesar
-- 6. Insertar en logs_sistema en cada operación crítica (ventas, compras, ajustes)
-- 7. Para reportes PDF usar librería TCPDF o FPDF
