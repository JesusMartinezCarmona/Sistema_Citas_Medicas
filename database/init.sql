-- ==========================================
-- ESTRUCTURA DE TABLAS (DDL) - SaaS MULTI-TENANT
-- ==========================================

CREATE TABLE IF NOT EXISTS tenant (
    id_tenant INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(150) NOT NULL,
    subdominio VARCHAR(100) NOT NULL UNIQUE,
    plan_suscripcion ENUM('basico', 'pro', 'enterprise') DEFAULT 'basico',
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS clinica (
    id_clinica INT PRIMARY KEY,
    id_tenant INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    direccion VARCHAR(255),
    correo VARCHAR(100),
    telefono VARCHAR(50),
    latitud DECIMAL(10,8),
    longitud DECIMAL(11,8),
    FOREIGN KEY (id_tenant) REFERENCES tenant(id_tenant) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS horarioclinica (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_clinica INT NOT NULL,
    dia_semana ENUM('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo') NOT NULL,
    hora_apertura TIME NOT NULL,
    hora_cierre TIME NOT NULL,
    FOREIGN KEY (id_clinica) REFERENCES clinica(id_clinica) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS especialidad (
    id_especialidad INT AUTO_INCREMENT PRIMARY KEY,
    id_tenant INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_tenant) REFERENCES tenant(id_tenant) ON DELETE CASCADE,
    UNIQUE(id_tenant, nombre)
);

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_tenant INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    password VARCHAR(255) NOT NULL,
    tipo_usuario ENUM('paciente', 'doctor', 'admin') NOT NULL,
    FOREIGN KEY (id_tenant) REFERENCES tenant(id_tenant) ON DELETE CASCADE,
    UNIQUE(id_tenant, correo)
);

CREATE TABLE IF NOT EXISTS paciente (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    rfc VARCHAR(13) NOT NULL,
    penalizado_hasta DATE DEFAULT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS doctor (
    id_doctor INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    id_especialidad INT NOT NULL,
    id_clinica INT NOT NULL,
    numero_licencia VARCHAR(50) NOT NULL,
    estado_doctor ENUM('activo', 'vacaciones', 'permiso', 'inactivo') DEFAULT 'activo',
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_especialidad) REFERENCES especialidad(id_especialidad),
    FOREIGN KEY (id_clinica) REFERENCES clinica(id_clinica)
);

CREATE TABLE IF NOT EXISTS disponibilidad (
    id_disponibilidad INT AUTO_INCREMENT PRIMARY KEY,
    id_doctor INT NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado ENUM('disponible', 'ocupado') DEFAULT 'disponible',
    FOREIGN KEY (id_doctor) REFERENCES doctor(id_doctor) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cita (
    id_cita INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_doctor INT NOT NULL,
    id_disponibilidad INT NOT NULL UNIQUE,
    motivo VARCHAR(255),
    estado ENUM('programada', 'completada', 'cancelada') DEFAULT 'programada',
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
    FOREIGN KEY (id_paciente) REFERENCES paciente(id_paciente) ON DELETE CASCADE,
    FOREIGN KEY (id_doctor) REFERENCES doctor(id_doctor) ON DELETE CASCADE,
    FOREIGN KEY (id_disponibilidad) REFERENCES disponibilidad(id_disponibilidad)
);

CREATE TABLE IF NOT EXISTS pago (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_cita INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    estado_pago ENUM('pendiente', 'pagado', 'fallido') DEFAULT 'pendiente',
    metodo_pago VARCHAR(50),
    transaccion_id VARCHAR(100),
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cita) REFERENCES cita(id_cita) ON DELETE CASCADE
);

-- ==========================================
-- AUTOMATIZACIÓN (TRIGGERS)
-- ==========================================
DELIMITER //

CREATE TRIGGER actualizar_disponibilidad_cita
AFTER INSERT ON cita
FOR EACH ROW
BEGIN
    UPDATE disponibilidad SET estado = 'ocupado' WHERE id_disponibilidad = NEW.id_disponibilidad;
END //

CREATE TRIGGER gestionar_cancelacion_y_penalizacion
AFTER UPDATE ON cita
FOR EACH ROW
BEGIN
    DECLARE total_cancelaciones INT;

    IF NEW.estado = 'cancelada' AND OLD.estado != 'cancelada' THEN
        
        UPDATE disponibilidad SET estado = 'disponible' WHERE id_disponibilidad = NEW.id_disponibilidad;

        SELECT COUNT(*) INTO total_cancelaciones
        FROM cita
        WHERE id_paciente = NEW.id_paciente
          AND estado = 'cancelada'
          AND MONTH(fecha_actualizacion) = MONTH(CURRENT_DATE())
          AND YEAR(fecha_actualizacion) = YEAR(CURRENT_DATE());

        IF total_cancelaciones >= 3 THEN
            UPDATE paciente 
            SET penalizado_hasta = DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY) 
            WHERE id_paciente = NEW.id_paciente;
        END IF;

    END IF;
END //
DELIMITER ;

-- ==========================================
-- DATOS DE PRUEBA (SaaS)
-- ==========================================

INSERT INTO tenant (nombre_empresa, subdominio, plan_suscripcion) 
VALUES 
('Grupo Médico Ensenada', 'gme', 'pro'),
('Pediatras del Noroeste', 'pediatrasnw', 'basico');

INSERT INTO especialidad (id_tenant, nombre) VALUES (1, 'Medicina General'), (1, 'Cardiología');

INSERT INTO clinica (id_clinica, id_tenant, nombre, direccion, correo, telefono, latitud, longitud) 
VALUES (1, 1, 'Clínica Ensenada Matriz', 'Av. Ryerson', 'contacto@clinicaens.com', '6461234567', 31.8667, -116.5964);

INSERT INTO usuario (id_tenant, nombre, apellido, correo, password, tipo_usuario) VALUES 
(1, 'Alejandro', 'Chavez', 'alejandro@mail.com', 'weroereselmejor2000', 'paciente'),
(1, 'Luis', 'Torres', 'luis.t@mail.com', 'weroereselmejor2000', 'doctor'),
(1, 'Admin', 'Sistemas', 'admin@mail.com', 'weroereselmejor2000', 'admin');

INSERT INTO paciente (id_usuario, rfc) VALUES (1, 'CURP123456');
INSERT INTO doctor (id_usuario, id_especialidad, id_clinica, numero_licencia) VALUES (2, 1, 1, 'LIC777');

INSERT INTO especialidad (id_tenant, nombre) VALUES (2, 'Pediatría');

INSERT INTO clinica (id_clinica, id_tenant, nombre, direccion) 
VALUES (2, 2, 'Sucursal Tijuana', 'Zona Rio');

INSERT INTO usuario (id_tenant, nombre, apellido, correo, password, tipo_usuario) VALUES 
(2, 'Alejandro', 'Chavez', 'alejandro@mail.com', 'weroereselmejor2000', 'paciente'),
(2, 'Ana', 'Gomez', 'ana.g@mail.com', 'weroereselmejor2000', 'doctor')