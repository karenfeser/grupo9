SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- Crear base de datos y usarla
CREATE DATABASE IF NOT EXISTS erp_comercial
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE erp_comercial;

-- ------------------------------------------------------------
-- LOOKUPS / CATÁLOGOS
-- ------------------------------------------------------------
CREATE TABLE payment_methods (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE sales_order_status (
  code VARCHAR(20) PRIMARY KEY, -- PENDIENTE, CONFIRMADA, ANULADA
  description VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE purchase_order_status (
  code VARCHAR(20) PRIMARY KEY, -- PENDIENTE, RECEPCIONADA, ANULADA
  description VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE product_categories (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL UNIQUE,
  description VARCHAR(255) NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ADMINISTRACIÓN DE USUARIOS
-- ------------------------------------------------------------
CREATE TABLE roles (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE permissions (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(60) NOT NULL UNIQUE,
  description VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
  role_id SMALLINT UNSIGNED NOT NULL,
  permission_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id),
  CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permissions(id)
) ENGINE=InnoDB;

CREATE TABLE users (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(120) NOT NULL,
  internal_id VARCHAR(50) NULL,
  area VARCHAR(80) NULL,
  username VARCHAR(60) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_id INT UNSIGNED NOT NULL,
  role_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE user_activity_log (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  action VARCHAR(100) NOT NULL,
  details JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ual_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- GESTIÓN DE CLIENTES Y PROVEEDORES
-- ------------------------------------------------------------
CREATE TABLE customers (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  business_name VARCHAR(200) NULL,
  tax_id VARCHAR(20) NULL, -- CUIT/DNI
  phone VARCHAR(40) NULL,
  email VARCHAR(120) NULL,
  address VARCHAR(200) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  zip_code VARCHAR(20) NULL,
  country VARCHAR(80) NULL,
  discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  payment_method_id SMALLINT UNSIGNED NULL,
  credit_limit DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customers_tax (tax_id),
  CONSTRAINT fk_customers_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  business_name VARCHAR(200) NULL,
  tax_id VARCHAR(20) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(120) NULL,
  address VARCHAR(200) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  zip_code VARCHAR(20) NULL,
  country VARCHAR(80) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_suppliers_tax (tax_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PRODUCTOS, PRECIOS, STOCK
-- ------------------------------------------------------------
CREATE TABLE products (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sku VARCHAR(60) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  weight_kg DECIMAL(10,3) NULL,
  volume_m3 DECIMAL(10,4) NULL,
  category_id INT UNSIGNED NULL,
  cost DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  price DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  stock_on_hand DECIMAL(14,3) NOT NULL DEFAULT 0.000, -- unidad genérica
  stock_min DECIMAL(14,3) NOT NULL DEFAULT 0.000,
  stock_max DECIMAL(14,3) NOT NULL DEFAULT 0.000,
  preferred_supplier_id INT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(id),
  CONSTRAINT fk_products_supplier FOREIGN KEY (preferred_supplier_id) REFERENCES suppliers(id)
) ENGINE=InnoDB;

CREATE TABLE product_price_history (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  old_cost DECIMAL(14,4) NULL,
  new_cost DECIMAL(14,4) NULL,
  old_price DECIMAL(14,4) NULL,
  new_price DECIMAL(14,4) NULL,
  changed_by INT UNSIGNED NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pph_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_pph_user FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE product_deactivation_log (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  reason VARCHAR(200) NOT NULL, -- obsolescencia, reemplazo, sin stock, etc.
  deactivated_by INT UNSIGNED NULL,
  deactivated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  previous_state TINYINT(1) NOT NULL,
  CONSTRAINT fk_pdl_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_pdl_user FOREIGN KEY (deactivated_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE stock_movements (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  movement_type ENUM('IN','OUT') NOT NULL,
  source VARCHAR(30) NOT NULL, -- SALES_ORDER, PURCHASE_ORDER, ADJUSTMENT
  source_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(14,3) NOT NULL,
  unit_cost DECIMAL(14,4) NULL,
  note VARCHAR(200) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sm_product FOREIGN KEY (product_id) REFERENCES products(id),
  INDEX idx_sm_source (source, source_id),
  INDEX idx_sm_product_created (product_id, created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- VENTAS (ORDEN DE PEDIDO)
-- ------------------------------------------------------------
CREATE TABLE sales_orders (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  order_number VARCHAR(30) NOT NULL UNIQUE, -- nro de pedido/comprobante
  customer_id INT UNSIGNED NOT NULL,
  status VARCHAR(20) NOT NULL, -- PENDIENTE, CONFIRMADA, ANULADA (FK)
  order_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  payment_method_id SMALLINT UNSIGNED NULL,
  remarks VARCHAR(255) NULL,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_by INT UNSIGNED NULL,
  updated_by INT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_so_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_so_status FOREIGN KEY (status) REFERENCES sales_order_status(code),
  CONSTRAINT fk_so_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
  CONSTRAINT fk_so_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_so_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE sales_order_items (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  sku VARCHAR(60) NOT NULL,
  description VARCHAR(200) NULL,
  quantity DECIMAL(14,3) NOT NULL,
  unit_price DECIMAL(14,4) NOT NULL,
  line_total DECIMAL(14,4) NOT NULL,
  CONSTRAINT fk_soi_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_soi_product FOREIGN KEY (product_id) REFERENCES products(id),
  INDEX idx_soi_order (sales_order_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- COMPRAS (ORDEN DE COMPRA)
-- ------------------------------------------------------------
CREATE TABLE purchase_orders (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  po_number VARCHAR(30) NOT NULL UNIQUE,
  supplier_id INT UNSIGNED NOT NULL,
  status VARCHAR(20) NOT NULL, -- PENDIENTE, RECEPCIONADA, ANULADA
  order_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expected_date DATE NULL,
  remarks VARCHAR(255) NULL,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_by INT UNSIGNED NULL,
  updated_by INT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_po_status FOREIGN KEY (status) REFERENCES purchase_order_status(code),
  CONSTRAINT fk_po_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_po_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_items (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  sku VARCHAR(60) NOT NULL,
  description VARCHAR(200) NULL,
  quantity DECIMAL(14,3) NOT NULL,
  unit_cost DECIMAL(14,4) NOT NULL,
  line_total DECIMAL(14,4) NOT NULL,
  CONSTRAINT fk_poi_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_poi_product FOREIGN KEY (product_id) REFERENCES products(id),
  INDEX idx_poi_order (purchase_order_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PAGOS (SIMPLIFICADO)
-- ------------------------------------------------------------
CREATE TABLE payments (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sales_order_id BIGINT UNSIGNED NULL,
  customer_id INT UNSIGNED NULL,
  payment_method_id SMALLINT UNSIGNED NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reference VARCHAR(80) NULL,
  CONSTRAINT fk_pay_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
  CONSTRAINT fk_pay_sales_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_pay_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  INDEX idx_pay_customer_date (customer_id, paid_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TRIGGERS: ACTUALIZACIÓN AUTOMÁTICA DE STOCK
-- ------------------------------------------------------------

-- Venta: al confirmar el pedido, descuenta stock y registra movimiento
DELIMITER $$
CREATE TRIGGER trg_sales_orders_confirm_stock
AFTER UPDATE ON sales_orders
FOR EACH ROW
BEGIN
  IF OLD.status <> 'CONFIRMADA' AND NEW.status = 'CONFIRMADA' THEN
    -- Descontar stock por cada ítem
    INSERT INTO stock_movements (product_id, movement_type, source, source_id, quantity, unit_cost, note)
    SELECT
      soi.product_id,
      'OUT',
      'SALES_ORDER',
      NEW.id,
      soi.quantity,
      p.cost,
      CONCAT('Pedido de venta ', NEW.order_number)
    FROM sales_order_items soi
    JOIN products p ON p.id = soi.product_id
    WHERE soi.sales_order_id = NEW.id;

    -- Aplicar descuento al stock_on_hand
    UPDATE products p
    JOIN sales_order_items soi ON soi.product_id = p.id AND soi.sales_order_id = NEW.id
    SET p.stock_on_hand = p.stock_on_hand - soi.quantity;
  END IF;
END$$
DELIMITER ;

-- Compra: al recepcionar, aumenta stock y registra movimiento
DELIMITER $$
CREATE TRIGGER trg_purchase_orders_receive_stock
AFTER UPDATE ON purchase_orders
FOR EACH ROW
BEGIN
  IF OLD.status <> 'RECEPCIONADA' AND NEW.status = 'RECEPCIONADA' THEN
    -- Aumentar stock por cada ítem
    INSERT INTO stock_movements (product_id, movement_type, source, source_id, quantity, unit_cost, note)
    SELECT
      poi.product_id,
      'IN',
      'PURCHASE_ORDER',
      NEW.id,
      poi.quantity,
      poi.unit_cost,
      CONCAT('Orden de compra ', NEW.po_number)
    FROM purchase_order_items poi
    WHERE poi.purchase_order_id = NEW.id;

    -- Aplicar incremento al stock_on_hand y actualizar costo promedio simple (opcional)
    UPDATE products p
    JOIN (
      SELECT product_id, SUM(quantity) AS qty, AVG(unit_cost) AS avg_cost
      FROM purchase_order_items
      WHERE purchase_order_id = NEW.id
      GROUP BY product_id
    ) x ON x.product_id = p.id
    SET p.stock_on_hand = p.stock_on_hand + x.qty,
        p.cost = COALESCE(x.avg_cost, p.cost);
  END IF;
END$$
DELIMITER ;

-- Historial de precios al modificar price o cost
DELIMITER $$
CREATE TRIGGER trg_products_price_cost_history
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
  IF (NEW.price <> OLD.price) OR (NEW.cost <> OLD.cost) THEN
    INSERT INTO product_price_history (product_id, old_cost, new_cost, old_price, new_price, changed_at)
    VALUES (OLD.id, OLD.cost, NEW.cost, OLD.price, NEW.price, NOW());
  END IF;
END$$
DELIMITER ;

-- Log de baja de producto
DELIMITER $$
CREATE TRIGGER trg_products_deactivation_log
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  IF OLD.is_active = 1 AND NEW.is_active = 0 THEN
    INSERT INTO product_deactivation_log (product_id, reason, deactivated_by, previous_state, deactivated_at)
    VALUES (NEW.id, 'Baja de producto (manual)', NULL, 1, NOW());
  END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- VISTAS ÚTILES
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_customer_purchase_history AS
SELECT
  so.id AS sales_order_id,
  so.order_number,
  so.order_datetime,
  so.customer_id,
  c.name AS customer_name,
  so.status,
  so.total_amount
FROM sales_orders so
JOIN customers c ON c.id = so.customer_id;

CREATE OR REPLACE VIEW v_product_stock_kardex AS
SELECT
  p.id AS product_id,
  p.sku,
  p.name,
  sm.id AS movement_id,
  sm.created_at,
  sm.movement_type,
  sm.source,
  sm.source_id,
  sm.quantity,
  sm.unit_cost
FROM stock_movements sm
JOIN products p ON p.id = sm.product_id
ORDER BY p.id, sm.created_at;

-- ------------------------------------------------------------
-- ÍNDICES ADICIONALES
-- ------------------------------------------------------------
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_suppliers_name ON suppliers(name);

-- ------------------------------------------------------------
-- SEED BÁSICO
-- ------------------------------------------------------------
INSERT IGNORE INTO payment_methods (name) VALUES
  ('Efectivo'), ('Transferencia'), ('Tarjeta Crédito'), ('Tarjeta Débito'), ('Cuenta Corriente');

INSERT IGNORE INTO sales_order_status (code, description) VALUES
  ('PENDIENTE', 'Pendiente de confirmación'),
  ('CONFIRMADA', 'Confirmada'),
  ('ANULADA', 'Anulada');

INSERT IGNORE INTO purchase_order_status (code, description) VALUES
  ('PENDIENTE', 'Pendiente de recepción'),
  ('RECEPCIONADA', 'Recepcionada'),
  ('ANULADA', 'Anulada');

INSERT IGNORE INTO roles (name) VALUES
  ('Administrador'), ('Ventas'), ('Compras');

INSERT IGNORE INTO permissions (code, description) VALUES
  ('CLIENTS_MANAGE', 'Gestionar clientes'),
  ('PRODUCTS_MANAGE', 'Gestionar productos'),
  ('USERS_MANAGE', 'Gestionar usuarios'),
  ('SALES_MANAGE', 'Gestionar ventas'),
  ('PURCHASES_MANAGE', 'Gestionar compras');

-- Asignar permisos básicos a roles (ejemplo)
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
ON (r.name = 'Administrador') -- admin: todos
WHERE NOT EXISTS (
  SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
ON r.name = 'Ventas' AND p.code IN ('CLIENTS_MANAGE','PRODUCTS_MANAGE','SALES_MANAGE')
WHERE NOT EXISTS (SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
ON r.name = 'Compras' AND p.code IN ('PRODUCTS_MANAGE','PURCHASES_MANAGE')
WHERE NOT EXISTS (SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id);